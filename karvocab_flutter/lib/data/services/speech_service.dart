/// Dịch vụ phát âm cho các chế độ "Nghe".
/// Mặc định là bản mô phỏng (không cần package) để chạy được ở chế độ Demo/offline.
/// Khi nhóm thống nhất dùng `flutter_tts`, chỉ cần viết 1 class implement `SpeechService`
/// rồi gán `SpeechService.instance = FlutterTtsSpeechService();` ở `main()`.
abstract class SpeechService {
  static SpeechService instance = SimulatedSpeechService();

  /// Phát âm [text]; Future hoàn thành khi phát xong.
  Future<void> speak(String text);
}

class SimulatedSpeechService implements SpeechService {
  @override
  Future<void> speak(String text) async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
  }
}
