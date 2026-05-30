import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A segmented control on a tinted track. The selected segment fills accent.
class Segmented<T> extends StatelessWidget {
  final AppTheme theme;
  final T value;
  final List<T> options;
  final List<String> labels;
  final ValueChanged<T> onChanged;
  final double height;

  const Segmented({
    super.key,
    required this.theme,
    required this.value,
    required this.options,
    required this.labels,
    required this.onChanged,
    this.height = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.surface2,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          for (int i = 0; i < options.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 3),
                child: GestureDetector(
                  onTap: () => onChanged(options[i]),
                  child: Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: options[i] == value ? theme.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      labels[i],
                      style: theme.ui(
                        size: 13.5,
                        weight: FontWeight.w600,
                        color: options[i] == value ? theme.onAccent : theme.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
