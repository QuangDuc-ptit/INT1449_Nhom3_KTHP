import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:karvocab_flutter/core/constants/app_strings.dart';
import 'package:karvocab_flutter/data/remote/api_client.dart';
import 'package:karvocab_flutter/data/remote/remote_ai_vocab_repository.dart';
import 'package:karvocab_flutter/data/repositories/ai_vocab_repository.dart';
import 'package:karvocab_flutter/data/repositories/auth_repository.dart';

/// Kiểm tra lớp nối backend bằng client HTTP giả (không cần chạy BE thật).
void main() {
  http.Response ok(Object data) =>
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
}
