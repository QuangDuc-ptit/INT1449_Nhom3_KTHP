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

  /// Học phần chưa đồng bộ lên BE còn mang id cục bộ: không gửi (BE sẽ báo 400).
  static final RegExp _uuid = RegExp(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$");

  @override
  Future<List<AiVocabDraft>> generate({
    required String topic,
    String? cefrLevel,
    required int wordCount,
    String? collectionId,
  }) async {
    try {
      final data = await _api.post(
        '/ai/generate-vocab',
        body: {
          'topic': topic,
          'cefrLevel': cefrLevel ?? ApiConfig.defaultAiCefrLevel,
          'wordCount': wordCount,
          if (collectionId != null && _uuid.hasMatch(collectionId)) 'collectionId': collectionId,
        },
        timeout: ApiConfig.aiRequestTimeout,
      );
      final words = data is Map<String, dynamic> ? data['words'] : null;
      if (words is! List) throw const AiVocabException('AI_BAD_RESPONSE');
      return [
        for (final w in words)
          if (w is Map<String, dynamic>) AiVocabDraft.fromJson(w),
      ];
    } on ApiException catch (e) {
      // Học phần không còn trên BE (vừa xoá ở máy khác...): vẫn tạo từ, chỉ bỏ phần tránh trùng
      if (e.statusCode == 404 && collectionId != null) {
        return generate(topic: topic, cefrLevel: cefrLevel, wordCount: wordCount);
      }
      throw AiVocabException(e.errorCode, message: e.message, retryAfterSeconds: e.retryAfterSeconds);
    } on TypeError {
      throw const AiVocabException('AI_BAD_RESPONSE');
    }
  }
}
