import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Exports/imports the encrypted vault as a portable `bitanon-vault.enc` file.
class BackupFile {
  BackupFile._();

  static const fileName = 'bitanon-vault.enc';

  /// Writes [blob] to a file and offers it via the OS share/save sheet.
  /// On desktop falls back to a save dialog. Returns true on success.
  static Future<bool> exportBlob(String blob) async {
    final bytes = Uint8List.fromList(utf8.encode(blob));
    if (kIsWeb) {
      await FilePicker.saveFile(fileName: fileName, bytes: bytes);
      return true;
    }
    if (Platform.isAndroid || Platform.isIOS) {
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/$fileName');
      await f.writeAsBytes(bytes, flush: true);
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(f.path, mimeType: 'application/octet-stream', name: fileName)],
          text: 'Bitanon encrypted vault backup',
        ),
      );
      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    }
    // Desktop: native save dialog.
    final path = await FilePicker.saveFile(
      dialogTitle: 'Save encrypted vault',
      fileName: fileName,
      bytes: bytes,
    );
    if (path == null) return false;
    // Some desktop platforms return a path without writing; ensure contents.
    final out = File(path);
    if (!await out.exists() || (await out.length()) == 0) {
      await out.writeAsBytes(bytes, flush: true);
    }
    return true;
  }

  /// Lets the user pick a `.enc` file and returns its contents, or null.
  static Future<String?> importBlob() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Choose encrypted vault',
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final picked = result.files.first;
    if (picked.bytes != null) return utf8.decode(picked.bytes!);
    if (picked.path != null) return File(picked.path!).readAsString();
    return null;
  }
}
