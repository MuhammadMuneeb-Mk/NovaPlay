import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../home_screen.dart';
import 'signup_screen.dart';
import 'forgot_password.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../../providers/owned_provider.dart';
import '../../app_config.dart';
import '../../services/mock_backend.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _useDemoAccount() {
    _identifierController.text = MockBackend.demoUsername;
    _passwordController.text = MockBackend.demoPassword;
    _handleLogin();
  }

  void _showDemoAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Demo account"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Use this account to try the app:"),
            SizedBox(height: 12),
            SelectableText(
              "Username: ${MockBackend.demoUsername}\nPassword: ${MockBackend.demoPassword}",
              style: TextStyle(fontWeight: FontWeight.bold, height: 1.6),
            ),
            SizedBox(height: 12),
            Text(
              "This version uses sample data saved in your browser.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _useDemoAccount();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text("Log in as demo"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final username = _identifierController.text.trim();
      final password = _passwordController.text;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authService = AuthService(authProvider);
      try {
        final success = await authService.login(username, password);
        if (success) {
          final user = authProvider.user;
          if (user != null) {
            context.read<ProfileProvider>().setProfile(
              displayName: user['display_name'] ?? user['username'],
              identifier: user['email'] ?? user['username'],
              password: password,
            );
          }
          final ownedProvider = Provider.of<OwnedProvider>(
            context,
            listen: false,
          );
          final apiClient = ApiClient(authProvider);
          await ownedProvider.loadOwnedGames(apiClient);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid username or password')),
          );
        }
      } catch (e) {
        String errorMsg = e.toString();
        if (errorMsg.contains('SocketException')) {
          errorMsg = 'Network error. Please check your internet connection.';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    "NovaPlay",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Your Game Store",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _identifierController,
                    decoration: const InputDecoration(
                      labelText: "Username or Email",
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter username or email'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password"),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your password'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (AppConfig.demoMode)
                        TextButton.icon(
                          onPressed: _showDemoAccount,
                          icon: const Icon(Icons.person_outline, size: 18),
                          label: const Text("Demo account"),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text("Forgot Password?"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleLogin,
                      child: const Text("Login"),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    child: const Text("Create an account"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
