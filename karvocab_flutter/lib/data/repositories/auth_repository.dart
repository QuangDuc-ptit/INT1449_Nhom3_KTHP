import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/member_id.dart';
import '../local/local_store.dart';
import '../models/user_profile_model.dart';
import '../remote/api_client.dart';

/// Ô nhập mà lỗi xác thực gắn vào (để hiển thị lỗi ngay dưới ô đó).
enum AuthErrorField { email, password }

/// Lỗi nghiệp vụ xác thực, [message] hiển thị trực tiếp cho người dùng.
/// [field] = ô nhập gây lỗi; `null` nếu lỗi không thuộc ô nào.
class AuthException implements Exception {
  final String message;
  final AuthErrorField? field;
  const AuthException(this.message, {this.field});

  @override
  String toString() => message;
}

enum SocialProvider { google, facebook }

/// Tài khoản lưu trên máy. Mật khẩu chỉ lưu dạng băm SHA-256 kèm muối riêng, không lưu chữ thường.
class _Account {
  String fullName;
  String _salt;
  String _passwordHash;
  DateTime? birthDate;
  String? memberId;

  // Cài đặt riêng của tài khoản (Màn 23).
  int dailyGoal;
  String reminderTime;
  bool notificationsEnabled;

  _Account({required this.fullName, required String password})
      : _salt = _newSalt(),
        _passwordHash = '',
        dailyGoal = _defaults.dailyGoalWords,
        reminderTime = _defaults.reminderTime,
        notificationsEnabled = _defaults.isNotificationEnabled {
    setPassword(password);
  }

  static final UserProfileModel _defaults = UserProfileModel.initial();

  static String _newSalt() {
    final r = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  static String _hash(String salt, String password) => sha256.convert(utf8.encode('$salt:$password')).toString();

  void setPassword(String password) {
    _salt = _newSalt();
    _passwordHash = _hash(_salt, password);
  }

  bool checkPassword(String password) => _hash(_salt, password) == _passwordHash;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'salt': _salt,
        'passwordHash': _passwordHash,
        'birthDate': birthDate?.toIso8601String(),
        'memberId': memberId,
        'dailyGoal': dailyGoal,
        'reminderTime': reminderTime,
        'notificationsEnabled': notificationsEnabled,
      };

  static _Account fromJson(Map<String, dynamic> json) {
    final birth = json['birthDate'];
    return _Account(fullName: json['fullName'] as String, password: '')
      .._salt = json['salt'] as String
      .._passwordHash = json['passwordHash'] as String
      ..birthDate = birth is String ? DateTime.parse(birth) : null
      ..memberId = json['memberId'] as String?
      ..dailyGoal = (json['dailyGoal'] as num?)?.toInt() ?? _defaults.dailyGoalWords
      ..reminderTime = (json['reminderTime'] as String?) ?? _defaults.reminderTime
      ..notificationsEnabled = (json['notificationsEnabled'] as bool?) ?? _defaults.isNotificationEnabled;
  }
}

class _OtpTicket {
  final String code;
  final DateTime expiresAt;
  bool verified = false;
  _OtpTicket(this.code, this.expiresAt);
}

/// Kho xác thực của Track A (Màn 01, 02, 03, 21, 23).
///
/// Có [api] (chạy app với `--dart-define=API_BASE_URL=...`): đăng nhập, đăng ký, Google / Facebook
/// và đăng xuất gọi backend (`/auth/login`, `/auth/register`, `/auth/social-login`, `/auth/logout`).
/// Token chỉ giữ trong bộ nhớ. Không có [api]: chạy offline, tài khoản và phiên đăng nhập lưu
/// trên máy qua [storage] (mở lại app vẫn còn đăng nhập).
/// Chế độ Dùng thử luôn chạy offline. Các phần khác (quên mật khẩu, đổi mật khẩu) vẫn offline.
class AuthRepository extends ChangeNotifier {
  AuthRepository({
    this.latency = const Duration(milliseconds: 600),
    Random? random,
    ApiClient? apiClient,
    this._storage,
  })  : _random = random ?? Random(),
        _api = apiClient {
    _restoreAccounts();
    _seedAccounts();
  }

  static final AuthRepository instance = AuthRepository(apiClient: ApiClient.instance, storage: LocalStore.app);

  /// Tài khoản Demo để giảng viên đăng nhập thử (không kèm dữ liệu mẫu, bắt đầu trống).
  static const String demoEmail = 'learner@karvocab.com';
  static const String demoPassword = 'Karvocab1';

  /// Thời hạn hiệu lực của mã OTP.
  static const Duration otpLifetime = Duration(minutes: 5);

  final Duration latency;
  final Random _random;
  final ApiClient? _api;
  final LocalStore? _storage;

  /// `true` khi đăng nhập / đăng ký đi qua backend thật.
  bool get usesBackend => _api != null;

  final Map<String, _Account> _accounts = {};
  final Map<String, _OtpTicket> _otpTickets = {};

  UserProfileModel? _currentUser;
  bool _isDemo = false;

  UserProfileModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isDemo => _isDemo;

  // ---------------------------------------------------------------------------
  // Phiên đăng nhập
  // ---------------------------------------------------------------------------

  /// Màn 01: kiểm tra phiên đã lưu. Trả về `true` nếu còn đăng nhập.
  /// Bản offline nhớ phiên trên máy; bản nối BE chưa lưu token nên phải đăng nhập lại.
  Future<bool> restoreSession() async {
    if (isLoggedIn) return true;
    if (_api != null) return false;
    final session = _storage?.readJson(StorageKeys.session);
    if (session is! Map<String, dynamic>) return false;
    final email = session['email'];
    if (email is! String) return false;
    final account = _accounts[email];
    if (account == null) return false;
    _startSession(_profileFor(email, account), demo: session['demo'] == true);
    return true;
  }

  /// Màn 02: đăng nhập email + mật khẩu.
  Future<UserProfileModel> login(String email, String password) async {
    final api = _api;
    if (api != null) {
      return _remoteSession(
        api,
        () => api.post('/auth/login', auth: false, body: {'email': email.trim(), 'password': password}),
        password: password,
      );
    }
    await Future<void>.delayed(latency);
    final key = _normalize(email);
    final account = _accounts[key];
    if (account == null) {
      throw const AuthException(AppStrings.loginEmailNotRegistered, field: AuthErrorField.email);
    }
    if (!account.checkPassword(password)) {
      throw const AuthException(AppStrings.loginWrongPassword, field: AuthErrorField.password);
    }
    return _startSession(_profileFor(key, account));
  }

  /// Màn 02: đăng nhập Google / Facebook (verifier giả lập — backend cũng dùng mock).
  Future<UserProfileModel> loginWithSocial(SocialProvider provider) async {
    final isGoogle = provider == SocialProvider.google;
    final email = isGoogle ? 'google.user@gmail.com' : 'facebook.user@facebook.com';
    final name = isGoogle ? 'Người dùng Google' : 'Người dùng Facebook';
    final api = _api;
    if (api != null) {
      // BE chạy SOCIAL_AUTH_MODE=mock nhận token dạng `mock:<providerId>:<email>:<họ tên>`.
      final providerName = isGoogle ? 'google' : 'facebook';
      return _remoteSession(
        api,
        () => api.post('/auth/social-login', auth: false, body: {
          'provider': providerName,
          'idToken': 'mock:$providerName-demo:$email:$name',
        }),
      );
    }
    await Future<void>.delayed(latency);
    // Google / Facebook không trả ngày sinh: chưa có mã ID cho tới khi người dùng bổ sung.
    final account = _accounts.putIfAbsent(email, () => _Account(fullName: name, password: _randomPassword()));
    return _startSession(_profileFor(email, account));
  }

  /// Màn 02: Chế độ Dùng thử — vào thẳng app với hồ sơ mẫu, không cần mạng.
  UserProfileModel enterDemoMode() {
    _api?.setTokens(null); // Dùng thử không gọi BE: AI dùng kho từ mẫu.
    final account = _accounts[demoEmail]!;
    return _startSession(_profileFor(demoEmail, account), demo: true);
  }

  /// Màn 03: đăng ký tài khoản mới rồi tự đăng nhập.
  /// Có [birthDate] thì cấp mã ID ngay.
  Future<UserProfileModel> register({
    required String fullName,
    required String email,
    required String password,
    DateTime? birthDate,
  }) async {
    final api = _api;
    if (api != null) {
      return _remoteSession(
        api,
        () => api.post('/auth/register', auth: false, body: {
          'email': email.trim(),
          'password': password,
          'fullName': fullName.trim(),
        }),
        password: password,
        birthDate: birthDate,
      );
    }
    await Future<void>.delayed(latency);
    final key = _normalize(email);
    if (_accounts.containsKey(key)) {
      throw const AuthException(AppStrings.registerEmailTaken, field: AuthErrorField.email);
    }
    final account = _Account(fullName: fullName.trim(), password: password);
    _accounts[key] = account;
    if (birthDate != null) _assignBirthDate(account, birthDate);
    return _startSession(_profileFor(key, account));
  }

  /// Màn 15 / 23: cập nhật ngày sinh. Lần đầu có ngày sinh thì cấp mã ID;
  /// đã có mã thì mã giữ nguyên dù ngày sinh đổi.
  void updateBirthDate(DateTime birthDate) {
    final user = _currentUser;
    if (user == null) return;
    final account = _accounts[_normalize(user.email)];
    if (account == null) return;
    _assignBirthDate(account, birthDate);
    _currentUser = user.copyWith(birthDate: account.birthDate, memberId: account.memberId);
    notifyListeners();
  }

  /// Màn 23: đăng xuất — xoá phiên hiện tại.
  void logout() {
    final api = _api;
    final refresh = api?.refreshToken;
    if (api != null && refresh != null) {
      // Thu hồi token ở BE; lỗi mạng cũng không chặn việc đăng xuất trên máy.
      api.post('/auth/logout', body: {'refreshToken': refresh}).catchError((Object _) => null);
    }
    api?.setTokens(null);
    _currentUser = null;
    _isDemo = false;
    notifyListeners();
  }

  /// Màn 23: lưu cài đặt (mục tiêu ngày, giờ nhắc học, ...).
  void updateProfile(UserProfileModel profile) {
    _currentUser = profile;
    final account = _accounts[_normalize(profile.email)];
    if (account != null) {
      account
        ..dailyGoal = profile.dailyGoalWords
        ..reminderTime = profile.reminderTime
        ..notificationsEnabled = profile.isNotificationEnabled;
    }
    notifyListeners();
  }

  /// Màn 23: đổi mật khẩu (kiểm tra mật khẩu hiện tại).
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await Future<void>.delayed(latency);
    final user = _currentUser;
    if (user == null) throw const AuthException('Phiên đăng nhập đã hết hạn');
    if (_isDemo) {
      throw const AuthException('Không thể đổi mật khẩu ở Chế độ Dùng thử');
    }
    final account = _accounts[_normalize(user.email)];
    if (account == null || !account.checkPassword(currentPassword)) {
      throw const AuthException('Mật khẩu hiện tại không đúng');
    }
    if (currentPassword == newPassword) {
      throw const AuthException('Mật khẩu mới phải khác mật khẩu hiện tại');
    }
    account.setPassword(newPassword);
    _saveAccounts();
  }

  // ---------------------------------------------------------------------------
  // Quên mật khẩu (Màn 21): Email → OTP 6 số → Mật khẩu mới
  // ---------------------------------------------------------------------------

  /// Gửi mã OTP. Ở chế độ offline mã được trả về để hiển thị cho người dùng
  /// (thay cho email); khi nối backend, hàm chỉ trả về sau khi server gửi mail.
  Future<String> requestPasswordReset(String email) async {
    await Future<void>.delayed(latency);
    final key = _normalize(email);
    if (!_accounts.containsKey(key)) {
      throw const AuthException('Không tìm thấy tài khoản với email này');
    }
    final code = List.generate(6, (_) => _random.nextInt(10)).join();
    _otpTickets[key] = _OtpTicket(code, DateTime.now().add(otpLifetime));
    return code;
  }

  Future<void> verifyOtp(String email, String code) async {
    await Future<void>.delayed(latency);
    final ticket = _otpTickets[_normalize(email)];
    if (ticket == null) throw const AuthException('Vui lòng yêu cầu gửi mã OTP trước');
    if (DateTime.now().isAfter(ticket.expiresAt)) {
      throw const AuthException('Mã OTP đã hết hạn, vui lòng gửi lại mã');
    }
    if (ticket.code != code.trim()) throw const AuthException('Mã OTP không chính xác');
    ticket.verified = true;
  }

  Future<void> resetPassword(String email, String newPassword) async {
    await Future<void>.delayed(latency);
    final key = _normalize(email);
    final ticket = _otpTickets[key];
    final account = _accounts[key];
    if (ticket == null || !ticket.verified || account == null) {
      throw const AuthException('Phiên đặt lại mật khẩu không hợp lệ');
    }
    account.setPassword(newPassword);
    _saveAccounts();
    _otpTickets.remove(key);
  }

  /// Đưa kho về trạng thái ban đầu (dùng trong kiểm thử).
  @visibleForTesting
  void debugReset() {
    _accounts.clear();
    _seedAccounts();
    _otpTickets.clear();
    _currentUser = null;
    _isDemo = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Nội bộ
  // ---------------------------------------------------------------------------

  String _normalize(String email) => email.trim().toLowerCase();

  /// Gọi API xác thực, lưu token, rồi dựng hồ sơ từ `data.user` của BE.
  /// Tài khoản được ghi lại trên máy để ngày sinh / mã ID (chưa có API) vẫn dùng được.
  Future<UserProfileModel> _remoteSession(
    ApiClient api,
    Future<dynamic> Function() call, {
    String? password,
    DateTime? birthDate,
  }) async {
    final Object? data;
    try {
      data = await call();
    } on ApiException catch (e) {
      throw _authErrorFrom(e);
    }
    final user = data is Map<String, dynamic> ? data['user'] : null;
    if (data is! Map<String, dynamic> || user is! Map<String, dynamic> || user['email'] is! String) {
      throw const AuthException(AppStrings.authServerError);
    }
    api.saveTokensFrom(data);
    final key = _normalize(user['email'] as String);
    final fullName = (user['fullName'] as String?) ?? key;
    final account = _accounts.putIfAbsent(
      key,
      () => _Account(fullName: fullName, password: password ?? _randomPassword()),
    )..fullName = fullName;
    if (password != null) account.setPassword(password);
    if (birthDate != null) _assignBirthDate(account, birthDate);
    return _startSession(_profileFor(key, account));
  }

  static AuthException _authErrorFrom(ApiException e) {
    switch (e.errorCode) {
      case 'INVALID_CREDENTIALS':
        return const AuthException(AppStrings.loginInvalidCredentials, field: AuthErrorField.password);
      case 'EMAIL_EXISTS':
        return const AuthException(AppStrings.registerEmailTaken, field: AuthErrorField.email);
      case 'RATE_LIMITED':
        final s = e.retryAfterSeconds;
        return AuthException(s == null ? AppStrings.authRateLimited : AppStrings.authRateLimitedSeconds(s));
    }
    if (e.fieldErrors.containsKey('email')) {
      return AuthException(e.fieldErrors['email']!, field: AuthErrorField.email);
    }
    if (e.fieldErrors.containsKey('password')) {
      return AuthException(e.fieldErrors['password']!, field: AuthErrorField.password);
    }
    return AuthException(e.message);
  }

  /// Chỉ tạo sẵn tài khoản Demo (trống, chưa có ngày sinh / mã ID) nếu máy chưa có.
  void _seedAccounts() {
    _accounts.putIfAbsent(demoEmail, () => _Account(fullName: demoFullName, password: demoPassword));
  }

  static const String demoFullName = 'Học viên Demo';

  void _restoreAccounts() {
    final data = _storage?.readJson(StorageKeys.accounts);
    if (data is! Map<String, dynamic>) return;
    try {
      _accounts.addAll({
        for (final e in data.entries) e.key: _Account.fromJson(e.value as Map<String, dynamic>),
      });
    } on Object {
      _accounts.clear(); // dữ liệu hỏng: chỉ còn tài khoản Demo
    }
  }

  void _saveAccounts() {
    _storage?.writeJson(StorageKeys.accounts, {for (final e in _accounts.entries) e.key: e.value.toJson()});
  }

  /// Mỗi lần trạng thái đổi: lưu danh sách tài khoản và phiên đăng nhập hiện tại.
  @override
  void notifyListeners() {
    final storage = _storage;
    if (storage != null) {
      _saveAccounts();
      final user = _currentUser;
      if (user == null || _api != null) {
        storage.remove(StorageKeys.session);
      } else {
        storage.writeJson(StorageKeys.session, {'email': _normalize(user.email), 'demo': _isDemo});
      }
    }
    super.notifyListeners();
  }

  void _assignBirthDate(_Account account, DateTime birthDate) {
    account.birthDate = DateTime(birthDate.year, birthDate.month, birthDate.day);
    account.memberId ??= MemberId.generate(
      birthDate,
      _accounts.values.map((a) => a.memberId).whereType<String>(),
    );
  }

  String _randomPassword() => List.generate(16, (_) => _random.nextInt(36).toRadixString(36)).join();

  UserProfileModel _startSession(UserProfileModel profile, {bool demo = false}) {
    _currentUser = profile;
    _isDemo = demo;
    notifyListeners();
    return profile;
  }

  /// Hồ sơ của tài khoản; số liệu học tập lấy từ CollectionStore / DashboardStore.
  UserProfileModel _profileFor(String email, _Account account) {
    return UserProfileModel(
      fullName: account.fullName,
      email: email,
      avatarUrl: '',
      totalWordsLearned: 0,
      currentStreak: 0,
      totalCollections: 0,
      dailyGoalWords: account.dailyGoal,
      reminderTime: account.reminderTime,
      isNotificationEnabled: account.notificationsEnabled,
      memberId: account.memberId,
      birthDate: account.birthDate,
    );
  }
}
