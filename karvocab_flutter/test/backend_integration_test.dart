import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:karvocab_flutter/core/constants/app_strings.dart';
import 'package:karvocab_flutter/core/utils/validators.dart';
import 'package:karvocab_flutter/core/widgets/app_text_field.dart';
import 'package:karvocab_flutter/data/local/local_store.dart';
import 'package:karvocab_flutter/data/remote/api_client.dart';
import 'package:karvocab_flutter/data/remote/remote_ai_vocab_repository.dart';
import 'package:karvocab_flutter/data/repositories/ai_vocab_repository.dart';
import 'package:karvocab_flutter/data/repositories/auth_repository.dart';
import 'package:karvocab_flutter/presentation/forgot_password/forgot_password_flow.dart';

/// Kiểm tra lớp nối backend bằng client HTTP giả (không cần chạy BE thật).
void main() {
  http.Response ok(Object? data) =>
      http.Response(jsonEncode({'success': true, 'data': data, 'message': 'Thành công'}), 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
  http.Response fail(int status, String code, String message, {Map<String, String> headers = const {}}) =>
      http.Response(jsonEncode({'success': false, 'data': null, 'message': message, 'errorCode': code}), status,
          headers: {'content-type': 'application/json; charset=utf-8', ...headers});

  final authData = {
    'accessToken': 'access-1',
    'refreshToken': 'refresh-1',
    'user': {'id': 'u1', 'email': 'learner@karvocab.com', 'fullName': 'Nguyễn Văn A', 'avatarUrl': null},
  };

  test('Đăng nhập qua BE: lưu token, dựng hồ sơ từ data.user', () async {
    late http.Request sent;
    final api = ApiClient(
      baseUrl: 'http://be/api/v1',
      httpClient: MockClient((r) async {
        sent = r;
        return ok(authData);
      }),
    );
    final auth = AuthRepository(latency: Duration.zero, apiClient: api);
    final user = await auth.login(' learner@karvocab.com ', 'Karvocab1');

    expect(sent.url.toString(), 'http://be/api/v1/auth/login');
    expect(jsonDecode(sent.body), {'email': 'learner@karvocab.com', 'password': 'Karvocab1'});
    expect(user.fullName, 'Nguyễn Văn A');
    expect(api.hasSession, isTrue);
  });

  test('Sai mật khẩu ở BE → thông báo tiếng Việt gắn ô mật khẩu', () async {
    final api = ApiClient(
      baseUrl: 'http://be/api/v1',
      httpClient: MockClient((_) async => fail(401, 'INVALID_CREDENTIALS', 'Email hoặc mật khẩu không đúng')),
    );
    final auth = AuthRepository(latency: Duration.zero, apiClient: api);
    await expectLater(
      auth.login('learner@karvocab.com', 'sai'),
      throwsA(isA<AuthException>()
          .having((e) => e.message, 'message', AppStrings.loginInvalidCredentials)
          .having((e) => e.field, 'field', AuthErrorField.password)),
    );
    expect(auth.isLoggedIn, isFalse);
  });

  test('AI thật: gửi cefrLevel mặc định B1, gắn Bearer token, đọc danh sách từ', () async {
    late http.Request sent;
    final api = ApiClient(
      baseUrl: 'http://be/api/v1',
      httpClient: MockClient((r) async {
        sent = r;
        return ok({
          'words': [
            {
              'term': 'itinerary',
              'partOfSpeech': 'noun',
              'ipa': '/aɪˈtɪnərəri/',
              'definitionEn': 'a planned route of a journey',
              'definitionVi': 'lịch trình',
              'exampleSentence': 'Our itinerary includes Hue.',
              'cefrLevel': 'B2',
              'existsInCollection': false,
            },
          ],
        });
      }),
    )..setTokens(const AuthTokens('access-1', 'refresh-1'));

    final words = await RemoteAiVocabRepository(api).generate(topic: 'Du lịch', wordCount: 5);
    expect(sent.headers['Authorization'], 'Bearer access-1');
    expect(jsonDecode(sent.body), {'topic': 'Du lịch', 'cefrLevel': 'B1', 'wordCount': 5});
    expect(words.single.term, 'itinerary');
    expect(words.single.ipa, '/aɪˈtɪnərəri/');
  });

  test('AI thật: access token hết hạn thì tự làm mới rồi gọi lại', () async {
    final calls = <String>[];
    final api = ApiClient(
      baseUrl: 'http://be/api/v1',
      httpClient: MockClient((r) async {
        calls.add('${r.url.path} ${r.headers['Authorization'] ?? ''}');
        if (r.url.path.endsWith('/auth/refresh')) {
          return ok({...authData, 'accessToken': 'access-2', 'refreshToken': 'refresh-2'});
        }
        if (r.headers['Authorization'] == 'Bearer access-1') return fail(401, 'UNAUTHORIZED', 'Hết phiên');
        return ok({'words': <Object>[]});
      }),
    )..setTokens(const AuthTokens('access-1', 'refresh-1'));

    await RemoteAiVocabRepository(api).generate(topic: 'Travel', wordCount: 3);
    expect(calls, [
      '/api/v1/ai/generate-vocab Bearer access-1',
      '/api/v1/auth/refresh ',
      '/api/v1/ai/generate-vocab Bearer access-2',
    ]);
  });

  test('AI thật: lỗi BE (RATE_LIMITED, mất mạng) đổi thành AiVocabException', () async {
    final limited = ApiClient(
      baseUrl: 'http://be/api/v1',
      httpClient: MockClient((_) async => fail(429, 'RATE_LIMITED', 'Chậm lại', headers: {'retry-after': '42'})),
    );
    await expectLater(
      RemoteAiVocabRepository(limited).generate(topic: 'Travel', wordCount: 3),
      throwsA(isA<AiVocabException>()
          .having((e) => e.errorCode, 'code', 'RATE_LIMITED')
          .having((e) => e.retryAfterSeconds, 'retry', 42)),
    );

    final offline = ApiClient(
      baseUrl: 'http://be/api/v1',
      httpClient: MockClient((_) async => throw http.ClientException('refused')),
    );
    await expectLater(
      RemoteAiVocabRepository(offline).generate(topic: 'Travel', wordCount: 3),
      throwsA(isA<AiVocabException>().having((e) => e.errorCode, 'code', ApiException.networkError)),
    );
  });

  group('Quên mật khẩu qua BE (Màn 21)', () {
    test('forgot-password → verifyOtp chỉ giữ mã → reset-password gửi kèm mã', () async {
      final sent = <http.Request>[];
      final api = ApiClient(
        baseUrl: 'http://be/api/v1',
        httpClient: MockClient((r) async {
          sent.add(r);
          return ok(null);
        }),
      );
      final auth = AuthRepository(latency: Duration.zero, apiClient: api);

      expect(await auth.requestPasswordReset(' nguoi.moi@karvocab.com '), '');
      expect(sent.single.url.path, '/api/v1/auth/forgot-password');
      expect(sent.single.headers.containsKey('Authorization'), isFalse);
      expect(jsonDecode(sent.single.body), {'email': 'nguoi.moi@karvocab.com'});

      await expectLater(
        auth.verifyOtp('nguoi.moi@karvocab.com', '12a'),
        throwsA(isA<AuthException>()
            .having((e) => e.field, 'field', AuthErrorField.otp)
            .having((e) => e.message, 'message', Validators.otp('12a'))),
      );
      await auth.verifyOtp('nguoi.moi@karvocab.com', ' 123456 ');
      expect(sent, hasLength(1), reason: 'BE không có API kiểm tra OTP riêng');

      await auth.resetPassword('nguoi.moi@karvocab.com', 'Matkhau9');
      expect(sent.last.url.path, '/api/v1/auth/reset-password');
      expect(jsonDecode(sent.last.body), {'email': 'nguoi.moi@karvocab.com', 'otp': '123456', 'newPassword': 'Matkhau9'});
    });

    test('OTP sai / hết hạn ở BE → AuthException gắn ô OTP, giữ thông báo của server', () async {
      final api = ApiClient(
        baseUrl: 'http://be/api/v1',
        httpClient: MockClient((r) async => r.url.path.endsWith('/reset-password')
            ? fail(400, 'OTP_INVALID', 'Mã xác nhận không đúng hoặc đã hết hạn')
            : ok(null)),
      );
      final auth = AuthRepository(latency: Duration.zero, apiClient: api);
      await auth.requestPasswordReset('a@b.com');
      await auth.verifyOtp('a@b.com', '000000');

      await expectLater(
        auth.resetPassword('a@b.com', 'Matkhau9'),
        throwsA(isA<AuthException>()
            .having((e) => e.field, 'field', AuthErrorField.otp)
            .having((e) => e.message, 'message', 'Mã xác nhận không đúng hoặc đã hết hạn')),
      );
    });

    test('Gửi mã quá 3 lần trong 15 phút (RATE_LIMITED) → thông báo của server', () async {
      final api = ApiClient(
        baseUrl: 'http://be/api/v1',
        httpClient: MockClient(
            (_) async => fail(429, 'RATE_LIMITED', 'Bạn thao tác quá nhanh, vui lòng thử lại sau', headers: {'retry-after': '900'})),
      );
      final auth = AuthRepository(latency: Duration.zero, apiClient: api);
      await expectLater(
        auth.requestPasswordReset('a@b.com'),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', 'Bạn thao tác quá nhanh, vui lòng thử lại sau')),
      );
    });

    test('Chưa qua bước OTP thì resetPassword không gọi BE', () async {
      var calls = 0;
      final api = ApiClient(
        baseUrl: 'http://be/api/v1',
        httpClient: MockClient((_) async {
          calls++;
          return ok(null);
        }),
      );
      final auth = AuthRepository(latency: Duration.zero, apiClient: api);
      await expectLater(
        auth.resetPassword('a@b.com', 'Matkhau9'),
        throwsA(isA<AuthException>().having((e) => e.field, 'field', AuthErrorField.otp)),
      );
      expect(calls, 0);
    });

    testWidgets('Màn 21 nối BE: không hiện mã offline; OTP sai lúc đặt lại → lùi về bước OTP, lỗi dưới ô',
        (tester) async {
      final api = ApiClient(
        baseUrl: 'http://be/api/v1',
        httpClient: MockClient((r) async => r.url.path.endsWith('/reset-password')
            ? fail(400, 'OTP_INVALID', 'Mã xác nhận không đúng hoặc đã hết hạn')
            : ok(null)),
      );
      final auth = AuthRepository(latency: Duration.zero, apiClient: api);
      Finder input(String key) => find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));
      Future<void> tapKey(String key) async {
        await tester.ensureVisible(find.byKey(Key(key)));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key(key)));
        // MockClient trả kết quả qua I/O thật: chờ ngoài fake async rồi mới vẽ lại.
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();
      }

      await tester.pumpWidget(MaterialApp(home: ForgotPasswordFlow(authRepository: auth)));
      await tester.enterText(input('forgot_email'), 'a@b.com');
      await tapKey('forgot_send');
      expect(find.byKey(const Key('forgot_otp')), findsOneWidget);
      expect(find.byKey(const Key('forgot_offline_otp')), findsNothing);

      await tester.enterText(input('forgot_otp'), '000000');
      await tapKey('forgot_verify');
      await tester.enterText(input('forgot_new_password'), 'Matkhau9');
      await tester.enterText(input('forgot_confirm_password'), 'Matkhau9');
      await tapKey('forgot_reset');

      expect(find.byKey(const Key('forgot_otp')), findsOneWidget);
      expect(tester.widget<AppTextField>(find.byKey(const Key('forgot_otp'))).errorText,
          'Mã xác nhận không đúng hoặc đã hết hạn');
    });
  });

  group('Đổi mật khẩu qua BE (Màn 23)', () {
    test('PATCH /users/password gửi mật khẩu cũ + mới, lưu đè cặp token mới', () async {
      final sent = <http.Request>[];
      final api = ApiClient(
        baseUrl: 'http://be/api/v1',
        httpClient: MockClient((r) async {
          sent.add(r);
          if (r.url.path.endsWith('/auth/login')) return ok(authData);
          if (r.url.path.endsWith('/users/password')) {
            return ok({'accessToken': 'access-2', 'refreshToken': 'refresh-2'});
          }
          return ok(null);
        }),
      );
      final auth = AuthRepository(latency: Duration.zero, apiClient: api);
      await auth.login('learner@karvocab.com', 'Karvocab1');

      await auth.changePassword('Karvocab1', 'Matkhau9');
      final patch = sent.last;
      expect(patch.method, 'PATCH');
      expect(patch.url.path, '/api/v1/users/password');
      expect(patch.headers['Authorization'], 'Bearer access-1');
      expect(jsonDecode(patch.body), {'currentPassword': 'Karvocab1', 'newPassword': 'Matkhau9'});

      expect(api.refreshToken, 'refresh-2');
      await api.get('/users/profile');
      expect(sent.last.headers['Authorization'], 'Bearer access-2');
    });

    test('Mật khẩu hiện tại sai (PASSWORD_INCORRECT) → thông báo của server', () async {
      final api = ApiClient(
        baseUrl: 'http://be/api/v1',
        httpClient: MockClient((r) async => r.url.path.endsWith('/auth/login')
            ? ok(authData)
            : fail(400, 'PASSWORD_INCORRECT', 'Mật khẩu hiện tại không đúng')),
      );
      final auth = AuthRepository(latency: Duration.zero, apiClient: api);
      await auth.login('learner@karvocab.com', 'Karvocab1');

      await expectLater(
        auth.changePassword('sai-roi', 'Matkhau9'),
        throwsA(isA<AuthException>()
            .having((e) => e.message, 'message', 'Mật khẩu hiện tại không đúng')
            .having((e) => e.field, 'field', AuthErrorField.password)),
      );
      expect(api.refreshToken, 'refresh-1');
    });
  });

  group('Nhớ phiên khi nối BE (Màn 01)', () {
    test('Đăng nhập rồi mở lại app: nạp token đã lưu, gọi /auth/me, vào thẳng app', () async {
      final storage = MemoryLocalStore();
      final first = AuthRepository(
        latency: Duration.zero,
        storage: storage,
        apiClient: ApiClient(baseUrl: 'http://be/api/v1', httpClient: MockClient((_) async => ok(authData))),
      );
      await first.login('learner@karvocab.com', 'Karvocab1');
      expect(AuthTokens.fromJson(storage.readJson(StorageKeys.tokens))?.refreshToken, 'refresh-1');

      final sent = <http.Request>[];
      final reopenedApi = ApiClient(
        baseUrl: 'http://be/api/v1',
        httpClient: MockClient((r) async {
          sent.add(r);
          return ok(authData['user']);
        }),
      );
      final reopened = AuthRepository(latency: Duration.zero, storage: storage, apiClient: reopenedApi);
      expect(await reopened.restoreSession(), isTrue);
      expect(reopened.currentUser?.fullName, 'Nguyễn Văn A');
      expect(sent.single.url.path, '/api/v1/auth/me');
      expect(sent.single.headers['Authorization'], 'Bearer access-1');
    });

    test('Access token hết hạn: tự làm mới, lưu cặp token mới', () async {
      final storage = MemoryLocalStore()
        ..writeJson(StorageKeys.session, {'email': 'learner@karvocab.com', 'demo': false})
        ..writeJson(StorageKeys.tokens, {'accessToken': 'old', 'refreshToken': 'refresh-1'});
      final api = ApiClient(
        baseUrl: 'http://be/api/v1',
        httpClient: MockClient((r) async {
          if (r.url.path.endsWith('/auth/refresh')) return ok({'accessToken': 'new', 'refreshToken': 'refresh-2'});
          if (r.headers['Authorization'] == 'Bearer new') return ok(authData['user']);
          return fail(401, 'UNAUTHORIZED', 'Hết hạn');
        }),
      );
      final auth = AuthRepository(latency: Duration.zero, storage: storage, apiClient: api);
      expect(await auth.restoreSession(), isTrue);
      expect(AuthTokens.fromJson(storage.readJson(StorageKeys.tokens))?.refreshToken, 'refresh-2');
    });

    test('Refresh token bị BE từ chối: xoá phiên, về màn đăng nhập', () async {
      final storage = MemoryLocalStore()
        ..writeJson(StorageKeys.session, {'email': 'learner@karvocab.com', 'demo': false})
        ..writeJson(StorageKeys.tokens, {'accessToken': 'old', 'refreshToken': 'revoked'});
      final api = ApiClient(
        baseUrl: 'http://be/api/v1',
        httpClient: MockClient((_) async => fail(401, 'UNAUTHORIZED', 'Phiên đã hết hạn')),
      );
      final auth = AuthRepository(latency: Duration.zero, storage: storage, apiClient: api);
      expect(await auth.restoreSession(), isFalse);
      expect(storage.read(StorageKeys.tokens), isNull);
      expect(storage.read(StorageKeys.session), isNull);
    });

    test('Mất mạng lúc mở app: vẫn vào app bằng hồ sơ đã lưu, giữ token', () async {
      final storage = MemoryLocalStore()
        ..writeJson(StorageKeys.session, {'email': 'learner@karvocab.com', 'demo': false})
        ..writeJson(StorageKeys.tokens, {'accessToken': 'a', 'refreshToken': 'r'});
      final api = ApiClient(
        baseUrl: 'http://be/api/v1',
        httpClient: MockClient((_) async => throw http.ClientException('offline')),
      );
      final auth = AuthRepository(latency: Duration.zero, storage: storage, apiClient: api);
      expect(await auth.restoreSession(), isTrue);
      expect(api.hasSession, isTrue);
      expect(storage.read(StorageKeys.tokens), isNotNull);
    });

    test('Đăng xuất: xoá token đã lưu', () async {
      final storage = MemoryLocalStore();
      final auth = AuthRepository(
        latency: Duration.zero,
        storage: storage,
        apiClient: ApiClient(baseUrl: 'http://be/api/v1', httpClient: MockClient((_) async => ok(authData))),
      );
      await auth.login('learner@karvocab.com', 'Karvocab1');
      auth.logout();
      expect(storage.read(StorageKeys.tokens), isNull);
      expect(await AuthRepository(latency: Duration.zero, storage: storage).restoreSession(), isFalse);
    });
  });
}
