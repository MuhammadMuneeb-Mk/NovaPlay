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
          final ownedProvider = Provider.of<OwnedProvider>(context, listen: false);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
                const Text("Your Game Store", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),
                if (AppConfig.demoMode) ...[
                  _DemoBanner(onUseDemo: _useDemoAccount),
                  const SizedBox(height: 24),
                ],
                TextFormField(
                  controller: _identifierController,
                  decoration: const InputDecoration(labelText: "Username or Email"),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Enter username or email' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                  validator: (value) => value == null || value.isEmpty ? 'Enter your password' : null,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                      );
                    },
                    child: const Text("Forgot Password?"),
                  ),
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
    );
  }
}

class _DemoBanner extends StatelessWidget {
  final VoidCallback onUseDemo;
  const _DemoBanner({required this.onUseDemo});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, color: color),
              const SizedBox(width: 8),
              const Text('Demo', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          const Text('This version uses sample data. Log in with demo / demo1234 or sign up.'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onUseDemo,
              icon: const Icon(Icons.login),
              label: const Text('Use demo account'),
            ),
          ),
        ],
      ),
    );
  }
}
