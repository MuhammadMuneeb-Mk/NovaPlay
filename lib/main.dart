import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'screens/auth/login_screen.dart';
import 'utils/theme.dart';
import 'providers/theme_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/download_provider.dart';
import 'providers/owned_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  // always start on the login screen, even if a session was saved last time
  await authProvider.logout();

  final profileProvider = ProfileProvider();
  final ownedProvider = OwnedProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: profileProvider),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
        ChangeNotifierProvider.value(value: ownedProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NovaPlay',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: context.watch<ThemeProvider>().themeMode,
      home: auth.isLoggedIn ? HomeScreen() : LoginScreen(),
    );
  }
}
