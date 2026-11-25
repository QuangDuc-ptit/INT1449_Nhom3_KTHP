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

/// Trạng thái kết nối của tính năng tạo từ bằng AI.
enum AiConnection {
  /// Đã đăng nhập tài khoản trên máy chủ: gọi được AI.
  ready,

  /// Bản chạy không nối máy chủ (không có `API_BASE_URL`).
  noServer,

  /// Có máy chủ nhưng đang ở chế độ Dùng thử / chưa đăng nhập.
  needsLogin,
}

/// Hợp đồng gọi `POST /api/v1/ai/generate-vocab`.
/// Bản gọi BE thật: `RemoteAiVocabRepository` (khoá Gemini nằm ở server, KHÔNG nằm trong app).
abstract class AiVocabRepository {
  /// Tạo từ bằng AI chỉ chạy qua backend (BE gọi Gemini). App không có kho từ dựng sẵn.
  static AiConnection get connection {
    final api = ApiClient.instance;
    if (api == null) return AiConnection.noServer;
    return api.hasSession ? AiConnection.ready : AiConnection.needsLogin;
  }

  /// Repository gọi BE; `null` khi chưa thể gọi (xem [connection]).
  static AiVocabRepository? forCurrentSession() {
    final api = ApiClient.instance;
    return api != null && api.hasSession ? RemoteAiVocabRepository(api) : null;
  }

  /// Giới hạn theo `GenerateVocabDto` của BE.
  static const int minTopicLength = 3;
  static const int maxTopicLength = 100;
  static const int minWordCount = 3;
  static const int maxWordCount = 20;

  /// [topic] nhập bằng tiếng Anh hoặc tiếng Việt. [cefrLevel] = `null` thì gửi mức mặc định của app.
  Future<List<AiVocabDraft>> generate({required String topic, String? cefrLevel, required int wordCount});
}
