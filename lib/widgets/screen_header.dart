import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_icons.dart';

/// A small square icon button used in headers and rows.
class IconSquareButton extends StatelessWidget {
  final AppTheme theme;
  final String icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final double size;
  final double iconSize;

  const IconSquareButton({
    super.key,
    required this.theme,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.size = 42,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: theme.border),
        ),
        alignment: Alignment.center,
        child: AppIcon(icon, size: iconSize, color: iconColor ?? theme.muted),
      ),
    );
  }
}

/// A back arrow + title (+ optional subtitle / trailing action) row.
class ScreenHeader extends StatelessWidget {
  final AppTheme theme;
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? action;

  const ScreenHeader({
    super.key,
    required this.theme,
    required this.title,
    this.subtitle,
    this.onBack,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      child: Row(
        children: [
          if (onBack != null) ...[
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: theme.border),
                ),
                alignment: Alignment.center,
                child: AppIcon('chevL', size: 20, color: theme.text),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: theme.ui(size: 20, weight: FontWeight.w700, height: 1.1)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: theme.ui(size: 12.5, color: theme.dim)),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
