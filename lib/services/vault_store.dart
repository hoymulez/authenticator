import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/account.dart';

/// Persists the encrypted vault blob. Uses a file on native platforms and
/// falls back to SharedPreferences on web (no file system).
class VaultStore {
  VaultStore._();
  static final VaultStore instance = VaultStore._();

  static const _fileName = 'bitanon_vault.enc';
  static const _prefsKey = 'bitanon_vault_blob';

  File? _file;

  Future<File> _ensureFile() async {
    if (_file != null) return _file!;
    final dir = await getApplicationDocumentsDirectory();
    return _file = File('${dir.path}/$_fileName');
  }

  /// Whether a vault has been created (i.e. a PIN was set).
  Future<bool> exists() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_prefsKey);
    }
    return (await _ensureFile()).exists();
  }

  Future<String?> readBlob() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefsKey);
    }
    final f = await _ensureFile();
    if (!await f.exists()) return null;
    return f.readAsString();
  }

  Future<void> writeBlob(String blob) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, blob);
      return;
    }
    final f = await _ensureFile();
    await f.writeAsString(blob, flush: true);
  }

  Future<void> delete() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
      return;
    }
    final f = await _ensureFile();
    if (await f.exists()) await f.delete();
  }

  /// Serialize accounts to the JSON document that gets encrypted.
  static String encode(List<Account> accounts) =>
      jsonEncode({'version': 1, 'accounts': accounts.map((a) => a.toJson()).toList()});

  static List<Account> decode(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    final list = (map['accounts'] as List).cast<Map<String, dynamic>>();
    return list.map(Account.fromJson).toList();
  }
}
