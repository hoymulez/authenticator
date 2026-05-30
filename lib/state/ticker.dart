import 'dart:async';
import 'package:flutter/foundation.dart';

/// A single app-wide heartbeat that drives every live code and countdown.
///
/// Mirrors the prototype's `useTick` — one timer, broadcast to all cards,
/// rather than a timer per widget.
class AppTicker {
  AppTicker._() {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      tick.value++;
    });
  }

  static final AppTicker instance = AppTicker._();

  final ValueNotifier<int> tick = ValueNotifier<int>(0);
  late final Timer _timer;

  void dispose() => _timer.cancel();
}

/// Convenience global accessor.
ValueListenable<int> get appTick => AppTicker.instance.tick;
