import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/totp.dart';
import '../state/ticker.dart';
import '../theme/app_theme.dart';
import 'app_icons.dart';
import 'brand_tile.dart';
import 'countdown.dart';

/// A vault list row: brand tile, issuer + live code + label, copy button,
/// and a countdown indicator whose style follows the theme.
class AccountCard extends StatefulWidget {
  final Account account;
  final AppTheme theme;
  final void Function(Account account, String code) onCopy;
  final void Function(Account account) onOpen;

  const AccountCard({
    super.key,
    required this.account,
    required this.theme,
    required this.onCopy,
    required this.onOpen,
  });

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard> {
  bool _flash = false;

  void _copy() {
    final code = Totp.codeFor(widget.account);
    setState(() => _flash = true);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _flash = false);
    });
    widget.onCopy(widget.account, code);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final acct = widget.account;
    final compact = theme.isCompact;
    final isLogo = theme.countdown == CountdownStyle.logo;
    final isBorder = theme.countdown == CountdownStyle.border;

    return GestureDetector(
      onTap: () => widget.onOpen(acct),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 16,
          vertical: compact ? 11 : 15,
        ),
        decoration: BoxDecoration(
          color: _flash ? theme.accentSoft : theme.surface,
          borderRadius: BorderRadius.circular(theme.radius),
          border: Border.all(
            color: _flash ? theme.accent.withValues(alpha: 0.4) : theme.border,
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                isLogo
                    ? AccountTile(account: acct, theme: theme, size: compact ? 36 : 42)
                    : BrandTile(account: acct, size: compact ? 38 : 44, radius: theme.tileRadius),
                SizedBox(width: compact ? 12 : 14),
                Expanded(child: _middle(theme, acct, compact)),
                SizedBox(width: compact ? 12 : 14),
                _trailing(theme, acct),
              ],
            ),
            if (isBorder)
              PerimeterCountdown(theme: theme, period: acct.period, radius: theme.radius),
          ],
        ),
      ),
    );
  }

  Widget _middle(AppTheme theme, Account acct, bool compact) {
    return ValueListenableBuilder<int>(
      valueListenable: appTick,
      builder: (context, _, _) {
        final code = Totp.codeFor(acct);
        final rem = Totp.remaining(acct.period);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              acct.issuer,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.ui(size: compact ? 14 : 15, weight: FontWeight.w600),
            ),
            SizedBox(height: compact ? 1 : 3),
            Text(
              Totp.format(code),
              style: theme.mono(
                size: compact ? 22 : 27,
                weight: FontWeight.w600,
                letterSpacing: 2,
                height: 1.15,
                color: rem <= 5 ? AppTheme.danger : theme.text,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 2),
              Text(
                acct.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.ui(size: 12.5, weight: FontWeight.w400, color: theme.dim),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _trailing(AppTheme theme, Account acct) {
    final showSideCountdown =
        theme.countdown == CountdownStyle.ring || theme.countdown == CountdownStyle.bar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _copy,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _flash ? theme.accent : theme.surface2,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: AppIcon(
              _flash ? 'check' : 'copy',
              size: 18,
              color: _flash ? theme.onAccent : theme.muted,
            ),
          ),
        ),
        if (showSideCountdown) ...[
          const SizedBox(height: 8),
          theme.countdown == CountdownStyle.bar
              ? CountdownBar(theme: theme, period: acct.period)
              : CountdownRing(
                  theme: theme, period: acct.period, size: theme.isCompact ? 22 : 26),
        ],
      ],
    );
  }
}
