import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _displayNameController = TextEditingController(text: auth.user?['display_name']?.toString() ?? '');
    _usernameController = TextEditingController(text: auth.user?['username']?.toString() ?? '');
    _emailController = TextEditingController(text: auth.user?['email']?.toString() ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool _hasChanges() {
    final auth = context.read<AuthProvider>();
    final currentDisplayName = auth.user?['display_name']?.toString() ?? '';
    final currentUsername = auth.user?['username']?.toString() ?? '';
    final currentEmail = auth.user?['email']?.toString() ?? '';
    return _displayNameController.text.trim() != currentDisplayName ||
        _usernameController.text.trim() != currentUsername ||
        _emailController.text.trim() != currentEmail;
  }

  // Update profile (username, email, display name)
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to save')),
      );
      Navigator.pop(context);
      return;
    }

    // Dialog for current password
    final TextEditingController passwordController = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Profile Update'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Enter your current password'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true) return;
    final currentPassword = passwordController.text.trim();
    if (currentPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password required to save changes')),
      );
      return;
    }

    setState(() => _isUpdating = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final apiClient = ApiClient(auth);
    final userService = UserService(apiClient);
    final userId = auth.user?['id'];
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not logged in')));
      setState(() => _isUpdating = false);
      return;
    }

    try {
      final updatedUser = await userService.updateUserProfile(
        userId,
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        displayName: _displayNameController.text.trim(),
        currentPassword: currentPassword,
      );
      // Update AuthProvider.user
      await auth.setToken(auth.token!, user: {
        'id': updatedUser.id,
        'username': updatedUser.username,
        'email': updatedUser.email,
        'display_name': updatedUser.displayName,
      });
      // Update ProfileProvider
      context.read<ProfileProvider>().updateProfile(
        displayName: updatedUser.displayName,
        identifier: updatedUser.email,
        password: context.read<ProfileProvider>().password, // unchanged
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      String message = e.toString().replaceAll('Exception: ', '');
      if (message.contains('Username already taken')) {
        message = 'Username already taken. Please choose another.';
      } else if (message.contains('Email already registered')) {
        message = 'Email already registered. Please use another email.';
      } else if (message.contains('Current password is incorrect')) {
        message = 'Current password is incorrect.';
      } else if (message.contains('401') || message.contains('Session expired')) {
        message = 'Session expired. Please login again.';
        auth.logout();
        Navigator.pushReplacementNamed(context, '/login');
      } else if (message.contains('SocketException')) {
        message = 'Network error. Please check your connection.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() => _isUpdating = false);
    }
  }

// Change password (separate dialog)
  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
                validator: (v) => v == null || v.length < 4 ? 'Minimum 4 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm New Password'),
                validator: (v) => v == newPasswordController.text ? null : 'Passwords do not match',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final apiClient = ApiClient(auth);
    final userService = UserService(apiClient);
    final userId = auth.user?['id'];
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not logged in')));
      return;
    }

    try {
      await userService.changePassword(
        userId,
        currentPassword: currentPasswordController.text.trim(),
        newPassword: newPasswordController.text.trim(),
      );
      // Update local password in ProfileProvider (optional)
      context.read<ProfileProvider>().updateProfile(password: newPasswordController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully!')),
      );
    } catch (e) {
      String message = e.toString().replaceAll('Exception: ', '');
      if (message.contains('Current password is incorrect')) {
        message = 'Current password is incorrect.';
      } else if (message.contains('401') || message.contains('Session expired')) {
        message = 'Session expired. Please login again.';
        auth.logout();
        Navigator.pushReplacementNamed(context, '/login');
      } else if (message.contains('SocketException')) {
        message = 'Network error. Please check your connection.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(labelText: 'Display Name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter display name' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter username' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter email';
                  if (!v.contains('@')) return 'Enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: _isUpdating
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save Profile'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _changePassword,
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange)),
                  child: const Text('Change Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}