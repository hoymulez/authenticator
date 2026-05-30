import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shows a styled bottom sheet matching the design (grabber + title + body).
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required AppTheme theme,
  String? title,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C000000),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: theme.border),
              left: BorderSide(color: theme.border),
              right: BorderSide(color: theme.border),
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x80000000), blurRadius: 60, offset: Offset(0, -20)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: theme.borderHi,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                if (title != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(title,
                        style: theme.ui(size: 19, weight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 14),
                ],
                Flexible(child: builder(ctx)),
              ],
            ),
          ),
        ),
      );
    },
  );
}
