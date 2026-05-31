import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/otpauth.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/app_scope.dart';
import '../widgets/brand_tile.dart';
import '../widgets/buttons.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/scanner_view.dart';
import '../widgets/screen_header.dart';
import '../widgets/toast.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  Account? _found;

  void _onCode(String raw) {
    if (_found != null) return;
    final acct = OtpAuth.parse(raw);
    if (acct != null) {
      setState(() => _found = acct);
    }
    // Non-otpauth codes are ignored; the scanner keeps looking.
  }

  void _add(AppTheme theme) {
    AppScope.appOf(context).addAccount(_found!);
    Navigator.popUntil(context, (r) => r.isFirst);
    showAppToast(context, theme, '${_found!.issuer} added');
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppScope.themeOf(context);
    final found = _found;
    return GradientScaffold(
      theme: theme,
      child: Column(
        children: [
          ScreenHeader(theme: theme, title: 'Scan QR code', onBack: () => Navigator.pop(context)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
              children: [
                if (found == null)
                  ScannerView(theme: theme, onCode: _onCode)
                else
                  _DetectedPreview(theme: theme, account: found),
                const SizedBox(height: 18),
                Text(found != null ? 'Code detected' : 'Point at the QR code',
                    textAlign: TextAlign.center, style: theme.ui(size: 16, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  found != null
                      ? 'Review and confirm the account below.'
                      : 'Align the QR code from your service inside the frame.',
                  textAlign: TextAlign.center,
                  style: theme.ui(size: 13.5, weight: FontWeight.w400, color: theme.dim),
                ),
                const SizedBox(height: 18),
                if (found != null) ...[
                  _detectedCard(theme, found),
                ] else
                  GhostButton(
                    theme: theme,
                    icon: 'edit',
                    label: 'Enter manually instead',
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detectedCard(AppTheme theme, Account found) {
    return Column(
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
              BrandTile(account: found, size: 46, radius: 14),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(found.issuer, style: theme.ui(size: 16, weight: FontWeight.w600)),
                    Text(found.label, style: theme.ui(size: 13, weight: FontWeight.w400, color: theme.muted)),
                  ],
                ),
              ),
              AppIcon('checkCircle', size: 24, color: AppTheme.success),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GhostButton(
                theme: theme,
                icon: 'x',
                label: 'Rescan',
                onPressed: () => setState(() => _found = null),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              flex: 2,
              child: PrimaryButton(theme: theme, icon: 'plus', label: 'Add account', onPressed: () => _add(theme)),
            ),
          ],
        ),
      ],
    );
  }
}

/// A neutral placeholder shown in the camera slot once a code is captured.
class _DetectedPreview extends StatelessWidget {
  final AppTheme theme;
  final Account account;
  const _DetectedPreview({required this.theme, required this.account});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: theme.accentSoft,
          borderRadius: BorderRadius.circular(theme.radius),
        ),
        alignment: Alignment.center,
        child: AppIcon('checkCircle', size: 64, color: theme.accent),
      ),
    );
  }
}
