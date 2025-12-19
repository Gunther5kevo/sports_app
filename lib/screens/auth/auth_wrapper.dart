import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';
import 'sign_in_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show sign in screen if not authenticated
        if (!snapshot.hasData || snapshot.data == null) {
          return const SignInScreen();
        }

        // Show home screen if authenticated
        return const HomeScreen();
      },
    );
  }
}