import 'package:flutter/material.dart';
import '../router.dart';
import 'pin_screen.dart';
import 'vault_screen.dart';

/// The lock gate. Any 6-digit PIN or the biometric shortcut unlocks the vault
/// (the demo does not validate against a stored PIN).
class UnlockScreen extends StatelessWidget {
  const UnlockScreen({super.key});

  void _open(BuildContext context) {
    Navigator.pushReplacement(context, appRoute(const VaultScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return PinScreen(
      mode: PinMode.unlock,
      onComplete: (_) {
        _open(context);
        return true;
      },
      onBiometric: () => _open(context),
    );
  }
}
