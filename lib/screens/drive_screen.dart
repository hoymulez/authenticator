import 'package:flutter/material.dart';
import '../services/drive_backup.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/app_scope.dart';
import '../widgets/buttons.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/meta_row.dart';
import '../widgets/pin_prompt.dart';
import '../widgets/screen_header.dart';
import '../widgets/toast.dart';

class DriveScreen extends StatefulWidget {
  const DriveScreen({super.key});

  @override
  State<DriveScreen> createState() => _DriveScreenState();
}

enum _Phase { idle, running, done }

class _DriveScreenState extends State<DriveScreen> {
  bool _auto = true;
  _Phase _phase = _Phase.idle;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _silentSignIn());
  }

  Future<void> _silentSignIn() async {
    final app = AppScope.appOf(context);
    if (app.driveConnected) return;
    final acc = await DriveBackup.instance.trySilent();
    if (acc != null && mounted) app.setDriveConnected(true, email: acc.email);
  }

  String _fmtTime(DateTime? t) {
    if (t == null) return 'Never';
    final now = DateTime.now();
    if (now.difference(t).inMinutes < 1) return 'Just now';
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ap = t.hour < 12 ? 'AM' : 'PM';
    return 'Today, $h:$m $ap';
  }

  Future<void> _connect(AppTheme theme, AppController app) async {
    setState(() => _busy = true);
    try {
      final acc = await DriveBackup.instance.connect();
      app.setDriveConnected(true, email: acc.email);
      // First backup right away.
      final blob = app.exportEncrypted();
      if (blob != null) {
        await DriveBackup.instance.upload(blob);
        app.markBackedUp();
      }
      if (mounted) showAppToast(context, theme, 'Google Drive connected');
    } on UnsupportedError {
      if (mounted) showAppToast(context, theme, 'Sign-in not supported on this platform');
    } catch (_) {
      if (mounted) showAppToast(context, theme, 'Could not connect to Drive');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _backupNow(AppTheme theme, AppController app) async {
    final blob = app.exportEncrypted();
    if (blob == null) return;
    setState(() => _phase = _Phase.running);
    try {
      await DriveBackup.instance.upload(blob);
      app.markBackedUp();
      if (mounted) {
        setState(() => _phase = _Phase.done);
        showAppToast(context, theme, 'Backup complete');
        Future.delayed(const Duration(milliseconds: 1600), () {
          if (mounted) setState(() => _phase = _Phase.idle);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _phase = _Phase.idle);
        showAppToast(context, theme, 'Backup failed');
      }
    }
  }

  Future<void> _restore(AppTheme theme, AppController app) async {
    setState(() => _busy = true);
    try {
      final blob = await DriveBackup.instance.download();
      if (blob == null) {
        if (mounted) showAppToast(context, theme, 'No backup found on Drive');
        return;
      }
      var accounts = app.decodeBackup(blob);
      if (accounts == null && mounted) {
        final pin = await askBackupPin(context, theme);
        if (pin == null) return;
        accounts = app.decodeBackup(blob, pin: pin);
      }
      if (accounts == null) {
        if (mounted) showAppToast(context, theme, 'Wrong PIN or corrupt backup');
        return;
      }
      final added = await app.mergeAccounts(accounts);
      if (mounted) showAppToast(context, theme, 'Restored $added ${added == 1 ? 'account' : 'accounts'}');
    } catch (_) {
      if (mounted) showAppToast(context, theme, 'Restore failed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect(AppTheme theme, AppController app) async {
    await DriveBackup.instance.disconnect();
    app.setDriveConnected(false);
    if (mounted) showAppToast(context, theme, 'Disconnected from Drive');
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppScope.themeOf(context);
    final app = AppScope.appOf(context);

    return GradientScaffold(
      theme: theme,
      child: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          return Column(
            children: [
              ScreenHeader(theme: theme, title: 'Google Drive backup', onBack: () => Navigator.pop(context)),
              Expanded(child: app.driveConnected ? _connected(theme, app) : _setup(theme, app)),
            ],
          );
        },
      ),
    );
  }

  Widget _setup(AppTheme theme, AppController app) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(color: theme.accentSoft, borderRadius: BorderRadius.circular(22)),
            alignment: Alignment.center,
            child: AppIcon('drive', size: 38, color: theme.accent),
          ),
          const SizedBox(height: 22),
          Text('Back up to Google Drive',
              textAlign: TextAlign.center, style: theme.ui(size: 21, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              'Connect your Google account to keep an encrypted copy of your vault in a private app folder. You can restore it on any device.',
              textAlign: TextAlign.center,
              style: theme.ui(size: 14.5, weight: FontWeight.w400, color: theme.muted, height: 1.5),
            ),
          ),
          const SizedBox(height: 22),
          _encryptionNote(theme,
              'Everything is end-to-end encrypted with your PIN using cipherlib before it leaves your device.'),
          const Spacer(),
          PrimaryButton(
            theme: theme,
            icon: 'drive',
            label: _busy ? 'Connecting…' : 'Connect Google Drive',
            disabled: _busy,
            onPressed: () => _connect(theme, app),
          ),
        ],
      ),
    );
  }

  Widget _connected(AppTheme theme, AppController app) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(theme.radius),
            border: Border.all(color: theme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: theme.surface2, borderRadius: BorderRadius.circular(13)),
                alignment: Alignment.center,
                child: AppIcon('drive', size: 24, color: theme.accent),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Connected', style: theme.ui(size: 15, weight: FontWeight.w600)),
                    Text(app.driveEmail ?? 'Google account',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.ui(size: 13, weight: FontWeight.w400, color: theme.muted)),
                  ],
                ),
              ),
              AppIcon('checkCircle', size: 22, color: AppTheme.success),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(theme.radius),
            border: Border.all(color: theme.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              MetaRow(theme: theme, label: 'Last backup', value: _fmtTime(app.lastBackupAt)),
              MetaRow(theme: theme, label: 'Accounts', value: '${app.count} encrypted'),
              MetaRow(theme: theme, label: 'Folder', value: 'appDataFolder', last: true),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _encryptionNote(theme,
            'Backups are end-to-end encrypted with your PIN using cipherlib. Google can\'t read your codes.'),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(theme.radius),
            border: Border.all(color: theme.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Auto-backup', style: theme.ui(size: 15, weight: FontWeight.w600)),
                    const SizedBox(height: 1),
                    Text('After every change',
                        style: theme.ui(size: 12.5, weight: FontWeight.w400, color: theme.dim)),
                  ],
                ),
              ),
              AppToggle(theme: theme, value: _auto, onChanged: () => setState(() => _auto = !_auto)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          theme: theme,
          icon: _phase == _Phase.done ? 'check' : 'cloudUp',
          label: _phase == _Phase.running
              ? 'Backing up…'
              : _phase == _Phase.done
                  ? 'Backed up'
                  : 'Back up now',
          disabled: _phase == _Phase.running,
          onPressed: () => _backupNow(theme, app),
        ),
        const SizedBox(height: 11),
        GhostButton(
          theme: theme,
          icon: 'refresh',
          label: _busy ? 'Working…' : 'Restore from Drive',
          onPressed: _busy ? null : () => _restore(theme, app),
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: () => _disconnect(theme, app),
            child: Text('Disconnect Google Drive',
                style: theme.ui(size: 13.5, weight: FontWeight.w600, color: theme.dim)),
          ),
        ),
      ],
    );
  }

  Widget _encryptionNote(AppTheme theme, String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: theme.accentSoft, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: AppIcon('lock', size: 19, color: theme.accent),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(text,
                style: theme.ui(size: 13, weight: FontWeight.w400, color: theme.muted, height: 1.45)),
          ),
        ],
      ),
    );
  }
}
