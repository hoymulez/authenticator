import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/seed_data.dart';
import '../models/account.dart';

enum SyncStatus { synced, syncing, offline }

/// Holds vault + backup state and notifies listeners on change.
class AppController extends ChangeNotifier {
  final List<Account> _accounts = List.of(kSeedAccounts);
  List<Account> get accounts => List.unmodifiable(_accounts);
  int get count => _accounts.length;

  bool _driveConnected = false;
  bool get driveConnected => _driveConnected;

  SyncStatus _syncStatus = SyncStatus.synced;
  SyncStatus get syncStatus => _syncStatus;

  Timer? _syncTimer;

  /// Returns the live copy of an account by id (or the passed one if removed).
  Account live(Account a) =>
      _accounts.firstWhere((x) => x.id == a.id, orElse: () => a);

  void addAccount(Account a) {
    if (_accounts.any((x) => x.id == a.id)) return;
    _accounts.add(a);
    notifyListeners();
  }

  void importAccounts(List<Account> items) {
    final ids = _accounts.map((a) => a.id).toSet();
    _accounts.addAll(items.where((a) => !ids.contains(a.id)));
    notifyListeners();
  }

  void deleteAccount(Account a) {
    _accounts.removeWhere((x) => x.id == a.id);
    notifyListeners();
  }

  void saveEdit(String id, {required String issuer, required String label}) {
    final i = _accounts.indexWhere((a) => a.id == id);
    if (i == -1) return;
    _accounts[i] = _accounts[i].copyWith(issuer: issuer, label: label);
    notifyListeners();
  }

  void setDriveConnected(bool v) {
    _driveConnected = v;
    notifyListeners();
  }

  /// Kicks off a simulated sync; calls [onComplete] when it lands.
  void sync({required VoidCallback onComplete}) {
    if (_syncStatus == SyncStatus.syncing) return;
    _syncStatus = SyncStatus.syncing;
    notifyListeners();
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(milliseconds: 1900), () {
      _syncStatus = SyncStatus.synced;
      notifyListeners();
      onComplete();
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
