import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:authenticator/services/otpauth.dart';
import 'package:authenticator/services/totp.dart';
import 'package:authenticator/services/vault_crypto.dart';

void main() {
  test('base32 secret decodes to the RFC 6238 test key', () {
    // "GEZD..." is base32 of ASCII "12345678901234567890".
    final bytes = Totp.decodeSecret('GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ');
    expect(bytes, isNotNull);
    expect(utf8.decode(bytes!), '12345678901234567890');
  });

  test('invalid secrets are rejected', () {
    expect(Totp.isValidSecret('not base 32 !!!'), isFalse);
    expect(Totp.isValidSecret('JBSWY3DPEHPK3PXP'), isTrue);
  });

  test('code formatting groups digits', () {
    expect(Totp.format('123456'), '123 456');
    expect(Totp.format('12345678'), '1234 5678');
  });

  test('vault encrypt/decrypt round-trips with the right PIN', () {
    const json = '{"version":1,"accounts":[]}';
    final blob = VaultCrypto.encryptWithPin(json, '135790');
    final out = VaultCrypto.decryptWithPin(blob, '135790');
    expect(out.json, json);
  });

  test('wrong PIN fails to decrypt (GCM tag mismatch)', () {
    final blob = VaultCrypto.encryptWithPin('secret-data', '135790');
    expect(() => VaultCrypto.decryptWithPin(blob, '000000'), throwsA(anything));
  });

  test('otpauth URI parses into an account', () {
    final a = OtpAuth.parse(
      'otpauth://totp/GitHub:alex?secret=JBSWY3DPEHPK3PXP&issuer=GitHub&digits=6&period=30',
    );
    expect(a, isNotNull);
    expect(a!.issuer, 'GitHub');
    expect(a.label, 'alex');
    expect(a.secret, 'JBSWY3DPEHPK3PXP');
    expect(a.digits, 6);
    expect(a.period, 30);
  });
}
