import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Thin wrapper over local_auth for biometric (Face ID / fingerprint) unlock.
class Biometric {
  Biometric._();
  static final Biometric instance = Biometric._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// True if the device has biometrics (or device credentials) available.
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Prompts for biometric auth. Returns true on success.
  Future<bool> authenticate({String reason = 'Unlock your vault'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
      );
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
