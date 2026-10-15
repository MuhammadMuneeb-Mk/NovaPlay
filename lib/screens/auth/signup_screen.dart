import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isChecked = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Terms & Conditions'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('NovaPlay Terms & Conditions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  SizedBox(height: 12),
                  Text(
                    'Last updated: April 26, 2026\n\n'
                        '1. Acceptance of Terms\n'
                        'By creating an account on NovaPlay, you agree to be bound by these Terms & Conditions.\n\n'
                        '2. Ownership\n'
                        'This application and all its content, features, and functionality are owned by Muneeb. All rights are reserved.\n\n'
                        '3. Prohibited Use\n'
                        'You may not:\n'
                        '   - Copy, modify, or distribute any part of the app without written permission.\n'
                        '   - Attempt to hack, reverse‑engineer, or disrupt the app\'s functionality.\n'
                        '   - Use the app for any illegal or unauthorized purpose.\n'
                        '   - Share your account credentials with others.\n\n'
                        '4. Account Termination\n'
                        'We reserve the right to suspend or terminate your account if you violate these terms.\n\n'
                        '5. Disclaimer of Warranties\n'
                        'The app is provided "as is" without any warranties. We do not guarantee uninterrupted service.\n\n'
                        '6. Limitation of Liability\n'
                        'Muneeb shall not be liable for any damages arising from your use of the app.\n\n'
                        '7. Changes to Terms\n'
                        'We may update these terms from time to time. Continued use of the app implies acceptance.\n\n'
                        '8. Governing Law\n'
                        'These terms shall be governed by the laws of your jurisdiction.\n\n'
                        '9. Contact\n'
                        'For any questions, please contact support at muneeb@novaplay.com\n\n'
                        'By checking the box and clicking "Sign Up", you acknowledge that you have read, understood, and agree to be bound by these Terms & Conditions.',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        );
      },
    );
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate() && _isChecked) {
      final username = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authService = AuthService(authProvider);
      final success = await authService.signup(username, email, password, username);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created! Please log in.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup failed")),
        );
      }
    } else if (!_isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must accept the Terms & Conditions")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text("Create Account", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (value) => value == null || value.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter email';
                  if (!value.contains('@')) return 'Enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter password';
                  if (value.length < 4) return 'Password must be at least 4 characters';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _isChecked,
                    onChanged: (value) => setState(() => _isChecked = value ?? false),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _showTermsDialog,
                      child: const Text(
                        'I have read and agree to the Terms & Conditions',
                        style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSignUp,
                  child: const Text("Sign Up"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}