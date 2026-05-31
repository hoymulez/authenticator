import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'router.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pin_screen.dart';
import 'screens/unlock_screen.dart';
import 'screens/vault_screen.dart';
import 'state/app_controller.dart';
import 'state/ticker.dart';
import 'theme/app_theme.dart';
import 'widgets/app_scope.dart';
import 'widgets/gradient_scaffold.dart';

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
            home: const _Bootstrap(),
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

/// Decides the first screen: Unlock (vault exists) vs Onboarding (first run).
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decide());
  }

  Future<void> _decide() async {
    final app = AppScope.appOf(context);
    await app.init();
    if (!mounted) return;
    final next = app.hasVault ? const UnlockScreen() : const _SetupFlow();
    Navigator.pushReplacement(context, appRoute(next));
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppScope.themeOf(context);
    return GradientScaffold(
      theme: theme,
      child: Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: theme.accent),
        ),
      ),
    );
  }
}

/// First-run flow: Onboarding → Create PIN → Confirm PIN → create vault → Vault.
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
      onComplete: (pin) async {
        Navigator.push(context, appRoute(_ConfirmPin(firstPin: pin)));
        return true;
      },
    );
  }
}

class _ConfirmPin extends StatelessWidget {
  final String firstPin;
  const _ConfirmPin({required this.firstPin});

  @override
  Widget build(BuildContext context) {
    return PinScreen(
      mode: PinMode.confirm,
      onCancel: () => Navigator.pop(context),
      onComplete: (pin) async {
        if (pin != firstPin) return false;
        await AppScope.appOf(context).createVault(pin);
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(context, appRoute(const VaultScreen()), (r) => false);
        }
        return true;
      },
    );
  }
}
