import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'quran.dart';

const kRepo = 'SamaOmmy/IQRA';
const _geo = MethodChannel('iqra/geo');
const _dl = MethodChannel('iqra/download');

class _Asset {
  const _Asset(this.name, this.url, this.size);
  final String name, url;
  final int size;
}

/// Looks for a newer release on GitHub (at start-up, or when asked) and installs it: on Android the new APK is downloaded
/// and handed to the system installer; on Windows the installer is downloaded and run, and the app starts again.
class UpdateChecker extends ChangeNotifier {
  String current = '';
  String? latest;
  String? url;
  bool checking = false;
  bool checkedOnce = false;
  String? message;
  List<_Asset> _assets = const [];

  bool downloading = false;
  double progress = 0;
  String? installMessage;

  /// Android: the finished download, waiting to be installed.
  String? readyPath;
  bool get ready => readyPath != null && available;
  Timer? _poll;
  bool _installWhenDone = false;

  /// The person closed the notice for this run of the app (it comes back next time, and while a download is under way).
  bool dismissed = false;
  void dismiss() {
    dismissed = true;
    notifyListeners();
  }

  @visibleForTesting
  void debugOffer(String version) {
    current = '3.7.0';
    latest = version;
    dismissed = false;
    notifyListeners();
  }

  /// Whether the notice that sits on every screen should show.
  bool get showBanner => available && !personal && (!dismissed || downloading || ready);

  bool get available => latest != null && current.isNotEmpty && _newer(latest!, current);

  /// A personal copy (it carries the licensed mushaf fonts): the public update does not have them, so it must never replace this one.
  bool get personal => Quran.I.hasQcf;

  static bool _newer(String a, String b) {
    List<int> p(String s) => s.split('.').map((x) => int.tryParse(x.replaceAll(RegExp(r'\D'), '')) ?? 0).toList();
    final x = p(a), y = p(b);
    for (var i = 0; i < 3; i++) {
      final u = i < x.length ? x[i] : 0, v = i < y.length ? y[i] : 0;
      if (u != v) return u > v;
    }
    return false;
  }

  DateTime? _lastCheck;

  /// Checks again if the last check was more than three hours ago.
  void checkIfStale() {
    final last = _lastCheck;
    if (last == null || DateTime.now().difference(last) > const Duration(hours: 3)) check();
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
        _assets = [
          for (final a in (j['assets'] as List? ?? const []))
            _Asset((a as Map)['name'] as String, a['browser_download_url'] as String, (a['size'] as num?)?.toInt() ?? 0),
        ];
        message = available ? (personal ? 'Version $latest is out. This copy includes the licensed fonts, so it is updated from your PC (a new personal build), not from here.' : 'Version $latest is available.') : 'You have the latest version.';
        if (available && !personal) unawaited(resumePending());
      } else {
        message = 'Could not check for updates.';
      }
    } catch (_) {
      message = 'Could not check. Try again when you are online.';
    }
    checkedOnce = true;
    _lastCheck = DateTime.now();
    checking = false;
    notifyListeners();
  }

  /// True when the update can be installed from inside the app (otherwise the release page is opened).
  bool get canInstallHere {
    if (_assets.isEmpty || personal) return false;
    if (Platform.isAndroid) return true;
    // a portable copy is not replaced by the installer, so it is sent to the download page instead
    if (Platform.isWindows) return Platform.resolvedExecutable.toLowerCase().contains(r'\programs\iqra\');
    return false;
  }

  Future<_Asset?> _pick() async {
    if (Platform.isWindows) {
      for (final a in _assets) {
        if (a.name.endsWith('Windows-Setup.exe')) return a;
      }
    }
    if (Platform.isAndroid) {
      var arm64 = true;
      try {
        final abis = (await _geo.invokeMethod<List<Object?>>('abis'))?.cast<String>() ?? const [];
        arm64 = abis.contains('arm64-v8a');
      } catch (_) {}
      final want = arm64 ? 'Android-arm64.apk' : 'Android-all-phones.apk';
      for (final a in _assets) {
        if (a.name.endsWith(want)) return a;
      }
      for (final a in _assets) {
        if (a.name.endsWith('.apk')) return a;
      }
    }
    return null;
  }

  // ---------------- Android: the system download manager ----------------

  /// Joins a download that is already under way, or finished, for this release. The system keeps downloading while the app is
  /// closed, so this is what shows its progress (or the Install button) when the app is opened again.
  Future<void> resumePending() async {
    if (!Platform.isAndroid) return;
    try {
      final st = Map<String, dynamic>.from(await _dl.invokeMethod('status') as Map);
      _apply(st);
    } catch (_) {}
  }

  void _apply(Map<String, dynamic> st) {
    final state = st['state'] as String? ?? 'none';
    final name = st['name'] as String?;
    if (state != 'none' && (name == null || latest == null || !name.contains(latest!))) {
      // a download of some other version: not ours any more
      _stopPolling();
      return;
    }
    switch (state) {
      case 'pending' || 'running' || 'paused':
        final got = (st['got'] as num?)?.toDouble() ?? 0, total = (st['total'] as num?)?.toDouble() ?? 0;
        downloading = true;
        readyPath = null;
        progress = total > 0 ? (got / total).clamp(0.0, 1.0) : 0;
        installMessage = state == 'paused'
            ? 'Waiting for a connection. It carries on by itself.'
            : (total > 0 ? 'Downloading ${(progress * 100).round()}%. You can close the app: it keeps going.' : 'Starting the download…');
        _startPolling();
      case 'done':
        _stopPolling();
        downloading = false;
        progress = 1;
        readyPath = st['path'] as String?;
        installMessage = 'Downloaded. Tap Install to finish.';
        if (_installWhenDone && readyPath != null) {
          _installWhenDone = false;
          unawaited(_installApk(readyPath!));
        }
      case 'failed':
        _stopPolling();
        downloading = false;
        readyPath = null;
        installMessage = 'The download failed. Tap Update to try again.';
      default:
        _stopPolling();
        if (downloading) {
          downloading = false;
          installMessage = 'The download was cancelled.';
        }
    }
    notifyListeners();
  }

  void _startPolling() {
    _poll ??= Timer.periodic(const Duration(milliseconds: 700), (_) => resumePending());
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> _installApk(String path) async {
    try {
      final r = await _geo.invokeMethod<String>('installApk', {'path': path});
      installMessage = r == 'permission' ? 'Allow IQRA to install apps in the settings page that opened, then tap Install again.' : 'Follow the prompt to finish updating.';
    } catch (e) {
      installMessage = 'The update could not be installed ($e).';
    }
    notifyListeners();
  }

  /// Downloads the new version and starts installing it.
  Future<void> install() async {
    if (downloading || personal) return;
    if (Platform.isAndroid && readyPath != null && File(readyPath!).existsSync()) {
      await _installApk(readyPath!);
      return;
    }
    final asset = await _pick();
    if (asset == null || !canInstallHere) {
      if (url != null) await launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication);
      return;
    }
    if (Platform.isAndroid) {
      try {
        _installWhenDone = true;
        downloading = true;
        progress = 0;
        installMessage = 'Starting the download…';
        notifyListeners();
        await _dl.invokeMethod('start', {'url': asset.url, 'name': asset.name});
        await resumePending();
      } catch (e) {
        downloading = false;
        installMessage = 'The download could not start ($e). You can get it from the release page.';
        notifyListeners();
      }
      return;
    }

    // Windows: a download that is cut off keeps what it has and carries on from there next time
    downloading = true;
    progress = 0;
    installMessage = 'Downloading…';
    notifyListeners();
    final client = http.Client();
    try {
      final dir = await getApplicationSupportDirectory();
      await dir.create(recursive: true);
      final file = File('${dir.path}${Platform.pathSeparator}${asset.name}');
      final part = File('${file.path}.part');
      if (await file.exists() && asset.size > 0 && await file.length() == asset.size) {
        await _runInstaller(file);
        return;
      }
      var have = await part.exists() ? await part.length() : 0;
      if (asset.size > 0 && have >= asset.size) {
        await part.delete();
        have = 0;
      }
      final req = http.Request('GET', Uri.parse(asset.url));
      if (have > 0) req.headers['Range'] = 'bytes=$have-';
      final resp = await client.send(req);
      if (resp.statusCode != 200 && resp.statusCode != 206) throw 'download failed (${resp.statusCode})';
      if (resp.statusCode == 200) have = 0; // the server sent it all again
      final total = asset.size > 0 ? asset.size : (resp.contentLength ?? 0) + have;
      var got = have;
      final sink = part.openWrite(mode: have > 0 ? FileMode.append : FileMode.write);
      try {
        await for (final chunk in resp.stream) {
          sink.add(chunk);
          got += chunk.length;
          if (total > 0) {
            final p = got / total;
            if (p - progress > 0.01) {
              progress = p.clamp(0, 1).toDouble();
              installMessage = 'Downloading ${(progress * 100).round()}%';
              notifyListeners();
            }
          }
        }
      } finally {
        await sink.flush();
        await sink.close();
      }
      if (asset.size > 0 && await part.length() != asset.size) throw 'the download was cut off at ${(100 * await part.length() / asset.size).round()}%. Tap Update to continue from there';
      if (await file.exists()) await file.delete();
      await part.rename(file.path);
      await _runInstaller(file);
    } catch (e) {
      installMessage = 'The update could not finish: $e.';
    } finally {
      client.close();
      downloading = false;
      notifyListeners();
    }
  }

  Future<void> _runInstaller(File setup) async {
    installMessage = 'Installing…';
    progress = 1;
    notifyListeners();
    final exe = Platform.resolvedExecutable.replaceAll("'", "''");
    final path = setup.path.replaceAll("'", "''");
    await Process.start(
      'powershell',
      ['-NoProfile', '-WindowStyle', 'Hidden', '-Command', "Start-Sleep -Seconds 2; Start-Process -FilePath '$path' -ArgumentList '/S' -Wait; Start-Process -FilePath '$exe'"],
      mode: ProcessStartMode.detached,
    );
    await Future<void>.delayed(const Duration(milliseconds: 600));
    exit(0);
  }
}
