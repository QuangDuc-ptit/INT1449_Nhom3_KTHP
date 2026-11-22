import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_strings.dart';
import '../models/user_profile_model.dart';

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
  _Account({required this.fullName, required this.password});
}

class _OtpTicket {
  final String code;
  final DateTime expiresAt;
  bool verified = false;
  _OtpTicket(this.code, this.expiresAt);
}

/// Kho xác thực của Track A (Màn 01, 02, 03, 21, 23).
///
/// Bản hiện tại chạy offline với tài khoản lưu trong bộ nhớ (chế độ Demo, không lộ API key).
/// Sprint 3 thay thân các hàm bằng lời gọi `/auth/login`, `/auth/register`,
/// `/auth/forgot-password`, `/auth/reset-password` của backend (`be/develop`)
/// và lưu refresh token vào Secure Storage — chữ ký hàm giữ nguyên.
class AuthRepository extends ChangeNotifier {
  AuthRepository({this.latency = const Duration(milliseconds: 600), Random? random})
      : _random = random ?? Random();

  static final AuthRepository instance = AuthRepository();

  /// Tài khoản mẫu để giảng viên đăng nhập thử.
  static const String demoEmail = 'learner@karvocab.com';
  static const String demoPassword = 'Karvocab1';

  /// Tài khoản test nội bộ của nhóm (không hiển thị trên giao diện).
  static const String testEmail = 'admin@123';
  static const String testPassword = '123456';

  /// Thời hạn hiệu lực của mã OTP.
  static const Duration otpLifetime = Duration(minutes: 5);

  final Duration latency;
  final Random _random;

  final Map<String, _Account> _accounts = {
    demoEmail: _Account(fullName: 'Nguyễn Văn A', password: demoPassword),
    testEmail: _Account(fullName: 'Admin', password: testPassword),
  };
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
    await Future<void>.delayed(latency);
    final key = _normalize(email);
    final account = _accounts[key];
    if (account == null) {
      throw const AuthException(AppStrings.loginEmailNotRegistered, field: AuthErrorField.email);
    }
    if (account.password != password) {
      throw const AuthException(AppStrings.loginWrongPassword, field: AuthErrorField.password);
    }
    return _startSession(_profileFor(key, account.fullName, isNew: false));
  }

  /// Màn 02: đăng nhập Google / Facebook (verifier giả lập — backend cũng dùng mock).
  Future<UserProfileModel> loginWithSocial(SocialProvider provider) async {
    await Future<void>.delayed(latency);
    final isGoogle = provider == SocialProvider.google;
    final email = isGoogle ? 'google.user@gmail.com' : 'facebook.user@facebook.com';
    final name = isGoogle ? 'Người dùng Google' : 'Người dùng Facebook';
    _accounts.putIfAbsent(email, () => _Account(fullName: name, password: _randomPassword()));
    return _startSession(_profileFor(email, name, isNew: false));
  }

  /// Màn 02: Chế độ Dùng thử — vào thẳng app với hồ sơ mẫu, không cần mạng.
  UserProfileModel enterDemoMode() {
    return _startSession(UserProfileModel.mockDefault(), demo: true);
  }

  /// Màn 03: đăng ký tài khoản mới rồi tự đăng nhập.
  Future<UserProfileModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(latency);
    final key = _normalize(email);
    if (_accounts.containsKey(key)) {
      throw const AuthException('Email này đã được đăng ký');
    }
    _accounts[key] = _Account(fullName: fullName.trim(), password: password);
    return _startSession(_profileFor(key, fullName.trim(), isNew: true));
  }

  /// Màn 23: đăng xuất — xoá phiên hiện tại.
  void logout() {
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
    _accounts
      ..clear()
      ..[demoEmail] = _Account(fullName: 'Nguyễn Văn A', password: demoPassword)
      ..[testEmail] = _Account(fullName: 'Admin', password: testPassword);
    _otpTickets.clear();
    _currentUser = null;
    _isDemo = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Nội bộ
  // ---------------------------------------------------------------------------

  String _normalize(String email) => email.trim().toLowerCase();

  String _randomPassword() => List.generate(16, (_) => _random.nextInt(36).toRadixString(36)).join();

  UserProfileModel _startSession(UserProfileModel profile, {bool demo = false}) {
    _currentUser = profile;
    _isDemo = demo;
    notifyListeners();
    return profile;
  }

  UserProfileModel _profileFor(String email, String fullName, {required bool isNew}) {
    final base = UserProfileModel.mockDefault();
    if (!isNew) return base.copyWith(email: email, fullName: fullName);
    // Tài khoản mới: thống kê bắt đầu từ 0.
    return base.copyWith(
      email: email,
      fullName: fullName,
      totalWordsLearned: 0,
      currentStreak: 0,
      totalCollections: 0,
    );
  }
}
