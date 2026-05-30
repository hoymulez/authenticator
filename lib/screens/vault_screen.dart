import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/account.dart';
import '../router.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/app_scope.dart';
import '../widgets/account_card.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/screen_header.dart';
import '../widgets/sheet.dart';
import '../widgets/toast.dart';
import 'detail_screen.dart';
import 'import_screen.dart';
import 'manual_add_screen.dart';
import 'scan_screen.dart';
import 'drive_screen.dart';
import 'settings_screen.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _q = '';
  bool _sortAz = true;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<Account> _filtered(List<Account> accounts) {
    final s = _q.trim().toLowerCase();
    final base = s.isEmpty
        ? List<Account>.of(accounts)
        : accounts.where((a) => '${a.issuer} ${a.label}'.toLowerCase().contains(s)).toList();
    base.sort((a, b) => a.issuer.toLowerCase().compareTo(b.issuer.toLowerCase()));
    if (!_sortAz) {
      return base.reversed.toList();
    }
    return base;
  }

  void _copy(Account a, String code) {
    Clipboard.setData(ClipboardData(text: code));
    showAppToast(context, AppScope.themeOf(context), '${a.issuer} code copied');
  }

  void _openAddSheet(AppTheme theme, AppController app) {
    showAppSheet(
      context: context,
      theme: theme,
      title: 'Add account',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _addOption(theme, 'qr', 'Scan QR code', 'Point your camera at a setup code', () {
            Navigator.pop(ctx);
            Navigator.push(context, appRoute(const ScanScreen()));
          }),
          _addOption(theme, 'edit', 'Enter manually', 'Type a setup key or otpauth URL', () {
            Navigator.pop(ctx);
            Navigator.push(context, appRoute(const ManualAddScreen()));
          }),
          _addOption(theme, 'drive', 'Import from Google Authenticator',
              'Batch-transfer your existing accounts', () {
            Navigator.pop(ctx);
            Navigator.push(context, appRoute(const ImportScreen()));
          }),
        ],
      ),
    );
  }

  Widget _addOption(AppTheme theme, String icon, String title, String sub, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: theme.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.accentSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: AppIcon(icon, size: 22, color: theme.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.ui(size: 15.5, weight: FontWeight.w600)),
                  const SizedBox(height: 1),
                  Text(sub, style: theme.ui(size: 12.5, weight: FontWeight.w400, color: theme.dim)),
                ],
              ),
            ),
            AppIcon('chevR', size: 18, color: theme.dim),
          ],
        ),
      ),
    );
  }

  void _onCloud(AppController app, AppTheme theme) {
    if (!app.driveConnected) {
      Navigator.push(context, appRoute(const DriveScreen()));
      return;
    }
    app.sync(onComplete: () {
      if (mounted) showAppToast(context, theme, 'Synced to Google Drive');
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
          final list = _filtered(app.accounts);
          return Stack(
            children: [
              Column(
                children: [
                  _header(theme, app),
                  Expanded(child: _list(theme, list)),
                ],
              ),
              Positioned(
                right: 20,
                bottom: 38,
                child: GestureDetector(
                  onTap: () => _openAddSheet(theme, app),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: theme.accentGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: theme.accent.withValues(alpha: 0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: AppIcon('plus', size: 28, color: theme.onAccent),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _header(AppTheme theme, AppController app) {
    // Cloud button reflects sync/connection state.
    String icon;
    Color color;
    bool spinning = false;
    if (!app.driveConnected) {
      icon = 'cloudOff';
      color = theme.dim;
    } else if (app.syncStatus == SyncStatus.syncing) {
      icon = 'refresh';
      color = theme.accent;
      spinning = true;
    } else {
      icon = 'cloudCheck';
      color = AppTheme.success;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BITANON',
                        style: theme.ui(
                            size: 12.5, weight: FontWeight.w600, color: theme.dim, letterSpacing: 1.5)),
                    const SizedBox(height: 1),
                    Text('Authenticator',
                        style: theme.ui(size: 30, weight: FontWeight.w700, height: 1.05)),
                  ],
                ),
              ),
              _SpinningIcon(icon: icon, color: color, theme: theme, spinning: spinning, onTap: () => _onCloud(app, theme)),
              const SizedBox(width: 9),
              IconSquareButton(theme: theme, icon: 'settings', onTap: () {
                Navigator.push(context, appRoute(const SettingsScreen()));
              }),
            ],
          ),
          const SizedBox(height: 16),
          _searchField(theme),
        ],
      ),
    );
  }

  Widget _searchField(AppTheme theme) {
    final focused = _searchFocus.hasFocus;
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: focused ? theme.accent : theme.border),
      ),
      child: Row(
        children: [
          AppIcon('search', size: 19, color: focused ? theme.accent : theme.dim),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              onChanged: (v) => setState(() => _q = v),
              cursorColor: theme.accent,
              style: theme.ui(size: 15.5),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Search accounts',
                hintStyle: theme.ui(size: 15.5, color: theme.dim),
              ),
            ),
          ),
          if (_q.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _q = '');
              },
              child: AppIcon('x', size: 17, color: theme.dim),
            ),
        ],
      ),
    );
  }

  Widget _list(AppTheme theme, List<Account> list) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${list.length} ${list.length == 1 ? 'account' : 'accounts'}',
                  style: theme.ui(size: 12.5, weight: FontWeight.w600, color: theme.dim)),
              GestureDetector(
                onTap: () => setState(() => _sortAz = !_sortAz),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon('sort', size: 15, color: theme.dim),
                    const SizedBox(width: 5),
                    Text(_sortAz ? 'A–Z' : 'Z–A',
                        style: theme.ui(size: 12.5, weight: FontWeight.w600, color: theme.dim)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (list.isEmpty)
          _emptyState(theme)
        else
          ...list.map((a) => Padding(
                padding: EdgeInsets.only(bottom: theme.isCompact ? 8 : 11),
                child: AccountCard(
                  account: a,
                  theme: theme,
                  onCopy: _copy,
                  onOpen: (acct) => Navigator.push(context, appRoute(DetailScreen(accountId: acct.id))),
                ),
              )),
      ],
    );
  }

  Widget _emptyState(AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          Opacity(opacity: 0.5, child: AppIcon('search', size: 40, color: theme.dim)),
          const SizedBox(height: 12),
          Text('No matches for "$_q"',
              textAlign: TextAlign.center,
              style: theme.ui(size: 15, weight: FontWeight.w600, color: theme.muted)),
          const SizedBox(height: 4),
          Text('Try a different name or add a new account.',
              textAlign: TextAlign.center,
              style: theme.ui(size: 13, weight: FontWeight.w400, color: theme.dim)),
        ],
      ),
    );
  }
}

/// Header cloud button with an optional continuous spin (syncing state).
class _SpinningIcon extends StatefulWidget {
  final String icon;
  final Color color;
  final AppTheme theme;
  final bool spinning;
  final VoidCallback onTap;

  const _SpinningIcon({
    required this.icon,
    required this.color,
    required this.theme,
    required this.spinning,
    required this.onTap,
  });

  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    if (widget.spinning) _c.repeat();
  }

  @override
  void didUpdateWidget(_SpinningIcon old) {
    super.didUpdateWidget(old);
    if (widget.spinning && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.spinning && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    Widget glyph = AppIcon(widget.icon, size: 20, color: widget.color);
    if (widget.spinning) {
      glyph = RotationTransition(turns: _c, child: glyph);
    }
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: theme.border),
        ),
        alignment: Alignment.center,
        child: glyph,
      ),
    );
  }
}
