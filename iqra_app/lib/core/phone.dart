import 'dart:io';

import 'package:flutter/services.dart';

/// Android settings that decide whether the lock-screen controls and the adhan can show up and keep running.
class PhoneSetup {
  static const _ch = MethodChannel('iqra/geo');

  static Future<bool> notificationsOn() async {
    if (!Platform.isAndroid) return true;
    try {
      return (await _ch.invokeMethod<bool>('notificationsEnabled')) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> openNotificationSettings() async {
    try {
      await _ch.invokeMethod('openNotificationSettings');
    } catch (_) {}
  }

  static Future<void> openBatterySettings() async {
    try {
      await _ch.invokeMethod('openBatterySettings');
    } catch (_) {}
  }
}
