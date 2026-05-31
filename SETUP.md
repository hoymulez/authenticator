# Bitanon Authenticator — setup & integration notes

This app implements real authenticator functionality on top of the design:

| Feature | Package | Where |
|---|---|---|
| RFC 6238 TOTP (HMAC-SHA1/256/512) | `hashlib` | `lib/services/totp.dart` |
| Vault & backup encryption (AES-256-GCM + PBKDF2) | `cipherlib` + `hashlib` | `lib/services/vault_crypto.dart` |
| Encrypted on-device persistence | `path_provider` / `shared_preferences` (web) | `lib/services/vault_store.dart` |
| QR scan (add + Google Authenticator import) | `mobile_scanner` | `lib/widgets/scanner_view.dart` |
| `otpauth://` + `otpauth-migration://` parsing | (built-in) | `lib/services/otpauth.dart`, `lib/services/ga_migration.dart` |
| Biometric unlock | `local_auth` + `flutter_secure_storage` | `lib/services/biometric.dart`, `lib/services/secure_key_store.dart` |
| Google Drive backup/restore | `google_sign_in` + `googleapis` | `lib/services/drive_backup.dart` |
| Encrypted file export/import (`bitanon-vault.enc`) | `file_picker` + `share_plus` | `lib/services/backup_file.dart` |

## Security model
- On first run the user sets a 6-digit **PIN**. A 32-byte AES key is derived with
  **PBKDF2-HMAC-SHA256** (120k iterations) from the PIN + a random salt.
- The vault is serialized to JSON and encrypted with **AES-256-GCM** (cipherlib).
  Blob layout: `salt(16) | iv(12) | ciphertext+tag`, base64. Self-contained so the
  same blob is portable across devices (decryptable with the PIN).
- The PIN is never stored. Unlock re-derives the key and succeeds only if GCM auth
  passes. **Forgetting the PIN means the local vault cannot be opened** (by design).
- Biometric unlock caches the derived key in the OS keystore/keychain
  (`flutter_secure_storage`), released only after a successful `local_auth` check.
- Google Drive and file backups store the **same encrypted blob** — Google/anyone
  with the file cannot read codes without the PIN.

## Build note (this environment)
`flutter build apk` failed here only because the container ships **JDK 26**, which
current Gradle does not support yet ("Unsupported class file major version 70").
Build Android with a Flutter-supported JDK (17 or 21):
```
flutter config --jdk-dir /path/to/jdk-21
```
`flutter analyze`, the unit tests, and `flutter build web` all pass.

---

## Platform setup

### Android (already configured)
- `android/app/src/main/AndroidManifest.xml` — CAMERA, USE_BIOMETRIC, INTERNET.
- `MainActivity.kt` extends `FlutterFragmentActivity` (required by `local_auth`).
- `minSdk` raised to 23 (`android/app/build.gradle.kts`).

### iOS (already configured)
- `ios/Runner/Info.plist` — `NSCameraUsageDescription`, `NSFaceIDUsageDescription`.
- Set the deployment target to iOS 13+ in Xcode/Podfile if pod install complains.

---

## Google Drive — OAuth setup (required to actually connect)

Drive code is complete but needs **your** OAuth credentials. Until configured,
tapping "Connect Google Drive" will fail gracefully with a toast.

1. **Google Cloud Console** → create/select a project.
2. **APIs & Services → Library** → enable **Google Drive API**.
3. **OAuth consent screen** → External; add the scope
   `https://www.googleapis.com/auth/drive.appdata`; add yourself as a test user.
4. **Credentials → Create OAuth client ID** for each platform:

   **Android**
   - Application type: Android.
   - Package name: `dev.bitanon.authenticator`.
   - SHA-1: `cd android && ./gradlew signingReport` (use the debug SHA-1 for dev).
   - No code change needed — Android uses the package+SHA-1 match.

   **iOS**
   - Application type: iOS, bundle id `dev.bitanon.authenticator` (match Xcode).
   - Add the iOS client ID to `DriveConfig.clientId` in
     `lib/services/drive_backup.dart`, **and** add the reversed client ID as a URL
     scheme in `ios/Runner/Info.plist`:
     ```xml
     <key>CFBundleURLTypes</key>
     <array><dict>
       <key>CFBundleURLSchemes</key>
       <array><string>com.googleusercontent.apps.XXXX</string></array>
     </dict></array>
     ```

   **Web** (optional)
   - Web client ID → put it in a `<meta name="google-signin-client_id">` tag in
     `web/index.html`, or pass via `DriveConfig.clientId`.

5. Fill `DriveConfig.clientId` / `serverClientId` in `lib/services/drive_backup.dart`
   for the platforms that need them (Android typically needs neither).

The backup is stored in Drive's private **appDataFolder** (hidden from the user's
Drive UI, only this app can read it).

---

## How the flows work
- **Add via QR**: `Add → Scan QR code`. Decodes `otpauth://totp/...`.
- **Add manually**: type issuer/secret (+ advanced algo/digits/period), or paste a
  full `otpauth://` URL into the secret field to auto-fill.
- **Import from Google Authenticator**: `Add → Import…` then scan the export QR;
  decodes the `otpauth-migration://` protobuf, multi-select, import.
- **Export/Import file**: `Settings → Export encrypted vault` → share/save
  `bitanon-vault.enc`; "Import from file" picks one back (asks for its PIN if it
  wasn't this device's current PIN).
- **Drive**: `Settings → Google Drive` (or the vault header cloud icon) → connect,
  back up now, restore, disconnect. Auto-detects an existing session silently.
