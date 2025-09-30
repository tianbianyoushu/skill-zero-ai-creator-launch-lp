import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'craving.dart';
import '../../core/storage/shared_prefs_storage.dart';

class CravingsController extends StateNotifier<List<Craving>> {
  CravingsController() : super(const []) {
    _load();
  }

  final _storage = SharedPrefsStorage();

  Future<void> _load() async {
    final list = await _storage.loadCravings();
    state = list;
  }

  void add(Craving c) {
    state = [...state, c];
    _storage.saveCravings(state);
  }

  void removeAt(int index) {
    final list = [...state];
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      state = list;
      _storage.saveCravings(state);
    }
  }

  void clear() {
    state = const [];
    _storage.saveCravings(state);
  }
}

final cravingsProvider =
    StateNotifierProvider<CravingsController, List<Craving>>((ref) {
  return CravingsController();
});
