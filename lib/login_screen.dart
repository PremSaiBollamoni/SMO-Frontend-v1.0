import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/controllers/login_controller.dart';

class LoginScreen extends StatefulWidget {
  final Function(bool)? setDarkMode;

  const LoginScreen({super.key, this.setDarkMode});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _controller = Get.put(LoginController());
  bool _obscurePassword = true;

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) return 'Employee ID is required';
    if (value.trim().length < 3) return 'Employee ID must be at least 3 characters';
    if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) return 'Employee ID must contain only numbers';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) return 'Password is required';
    if (value.trim().length < 4) return 'Password must be at least 4 characters';
    return null;
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    _controller.performLogin(
      context: context,
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
      setDarkMode: widget.setDarkMode,
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryVariant, Color(0xFF060D1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            _DecorativeCircle(top: -60, right: -40, size: 200, color: Colors.white.withValues(alpha: 0.05)),
            _DecorativeCircle(top: 80, left: -60, size: 160, color: AppTheme.secondary.withValues(alpha: 0.12)),
            _DecorativeCircle(bottom: -50, right: -30, size: 180, color: Colors.white.withValues(alpha: 0.04)),
            SafeArea(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.vertical),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _BrandHeader(),
                        const SizedBox(height: 36),
                        _LoginCard(
                          formKey: _formKey,
                          usernameController: _usernameController,
                          passwordController: _passwordController,
                          obscurePassword: _obscurePassword,
                          onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                          validateUsername: _validateUsername,
                          validatePassword: _validatePassword,
                          onSubmit: _submit,
                          controller: _controller,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Version $appVersion | GramTarang Technologies",
                          style: AppTheme.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  final double? top, bottom, left, right, size;
  final Color color;

  const _DecorativeCircle({this.top, this.bottom, this.left, this.right, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: const Icon(Icons.precision_manufacturing, size: 48, color: AppTheme.primary),
        ),
        const SizedBox(height: 20),
        Text(
          "SMO System",
          style: AppTheme.displaySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          "Sewing Machine Operations",
          style: AppTheme.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.8), letterSpacing: 0.3),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final FormFieldValidator<String> validateUsername;
  final FormFieldValidator<String> validatePassword;
  final VoidCallback onSubmit;
  final LoginController controller;

  const _LoginCard({
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.validateUsername,
    required this.validatePassword,
    required this.onSubmit,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 12))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Welcome Back", style: AppTheme.headlineMedium.copyWith(color: AppTheme.onSurface, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text("Sign in to continue to your workspace", style: AppTheme.bodyMedium.copyWith(color: AppTheme.onSurfaceVariant)),
              const SizedBox(height: 28),
              TextFormField(
                controller: usernameController,
                validator: validateUsername,
                keyboardType: TextInputType.number,
                decoration: AppTheme.inputDecoration("Employee ID").copyWith(
                  prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                validator: validatePassword,
                obscureText: obscurePassword,
                decoration: AppTheme.inputDecoration("Password").copyWith(
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppTheme.onSurfaceVariant,
                    ),
                    onPressed: onToggleObscure,
                  ),
                ),
                onFieldSubmitted: (_) => onSubmit(),
              ),
              const SizedBox(height: 28),
              Obx(() => SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value ? null : onSubmit,
                  style: AppTheme.primaryButtonStyle.copyWith(elevation: WidgetStateProperty.all(4)),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(color: AppTheme.onPrimary, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Sign In", style: AppTheme.labelLarge.copyWith(color: AppTheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
