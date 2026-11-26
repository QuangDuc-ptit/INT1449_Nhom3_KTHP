import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/constants/app_strings.dart';
import 'package:karvocab_flutter/core/widgets/app_button.dart';
import 'package:karvocab_flutter/data/models/ai_vocab_draft.dart';
import 'package:karvocab_flutter/data/repositories/ai_vocab_repository.dart';
import 'package:karvocab_flutter/presentation/ai_vocab/ai_generate_screen.dart';
import 'package:karvocab_flutter/presentation/ai_vocab/ai_preview_screen.dart';

/// Thay cho BE trong test: trả về đúng những gì BE trả (`{ words: [...] }`), ghi lại yêu cầu đã gửi.
class _FakeBackendAi implements AiVocabRepository {
  _FakeBackendAi(this.words);

  final List<AiVocabDraft> words;
  String? lastTopic;
  int? lastCount;

  @override
  Future<List<AiVocabDraft>> generate({
    required String topic,
    String? cefrLevel,
    required int wordCount,
    String? collectionId,
  }) async {
    lastTopic = topic;
    lastCount = wordCount;
    return words.take(wordCount).toList();
  }
}

AiVocabDraft _draft(String term) => AiVocabDraft(
  term: term,
  partOfSpeech: 'noun',
  definitionEn: 'meaning of $term',
  definitionVi: 'nghĩa của $term',
  exampleSentence: 'This is $term.',
  cefrLevel: 'B1',
);

Future<void> _pump(WidgetTester tester, Widget home) async {
  await tester.binding.setSurfaceSize(const Size(420, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(home: home));
}

AppButton _generateButton(WidgetTester tester) =>
    tester.widget<AppButton>(find.widgetWithText(AppButton, AppStrings.aiGenerateButton));

void main() {
  group('Màn 13 · Chỉ tạo từ qua backend (không có kho từ dựng sẵn)', () {
    testWidgets('Không nối máy chủ: báo rõ lý do, khoá nút tạo dù đã nhập chủ đề', (tester) async {
      await _pump(tester, const AiGenerateScreen());

      expect(AiVocabRepository.connection, AiConnection.noServer);
      expect(find.byKey(const Key('ai_connection_notice')), findsOneWidget);
      expect(find.text(AppStrings.aiNoServerTitle), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Du lịch');
      await tester.pump();
      expect(_generateButton(tester).isEnabled, isFalse);
    });

    testWidgets('Chủ đề dưới 3 ký tự (BE yêu cầu 3–100): báo lỗi và khoá nút', (tester) async {
      await _pump(tester, AiGenerateScreen(repository: _FakeBackendAi([])));

      await tester.enterText(find.byType(TextField), 'ab');
      await tester.pump();
      expect(find.byKey(const Key('ai_topic_too_short')), findsOneWidget);
      expect(_generateButton(tester).isEnabled, isFalse);

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();
      expect(find.byKey(const Key('ai_topic_too_short')), findsNothing);
      expect(_generateButton(tester).isEnabled, isTrue);
    });

    testWidgets('Kéo thanh 3–20, gửi đúng chủ đề và số lượng; xem trước đúng các từ BE trả về', (tester) async {
      final ai = _FakeBackendAi([for (var i = 0; i < 20; i++) _draft('word$i')]);
      await _pump(tester, AiGenerateScreen(repository: ai));

      expect(find.byKey(const Key('ai_connection_notice')), findsNothing);
      final slider = find.byKey(const Key('ai_word_count_slider'));
      expect(tester.widget<Slider>(slider).value, 5);
      expect(tester.getSize(slider).height, greaterThanOrEqualTo(48));
      await tester.drag(slider, const Offset(-1000, 0));
      await tester.pump();
      expect(find.text(AppStrings.aiWordCountValue(3)), findsOneWidget);
      await tester.drag(slider, const Offset(1000, 0));
      await tester.pump();
      expect(find.text(AppStrings.aiWordCountValue(20)), findsOneWidget);

      await tester.enterText(find.byType(TextField), '  Giáo dục  ');
      await tester.pump();
      await tester.tap(find.text(AppStrings.aiGenerateButton));
      await tester.pumpAndSettle();

      expect(ai.lastTopic, 'Giáo dục');
      expect(ai.lastCount, 20);
      final preview = tester.widget<AiPreviewScreen>(find.byType(AiPreviewScreen));
      expect(preview.drafts.map((d) => d.term), [for (var i = 0; i < 20; i++) 'word$i']);
    });

    testWidgets('BE trả ít hơn số đã chọn: báo số từ thật nhận được, không tự thêm từ', (tester) async {
      final ai = _FakeBackendAi([_draft('airport'), _draft('luggage')]);
      await _pump(tester, AiGenerateScreen(repository: ai));

      await tester.enterText(find.byType(TextField), 'Du lịch');
      await tester.pump();
      await tester.tap(find.text(AppStrings.aiGenerateButton));
      await tester.pump();
      expect(find.text(AppStrings.aiFewerWords(2, 5)), findsOneWidget);
      await tester.pumpAndSettle();
      expect(tester.widget<AiPreviewScreen>(find.byType(AiPreviewScreen)).drafts, hasLength(2));
    });

    test('Mã lỗi của BE đổi thành câu tiếng Việt', () {
      expect(AiGenerateScreen.aiErrorMessage(const AiVocabException('AI_TIMEOUT')), AppStrings.aiErrorTimeout);
      expect(AiGenerateScreen.aiErrorMessage(const AiVocabException('AI_UNAVAILABLE')), AppStrings.aiErrorUnavailable);
      expect(
        AiGenerateScreen.aiErrorMessage(const AiVocabException('RATE_LIMITED', retryAfterSeconds: 30)),
        AppStrings.aiErrorRateLimitedSeconds(30),
      );
      // Mã chưa biết (vd VALIDATION_ERROR): dùng câu BE gửi kèm.
      expect(
        AiGenerateScreen.aiErrorMessage(
          const AiVocabException('VALIDATION_ERROR', message: 'Chủ đề phải từ 3 đến 100 ký tự'),
        ),
        'Chủ đề phải từ 3 đến 100 ký tự',
      );
    });
  });
}
