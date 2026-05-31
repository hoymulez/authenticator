import 'package:flutter/foundation.dart';

import '../models/account.dart';
import '../services/secure_key_store.dart';
import '../services/vault_crypto.dart';
import '../services/vault_store.dart';

enum SyncStatus { synced, syncing, offline }

/// Holds the (decrypted, in-memory) vault plus backup state, and owns
/// persistence: every mutation re-encrypts and writes the vault to disk.
class AppController extends ChangeNotifier {
  final List<Account> _accounts = [];
  List<Account> get accounts => List.unmodifiable(_accounts);
  int get count => _accounts.length;

  // ── Lock / crypto state ─────────────────────────────────────
  Uint8List? _key;
  Uint8List? _salt;
  bool _unlocked = false;
  bool get isUnlocked => _unlocked;

  bool _hasVault = false;
  bool get hasVault => _hasVault;

  bool _biometricEnabled = false;
  bool get biometricEnabled => _biometricEnabled;

  // ── Backup state ────────────────────────────────────────────
  bool _driveConnected = false;
  bool get driveConnected => _driveConnected;
  String? driveEmail;
  DateTime? lastBackupAt;

  SyncStatus _syncStatus = SyncStatus.synced;
  SyncStatus get syncStatus => _syncStatus;

  /// Loads persisted flags before the first screen is shown. Resilient to
  /// storage/plugin errors (treated as "no vault yet").
  Future<void> init() async {
    try {
      _hasVault = await VaultStore.instance.exists();
      _biometricEnabled = await SecureKeyStore.instance.isEnabled;
    } catch (_) {
      _hasVault = false;
      _biometricEnabled = false;
    }
    notifyListeners();
  }

  Account live(Account a) =>
      _accounts.firstWhere((x) => x.id == a.id, orElse: () => a);

  // ── Unlock lifecycle ────────────────────────────────────────

  /// First run: create the vault with a fresh salt + key derived from [pin].
  Future<void> createVault(String pin) async {
    _salt = VaultCrypto.newSalt();
    _key = VaultCrypto.deriveKey(pin, _salt!);
    _accounts.clear();
    _unlocked = true;
    _hasVault = true;
    await _persist();
    notifyListeners();
  }

  /// Returns true if [pin] decrypts the stored vault.
  Future<bool> unlockWithPin(String pin) async {
    final blob = await VaultStore.instance.readBlob();
    if (blob == null) return false;
    try {
      final res = VaultCrypto.decryptWithPin(blob, pin);
      _loadFrom(res.json);
      _key = res.key;
      _salt = res.salt;
      _unlocked = true;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Unlocks using the keystore-cached key (after a successful biometric check).
  Future<bool> unlockWithCachedKey() async {
    final key = await SecureKeyStore.instance.readKey();
    final blob = await VaultStore.instance.readBlob();
    if (key == null || blob == null) return false;
    try {
      final json = VaultCrypto.decryptWithKey(blob, key);
      _loadFrom(json);
      _key = key;
      _unlocked = true;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void lock() {
    _unlocked = false;
    _key = null;
    _salt = null;
    _accounts.clear();
    notifyListeners();
  }

  void _loadFrom(String json) {
    _accounts
      ..clear()
      ..addAll(VaultStore.decode(json));
  }

  Future<void> _persist() async {
    if (_key == null || _salt == null) return;
    final blob = VaultCrypto.encrypt(
      VaultStore.encode(_accounts),
      _key!,
      _salt!,
    );
    await VaultStore.instance.writeBlob(blob);
  }

  // ── Biometric ───────────────────────────────────────────────
  Future<void> setBiometricEnabled(bool enabled) async {
    if (enabled && _key != null) {
      await SecureKeyStore.instance.saveKey(_key!);
      _biometricEnabled = true;
    } else {
      await SecureKeyStore.instance.clear();
      _biometricEnabled = false;
    }
    notifyListeners();
  }

  Future<void> changePin(String newPin) async {
    _salt = VaultCrypto.newSalt();
    _key = VaultCrypto.deriveKey(newPin, _salt!);
    await _persist();
    if (_biometricEnabled) await SecureKeyStore.instance.saveKey(_key!);
    notifyListeners();
  }

  // ── Mutations (persist after each) ──────────────────────────
  Future<void> addAccount(Account a) async {
    if (_accounts.any((x) => x.id == a.id)) return;
    _accounts.add(a);
    notifyListeners();
    await _persist();
  }

  Future<int> importAccounts(List<Account> items) async {
    final existing = _accounts.map((a) => '${a.issuer}|${a.secret}').toSet();
    final added = items
        .where((a) => !existing.contains('${a.issuer}|${a.secret}'))
        .toList();
    _accounts.addAll(added);
    notifyListeners();
    await _persist();
    return added.length;
  }

  /// Replaces the entire vault (used by encrypted-file / Drive restore).
  Future<int> mergeAccounts(List<Account> items) => importAccounts(items);

  Future<void> deleteAccount(Account a) async {
    _accounts.removeWhere((x) => x.id == a.id);
    notifyListeners();
    await _persist();
  }

  Future<void> saveEdit(
    String id, {
    required String issuer,
    required String label,
  }) async {
    final i = _accounts.indexWhere((a) => a.id == id);
    if (i == -1) return;
    _accounts[i] = _accounts[i].copyWith(issuer: issuer, label: label);
    notifyListeners();
    await _persist();
  }

  /// The current decrypted vault as a JSON string (for export).
  String exportJson() => VaultStore.encode(_accounts);

  /// The current vault as an encrypted, PIN-protected blob (for file/Drive
  /// backup). Decryptable with the user's current PIN via [decodeBackup].
  String? exportEncrypted() {
    if (_key == null || _salt == null) return null;
    return VaultCrypto.encrypt(VaultStore.encode(_accounts), _key!, _salt!);
  }

  /// Decodes a backup blob. Tries the in-session key first (same device/PIN);
  /// if [pin] is given, derives the key from the blob's embedded salt instead.
  List<Account>? decodeBackup(String blob, {String? pin}) {
    try {
      final json = pin != null
          ? VaultCrypto.decryptWithPin(blob, pin).json
          : VaultCrypto.decryptWithKey(blob, _key!);
      return VaultStore.decode(json);
    } catch (_) {
      return null;
    }
  }

  // ── Drive backup state ──────────────────────────────────────
  void setDriveConnected(bool v, {String? email}) {
    _driveConnected = v;
    driveEmail = v ? email : null;
    if (!v) _syncStatus = SyncStatus.synced;
    notifyListeners();
  }

  void markBackedUp() {
    lastBackupAt = DateTime.now();
    notifyListeners();
  }

  void setSyncStatus(SyncStatus s) {
    _syncStatus = s;
    notifyListeners();
  }
}
