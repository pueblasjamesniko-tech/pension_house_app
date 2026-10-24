import 'package:flutter/material.dart';
import 'core/config.dart';
import 'core/nav.dart';
import 'core/theme.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.instance.restore();
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    ApiService.instance.sessionExpired.addListener(_onSessionExpired);
  }

  @override
  void dispose() {
    ApiService.instance.sessionExpired.removeListener(_onSessionExpired);
    super.dispose();
  }

  /// The API said our token is no longer valid (JWT expires after ~2 hours).
  void _onSessionExpired() {
    navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('Your session expired. Please sign in again.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.danger,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: Config.appName,
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: messengerKey,
        theme: buildTheme(),
        home: ApiService.instance.signedIn
            ? const HomeShell()
            : const LoginScreen(),
      );
}
