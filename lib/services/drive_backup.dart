import 'dart:convert';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

/// OAuth client IDs for Google Sign-In.
///
/// These come from YOUR Google Cloud project (see SETUP.md). On Android they
/// are derived from the package name + SHA-1 (no value needed here); on iOS/web
/// you must provide a client ID. Leave null to use the platform default
/// (Android), or fill in for iOS/web/desktop.
class DriveConfig {
  /// iOS / desktop / web OAuth client ID (e.g. `xxxx.apps.googleusercontent.com`).
  static const String? clientId = null;

  /// Web/server "serverClientId" if you exchange tokens server-side.
  static const String? serverClientId = null;
}

/// Real Google Drive backup/restore. The encrypted vault blob is stored in the
/// app-private **appDataFolder** (invisible to the user's Drive UI, and only
/// accessible by this app).
class DriveBackup {
  DriveBackup._();
  static final DriveBackup instance = DriveBackup._();

  static const List<String> _scopes = [drive.DriveApi.driveAppdataScope];
  static const String _backupName = 'bitanon-vault.enc';

  bool _initialized = false;
  GoogleSignInAccount? _account;

  String? get email => _account?.email;
  bool get isConnected => _account != null;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: DriveConfig.clientId,
      serverClientId: DriveConfig.serverClientId,
    );
    _initialized = true;
  }

  /// Tries a silent sign-in (no UI). Returns the account if one is cached.
  Future<GoogleSignInAccount?> trySilent() async {
    await _ensureInit();
    _account = await GoogleSignIn.instance.attemptLightweightAuthentication();
    return _account;
  }

  /// Interactive connect. Throws [UnsupportedError] on platforms without an
  /// interactive flow, or rethrows sign-in errors.
  Future<GoogleSignInAccount> connect() async {
    await _ensureInit();
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw UnsupportedError('Interactive Google Sign-In is not available on this platform.');
    }
    _account = await GoogleSignIn.instance.authenticate(scopeHint: _scopes);
    return _account!;
  }

  Future<void> disconnect() async {
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {}
    _account = null;
  }

  Future<drive.DriveApi> _api() async {
    final acc = _account;
    if (acc == null) throw StateError('Google Drive is not connected.');
    final authz = await acc.authorizationClient.authorizeScopes(_scopes);
    return drive.DriveApi(authz.authClient(scopes: _scopes));
  }

  Future<String?> _findBackupId(drive.DriveApi api) async {
    final res = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_backupName'",
      $fields: 'files(id,name)',
    );
    final files = res.files;
    if (files == null || files.isEmpty) return null;
    return files.first.id;
  }

  /// Uploads (creates or overwrites) the encrypted [blob] backup.
  Future<void> upload(String blob) async {
    final api = await _api();
    final bytes = utf8.encode(blob);
    final media = drive.Media(Stream.value(bytes), bytes.length);
    final existingId = await _findBackupId(api);
    if (existingId != null) {
      await api.files.update(drive.File(), existingId, uploadMedia: media);
    } else {
      final meta = drive.File()
        ..name = _backupName
        ..parents = ['appDataFolder'];
      await api.files.create(meta, uploadMedia: media);
    }
  }

  /// Downloads the encrypted backup blob, or null if none exists.
  Future<String?> download() async {
    final api = await _api();
    final id = await _findBackupId(api);
    if (id == null) return null;
    final media = await api.files.get(
      id,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final chunks = <int>[];
    await for (final c in media.stream) {
      chunks.addAll(c);
    }
    return utf8.decode(chunks);
  }
}
