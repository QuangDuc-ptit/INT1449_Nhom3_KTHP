import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

/// Lỗi trả về từ backend theo định dạng chung:
/// `{ success: false, message, errorCode, errors?: [{ field, message }] }`.
class ApiException implements Exception {
  /// Mã HTTP; 0 = không kết nối được máy chủ.
  final int statusCode;
  final String errorCode;
  final String message;
  final Map<String, String> fieldErrors;

  /// Số giây chờ khi bị `RATE_LIMITED` (header `Retry-After`), nếu đọc được.
  final int? retryAfterSeconds;

  const ApiException(
    this.statusCode,
    this.errorCode,
    this.message, {
    this.fieldErrors = const {},
    this.retryAfterSeconds,
  });

  static const String networkError = 'NETWORK_ERROR';

  bool get isNetworkError => errorCode == networkError;

  @override
  String toString() => 'ApiException($statusCode, $errorCode, $message)';
}

/// Cặp token BE cấp khi đăng nhập / đăng ký / làm mới.
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  const AuthTokens(this.accessToken, this.refreshToken);

  Map<String, String> toJson() => {'accessToken': accessToken, 'refreshToken': refreshToken};

  /// Đọc lại cặp token đã lưu; dữ liệu thiếu / sai kiểu thì trả `null`.
  static AuthTokens? fromJson(Object? json) {
    if (json is! Map) return null;
    final access = json['accessToken'];
    final refresh = json['refreshToken'];
    return access is String && refresh is String ? AuthTokens(access, refresh) : null;
  }
}

/// Gọi REST API của backend: tự gắn `Authorization: Bearer`, bóc lớp `{ success, data }`,
/// đổi lỗi thành [ApiException], hết hạn access token (401) thì làm mới một lần rồi gọi lại.
///
/// Mỗi lần cặp token đổi (đăng nhập, làm mới, đăng xuất) gọi [onTokensChanged] để
/// [AuthRepository] lưu xuống máy, nhờ đó mở lại app không phải đăng nhập lại.
class ApiClient {
  ApiClient({required this.baseUrl, http.Client? httpClient, this.timeout = ApiConfig.requestTimeout})
      : _http = httpClient ?? http.Client();

  /// Client dùng chung khi app chạy với `API_BASE_URL`; `null` ở Demo Mode.
  static final ApiClient? instance = ApiConfig.isEnabled ? ApiClient(baseUrl: ApiConfig.baseUrl) : null;

  final String baseUrl;
  final Duration timeout;
  final http.Client _http;

  AuthTokens? _tokens;
  Future<bool>? _refreshing;

  /// Được gọi mỗi khi cặp token đổi; `null` = phiên đã bị xoá.
  void Function(AuthTokens? tokens)? onTokensChanged;

  bool get hasSession => _tokens != null;

  void setTokens(AuthTokens? tokens) {
    _tokens = tokens;
    onTokensChanged?.call(tokens);
  }

  /// Đọc `accessToken` / `refreshToken` trong `data` của các API xác thực và lưu lại.
  void saveTokensFrom(Map<String, dynamic> data) {
    final tokens = AuthTokens.fromJson(data);
    if (tokens != null) setTokens(tokens);
  }

  String? get refreshToken => _tokens?.refreshToken;

  Future<dynamic> get(String path, {bool auth = true}) => _send('GET', path, auth: auth);

  Future<dynamic> post(String path, {Object? body, bool auth = true}) => _send('POST', path, body: body, auth: auth);

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) => _send('PATCH', path, body: body, auth: auth);

  Future<dynamic> put(String path, {Object? body, bool auth = true}) => _send('PUT', path, body: body, auth: auth);

  Future<dynamic> delete(String path, {Object? body, bool auth = true}) =>
      _send('DELETE', path, body: body, auth: auth);

  Future<dynamic> _send(String method, String path, {Object? body, required bool auth, bool retried = false}) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final token = _tokens?.accessToken;
    if (auth && token != null) request.headers['Authorization'] = 'Bearer $token';

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _http.send(request).timeout(timeout));
    } on TimeoutException {
      throw const ApiException(0, 'TIMEOUT', 'Máy chủ phản hồi quá lâu, vui lòng thử lại.');
    } catch (_) {
      throw const ApiException(0, ApiException.networkError, 'Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.');
    }

    if (response.statusCode == 401 && auth && !retried && _tokens != null && await _refresh()) {
      return _send(method, path, body: body, auth: auth, retried: true);
    }

    final decoded = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded is Map<String, dynamic> && decoded.containsKey('data') ? decoded['data'] : decoded;
    }
    throw _errorFrom(response, decoded);
  }

  /// Làm mới access token bằng refresh token (gộp các lời gọi đồng thời thành một).
  Future<bool> _refresh() {
    return _refreshing ??= () async {
      try {
        final refresh = _tokens?.refreshToken;
        if (refresh == null) return false;
        final data = await _send('POST', '/auth/refresh', body: {'refreshToken': refresh}, auth: false, retried: true);
        if (data is Map<String, dynamic>) {
          saveTokensFrom(data);
          return true;
        }
        return false;
      } on ApiException catch (e) {
        // Chỉ bỏ phiên khi BE từ chối refresh token; mất mạng / quá giờ thì giữ để thử lại sau.
        if (e.statusCode != 0) setTokens(null);
        return false;
      } finally {
        _refreshing = null;
      }
    }();
  }

  static Object? _decode(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return null;
    }
  }

  static ApiException _errorFrom(http.Response response, Object? decoded) {
    final map = decoded is Map<String, dynamic> ? decoded : const <String, dynamic>{};
    final fields = <String, String>{};
    final errors = map['errors'];
    if (errors is List) {
      for (final e in errors) {
        if (e is Map && e['field'] is String && e['message'] is String) {
          fields.putIfAbsent(e['field'] as String, () => e['message'] as String);
        }
      }
    }
    return ApiException(
      response.statusCode,
      (map['errorCode'] as String?) ?? 'HTTP_${response.statusCode}',
      (map['message'] as String?) ?? 'Đã có lỗi xảy ra, vui lòng thử lại sau.',
      fieldErrors: fields,
      retryAfterSeconds: int.tryParse(response.headers['retry-after'] ?? ''),
    );
  }
}
