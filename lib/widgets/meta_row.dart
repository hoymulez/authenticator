import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A label/value row used in the detail meta list and the Drive status list.
class MetaRow extends StatelessWidget {
  final AppTheme theme;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool mono;
  final Widget? action;
  final bool last;

  const MetaRow({
    super.key,
    required this.theme,
    required this.label,
    this.value,
    this.valueWidget,
    this.mono = false,
    this.action,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: theme.border)),
      ),
      child: Row(
        children: [
          Text(label, style: theme.ui(size: 14, weight: FontWeight.w500, color: theme.muted)),
          const Spacer(),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: valueWidget ??
                      Text(
                        value ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: mono
                            ? theme.mono(size: 13.5, weight: FontWeight.w500)
                            : theme.ui(size: 14.5, weight: FontWeight.w500),
                      ),
                ),
                if (action != null) ...[
                  const SizedBox(width: 12),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
