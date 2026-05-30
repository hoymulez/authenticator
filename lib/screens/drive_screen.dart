import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/app_scope.dart';
import '../widgets/buttons.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/meta_row.dart';
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
  String _last = 'Today, 9:32 AM';

  void _backup(AppTheme theme) {
    setState(() => _phase = _Phase.running);
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.done;
        _last = 'Just now';
      });
      showAppToast(context, theme, 'Backup complete');
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => _phase = _Phase.idle);
      });
    });
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
              Expanded(
                child: app.driveConnected ? _connected(theme, app) : _setup(theme, app),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _setup(AppTheme theme, app) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: theme.accentSoft,
              borderRadius: BorderRadius.circular(22),
            ),
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
              'Connect your Google account to keep an encrypted copy of your vault. You can restore it on any device.',
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
            label: 'Connect Google Drive',
            onPressed: () {
              app.setDriveConnected(true);
              showAppToast(context, theme, 'Google Drive connected');
            },
          ),
        ],
      ),
    );
  }

  Widget _connected(AppTheme theme, app) {
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
                decoration: BoxDecoration(
                  color: theme.surface2,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: AppIcon('drive', size: 24, color: theme.accent),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Connected', style: theme.ui(size: 15, weight: FontWeight.w600)),
                    Text('alex.rivera@gmail.com',
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
              MetaRow(theme: theme, label: 'Last backup', value: _last),
              MetaRow(theme: theme, label: 'Accounts', value: '${app.count} encrypted'),
              MetaRow(theme: theme, label: 'Folder', value: '/Apps/Bitanon', last: true),
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
          onPressed: () => _backup(theme),
        ),
        const SizedBox(height: 11),
        GhostButton(
          theme: theme,
          icon: 'refresh',
          label: 'Restore from Drive',
          onPressed: () => showAppToast(context, theme, 'Restoring from Drive…'),
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: () {
              app.setDriveConnected(false);
              showAppToast(context, theme, 'Disconnected from Drive');
            },
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
      decoration: BoxDecoration(
        color: theme.accentSoft,
        borderRadius: BorderRadius.circular(16),
      ),
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
