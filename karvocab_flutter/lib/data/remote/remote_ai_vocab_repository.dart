import '../../core/config/api_config.dart';
import '../models/ai_vocab_draft.dart';
import '../repositories/ai_vocab_repository.dart';
import 'api_client.dart';

/// Màn 13 gọi AI thật qua backend: `POST /ai/generate-vocab` (BE gọi Gemini, khoá API nằm ở server).
///
/// BE bắt buộc `cefrLevel`; app không cho chọn cấp độ nên gửi [ApiConfig.defaultAiCefrLevel] (B1).
class RemoteAiVocabRepository implements AiVocabRepository {
  RemoteAiVocabRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<AiVocabDraft>> generate({
    required String topic,
    String? cefrLevel,
    required int wordCount,
  }) async {
    try {
      final data = await _api.post('/ai/generate-vocab', body: {
        'topic': topic,
        'cefrLevel': cefrLevel ?? ApiConfig.defaultAiCefrLevel,
        'wordCount': wordCount,
      });
      final words = data is Map<String, dynamic> ? data['words'] : null;
      if (words is! List) throw const AiVocabException('AI_BAD_RESPONSE');
      return [
        for (final w in words)
          if (w is Map<String, dynamic>) AiVocabDraft.fromJson(w),
      ];
    } on ApiException catch (e) {
      throw AiVocabException(e.errorCode, message: e.message, retryAfterSeconds: e.retryAfterSeconds);
    } on TypeError {
      throw const AiVocabException('AI_BAD_RESPONSE');
    }
  }
}
