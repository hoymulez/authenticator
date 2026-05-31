import 'dart:convert';
import 'dart:typed_data';

import 'package:hashlib/codecs.dart' show toBase32;

import '../models/account.dart';
import 'otpauth.dart';

/// Decodes Google Authenticator export payloads
/// (`otpauth-migration://offline?data=<base64>`) into [Account]s.
///
/// The payload is a protobuf `MigrationPayload { repeated OtpParameters
/// otp_parameters = 1; ... }`. We hand-parse the wire format (no codegen).
class GoogleAuthMigration {
  GoogleAuthMigration._();

  /// Returns the TOTP accounts contained in a migration URI, or [] if none.
  static List<Account> parseUri(String raw) {
    final Uri uri;
    try {
      uri = Uri.parse(raw.trim());
    } catch (_) {
      return const [];
    }
    if (uri.scheme.toLowerCase() != 'otpauth-migration') return const [];
    final data = uri.queryParameters['data'];
    if (data == null || data.isEmpty) return const [];
    final Uint8List bytes;
    try {
      bytes = base64.decode(base64.normalize(data));
    } catch (_) {
      return const [];
    }
    return _parsePayload(bytes);
  }

  static List<Account> _parsePayload(Uint8List bytes) {
    final reader = _ProtoReader(bytes);
    final accounts = <Account>[];
    var index = 0;
    while (!reader.isAtEnd) {
      final tag = reader.readVarint();
      final field = tag >> 3;
      final wire = tag & 0x7;
      if (field == 1 && wire == 2) {
        final sub = reader.readLengthDelimited();
        final a = _parseOtpParameters(sub, index);
        if (a != null) {
          accounts.add(a);
          index++;
        }
      } else {
        reader.skip(wire);
      }
    }
    return accounts;
  }

  static Account? _parseOtpParameters(Uint8List bytes, int index) {
    final reader = _ProtoReader(bytes);
    List<int>? secret;
    String name = '';
    String issuer = '';
    int algorithm = 1; // SHA1
    int digits = 1; // SIX
    int type = 2; // TOTP
    while (!reader.isAtEnd) {
      final tag = reader.readVarint();
      final field = tag >> 3;
      final wire = tag & 0x7;
      switch (field) {
        case 1:
          secret = reader.readLengthDelimited();
          break;
        case 2:
          name = utf8.decode(reader.readLengthDelimited(), allowMalformed: true);
          break;
        case 3:
          issuer = utf8.decode(reader.readLengthDelimited(), allowMalformed: true);
          break;
        case 4:
          algorithm = reader.readVarint();
          break;
        case 5:
          digits = reader.readVarint();
          break;
        case 6:
          type = reader.readVarint();
          break;
        default:
          reader.skip(wire);
      }
    }
    if (secret == null || secret.isEmpty) return null;
    if (type != 2) return null; // only TOTP

    // A GA "name" is often "Issuer:account".
    var label = name;
    if (issuer.isEmpty && name.contains(':')) {
      final parts = name.split(':');
      issuer = parts.first.trim();
      label = parts.sublist(1).join(':').trim();
    }
    if (issuer.isEmpty) issuer = name.isEmpty ? 'Account' : name;

    final algoStr = algorithm == 2
        ? 'SHA-256'
        : algorithm == 3
            ? 'SHA-512'
            : 'SHA-1';

    return Account(
      id: 'ga${DateTime.now().microsecondsSinceEpoch}_$index',
      issuer: issuer,
      label: label.isEmpty ? issuer : label,
      secret: toBase32(secret, padding: false),
      logo: issuer.toLowerCase(),
      color: OtpAuth.colorForIssuer(issuer),
      period: 30,
      digits: digits == 2 ? 8 : 6,
      algorithm: algoStr,
    );
  }
}

/// Minimal protobuf wire-format reader (varint + length-delimited).
class _ProtoReader {
  final Uint8List _b;
  int _pos = 0;
  _ProtoReader(this._b);

  bool get isAtEnd => _pos >= _b.length;

  int readVarint() {
    int result = 0;
    int shift = 0;
    while (_pos < _b.length) {
      final byte = _b[_pos++];
      result |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) break;
      shift += 7;
    }
    return result;
  }

  Uint8List readLengthDelimited() {
    final len = readVarint();
    final end = (_pos + len).clamp(0, _b.length);
    final out = Uint8List.sublistView(_b, _pos, end);
    _pos = end;
    return out;
  }

  /// Skips a field of the given wire type.
  void skip(int wire) {
    switch (wire) {
      case 0:
        readVarint();
        break;
      case 1:
        _pos += 8;
        break;
      case 2:
        final len = readVarint();
        _pos += len;
        break;
      case 5:
        _pos += 4;
        break;
      default:
        _pos = _b.length; // unknown — stop
    }
  }
}
