import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/otpauth.dart';
import '../services/totp.dart';
import '../state/ticker.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/app_scope.dart';
import '../widgets/buttons.dart';
import '../widgets/countdown.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/screen_header.dart';
import '../widgets/segmented.dart';
import '../widgets/toast.dart';

class ManualAddScreen extends StatefulWidget {
  const ManualAddScreen({super.key});

  @override
  State<ManualAddScreen> createState() => _ManualAddScreenState();
}

class _ManualAddScreenState extends State<ManualAddScreen> {
  final _issuer = TextEditingController();
  final _label = TextEditingController();
  final _secret = TextEditingController();
  bool _adv = false;
  String _alg = 'SHA-1';
  int _digits = 6;
  int _period = 30;

  @override
  void initState() {
    super.initState();
    _issuer.addListener(() => setState(() {}));
    _label.addListener(() => setState(() {}));
    _secret.addListener(_onSecretChanged);
  }

  /// If an otpauth:// URL is pasted into the secret field, parse it and
  /// populate every field automatically.
  void _onSecretChanged() {
    final text = _secret.text.trim();
    if (text.toLowerCase().startsWith('otpauth://')) {
      final acct = OtpAuth.parse(text);
      if (acct != null) {
        _secret.removeListener(_onSecretChanged);
        setState(() {
          _issuer.text = acct.issuer;
          _label.text = acct.label;
          _secret.text = acct.secret;
          _digits = acct.digits;
          _period = acct.period;
          _alg = acct.algorithm;
          _adv = acct.digits != 6 || acct.period != 30 || acct.algorithm != 'SHA-1';
        });
        _secret.addListener(_onSecretChanged);
        return;
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _issuer.dispose();
    _label.dispose();
    _secret.dispose();
    super.dispose();
  }

  bool get _valid =>
      _issuer.text.trim().isNotEmpty && Totp.isValidSecret(_secret.text);

  void _add(AppTheme theme) {
    final app = AppScope.appOf(context);
    final issuer = _issuer.text.trim();
    final acct = Account(
      id: 'm${DateTime.now().millisecondsSinceEpoch}',
      issuer: issuer,
      label: _label.text.trim().isEmpty ? issuer : _label.text.trim(),
      secret: _secret.text.replaceAll(RegExp(r'\s'), '').toUpperCase(),
      logo: issuer.toLowerCase(),
      color: OtpAuth.colorForIssuer(issuer),
      period: _period,
      digits: _digits,
      algorithm: _alg,
    );
    app.addAccount(acct);
    Navigator.popUntil(context, (r) => r.isFirst);
    showAppToast(context, theme, '${acct.issuer} added');
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppScope.themeOf(context);
    return GradientScaffold(
      theme: theme,
      child: Column(
        children: [
          ScreenHeader(theme: theme, title: 'Enter manually', onBack: () => Navigator.pop(context)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
              children: [
                _preview(theme),
                const SizedBox(height: 20),
                _field(theme, 'Service / Issuer', _issuer, 'e.g. GitHub'),
                _field(theme, 'Account name', _label, 'e.g. you@email.com'),
                _field(theme, 'Secret key', _secret, 'Base32 key from the service', mono: true),
                GestureDetector(
                  onTap: () => setState(() => _adv = !_adv),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(2, 4, 2, _adv ? 14 : 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedRotation(
                          turns: _adv ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: AppIcon('chevDown', size: 16, color: theme.accent),
                        ),
                        const SizedBox(width: 8),
                        Text('Advanced options',
                            style: theme.ui(size: 14, weight: FontWeight.w600, color: theme.accent)),
                      ],
                    ),
                  ),
                ),
                if (_adv) ...[
                  _segField(theme, 'Algorithm',
                      Segmented<String>(theme: theme, value: _alg, options: const ['SHA-1', 'SHA-256', 'SHA-512'], labels: const ['SHA-1', 'SHA-256', 'SHA-512'], onChanged: (v) => setState(() => _alg = v))),
                  _segField(theme, 'Digits',
                      Segmented<int>(theme: theme, value: _digits, options: const [6, 8], labels: const ['6', '8'], onChanged: (v) => setState(() => _digits = v))),
                  _segField(theme, 'Period (seconds)',
                      Segmented<int>(theme: theme, value: _period, options: const [30, 60], labels: const ['30', '60'], onChanged: (v) => setState(() => _period = v))),
                ],
                const SizedBox(height: 12),
                PrimaryButton(
                  theme: theme,
                  icon: 'check',
                  label: 'Add account',
                  disabled: !_valid,
                  onPressed: () => _add(theme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _preview(AppTheme theme) {
    final valid = _valid;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.radius),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('PREVIEW',
                    style: theme.ui(size: 12, weight: FontWeight.w600, color: theme.dim, letterSpacing: 1)),
                const SizedBox(height: 4),
                ValueListenableBuilder<int>(
                  valueListenable: appTick,
                  builder: (context, _, _) => Text(
                    valid ? Totp.format(Totp.preview(_secret.text, _period, _digits, _alg)) : '••• •••',
                    style: theme.mono(
                      size: 30,
                      weight: FontWeight.w700,
                      letterSpacing: 4,
                      color: valid ? theme.text : theme.dim,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (valid)
            CountdownRing(theme: theme, period: _period, size: 40)
          else
            AppIcon('clock', size: 28, color: theme.dim),
        ],
      ),
    );
  }

  Widget _field(AppTheme theme, String label, TextEditingController ctrl, String hint, {bool mono = false}) {
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
            style: mono ? theme.mono(size: 15, letterSpacing: 1) : theme.ui(size: 15.5),
            decoration: InputDecoration(
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
              hintText: hint,
              hintStyle: theme.ui(size: 15.5, color: theme.dim),
              filled: true,
              fillColor: theme.surface,
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

  Widget _segField(AppTheme theme, String label, Widget seg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 7),
            child: Text(label, style: theme.ui(size: 12.5, weight: FontWeight.w600, color: theme.muted)),
          ),
          seg,
        ],
      ),
    );
  }
}
