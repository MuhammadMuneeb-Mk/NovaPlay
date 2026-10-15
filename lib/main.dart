import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'screens/auth/login_screen.dart';
import 'services/api_client.dart';
import 'utils/theme.dart';
import 'providers/theme_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/download_provider.dart';
import 'providers/owned_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'widgets/web_frame.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  await authProvider.loadToken();

  // if already logged in, load profile and owned games like the login screen does
  final profileProvider = ProfileProvider();
  final ownedProvider = OwnedProvider();
  final user = authProvider.user;
  if (authProvider.isLoggedIn && user != null) {
    profileProvider.setProfile(
      displayName: user['display_name'] ?? user['username'] ?? '',
      identifier: user['email'] ?? user['username'] ?? '',
      password: '',
    );
    ownedProvider.loadOwnedGames(ApiClient(authProvider));
  }

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
      // show the app at phone size in a desktop browser
      builder: kIsWeb ? (context, child) => WebFrame(child: child!) : null,
      home: auth.isLoggedIn ? HomeScreen() : LoginScreen(),
    );
  }
}
