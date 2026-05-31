import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../router.dart';
import '../services/backup_file.dart';
import '../services/biometric.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/app_scope.dart';
import '../widgets/buttons.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/pin_prompt.dart';
import '../widgets/screen_header.dart';
import '../widgets/segmented.dart';
import '../widgets/sheet.dart';
import '../widgets/toast.dart';
import 'drive_screen.dart';
import 'pin_screen.dart';
import 'unlock_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hide = false;
  String _lock = '30s';

  Future<void> _toggleBiometric(AppController app, AppTheme theme) async {
    if (app.biometricEnabled) {
      await app.setBiometricEnabled(false);
      return;
    }
    if (!await Biometric.instance.isAvailable()) {
      if (mounted) showAppToast(context, theme, 'No biometrics enrolled on this device');
      return;
    }
    if (!await Biometric.instance.authenticate(reason: 'Enable biometric unlock')) return;
    await app.setBiometricEnabled(true);
    if (mounted) showAppToast(context, theme, 'Biometric unlock enabled');
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
              ScreenHeader(theme: theme, title: 'Settings', onBack: () => Navigator.pop(context)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 40),
                  children: [
                    _group(theme, 'Security', [
                      _row(theme, 'key', 'Change PIN', onTap: _changePin),
                      _row(theme, 'faceid', 'Biometric unlock',
                          right: AppToggle(
                              theme: theme,
                              value: app.biometricEnabled,
                              onChanged: () => _toggleBiometric(app, theme))),
                      _row(theme, 'clock', 'Auto-lock', detail: _lock, onTap: () {
                        setState(() {
                          _lock = _lock == '30s'
                              ? '1 min'
                              : _lock == '1 min'
                                  ? 'Immediately'
                                  : '30s';
                        });
                      }),
                      _row(theme, 'lock', 'Hide codes until tapped',
                          right: AppToggle(theme: theme, value: _hide, onChanged: () => setState(() => _hide = !_hide)),
                          last: true),
                    ]),
                    _group(theme, 'Backup', [
                      _row(theme, 'drive', 'Google Drive',
                          detail: app.driveConnected ? 'On' : 'Off',
                          onTap: () => Navigator.push(context, appRoute(const DriveScreen()))),
                      _row(theme, 'cloudUp', 'Export encrypted vault',
                          onTap: () => _showExport(theme, app.count), last: true),
                    ]),
                    _group(theme, 'Appearance', [
                      _row(theme, 'sun', 'Theme & accent',
                          detail: theme.dark ? 'Dark' : 'Light',
                          onTap: () => _showAppearance(theme), last: true),
                    ]),
                    _group(theme, 'About', [
                      _row(theme, 'shield', 'Encryption',
                          detailWidget: _link(theme, 'cipherlib', 'https://github.com/bitanon/cipherlib')),
                      _row(theme, 'clock', 'Code engine',
                          detailWidget: _link(theme, 'hashlib', 'https://github.com/bitanon/hashlib')),
                      _row(theme, 'info', 'Version', detail: '1.0.0', last: true),
                    ]),
                    GhostButton(
                      theme: theme,
                      icon: 'lock',
                      label: 'Lock vault now',
                      color: AppTheme.danger,
                      onPressed: () {
                        app.lock();
                        Navigator.pushAndRemoveUntil(
                          context,
                          appRoute(const UnlockScreen()),
                          (r) => false,
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: Text('Bitanon Authenticator · ${app.count} accounts secured',
                          style: theme.ui(size: 12, weight: FontWeight.w400, color: theme.dim)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _link(AppTheme theme, String label, String url) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          if (mounted) showAppToast(context, theme, 'Could not open $label');
        }
      },
      child: Text(label, style: theme.ui(size: 14, weight: FontWeight.w600, color: theme.accent)),
    );
  }

  Widget _group(AppTheme theme, String header, List<Widget> rows) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 9),
            child: Text(header,
                style: theme.ui(size: 12, weight: FontWeight.w600, color: theme.dim, letterSpacing: 1)),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(theme.radius),
              border: Border.all(color: theme.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _row(
    AppTheme theme,
    String icon,
    String label, {
    String? detail,
    Widget? detailWidget,
    Widget? right,
    VoidCallback? onTap,
    bool last = false,
    bool danger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: theme.border)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: AppIcon(icon, size: 20, color: danger ? AppTheme.danger : theme.accent),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(label,
                  style: theme.ui(size: 15.5, weight: FontWeight.w500, color: danger ? AppTheme.danger : theme.text)),
            ),
            ?detailWidget,
            if (detail != null)
              Text(detail, style: theme.ui(size: 14, weight: FontWeight.w400, color: theme.dim)),
            ?right,
            if (onTap != null && right == null && detailWidget == null) ...[
              const SizedBox(width: 8),
              AppIcon('chevR', size: 17, color: theme.dim),
            ],
          ],
        ),
      ),
    );
  }

  void _changePin() {
    String firstPin = '';
    Navigator.push(
      context,
      appRoute(PinScreen(
        mode: PinMode.create,
        onCancel: () => Navigator.pop(context),
        onComplete: (pin) async {
          firstPin = pin;
          Navigator.push(
            context,
            appRoute(PinScreen(
              mode: PinMode.confirm,
              onCancel: () => Navigator.pop(context),
              onComplete: (pin2) async {
                if (pin2 != firstPin) return false;
                final app = AppScope.appOf(context);
                final theme = AppScope.themeOf(context);
                final nav = Navigator.of(context);
                await app.changePin(pin2);
                if (!mounted) return true;
                nav.pop(); // confirm
                nav.pop(); // create
                showAppToast(context, theme, 'PIN updated');
                return true;
              },
            )),
          );
          return true;
        },
      )),
    );
  }

  void _showExport(AppTheme theme, int count) {
    showAppSheet(
      context: context,
      theme: theme,
      title: 'Export encrypted vault',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
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
                  child: Text.rich(
                    TextSpan(
                      style: theme.ui(size: 13, weight: FontWeight.w400, color: theme.muted, height: 1.45),
                      children: [
                        const TextSpan(text: 'Saves a '),
                        TextSpan(
                            text: 'bitanon-vault.enc',
                            style: theme.mono(size: 13, weight: FontWeight.w600)),
                        TextSpan(text: ' file with all $count accounts, encrypted with your PIN via '),
                        TextSpan(text: 'cipherlib', style: theme.ui(size: 13, weight: FontWeight.w600)),
                        const TextSpan(text: ". Store it anywhere — it's useless without your PIN."),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          PrimaryButton(
            theme: theme,
            icon: 'cloudUp',
            label: 'Export encrypted file',
            onPressed: () async {
              Navigator.pop(ctx);
              await _exportToFile(theme);
            },
          ),
          const SizedBox(height: 11),
          GhostButton(
            theme: theme,
            icon: 'refresh',
            label: 'Import from file',
            onPressed: () async {
              Navigator.pop(ctx);
              await _importFromFile(theme);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _exportToFile(AppTheme theme) async {
    final app = AppScope.appOf(context);
    final blob = app.exportEncrypted();
    if (blob == null) return;
    try {
      final ok = await BackupFile.exportBlob(blob);
      if (mounted && ok) showAppToast(context, theme, 'Exported $fileLabel');
    } catch (_) {
      if (mounted) showAppToast(context, theme, 'Export failed');
    }
  }

  static const fileLabel = 'bitanon-vault.enc';

  Future<void> _importFromFile(AppTheme theme) async {
    final app = AppScope.appOf(context);
    final String? blob;
    try {
      blob = await BackupFile.importBlob();
    } catch (_) {
      if (mounted) showAppToast(context, theme, 'Could not read file');
      return;
    }
    if (blob == null) return;

    // Try the current session key first (same device/PIN), else ask for the PIN.
    var accounts = app.decodeBackup(blob);
    if (accounts == null) {
      if (!mounted) return;
      final pin = await askBackupPin(context, theme);
      if (pin == null) return;
      accounts = app.decodeBackup(blob, pin: pin);
    }
    if (accounts == null) {
      if (mounted) showAppToast(context, theme, 'Wrong PIN or corrupt file');
      return;
    }
    final added = await app.mergeAccounts(accounts);
    if (mounted) showAppToast(context, theme, 'Imported $added ${added == 1 ? 'account' : 'accounts'}');
  }

  void _showAppearance(AppTheme theme) {
    final controller = AppScope.of(context).themeController;
    showAppSheet(
      context: context,
      theme: theme,
      title: 'Appearance',
      builder: (ctx) => ListenableBuilder(
        listenable: controller,
        builder: (ctx, _) {
          final t = controller.theme;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _apLabel(t, 'Theme'),
              Segmented<bool>(
                theme: t,
                value: t.dark,
                options: const [true, false],
                labels: const ['Dark', 'Light'],
                height: 40,
                onChanged: controller.setDark,
              ),
              const SizedBox(height: 18),
              _apLabel(t, 'Accent color'),
              Row(
                children: [
                  for (final c in kAccentOptions)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => controller.setAccent(c),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: t.accent.toARGB32() == c.toARGB32() ? t.text : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: c,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: [
                                BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 10),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              _apLabel(t, 'Countdown'),
              Segmented<CountdownStyle>(
                theme: t,
                value: t.countdown,
                options: const [
                  CountdownStyle.logo,
                  CountdownStyle.border,
                  CountdownStyle.ring,
                  CountdownStyle.bar,
                ],
                labels: const ['Logo', 'Border', 'Ring', 'Bar'],
                height: 40,
                onChanged: controller.setCountdown,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _apLabel(AppTheme theme, String text) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 9),
        child: Text(text, style: theme.ui(size: 12.5, weight: FontWeight.w600, color: theme.muted)),
      );
}
