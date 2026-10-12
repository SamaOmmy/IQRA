import 'package:flutter/foundation.dart';

import 'quran.dart';
import 'store.dart';

/// Keeps the chosen translation loaded and in step with the setting.
class TranslationModel extends ChangeNotifier {
  TranslationModel(this.store) {
    _load();
    store.addListener(_check);
  }

  final AppStore store;
  List<String>? _list;
  String? _id;
  bool loading = false;
  String? error;

  PackInfo get info => Quran.I.translations.firstWhere((t) => t.id == store.translationId, orElse: () => Quran.I.translations.first);

  void _check() {
    if (store.translationId != _id) _load();
  }

  Future<void> _load() async {
    final id = store.translationId;
    _id = id;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final list = await Quran.I.translation(id);
      if (_id != id) return;
      _list = list;
    } catch (e) {
      if (_id != id) return;
      error = e.toString().replaceFirst('Exception: ', '');
      _list = null;
    }
    loading = false;
    notifyListeners();
  }

  String text(Ayah a) {
    final l = _list;
    if (l != null && a.global - 1 < l.length) return l[a.global - 1];
    return store.translationId == 'en.sahih' ? a.t : '';
  }

  @override
  void dispose() {
    store.removeListener(_check);
    super.dispose();
  }
}
