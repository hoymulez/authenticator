import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/account.dart';
import '../services/totp.dart';
import '../state/app_controller.dart';
import '../state/ticker.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/app_scope.dart';
import '../widgets/brand_tile.dart';
import '../widgets/buttons.dart';
import '../widgets/countdown.dart';
import '../widgets/fake_qr.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/meta_row.dart';
import '../widgets/screen_header.dart';
import '../widgets/sheet.dart';
import '../widgets/toast.dart';

class DetailScreen extends StatefulWidget {
  final String accountId;

  const DetailScreen({super.key, required this.accountId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _reveal = false;
  bool _flash = false;

  void _copy(Account acct, AppTheme theme) {
    Clipboard.setData(ClipboardData(text: Totp.codeFor(acct)));
    setState(() => _flash = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _flash = false);
    });
    showAppToast(context, theme, '${acct.issuer} code copied');
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
          final matches = app.accounts.where((a) => a.id == widget.accountId);
          final acct = matches.isEmpty ? null : matches.first;
          if (acct == null) {
            // Account was deleted while this screen is animating away.
            return const SizedBox.shrink();
          }
          return Column(
            children: [
              ScreenHeader(
                theme: theme,
                title: 'Account',
                onBack: () => Navigator.pop(context),
                action: IconSquareButton(
                  theme: theme,
                  icon: 'qr',
                  onTap: () => _showQr(theme, acct),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 40),
                  children: [
                    _identity(theme, acct),
                    const SizedBox(height: 24),
                    _codeCard(theme, acct),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      theme: theme,
                      icon: _flash ? 'check' : 'copy',
                      label: _flash ? 'Copied to clipboard' : 'Copy code',
                      onPressed: () => _copy(acct, theme),
                    ),
                    const SizedBox(height: 22),
                    _meta(theme, acct),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: GhostButton(
                            theme: theme,
                            icon: 'edit',
                            label: 'Edit',
                            onPressed: () => _showEdit(theme, app, acct),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: GhostButton(
                            theme: theme,
                            icon: 'trash',
                            label: 'Delete',
                            color: AppTheme.danger,
                            onPressed: () {
                              app.deleteAccount(acct);
                              Navigator.pop(context);
                              showAppToast(context, theme, '${acct.issuer} removed');
                            },
                          ),
                        ),
                      ],
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

  Widget _identity(AppTheme theme, Account acct) {
    return Column(
      children: [
        const SizedBox(height: 6),
        BrandTile(account: acct, size: 64, radius: 20),
        const SizedBox(height: 14),
        Text(acct.issuer, style: theme.ui(size: 21, weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(acct.label, style: theme.ui(size: 13.5, weight: FontWeight.w400, color: theme.muted)),
      ],
    );
  }

  Widget _codeCard(AppTheme theme, Account acct) {
    return GestureDetector(
      onTap: () => _copy(acct, theme),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        decoration: BoxDecoration(
          color: _flash ? theme.accentSoft : theme.surface,
          borderRadius: BorderRadius.circular(theme.radius),
          border: Border.all(color: _flash ? theme.accent : theme.border),
        ),
        child: ValueListenableBuilder<int>(
          valueListenable: appTick,
          builder: (context, _, _) {
            final rem = Totp.remaining(acct.period);
            final code = Totp.codeFor(acct);
            final next = Totp.next(acct);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ONE-TIME CODE',
                        style: theme.ui(
                            size: 12.5, weight: FontWeight.w600, color: theme.dim, letterSpacing: 1.2)),
                    CountdownRing(theme: theme, period: acct.period, size: 36),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  Totp.format(code),
                  style: theme.mono(
                    size: 48,
                    weight: FontWeight.w700,
                    letterSpacing: 5,
                    height: 1,
                    color: rem <= 5 ? AppTheme.danger : theme.text,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    AppIcon('chevR', size: 13, color: theme.dim),
                    const SizedBox(width: 7),
                    Text('Next', style: theme.ui(size: 12.5, weight: FontWeight.w400, color: theme.dim)),
                    const SizedBox(width: 7),
                    Text(Totp.format(next),
                        style: theme.mono(size: 13, weight: FontWeight.w500, color: theme.muted)),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _meta(AppTheme theme, Account acct) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.radius),
        border: Border.all(color: theme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          MetaRow(
            theme: theme,
            label: 'Secret key',
            value: _reveal ? acct.secret : '•••• •••• •••• ••••',
            mono: true,
            action: GestureDetector(
              onTap: () => setState(() => _reveal = !_reveal),
              child: Text(_reveal ? 'Hide' : 'Reveal',
                  style: theme.ui(size: 13, weight: FontWeight.w600, color: theme.accent)),
            ),
          ),
          MetaRow(theme: theme, label: 'Type', value: 'Time-based (TOTP)'),
          MetaRow(theme: theme, label: 'Algorithm', value: acct.algorithm),
          MetaRow(theme: theme, label: 'Digits', value: '${acct.digits}'),
          MetaRow(theme: theme, label: 'Period', value: '${acct.period}s', last: true),
        ],
      ),
    );
  }

  void _showQr(AppTheme theme, Account acct) {
    showAppSheet(
      context: context,
      theme: theme,
      title: 'Account QR code',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Color(0x4D000000), blurRadius: 30, offset: Offset(0, 8)),
              ],
            ),
            child: FakeQr(seed: acct.secret + acct.issuer, size: 196),
          ),
          const SizedBox(height: 18),
          Text(acct.issuer, style: theme.ui(size: 16, weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(acct.label, style: theme.ui(size: 13.5, weight: FontWeight.w400, color: theme.muted)),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              'Scan this on another device to copy the account. Keep it private — it contains your secret key.',
              textAlign: TextAlign.center,
              style: theme.ui(size: 12.5, weight: FontWeight.w400, color: theme.dim, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _showEdit(AppTheme theme, AppController app, Account acct) {
    showAppSheet(
      context: context,
      theme: theme,
      title: 'Edit account',
      builder: (ctx) => _EditForm(
        theme: theme,
        account: acct,
        onSave: (issuer, label) {
          app.saveEdit(acct.id, issuer: issuer, label: label);
          Navigator.pop(ctx);
          showAppToast(context, theme, 'Account updated');
        },
      ),
    );
  }
}

class _EditForm extends StatefulWidget {
  final AppTheme theme;
  final Account account;
  final void Function(String issuer, String label) onSave;

  const _EditForm({required this.theme, required this.account, required this.onSave});

  @override
  State<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<_EditForm> {
  late final TextEditingController _issuer = TextEditingController(text: widget.account.issuer);
  late final TextEditingController _label = TextEditingController(text: widget.account.label);

  @override
  void dispose() {
    _issuer.dispose();
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final acct = widget.account;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            BrandTile(account: acct, size: 44, radius: 13),
            const SizedBox(width: 13),
            Text('•••• •••• · ${acct.period}s · ${acct.digits} digits',
                style: theme.mono(size: 12.5, weight: FontWeight.w400, color: theme.dim, letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 18),
        _field(theme, 'Service / Issuer', _issuer, 'Issuer'),
        _field(theme, 'Account name', _label, 'you@email.com'),
        const SizedBox(height: 6),
        ListenableBuilder(
          listenable: _issuer,
          builder: (context, _) => PrimaryButton(
            theme: theme,
            icon: 'check',
            label: 'Save changes',
            disabled: _issuer.text.trim().isEmpty,
            onPressed: () => widget.onSave(_issuer.text.trim(), _label.text.trim()),
          ),
        ),
      ],
    );
  }

  Widget _field(AppTheme theme, String label, TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 7),
            child: Text(label, style: theme.ui(size: 12.5, weight: FontWeight.w600, color: theme.muted)),
          ),
          TextField(
            controller: ctrl,
            cursorColor: theme.accent,
            style: theme.ui(size: 15.5),
            decoration: InputDecoration(
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
              hintText: hint,
              hintStyle: theme.ui(size: 15.5, color: theme.dim),
              filled: true,
              fillColor: theme.surface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
