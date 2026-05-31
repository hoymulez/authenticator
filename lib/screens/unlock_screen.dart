import 'package:flutter/material.dart';
import '../router.dart';
import '../services/biometric.dart';
import '../widgets/app_scope.dart';
import 'pin_screen.dart';
import 'vault_screen.dart';

/// The lock gate. A correct PIN (or biometric, if enabled) decrypts the vault.
class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  @override
  void initState() {
    super.initState();
    // Offer biometric immediately if it's set up.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final app = AppScope.appOf(context);
      if (app.biometricEnabled) _biometric();
    });
  }

  void _open() {
    if (!mounted) return;
    Navigator.pushReplacement(context, appRoute(const VaultScreen()));
  }

  Future<void> _biometric() async {
    final app = AppScope.appOf(context);
    if (!await Biometric.instance.authenticate(reason: 'Unlock Bitanon')) return;
    if (await app.unlockWithCachedKey()) _open();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.appOf(context);
    return PinScreen(
      mode: PinMode.unlock,
      onComplete: (pin) async {
        final ok = await app.unlockWithPin(pin);
        if (ok) _open();
        return ok;
      },
      onBiometric: app.biometricEnabled ? _biometric : null,
    );
  }
}
