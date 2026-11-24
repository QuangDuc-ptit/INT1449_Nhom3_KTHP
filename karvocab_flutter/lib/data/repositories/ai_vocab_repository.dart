import 'dart:math';

import '../mock/mock_ai_vocab_bank.dart';
import '../remote/api_client.dart';
import '../remote/remote_ai_vocab_repository.dart';
import '../models/ai_vocab_draft.dart';

/// Lỗi từ API AI, mang `errorCode` của BE (FE-BE-ALIGNMENT mục 2).
class AiVocabException implements Exception {
  /// RATE_LIMITED | AI_TIMEOUT | AI_BAD_RESPONSE | AI_UNAVAILABLE | UNAUTHORIZED ...
  final String errorCode;
  final String? message;

  /// Số giây chờ (header `Retry-After`) khi bị RATE_LIMITED.
  final int? retryAfterSeconds;

  const AiVocabException(this.errorCode, {this.message, this.retryAfterSeconds});

  @override
  String toString() => 'AiVocabException($errorCode)';
}

/// Hợp đồng gọi `POST /api/v1/ai/generate-vocab`.
/// Bản gọi BE thật: `RemoteAiVocabRepository` (khoá Gemini nằm ở server, KHÔNG nằm trong app).
abstract class AiVocabRepository {
  /// Đã đăng nhập qua backend thì gọi AI thật; Demo Mode / Chế độ Dùng thử thì dùng kho từ mẫu.
  static AiVocabRepository forCurrentSession() {
    final api = ApiClient.instance;
    return api != null && api.hasSession ? RemoteAiVocabRepository(api) : MockAiVocabRepository();
  }

  /// [topic] nhập bằng tiếng Anh hoặc tiếng Việt. [cefrLevel] = `null` khi người dùng không chọn
  /// trình độ: AI tự chọn từ phù hợp với chủ đề, mỗi từ ghi đúng trình độ của nó.
  Future<List<AiVocabDraft>> generate({
    required String topic,
    String? cefrLevel,
    required int wordCount,
  });
}

/// Bản Demo offline: lấy từ trong [MockAiVocabBank] sau ~2 giây, có công tắc giả lập lỗi để trình diễn Error State.
///
/// Chỉ trả về từ đúng chủ đề (không chèn từ chủ đề khác cho đủ số lượng). Chủ đề chưa có trong
/// kho Demo thì báo lỗi `TOPIC_UNSUPPORTED` kèm gợi ý chủ đề có sẵn.
class MockAiVocabRepository implements AiVocabRepository {
  /// Bật để mô phỏng mất mạng / AI timeout (Màn 13 - Error state).
  static bool simulateFailure = false;

  static const List<String> _levels = ['A1', 'A2', 'B1', 'B2', 'C1'];

  final Duration latency;
  final Random _random;

  MockAiVocabRepository({this.latency = const Duration(seconds: 2), Random? random}) : _random = random ?? Random();

  @override
  Future<List<AiVocabDraft>> generate({
    required String topic,
    String? cefrLevel,
    required int wordCount,
  }) async {
    await Future<void>.delayed(latency);
    if (simulateFailure) {
      throw const AiVocabException('AI_UNAVAILABLE');
    }

    final matched = MockAiVocabBank.match(topic);
    if (matched.isEmpty) {
      throw const AiVocabException('TOPIC_UNSUPPORTED');
    }

    // Xen kẽ từ của các chủ đề khớp (vd "du lịch và ẩm thực"), bỏ từ trùng.
    var pool = <MockAiWord>[];
    final seen = <String>{};
    final lists = [for (final t in matched) [...t.words]..shuffle(_random)];
    for (var i = 0; lists.any((l) => i < l.length); i++) {
      for (final l in lists) {
        if (i < l.length && seen.add(l[i].term)) pool.add(l[i]);
      }
    }

    // Có chọn trình độ: ưu tiên đúng cấp, thiếu thì lấy cấp liền kề trong cùng chủ đề.
    // Nhãn CEFR của mỗi từ luôn là trình độ thật của từ đó.
    final target = cefrLevel == null ? -1 : _levels.indexOf(cefrLevel);
    if (target >= 0) {
      int distance(MockAiWord w) => (_levels.indexOf(w.cefrLevel) - target).abs();
      pool = [
        for (var d = 0; d <= 1; d++) ...pool.where((w) => distance(w) == d),
      ];
    }

    return [
      for (final w in pool.take(wordCount))
        AiVocabDraft.fromJson({
          'term': w.term,
          'partOfSpeech': w.partOfSpeech,
          'ipaUk': w.ipa,
          'definitionEn': w.definitionEn,
          'definitionVi': w.definitionVi,
          'exampleSentence': w.example,
          'cefrLevel': w.cefrLevel,
        }),
    ];
  }
}
