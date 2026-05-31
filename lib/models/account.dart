import 'package:flutter/material.dart';

/// A single TOTP account in the vault.
@immutable
class Account {
  final String id;
  final String issuer;
  final String label;
  final String secret;
  final String logo;
  final Color color;
  final int period;
  final int digits;
  final String algorithm;

  const Account({
    required this.id,
    required this.issuer,
    required this.label,
    required this.secret,
    required this.logo,
    required this.color,
    this.period = 30,
    this.digits = 6,
    this.algorithm = 'SHA-1',
  });

  Account copyWith({String? issuer, String? label}) {
    return Account(
      id: id,
      issuer: issuer ?? this.issuer,
      label: label ?? this.label,
      secret: secret,
      logo: logo,
      color: color,
      period: period,
      digits: digits,
      algorithm: algorithm,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'issuer': issuer,
        'label': label,
        'secret': secret,
        'logo': logo,
        'color': color.toARGB32(),
        'period': period,
        'digits': digits,
        'algorithm': algorithm,
      };

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as String,
        issuer: j['issuer'] as String,
        label: (j['label'] as String?) ?? '',
        secret: j['secret'] as String,
        logo: (j['logo'] as String?) ?? '',
        color: Color((j['color'] as num).toInt()),
        period: (j['period'] as num?)?.toInt() ?? 30,
        digits: (j['digits'] as num?)?.toInt() ?? 6,
        algorithm: (j['algorithm'] as String?) ?? 'SHA-1',
      );
}
