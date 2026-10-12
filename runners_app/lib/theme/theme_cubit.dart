import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:material_ui/material_ui.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  new(this._storage) : super(ThemeMode.light);

  final FlutterSecureStorage _storage;
  static const _key = 'theme_mode';

  Future<void> restore() async {
    try {
      final saved = await _storage.read(key: _key);
      if (isClosed) return;
      if (saved == 'dark') emit(ThemeMode.dark);
      if (saved == 'light') emit(ThemeMode.light);
    } on Object {
      // Theme storage is unavailable in widget tests.
    }
  }

  Future<void> setDark({required bool enabled}) async {
    emit(enabled ? ThemeMode.dark : ThemeMode.light);
    try {
      await _storage.write(key: _key, value: enabled ? 'dark' : 'light');
    } on Object {
      // The choice still applies for this session.
    }
  }
}
