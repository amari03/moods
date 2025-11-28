import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../api/api_service.dart';

class ActivationScreen extends StatefulWidget {
  final String token;
  const ActivationScreen({super.key, required this.token});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  String _status = "Activating your account...";
  bool _success = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _activate();
  }

  Future<void> _activate() async {
    try {
      // Delay slightly to ensure UI builds first
      await Future.delayed(const Duration(seconds: 1));
      
      await ApiService.activateAccount(widget.token);
      
      if (mounted) {
        setState(() {
          _success = true;
          _status = "Account successfully activated!\nYou can now log in.";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _success = false;
          // This will show us EXACTLY why it failed (e.g., "Invalid token")
          _status = "Activation Failed:\n${e.toString().replaceAll('Exception: ', '')}";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Icon(
                  _success ? Icons.check_circle : Icons.error,
                  color: _success ? Colors.green : Colors.red,
                  size: 100,
                ),
              const SizedBox(height: 30),
              
              Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: _success ? Colors.black : Colors.red
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Only show the Login button if it actually succeeded, 
              // or if the user wants to try logging in anyway.
              ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _success ? Colors.deepPurple : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text("Go to Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}