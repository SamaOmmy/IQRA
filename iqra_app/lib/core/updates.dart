import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

const kRepo = 'SamaOmmy/IQRA';

/// Looks for a newer release on GitHub (once at start-up, or when asked).
class UpdateChecker extends ChangeNotifier {
  String current = '';
  String? latest;
  String? url;
  bool checking = false;
  bool checkedOnce = false;
  String? message;

  bool get available => latest != null && current.isNotEmpty && _newer(latest!, current);

  static bool _newer(String a, String b) {
    List<int> p(String s) => s.split('.').map((x) => int.tryParse(x.replaceAll(RegExp(r'\D'), '')) ?? 0).toList();
    final x = p(a), y = p(b);
    for (var i = 0; i < 3; i++) {
      final u = i < x.length ? x[i] : 0, v = i < y.length ? y[i] : 0;
      if (u != v) return u > v;
    }
    return false;
  }

  Future<void> check({bool announce = false}) async {
    if (checking) return;
    checking = true;
    if (announce) message = 'Checking…';
    notifyListeners();
    try {
      if (current.isEmpty) current = (await PackageInfo.fromPlatform()).version;
      final res = await http.get(Uri.parse('https://api.github.com/repos/$kRepo/releases/latest'), headers: {'Accept': 'application/vnd.github+json'}).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        latest = (j['tag_name'] as String).replaceFirst('v', '');
        url = j['html_url'] as String;
        message = available ? 'Version $latest is available.' : 'You have the latest version.';
      } else {
        message = 'Could not check for updates.';
      }
    } catch (_) {
      message = 'Could not check. Try again when you are online.';
    }
    checkedOnce = true;
    checking = false;
    notifyListeners();
  }
}
