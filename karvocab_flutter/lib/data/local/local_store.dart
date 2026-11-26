import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Kho lưu trữ khoá–giá trị trên máy để dữ liệu còn sau khi tải lại trang / mở lại app.
///
/// `main()` gán [app] = [PrefsLocalStore] trước khi dùng các store; test giữ mặc định
/// [MemoryLocalStore] nên mỗi lần chạy test bắt đầu trống.
abstract class LocalStore {
  /// Kho dùng chung của app.
  static LocalStore app = MemoryLocalStore();

  String? read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);

  /// Đọc JSON; giá trị hỏng (sửa tay, đổi định dạng) thì coi như chưa có.
  Object? readJson(String key) {
    final raw = read(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  Future<void> writeJson(String key, Object? value) => write(key, jsonEncode(value));
}

/// Lưu trong bộ nhớ (test, hoặc khi không mở được bộ nhớ máy).
class MemoryLocalStore extends LocalStore {
  final Map<String, String> _data = {};

  @override
  String? read(String key) => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> remove(String key) async => _data.remove(key);
}

/// Lưu bằng `shared_preferences` (localStorage trên web, SharedPreferences trên Android).
class PrefsLocalStore extends LocalStore {
  PrefsLocalStore(this._prefs);

  static Future<PrefsLocalStore> open() async => PrefsLocalStore(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  @override
  String? read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// Khoá lưu trữ, gom một chỗ để không trùng.
class StorageKeys {
  StorageKeys._();

  static const String accounts = 'auth.accounts';
  static const String session = 'auth.session';
  /// Cặp access / refresh token của backend (chỉ có khi chạy với `API_BASE_URL`).
  static const String tokens = 'auth.tokens';
  static const String collections = 'library.collections';
  static const String vocabularies = 'library.vocabularies';
  static const String dashboard = 'dashboard.state';
  static const String quizSettings = 'quiz.settings';
  static const String notificationRead = 'notifications.read';

  /// Khoá riêng của một tài khoản, vd `library.collections@an@gmail.com`.
  /// Dữ liệu học (học phần, tiến độ, thông báo đã đọc) tách theo tài khoản.
  static String forUser(String base, String userKey) => '$base@$userKey';
}
