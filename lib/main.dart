import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'router.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pin_screen.dart';
import 'screens/vault_screen.dart';
import 'state/app_controller.dart';
import 'state/ticker.dart';
import 'theme/app_theme.dart';
import 'widgets/app_scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppTicker.instance; // start the global heartbeat
  runApp(const BitanonApp());
}

class BitanonApp extends StatefulWidget {
  const BitanonApp({super.key});

  @override
  State<BitanonApp> createState() => _BitanonAppState();
}

class _BitanonAppState extends State<BitanonApp> {
  final ThemeController _themeController = ThemeController();
  final AppController _appController = AppController();

  @override
  void dispose() {
    _themeController.dispose();
    _appController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, _) {
        final theme = _themeController.theme;
        SystemChrome.setSystemUIOverlayStyle(
          theme.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        );
        return AppScope(
          theme: theme,
          themeController: _themeController,
          appController: _appController,
          child: MaterialApp(
            title: 'Bitanon Authenticator',
            debugShowCheckedModeBanner: false,
            theme: _materialTheme(theme),
            home: const _SetupFlow(),
          ),
        );
      },
    );
  }

  ThemeData _materialTheme(AppTheme t) {
    return ThemeData(
      brightness: t.dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: t.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: t.accent,
        brightness: t.dark ? Brightness.dark : Brightness.light,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: t.accent,
        selectionColor: t.accent.withValues(alpha: 0.3),
        selectionHandleColor: t.accent,
      ),
    );
  }
}

/// First-run flow: Onboarding → Create PIN → Confirm PIN → Vault.
class _SetupFlow extends StatelessWidget {
  const _SetupFlow();

  @override
  Widget build(BuildContext context) {
    return OnboardingScreen(
      onDone: () => Navigator.push(context, appRoute(const _CreatePin())),
    );
  }
}

class _CreatePin extends StatelessWidget {
  const _CreatePin();

  @override
  Widget build(BuildContext context) {
    return PinScreen(
      mode: PinMode.create,
      onComplete: (_) {
        Navigator.push(context, appRoute(const _ConfirmPin()));
        return true;
      },
    );
  }
}

class _ConfirmPin extends StatelessWidget {
  const _ConfirmPin();

  @override
  Widget build(BuildContext context) {
    return PinScreen(
      mode: PinMode.confirm,
      onComplete: (_) {
        Navigator.pushAndRemoveUntil(context, appRoute(const VaultScreen()), (r) => false);
        return true;
      },
    );
  }
}
