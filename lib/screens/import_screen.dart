import 'dart:async';
import 'package:flutter/material.dart';
import '../data/seed_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/app_scope.dart';
import '../widgets/brand_tile.dart';
import '../widgets/buttons.dart';
import '../widgets/camera_view.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/screen_header.dart';
import '../widgets/toast.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _selectStep = false;
  final Set<String> _sel = {...kImportAccounts.map((a) => a.id)};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _selectStep = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _allOn => _sel.length == kImportAccounts.length;

  void _import(AppTheme theme) {
    final app = AppScope.appOf(context);
    final items = kImportAccounts.where((a) => _sel.contains(a.id)).toList();
    app.importAccounts(items);
    Navigator.popUntil(context, (r) => r.isFirst);
    showAppToast(context, theme, 'Imported ${items.length} accounts');
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppScope.themeOf(context);
    return GradientScaffold(
      theme: theme,
      child: Column(
        children: [
          ScreenHeader(
            theme: theme,
            title: 'Import accounts',
            subtitle: 'From Google Authenticator',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: _selectStep ? _select(theme) : _scan(theme),
          ),
        ],
      ),
    );
  }

  Widget _scan(AppTheme theme) {
    const steps = [
      'Open Google Authenticator',
      'Tap ⋮ → Transfer accounts → Export',
      'Scan the QR code it shows',
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(theme.radius),
            border: Border.all(color: theme.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < steps.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 11),
                    child: Column(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: theme.accentSoft,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Text('${i + 1}',
                              style: theme.ui(size: 13, weight: FontWeight.w700, color: theme.accent)),
                        ),
                        const SizedBox(height: 7),
                        Text(steps[i],
                            textAlign: TextAlign.center,
                            style: theme.ui(size: 11.5, weight: FontWeight.w400, color: theme.muted, height: 1.3)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CameraView(theme: theme, scanning: true),
        const SizedBox(height: 16),
        Text('Looking for an export QR code…',
            textAlign: TextAlign.center,
            style: theme.ui(size: 13.5, weight: FontWeight.w400, color: theme.dim)),
      ],
    );
  }

  Widget _select(AppTheme theme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${kImportAccounts.length} accounts found',
                  style: theme.ui(size: 14, weight: FontWeight.w600)),
              GestureDetector(
                onTap: () => setState(() {
                  if (_allOn) {
                    _sel.clear();
                  } else {
                    _sel
                      ..clear()
                      ..addAll(kImportAccounts.map((a) => a.id));
                  }
                }),
                child: Text(_allOn ? 'Deselect all' : 'Select all',
                    style: theme.ui(size: 13.5, weight: FontWeight.w600, color: theme.accent)),
              ),
            ],
          ),
        ),
        ...kImportAccounts.map((a) {
          final on = _sel.contains(a.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: GestureDetector(
              onTap: () => setState(() {
                if (on) {
                  _sel.remove(a.id);
                } else {
                  _sel.add(a.id);
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(theme.radius),
                  border: Border.all(color: on ? theme.accent.withValues(alpha: 0.45) : theme.border),
                ),
                child: Row(
                  children: [
                    BrandTile(account: a, size: 40, radius: 12),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.issuer, style: theme.ui(size: 15, weight: FontWeight.w600)),
                          Text(a.label, style: theme.ui(size: 12.5, weight: FontWeight.w400, color: theme.muted)),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: on ? theme.accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: on ? theme.accent : theme.borderHi, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: on ? AppIcon('check', size: 15, color: theme.onAccent) : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 18),
        PrimaryButton(
          theme: theme,
          icon: 'check',
          label: 'Import ${_sel.length} ${_sel.length == 1 ? 'account' : 'accounts'}',
          disabled: _sel.isEmpty,
          onPressed: () => _import(theme),
        ),
      ],
    );
  }
}
