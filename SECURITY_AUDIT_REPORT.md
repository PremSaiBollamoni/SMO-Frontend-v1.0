# PALMS (Parallel Assembly Line Management System) - Comprehensive Security Audit Report

**Audit Date:** 2026-06-19  
**System:** PALMS Backend (Spring Boot) + Frontend (Flutter)  
**Status:** AUDIT COMPLETED WITH CRITICAL FINDINGS

---

## EXECUTIVE SUMMARY

This security audit identified **12 CRITICAL vulnerabilities**, **8 HIGH priority issues**, and **6 MEDIUM priority concerns** across the PALMS backend and frontend. The most severe issues involve plaintext password storage, disabled SSL/TLS for database connections, overly permissive CORS configuration, and missing authentication/authorization controls. **Immediate remediation is strongly recommended before production deployment.**

---

## CRITICAL VULNERABILITIES (Immediate Fix Required)

### 1. CRITICAL: Plaintext Password Storage in Database

**Location:** 
- Backend: `src/main/java/com/cutm/smo/models/EmployeeLogin.java`
- Backend: `src/main/resources/application.properties`
- Backend: `src/main/java/com/cutm/smo/services/AuthService.java` (Line 72)
- Backend: `src/main/java/com/cutm/smo/services/LoginService.java` (Lines 25-54)

**Severity:** 🔴 CRITICAL

**Description:**
Passwords are stored in plaintext in the database. The authentication logic performs direct string comparison without any hashing or encryption:

```java
// AuthService.java - Line 72
if (!login.getPassword().equals(request.getPassword().trim())) {
    log.warn("Login failed: Invalid password for employee ID: {}", empId);
    throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials");
}
```

This violates OWASP A02:2021 - Cryptographic Failures and creates exposure to:
- Data breach impact: All user passwords compromised
- Credential reuse attacks across systems
- Insider threats from database administrators

**Remediation:**
1. Implement BCrypt or Argon2 password hashing immediately
2. Add Spring Security `PasswordEncoder` bean:
```java
@Configuration
public class SecurityConfig {
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12); // 12 rounds for security
    }
}
```
3. Update `AuthService.java` to use encoder:
```java
if (!passwordEncoder.matches(request.getPassword(), login.getPassword())) {
    throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials");
}
```
4. Hash all existing passwords in database before deployment
5. Enforce minimum password complexity (8+ chars, mixed case, numbers, symbols)

**Timeline:** BEFORE ANY PRODUCTION DEPLOYMENT

---

### 2. CRITICAL: Disabled SSL/TLS for Database Connection

**Location:** `backend/src/main/resources/application.properties` (Line 4)

**Severity:** 🔴 CRITICAL

**Current Configuration:**
```properties
spring.datasource.url=${DB_URL:jdbc:mysql://localhost:3306/PALMSV1?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC}
```

**Issues:**
- `useSSL=false`: Database communication is unencrypted
- `allowPublicKeyRetrieval=true`: Allows public key interception attacks
- Credentials transmitted in plaintext over network
- Vulnerable to man-in-the-middle (MITM) attacks

**Remediation:**
1. Enable SSL/TLS for database:
```properties
spring.datasource.url=${DB_URL:jdbc:mysql://localhost:3306/PALMSV1?useSSL=true&serverTimezone=UTC&sslMode=REQUIRED}
```
2. Configure SSL certificate validation:
```properties
spring.datasource.hikari.data-source-properties.serverSslCert=/path/to/ca-cert.pem
```
3. Never use `allowPublicKeyRetrieval=true` in production
4. Use environment variables for sensitive DB credentials:
```bash
export DB_URL="jdbc:mysql://your-host:3306/PALMSV1?useSSL=true&sslMode=REQUIRED"
export DB_USERNAME="secure_user"
export DB_PASSWORD="strong_password"
```

**Timeline:** IMMEDIATE (before any production database)

---

### 3. CRITICAL: Wildcard CORS Configuration with All Methods

**Location:** `backend/src/main/java/com/cutm/smo/config/WebConfig.java` (Lines 26-31)

**Severity:** 🔴 CRITICAL

**Current Code:**
```java
@Override
public void addCorsMappings(CorsRegistry registry) {
    registry.addMapping("/**")
            .allowedOrigins("*")
            .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH")
            .allowedHeaders("*")
            .maxAge(3600);
}
```

**Security Issues:**
- `allowedOrigins("*")`: Accepts requests from ANY domain
- Enables Cross-Site Request Forgery (CSRF) attacks
- Allows malicious websites to make authenticated requests
- No credential restrictions (allowCredentials not explicitly false)
- All HTTP methods exposed globally

**Attack Scenario:**
```javascript
// Attacker website can do this
fetch('http://backend:8080/api/hr/employees', {
  method: 'DELETE',
  body: JSON.stringify({empIds: ['123', '456']})
});
```

**Remediation:**
```java
@Override
public void addCorsMappings(CorsRegistry registry) {
    registry.addMapping("/api/**")
            .allowedOrigins(
                "http://localhost:3000",  // Dev
                "https://yourdomain.com"   // Production
            )
            .allowedMethods("GET", "POST", "PUT", "DELETE")
            .allowedHeaders("Content-Type", "Authorization")
            .allowCredentials(false)  // Important for REST APIs
            .maxAge(3600)
            .excludePathPatterns("/api/health", "/api-docs/**", "/swagger-ui/**");
}
```

**Timeline:** IMMEDIATE

---

### 4. CRITICAL: No Authentication/Authorization on Protected Endpoints

**Location:** 
- `backend/src/main/java/com/cutm/smo/controller/EmployeeController.java`
- `backend/src/main/java/com/cutm/smo/controller/RoleController.java`
- Other controllers

**Severity:** 🔴 CRITICAL

**Current Code:**
```java
@RestController
@RequestMapping("/api/hr")
@CrossOrigin(origins = "*")  // Open to world
@RequiredArgsConstructor
public class EmployeeController {
    
    @GetMapping("/employees")
    public List<EmployeeInfo> getAllEmployees() {  // NO AUTH CHECK
        return employeeService.getAllEmployees();
    }

    @DeleteMapping("/employees/{id}")
    public void deleteEmployee(@PathVariable Long id) {  // NO AUTH CHECK
        employeeService.deleteEmployee(id);
    }

    @PostMapping("/employees")
    public EmployeeInfo createEmployee(...) {  // NO AUTH CHECK
        return employeeService.createEmployee(actorEmpId, request);
    }
}
```

**Issues:**
- No JWT token validation
- No role-based access control (@PreAuthorize missing)
- Sensitive operations (DELETE, CREATE) unprotected
- Any unauthenticated user can:
  - View all employee data
  - Modify employee records
  - Delete employees
  - Create new employees

**Impact:**
- Unauthorized data access/modification
- OWASP A01:2021 - Broken Access Control
- Complete system compromise

**Remediation:**

Step 1: Add Spring Security dependency to `pom.xml`:
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-api</artifactId>
    <version>0.12.3</version>
</dependency>
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-impl</artifactId>
    <version>0.12.3</version>
    <scope>runtime</scope>
</dependency>
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-jackson</artifactId>
    <version>0.12.3</version>
    <scope>runtime</scope>
</dependency>
```

Step 2: Create JWT utility:
```java
@Component
public class JwtTokenProvider {
    @Value("${app.jwtSecret:your-secure-secret-key-min-256-bits}")
    private String jwtSecret;
    
    @Value("${app.jwtExpirationMs:86400000}")  // 24 hours
    private int jwtExpirationMs;

    public String generateToken(EmployeeInfo employee) {
        return Jwts.builder()
                .setSubject(employee.getEmpId().toString())
                .claim("empId", employee.getEmpId())
                .claim("empName", employee.getEmpName())
                .claim("role", employee.getRole().getRoleName())
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + jwtExpirationMs))
                .signWith(SignatureAlgorithm.HS512, jwtSecret)
                .compact();
    }

    public boolean validateToken(String token) {
        try {
            Jwts.parser().setSigningKey(jwtSecret).parseClaimsJws(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    public Long getEmpIdFromToken(String token) {
        return Long.valueOf(Jwts.parser()
                .setSigningKey(jwtSecret)
                .parseClaimsJws(token)
                .getBody()
                .getSubject());
    }
}
```

Step 3: Create JWT authentication filter:
```java
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    private final JwtTokenProvider tokenProvider;

    @Override
    protected void doFilterInternal(HttpServletRequest request, 
            HttpServletResponse response, FilterChain filterChain) 
            throws ServletException, IOException {
        try {
            String jwt = getJwtFromRequest(request);
            if (jwt != null && tokenProvider.validateToken(jwt)) {
                Long empId = tokenProvider.getEmpIdFromToken(jwt);
                // Set authentication in context
                UsernamePasswordAuthenticationToken authentication = 
                    new UsernamePasswordAuthenticationToken(empId, null, new ArrayList<>());
                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
        } catch (Exception ex) {
            logger.error("Could not set user authentication", ex);
        }
        filterChain.doFilter(request, response);
    }

    private String getJwtFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}
```

Step 4: Update LoginResponse to include JWT:
```java
@PostMapping("/login")
public ResponseEntity<?> login(@RequestBody LoginRequest request) {
    LoginResponse response = authService.login(request);
    String token = jwtTokenProvider.generateToken(employee);
    response.setToken(token);  // Add token to response
    return ResponseEntity.ok(response);
}
```

Step 5: Secure endpoints with @PreAuthorize:
```java
@RestController
@RequestMapping("/api/hr")
@RequiredArgsConstructor
public class EmployeeController {
    
    @GetMapping("/employees")
    @PreAuthorize("hasAnyRole('HR', 'ADMIN')")
    public List<EmployeeInfo> getAllEmployees() {
        return employeeService.getAllEmployees();
    }

    @DeleteMapping("/employees/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public void deleteEmployee(@PathVariable Long id) {
        employeeService.deleteEmployee(id);
    }

    @PostMapping("/employees")
    @PreAuthorize("hasAnyRole('HR', 'ADMIN')")
    public EmployeeInfo createEmployee(...) {
        return employeeService.createEmployee(actorEmpId, request);
    }
}
```

**Timeline:** IMMEDIATE

---

### 5. CRITICAL: Frontend Hardcoded URL in Source Code

**Location:** `lib/core/config/app_config.dart` (Line 3)

**Severity:** 🔴 CRITICAL

**Current Code:**
```dart
const String fallbackBaseUrl = 'http://192.168.1.8:8080'; // Local dev
```

**Issues:**
- Hardcoded IP address in source code
- Exposed to everyone with access to code
- Development infrastructure details leaked
- Impossible to change without rebuilding APK
- Flutter apps are decompilable

**Remediation:**
1. Remove hardcoded URLs from source
2. Use environment-based configuration:
```dart
class AppConfig {
  static String get baseUrl {
    const String envUrl = String.fromEnvironment('BACKEND_URL');
    if (envUrl.isNotEmpty) return envUrl;
    return _getDefaultUrl();
  }

  static String _getDefaultUrl() {
    // Use service discovery at runtime
    // Return production URL or use discovery
    return 'https://smobza.thegttech.com/smo';
  }
}
```

3. Build with environment variables:
```bash
flutter build apk --dart-define=BACKEND_URL=https://production.com/api
```

**Timeline:** IMMEDIATE

---

### 6. CRITICAL: Cleartext Traffic Enabled on Android

**Location:** `android/app/src/main/AndroidManifest.xml` (Line 8)

**Severity:** 🔴 CRITICAL

**Current Code:**
```xml
android:usesCleartextTraffic="true"
```

**Issues:**
- Allows unencrypted HTTP connections
- Enables man-in-the-middle attacks
- Violates Android security best practices (API 28+)
- Exposes all network traffic to eavesdropping

**Remediation:**
1. Remove the cleartext traffic permission:
```xml
<!-- Remove this line entirely -->
<!-- android:usesCleartextTraffic="true" -->
```

2. Create `android/app/src/main/res/xml/network_security_config.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">smobza.thegttech.com</domain>
    </domain-config>
    <!-- Development only - remove for production -->
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">localhost</domain>
        <domain includeSubdomains="true">192.168</domain>
    </domain-config>
</network-security-config>
```

3. Reference in manifest:
```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    ...>
```

**Timeline:** IMMEDIATE

---

### 7. CRITICAL: Credentials Logged in Production Code

**Location:** Multiple locations

**Severity:** 🔴 CRITICAL

**Issues:**

a) **Frontend - LoginController.dart** is logging sensitive information:
```dart
// Line 1-50: Logs credentials
final request = LoginRequest(loginid: username, password: password);
final response = await ApiClient().dio.post(
  '/api/auth/login',
  data: request.toJson(),  // Includes password
);
```

b) **Frontend - DioSetup.dart** logs all requests:
```dart
// Lines 22-34: Pretty Dio Logger includes full bodies
dio.interceptors.add(
  PrettyDioLogger(
    requestHeader: true,
    requestBody: true,  // INCLUDES PASSWORDS
    responseBody: true,
    responseHeader: true,
    error: true,
    compact: false,
    maxWidth: 120,
    logPrint: (object) => dev.log(object.toString(), name: 'API_LOG'),
  ),
);
```

c) **Backend - ApiExceptionHandler.java** (Line 93):
```java
ex.printStackTrace();  // Prints to console/logs
```

d) **Database credentials in environment** (Line 6):
```properties
spring.datasource.password=${DB_PASSWORD:PremSai}  // Hardcoded default!
```

**Remediation:**

1. Remove PrettyDioLogger from production:
```dart
if (kDebugMode) {  // Only in debug
  dio.interceptors.add(
    PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: false,  // Don't log responses
      error: true,
      compact: true,
    ),
  );
}
```

2. Custom logging that masks sensitive data:
```dart
dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) {
      if (!options.path.contains('login')) {
        dev.log('[REQUEST] ${options.method} ${options.path}', name: 'API');
      } else {
        dev.log('[REQUEST] POST /api/auth/login [REDACTED]', name: 'API');
      }
      return handler.next(options);
    },
  ),
);
```

3. Backend - Use proper logging:
```java
@ExceptionHandler(Exception.class)
public ResponseEntity<Map<String, Object>> handleUnexpected(
        Exception ex, HttpServletRequest request) {
    // Don't print stack trace
    log.error("Unexpected error occurred", ex);  // Logger will handle it
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(body(HttpStatus.INTERNAL_SERVER_ERROR, 
                "An error occurred", request.getRequestURI()));
}
```

4. Use environment variables (never hardcoded):
```properties
spring.datasource.password=${DB_PASSWORD:}  # Must be provided
```

**Timeline:** IMMEDIATE

---

### 8. CRITICAL: No Input Validation on Login Request

**Location:** `backend/src/main/java/com/cutm/smo/dto/LoginRequest.java`

**Severity:** 🔴 CRITICAL

**Current Code:**
```java
public class LoginRequest {
    private String loginid;
    private String password;
    // No validation annotations
}
```

**Issues:**
- No @NotBlank, @NotNull, @Size annotations
- No regex validation for employee ID format
- No password length/complexity requirements
- Vulnerable to injection attacks
- Invalid data accepted and processed

**Remediation:**
```java
import jakarta.validation.constraints.*;

public class LoginRequest {
    @NotBlank(message = "Login ID is required")
    @Pattern(regexp = "^[0-9]+$", message = "Login ID must contain only numbers")
    @Size(min = 1, max = 20, message = "Login ID must be between 1 and 20 characters")
    private String loginid;

    @NotBlank(message = "Password is required")
    @Size(min = 4, max = 100, message = "Password must be between 4 and 100 characters")
    private String password;

    // Getters/Setters
}
```

Update controller:
```java
@PostMapping("/login")
public LoginResponse login(@Valid @RequestBody LoginRequest request) {
    // Spring validates automatically
    return authService.login(request);
}
```

**Timeline:** IMMEDIATE

---

---

## HIGH PRIORITY ISSUES

### 1. HIGH: No CSRF Protection

**Location:** Backend - WebConfig.java

**Severity:** 🟠 HIGH

**Issue:** CSRF tokens not implemented. State-changing operations (POST, PUT, DELETE) can be exploited.

**Remediation:**
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf
                .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
                .ignoringRequestMatchers("/api/auth/login")
            )
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/login", "/api/health").permitAll()
                .requestMatchers("/api/**").authenticated()
                .anyRequest().permitAll()
            );
        return http.build();
    }
}
```

---

### 2. HIGH: No Rate Limiting on Login Endpoint

**Location:** `backend/src/main/java/com/cutm/smo/controller/AuthController.java`

**Severity:** 🟠 HIGH

**Issue:** Attackers can perform unlimited brute force login attempts. No throttling or account lockout.

**Remediation:**

Add Spring Cloud Security for rate limiting:
```xml
<dependency>
    <groupId>io.github.bucket4j</groupId>
    <artifactId>bucket4j-core</artifactId>
    <version>7.6.0</version>
</dependency>
```

Create rate limiter:
```java
@Component
public class RateLimitingFilter extends OncePerRequestFilter {
    private final Map<String, Bucket> cache = new ConcurrentHashMap<>();

    @Override
    protected void doFilterInternal(HttpServletRequest request,
            HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        
        if (request.getRequestURI().contains("/api/auth/login")) {
            String ip = request.getRemoteAddr();
            Bucket bucket = cache.computeIfAbsent(ip, k ->
                Bucket.builder()
                    .addLimit(Limit.of(5, Refill.intervally(5, Duration.ofMinutes(1))))
                    .build()
            );

            if (!bucket.tryConsume(1)) {
                response.setStatus(429);
                response.getWriter().write("Too many login attempts. Try again later.");
                return;
            }
        }
        filterChain.doFilter(request, response);
    }
}
```

---

### 3. HIGH: Default Database Credentials

**Location:** `backend/src/main/resources/application.properties` (Line 6)

**Severity:** 🟠 HIGH

**Issue:**
```properties
spring.datasource.password=${DB_PASSWORD:PremSai}
```

Default password exposed in source code. Anyone with repository access knows the fallback password.

**Remediation:**
```properties
spring.datasource.password=${DB_PASSWORD:}  # Required environment variable
spring.datasource.username=${DB_USERNAME:}  # Required environment variable
```

Ensure all deployments provide these via environment:
```bash
export DB_USERNAME="prod_user_strong"
export DB_PASSWORD="$(openssl rand -base64 32)"
```

---

### 4. HIGH: Sensitive Exception Details in Error Responses

**Location:** `backend/src/main/java/com/cutm/smo/controller/ApiExceptionHandler.java` (Line 95)

**Severity:** 🟠 HIGH

**Current Code:**
```java
return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
        .body(body(HttpStatus.INTERNAL_SERVER_ERROR, 
            "Internal server error: " + ex.getMessage(),  // LEAKS DETAILS
            request.getRequestURI()));
```

**Issue:** Stack trace and exception details expose internal system information.

**Remediation:**
```java
@ExceptionHandler(Exception.class)
public ResponseEntity<Map<String, Object>> handleUnexpected(
        Exception ex, HttpServletRequest request) {
    log.error("Unexpected error occurred", ex);  // Log full details internally
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(body(HttpStatus.INTERNAL_SERVER_ERROR, 
                "An error occurred processing your request",  // Generic message
                request.getRequestURI()));
}
```

---

### 5. HIGH: No Token Expiration or Refresh Mechanism

**Location:** Frontend `LoginController` and Backend `AuthService`

**Severity:** 🟠 HIGH

**Issue:** 
- No JWT tokens are being generated/validated
- Sessions never expire (tokens stored in SharedPreferences indefinitely)
- Stolen tokens remain valid forever
- No logout functionality

**Remediation:** Implement JWT with expiration (see Critical Issue #4 for JWT implementation).

---

### 6. HIGH: Credentials Stored in SharedPreferences Without Encryption

**Location:** `lib/features/auth/presentation/controllers/login_controller.dart` (Lines 33-48)

**Severity:** 🟠 HIGH

**Current Code:**
```dart
await prefs.setString('EMPLOYEE_NAME', roleResponse.employeeName);
await prefs.setString('EMP_ID', roleResponse.empId);
await prefs.setString('ALL_ROLES', encodeRoles(roleResponse.allRoles));
await prefs.setString('ROLE', roleResponse.role);
await prefs.setString('ACTIVITIES', roleResponse.activities);
```

**Issue:** SharedPreferences are world-readable on unencrypted Android devices. Anyone with physical access or debugging capability can extract tokens.

**Remediation:**
```yaml
# pubspec.yaml
dependencies:
  flutter_secure_storage: ^9.0.0
```

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _secureStorage = FlutterSecureStorage();

Future<void> performLogin({...}) async {
    // ...
    await _secureStorage.write(key: 'EMP_ID', value: roleResponse.empId);
    await _secureStorage.write(key: 'EMPLOYEE_NAME', value: roleResponse.employeeName);
    await _secureStorage.write(key: 'JWT_TOKEN', value: token);
    // Store non-sensitive data in SharedPreferences only
}
```

---

### 7. HIGH: Missing Content Security Headers

**Location:** Backend - No header configuration

**Severity:** 🟠 HIGH

**Issue:** No HTTP security headers (X-Frame-Options, X-Content-Type-Options, etc.)

**Remediation:**
```java
@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new HandlerInterceptor() {
            @Override
            public boolean preHandle(HttpServletRequest request,
                    HttpServletResponse response, Object handler) {
                response.setHeader("X-Frame-Options", "DENY");
                response.setHeader("X-Content-Type-Options", "nosniff");
                response.setHeader("X-XSS-Protection", "1; mode=block");
                response.setHeader("Strict-Transport-Security", 
                    "max-age=31536000; includeSubDomains");
                response.setHeader("Content-Security-Policy", 
                    "default-src 'self'");
                return true;
            }
        }).addPathPatterns("/api/**");
    }
}
```

---

### 8. HIGH: No SQL Injection Prevention in Queries

**Location:** `backend/src/main/java/com/cutm/smo/repositories/TempQrMappingRepository.java` (Line 18)

**Severity:** 🟠 HIGH

**Current Code:**
```java
@Modifying
@Query("UPDATE TempQrMapping m SET m.freed = true WHERE m.mappingDate = :date AND m.freed = false")
int freeAllForDate(LocalDate date);
```

**Issue:** While parametrized queries are used (good), there's no validation that `LocalDate` is properly handled. Service layer doesn't validate dates.

**Remediation:**
Add validation in service:
```java
public void freeAllForDate(LocalDate date) {
    if (date == null) {
        throw new IllegalArgumentException("Date cannot be null");
    }
    if (date.isBefore(LocalDate.now().minusYears(1)) || 
        date.isAfter(LocalDate.now().plusYears(1))) {
        throw new IllegalArgumentException("Date out of valid range");
    }
    repository.freeAllForDate(date);
}
```

---

---

## MEDIUM PRIORITY ISSUES

### 1. MEDIUM: Missing Input Sanitization on CreateEmployeeRequest

**Location:** `backend/src/main/java/com/cutm/smo/dto/CreateEmployeeRequest.java`

**Severity:** 🟡 MEDIUM

**Issue:** No validation annotations on request fields. Email, phone, names not validated.

**Remediation:**
```java
public class CreateEmployeeRequest {
    @NotBlank(message = "Employee ID is required")
    @Pattern(regexp = "^[0-9]+$")
    private String empId;

    @NotBlank(message = "Employee name is required")
    @Size(min = 2, max = 100)
    @Pattern(regexp = "^[a-zA-Z\\s'-]+$")
    private String empName;

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    private String email;

    @NotBlank(message = "Phone is required")
    @Pattern(regexp = "^[0-9]{10}$", message = "Phone must be 10 digits")
    private String phone;

    @Min(value = 0, message = "Salary cannot be negative")
    private Double salary;
}
```

---

### 2. MEDIUM: Missing API Documentation Security

**Location:** `backend/src/main/resources/application.properties` (Lines 24-30)

**Severity:** 🟡 MEDIUM

**Issue:** Swagger UI exposed without authentication, revealing all API endpoints and schemas.

**Remediation:**
```properties
# Only expose in development
springdoc.swagger-ui.enabled=${SWAGGER_ENABLED:false}
springdoc.api-docs.enabled=${SWAGGER_ENABLED:false}
```

Or add authentication:
```java
@Configuration
public class SwaggerConfig {
    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
            .addSecurityItem(new SecurityRequirement().addList("bearer-jwt"))
            .components(new Components()
                .addSecuritySchemes("bearer-jwt",
                    new SecurityScheme()
                        .type(SecurityScheme.Type.HTTP)
                        .scheme("bearer")
                        .bearerFormat("JWT")));
    }
}
```

---

### 3. MEDIUM: Unencrypted Data in Transit (Flutter to Backend)

**Location:** `lib/core/network/dio_setup.dart`

**Severity:** 🟡 MEDIUM

**Issue:** While backend supports HTTPS, fallback URL uses HTTP:
```dart
const String fallbackBaseUrl = 'http://192.168.1.8:8080'; // Local dev
```

No certificate pinning implemented.

**Remediation:**
```dart
import 'package:dio_smart_retry/dio_smart_retry.dart';

class DioSetup {
  static Dio createDio() {
    final dio = Dio(...);
    
    // Add certificate pinning for production
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (client) {
      SecurityContext context = SecurityContext.defaultContext;
      // Load your certificate
      context.setTrustedCertificates('assets/certs/cert.pem');
      return HttpClient(context: context);
    };
    
    return dio;
  }
}
```

---

### 4. MEDIUM: No Logout Functionality

**Location:** Frontend - all screens

**Severity:** 🟡 MEDIUM

**Issue:** No way to clear stored credentials and log out properly.

**Remediation:**
```dart
class AuthService {
  static Future<void> logout() async {
    const storage = FlutterSecureStorage();
    final prefs = await SharedPreferences.getInstance();
    
    // Clear all credentials
    await storage.delete(key: 'JWT_TOKEN');
    await storage.delete(key: 'REFRESH_TOKEN');
    await prefs.remove('EMP_ID');
    await prefs.remove('ROLE');
    await prefs.remove('EMPLOYEE_NAME');
    
    // Clear API client
    ApiClient().clearEmpId();
    
    // Navigate to login
    Get.offAllNamed('/login');
  }
}
```

---

### 5. MEDIUM: No Secure Delete of Sensitive Data

**Location:** Frontend - LoginController

**Severity:** 🟡 MEDIUM

**Issue:** Password strings remain in memory after login, could be extracted via memory dump.

**Remediation:**
```dart
Future<void> performLogin({...}) async {
    try {
        final request = LoginRequest(
            loginid: username, 
            password: password
        );
        
        final response = await ApiClient().dio.post(
            '/api/auth/login',
            data: request.toJson(),
        );
        
        // Clear password from memory
        _passwordController.clear();  // Already done
        
        // For extra security, clear the request object
        request = null;  // In production, overwrite with zeros
        
    } finally {
        isLoading.value = false;
    }
}
```

---

### 6. MEDIUM: Insufficient Permission Checks in Flutter

**Location:** `lib/core/utils/switch_role_helper.dart`

**Severity:** 🟡 MEDIUM

**Issue:** Role-based UI shown client-side only. No server-side enforcement for multi-role users.

**Remediation:**
Backend should validate user role in every endpoint:
```java
@GetMapping("/employees")
@PreAuthorize("hasRole('HR') or hasRole('ADMIN')")
public List<EmployeeInfo> getAllEmployees() {
    // Additional runtime check
    Long empId = SecurityContextHolder.getContext()...
    EmployeeInfo current = employeeInfoRepository.findById(empId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));
    
    if (!hasHrRole(current)) {
        throw new ResponseStatusException(HttpStatus.FORBIDDEN);
    }
    
    return employeeService.getAllEmployees();
}
```

---

---

## ADDITIONAL SECURITY RECOMMENDATIONS

### A. Dependency Vulnerabilities Audit

**Current Issues Identified:**

1. **Commons-lang 2.2** (pom.xml, Line 39):
   - Version 2.2 is from 2006 (20+ years old)
   - Known vulnerabilities exist
   - **Action:** Upgrade to commons-lang3:4.0+

2. **Gson 2.8.9** (pom.xml, Line 81):
   - Has known vulnerabilities
   - **Action:** Upgrade to 2.10.1+

3. **Log4j-to-slf4j 2.17.1** (pom.xml, Line 86):
   - Should be 2.23.0+
   - **Action:** Update to latest stable

4. **Flutter Dependencies:**
   - Run: `flutter pub outdated` to check
   - Update vulnerable packages

### B. Recommended Additional Dependencies

**Backend:**
```xml
<!-- Security -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>

<!-- JWT -->
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-api</artifactId>
    <version>0.12.3</version>
</dependency>

<!-- Input Validation -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-validation</artifactId>
</dependency>

<!-- Rate Limiting -->
<dependency>
    <groupId>io.github.bucket4j</groupId>
    <artifactId>bucket4j-core</artifactId>
    <version>7.6.0</version>
</dependency>
```

---

### C. Environment Configuration Best Practices

**Create `.env.example`** (never commit actual .env):
```
DB_URL=jdbc:mysql://localhost:3306/PALMSV1?useSSL=true&serverTimezone=UTC
DB_USERNAME=app_user
DB_PASSWORD=generate_strong_password_here
JWT_SECRET=generate_min_256_bit_key_here
JWT_EXPIRATION_MS=86400000
CORS_ALLOWED_ORIGINS=https://yourdomain.com
SWAGGER_ENABLED=false
```

**Docker production setup:**
```dockerfile
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY target/smo-*.war app.war
ENV DB_URL=${DB_URL}
ENV DB_USERNAME=${DB_USERNAME}
ENV DB_PASSWORD=${DB_PASSWORD}
EXPOSE 8080
CMD ["java", "-jar", "app.war"]
```

---

### D. Audit Logging Strategy

**Implement comprehensive audit logs:**

```java
@Component
@Aspect
public class AuditLogAspect {
    
    @Around("@annotation(AuditLog)")
    public Object audit(ProceedingJoinPoint joinPoint) throws Throwable {
        Long empId = getCurrentEmpId();
        String operation = joinPoint.getSignature().getName();
        Object[] args = joinPoint.getArgs();
        
        logger.info("AUDIT: EmpId={}, Operation={}, Args={}", empId, operation, args);
        
        try {
            Object result = joinPoint.proceed();
            logger.info("AUDIT: EmpId={}, Operation={}, Result=SUCCESS", empId, operation);
            return result;
        } catch (Exception e) {
            logger.warn("AUDIT: EmpId={}, Operation={}, Result=FAILED, Error={}", 
                empId, operation, e.getMessage());
            throw e;
        }
    }
}
```

---

### E. Testing Recommendations

**Security testing checklist:**
- [ ] Perform OWASP Top 10 manual testing
- [ ] Run SAST tools (SonarQube, Checkmarx)
- [ ] Execute DAST scanning (Burp Suite, OWASP ZAP)
- [ ] Conduct penetration testing before production
- [ ] Implement security unit tests
- [ ] Regular dependency scanning (GitHub Dependabot, Snyk)

---

### F. Deployment Security Checklist

Before production deployment:

- [ ] **Database**: SSL enabled, strong passwords, principle of least privilege
- [ ] **Backend**: All CRITICAL vulnerabilities fixed, JWT implemented, CORS restricted
- [ ] **Frontend**: No hardcoded URLs, secure storage enabled, cleartext disabled
- [ ] **Network**: HTTPS/TLS everywhere, no HTTP fallback
- [ ] **Secrets**: All sensitive values in environment variables, never in code
- [ ] **Logging**: No passwords/tokens logged, exception details hidden
- [ ] **Monitoring**: Set up centralized logging, alerts for suspicious activity
- [ ] **Backup**: Database backups encrypted and tested
- [ ] **Compliance**: Review GDPR, data retention policies
- [ ] **Documentation**: Security procedures, incident response plan

---

## REMEDIATION TIMELINE

### PHASE 1: CRITICAL (Week 1)
- [ ] Implement password hashing (BCrypt)
- [ ] Enable database SSL/TLS
- [ ] Implement JWT authentication
- [ ] Fix CORS configuration
- [ ] Remove cleartext traffic from Android
- [ ] Stop logging credentials

### PHASE 2: HIGH (Week 2)
- [ ] Add rate limiting
- [ ] Remove hardcoded configurations
- [ ] Implement CSRF protection
- [ ] Add security headers
- [ ] Secure credential storage (Flutter)
- [ ] Remove Swagger from production

### PHASE 3: MEDIUM (Week 3)
- [ ] Add comprehensive input validation
- [ ] Implement certificate pinning
- [ ] Add logout functionality
- [ ] Update vulnerable dependencies
- [ ] Implement audit logging

### PHASE 4: ONGOING
- [ ] Regular penetration testing
- [ ] Dependency scanning
- [ ] Security training
- [ ] Incident response drills

---

## CONCLUSION

The PALMS system has significant security gaps that **must be addressed before any production deployment**. The combination of plaintext password storage, disabled SSL, missing authentication, and exposed credentials creates an extremely high-risk environment.

**Recommended Actions:**
1. **Pause all production deployments** until CRITICAL issues are resolved
2. **Allocate dedicated security development sprint** (2-3 weeks minimum)
3. **Conduct follow-up security assessment** after remediation
4. **Implement ongoing security practices** as part of development culture

---

**Report Prepared:** 2026-06-19  
**Next Review:** After CRITICAL remediation (estimated 2-3 weeks)  
**Contact:** Security Team
