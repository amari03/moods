import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../api/api_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _message;
  bool _isError = false;

  Future<void> _handleSignUp() async {
    try {
      await ApiService.signUp(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
      );
      setState(() {
        _isError = false;
        _message = "Account created! Please check your email to activate.";
      });
    } catch (e) {
      setState(() {
        _isError = true;
        _message = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_message != null)
              Text(
                _message!,
                style: TextStyle(color: _isError ? Colors.red : Colors.green),
                textAlign: TextAlign.center,
              ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _handleSignUp, child: const Text("Sign Up")),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text("Back to Login"),
            )
          ],
        ),
      ),
    );
  }
}