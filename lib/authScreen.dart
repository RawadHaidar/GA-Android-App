import 'package:flutter/material.dart';
import 'package:kicare_ml_firebase_server1/observer_homepage.dart';

class AuthScreen extends StatefulWidget {
  final bool isSignUp;

  const AuthScreen({super.key, required this.isSignUp});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _serialNumberController = TextEditingController();

  void _authenticate() {
    // Perform sign-in or sign-up logic
    // After success, navigate to ObserverHomePage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const ObserverHomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSignUp ? 'Sign Up' : 'Sign In'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (widget.isSignUp)
              TextField(
                controller: _serialNumberController,
                decoration:
                    const InputDecoration(labelText: 'Device Serial Number'),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _authenticate,
              child: Text(widget.isSignUp ? 'Sign Up' : 'Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
