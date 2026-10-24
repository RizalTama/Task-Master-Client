import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_master/src/providers/auth_provider.dart';
import 'package:task_master/src/screens/home_screen.dart';
import 'package:task_master/src/screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}