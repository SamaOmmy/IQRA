import 'dart:io';

import 'package:flutter/services.dart';

/// One app a picture can be sent straight to (Android).
class ShareApp {
  const ShareApp(this.pkg, this.label, this.color);
  final String pkg, label;
  final int color;
}

const kShareApps = <ShareApp>[
  ShareApp('com.whatsapp', 'WhatsApp Status', 0xFF25D366),
  ShareApp('com.whatsapp.w4b', 'WhatsApp Business', 0xFF128C7E),
  ShareApp('com.instagram.android', 'Instagram', 0xFFE1306C),
  ShareApp('org.telegram.messenger', 'Telegram', 0xFF2AABEE),
  ShareApp('com.facebook.katana', 'Facebook', 0xFF1877F2),
  ShareApp('com.snapchat.android', 'Snapchat', 0xFFFFC400),
  ShareApp('com.twitter.android', 'X', 0xFF111111),
];

/// Sending a picture to one particular app, and saving it to the phone's gallery. Phones only; elsewhere these return nothing.
class ShareTargets {
  static const _ch = MethodChannel('iqra/share');

  /// The apps from [kShareApps] that are installed on this phone.
  static Future<List<ShareApp>> installed() async {
    if (!Platform.isAndroid) return const [];
    try {
      final got = ((await _ch.invokeMethod<List>('apps')) ?? const []).cast<String>().toSet();
      return [for (final a in kShareApps) if (got.contains(a.pkg)) a];
    } catch (_) {
      return const [];
    }
  }

  /// Opens [pkg] (or the system share sheet when null) with the picture. WhatsApp lists "My status" at the top of its own list.
  static Future<bool> send(String path, {String? pkg, String? text}) async {
    if (!Platform.isAndroid) return false;
    try {
      return (await _ch.invokeMethod<bool>('send', {'path': path, 'pkg': pkg, 'text': text})) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Saves into Pictures/IQRA. False where that is not possible (Android 9 and older).
  static Future<bool> saveToGallery(String path, String name) async {
    if (!Platform.isAndroid) return false;
    try {
      return (await _ch.invokeMethod<bool>('save', {'path': path, 'name': name})) ?? false;
    } catch (_) {
      return false;
    }
  }
}
