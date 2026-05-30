import 'package:flutter/widgets.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';

/// Provides the resolved [AppTheme] plus the [ThemeController] and
/// [AppController] to the widget tree.
///
/// [theme] is carried as a value so that rebuilding [AppScope] with a new
/// theme notifies every dependent — including routes pushed onto the
/// Navigator — which keeps the live Appearance sheet working.
class AppScope extends InheritedWidget {
  final AppTheme theme;
  final ThemeController themeController;
  final AppController appController;

  const AppScope({
    super.key,
    required this.theme,
    required this.themeController,
    required this.appController,
    required super.child,
  });

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in context');
    return scope!;
  }

  /// Resolved theme tokens (subscribes the caller to theme changes).
  static AppTheme themeOf(BuildContext context) => of(context).theme;

  static AppController appOf(BuildContext context) => of(context).appController;

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      theme != oldWidget.theme ||
      themeController != oldWidget.themeController ||
      appController != oldWidget.appController;
}
