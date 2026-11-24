import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/member_id.dart';
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

class _Account {
  String fullName;
  String password;
  DateTime? birthDate;
  String? memberId;

  _Account({
    required this.fullName,
    required this.password,
    this.birthDate,
    this.memberId,
  });
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
/// Token chỉ giữ trong bộ nhớ. Không có [api]: chạy offline với tài khoản trong bộ nhớ (Demo Mode).
/// Chế độ Dùng thử luôn chạy offline. Các phần khác (quên mật khẩu, đổi mật khẩu) vẫn offline.
class AuthRepository extends ChangeNotifier {
  AuthRepository({this.latency = const Duration(milliseconds: 600), Random? random, ApiClient? apiClient})
      : _random = random ?? Random(),
        _api = apiClient {
    _seedAccounts();
  }

  static final AuthRepository instance = AuthRepository(apiClient: ApiClient.instance);

  /// Tài khoản mẫu để giảng viên đăng nhập thử.
  static const String demoEmail = 'learner@karvocab.com';
  static const String demoPassword = 'Karvocab1';

  /// Thời hạn hiệu lực của mã OTP.
  static const Duration otpLifetime = Duration(minutes: 5);

  final Duration latency;
  final Random _random;
  final ApiClient? _api;

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
  Future<bool> restoreSession() async => isLoggedIn;

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
    if (account.password != password) {
      throw const AuthException(AppStrings.loginWrongPassword, field: AuthErrorField.password);
    }
    return _startSession(_profileFor(key, account, isNew: false));
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
    return _startSession(_profileFor(email, account, isNew: false));
  }

  /// Màn 02: Chế độ Dùng thử — vào thẳng app với hồ sơ mẫu, không cần mạng.
  UserProfileModel enterDemoMode() {
    _api?.setTokens(null); // Dùng thử không gọi BE: AI dùng kho từ mẫu.
    final account = _accounts[demoEmail]!;
    return _startSession(_profileFor(demoEmail, account, isNew: false), demo: true);
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
        isNew: true,
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
    return _startSession(_profileFor(key, account, isNew: true));
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
    if (account == null || account.password != currentPassword) {
      throw const AuthException('Mật khẩu hiện tại không đúng');
    }
    if (currentPassword == newPassword) {
      throw const AuthException('Mật khẩu mới phải khác mật khẩu hiện tại');
    }
    account.password = newPassword;
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
    account.password = newPassword;
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
    bool isNew = false,
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
    if (password != null) account.password = password;
    if (birthDate != null) _assignBirthDate(account, birthDate);
    return _startSession(_profileFor(key, account, isNew: isNew));
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

  /// Tài khoản mẫu: chỉ có tài khoản demo.
  void _seedAccounts() {
    _accounts[demoEmail] = _Account(
      fullName: 'Nguyễn Văn A',
      password: demoPassword,
      birthDate: DateTime(2005, 9, 20),
      memberId: 'KM05092000',
    );
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

  UserProfileModel _profileFor(String email, _Account account, {required bool isNew}) {
    final mock = UserProfileModel.mockDefault();
    // Dựng lại để các trường có thể rỗng (mã ID, ngày sinh) lấy đúng của tài khoản.
    return UserProfileModel(
      fullName: account.fullName,
      email: email,
      avatarUrl: mock.avatarUrl,
      // Tài khoản mới: thống kê bắt đầu từ 0.
      totalWordsLearned: isNew ? 0 : mock.totalWordsLearned,
      currentStreak: isNew ? 0 : mock.currentStreak,
      totalCollections: isNew ? 0 : mock.totalCollections,
      dailyGoalWords: mock.dailyGoalWords,
      reminderTime: mock.reminderTime,
      isNotificationEnabled: mock.isNotificationEnabled,
      memberId: account.memberId,
      birthDate: account.birthDate,
    );
  }
}
