import 'dart:async';
import 'package:flutter/material.dart';
import '../data/seed_data.dart';
import '../models/account.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/app_scope.dart';
import '../widgets/brand_tile.dart';
import '../widgets/buttons.dart';
import '../widgets/camera_view.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/screen_header.dart';
import '../widgets/toast.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  Account? _found;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _found = kScanResult);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _add(AppTheme theme) {
    final app = AppScope.appOf(context);
    app.addAccount(_found!);
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
                CameraView(theme: theme, scanning: found == null),
                const SizedBox(height: 18),
                Text(found != null ? 'Code detected' : 'Point at the QR code',
                    textAlign: TextAlign.center,
                    style: theme.ui(size: 16, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  found != null
                      ? 'Review and confirm the account below.'
                      : 'Align the QR code from your service inside the frame.',
                  textAlign: TextAlign.center,
                  style: theme.ui(size: 13.5, weight: FontWeight.w400, color: theme.dim),
                ),
                const SizedBox(height: 18),
                if (found != null)
                  _detectedCard(theme, found)
                else
                  GhostButton(
                    theme: theme,
                    icon: 'image',
                    label: 'Choose from photos',
                    onPressed: () => showAppToast(context, theme, 'Pick a QR image from Photos'),
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
        PrimaryButton(theme: theme, icon: 'plus', label: 'Add account', onPressed: () => _add(theme)),
      ],
    );
  }
}
