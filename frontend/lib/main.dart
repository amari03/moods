import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/activation_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_mood_screen.dart';
import 'api/api_service.dart'; // Import ApiService

void main() {
  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  
  // --- THIS IS THE SECURITY GUARD ---
  redirect: (context, state) async {
    final bool loggedIn = await ApiService.isLoggedIn();
    final String location = state.uri.toString();

    // Define which pages are "Public" (anyone can see them)
    final bool isLoggingIn = location == '/';
    final bool isSigningUp = location == '/signup';
    final bool isActivating = location.startsWith('/activate');

    // 1. If user is NOT logged in...
    if (!loggedIn) {
      // ...and tries to go to a protected page (like dashboard or add-mood)
      if (!isLoggingIn && !isSigningUp && !isActivating) {
        return '/'; // Kick them back to login
      }
    } 
    
    // 2. If user IS logged in...
    if (loggedIn) {
      // ...and tries to go back to Login or Signup
      if (isLoggingIn || isSigningUp) {
        return '/dashboard'; // Send them to their dashboard
      }
    }

    // 3. Otherwise, let them go where they want
    return null;
  },
  // ----------------------------------

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