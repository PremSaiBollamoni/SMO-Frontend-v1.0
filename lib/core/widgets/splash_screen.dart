import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        child: Stack(children: [
          Positioned(
            top: -50, right: -40,
            child: Container(width: 200, height: 200,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05))),
          ),
          Positioned(
            bottom: -40, left: -50,
            child: Container(width: 180, height: 180,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.secondary.withValues(alpha: 0.12))),
          ),
          Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                child: const Icon(Icons.precision_manufacturing, size: 60, color: AppTheme.primary),
              ),
              const SizedBox(height: 28),
              const Text('SMO System', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Text('Sewing Machine Operations',
                  style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.8), letterSpacing: 0.3)),
              const SizedBox(height: 56),
              SizedBox(width: 32, height: 32,
                  child: CircularProgressIndicator(color: Colors.white.withValues(alpha: 0.9), strokeWidth: 3)),
            ]),
          ),
          Positioned(
            bottom: 32, left: 0, right: 0,
            child: Center(child: Text('Developed for GramTarang Technologies',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)))),
          ),
        ]),
      ),
    );
  }
}
