import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Asks for the PIN a backup was encrypted with (used when the current session
/// key can't decrypt an imported/restored blob — e.g. cross-device restore).
Future<String?> askBackupPin(BuildContext context, AppTheme theme) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: theme.surface,
      title: Text("Backup's PIN", style: theme.ui(size: 17, weight: FontWeight.w700)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        style: theme.ui(size: 16),
        cursorColor: theme.accent,
        decoration: InputDecoration(
          hintText: 'Enter the PIN this backup was saved with',
          hintStyle: theme.ui(size: 13.5, color: theme.dim),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel', style: theme.ui(size: 14, color: theme.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text),
          child: Text('Restore', style: theme.ui(size: 14, weight: FontWeight.w600, color: theme.accent)),
        ),
      ],
    ),
  );
}
