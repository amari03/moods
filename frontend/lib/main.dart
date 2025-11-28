import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/activation_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_mood_screen.dart';

void main() {
  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    // Login Route
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    // Sign Up Route
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    // Activation Route
    GoRoute(
      path: '/activate',
      builder: (context, state) {
        final token = state.uri.queryParameters['token'] ?? '';
        return ActivationScreen(token: token);
      },
    ),
    // Dashboard Route
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    // Add/Edit Mood Route
    GoRoute(
      path: '/add-mood',
      builder: (context, state) {
        // This handles both ADD (extra is null) and EDIT (extra has data)
        final moodToEdit = state.extra as Map<String, dynamic>?;
        return AddMoodScreen(moodToEdit: moodToEdit);
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'Feel Flow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}