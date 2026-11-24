import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fixtures/mock_vocab_data.dart';
import 'package:karvocab_flutter/data/models/quiz_models.dart';
import 'package:karvocab_flutter/data/models/vocabulary_model.dart';
import 'package:karvocab_flutter/data/repositories/quiz_question_factory.dart';
import 'package:karvocab_flutter/data/services/feedback_service.dart';
import 'package:karvocab_flutter/data/services/speech_recognition_service.dart';
import 'package:karvocab_flutter/data/services/speech_service.dart';
import 'package:karvocab_flutter/presentation/quiz/quiz_controller.dart';
import 'package:karvocab_flutter/presentation/quiz/quiz_session_screen.dart';

class _SilentFeedback extends FeedbackService {
  @override
  Future<void> playCorrect() async {}
  @override
  Future<void> playIncorrect() async {}
}

class _NoSpeech implements SpeechService {
  @override
  Future<void> speak(String text) async {}
}

/// Giả lập máy nghe được [heard], hoặc ném [failure].
class _FakeRecognizer implements SpeechRecognitionService {
  _FakeRecognizer({this.heard = const [], this.failure});
  final List<String> heard;
  final RecognitionFailure? failure;

  @override
  Future<List<String>> listenOnce({String localeId = 'en_US', ValueChanged<String>? onPartial}) async {
    if (failure != null) throw RecognitionException(failure!);
    onPartial?.call(heard.first);
    return heard;
  }

  @override
  Future<void> stop() async {}
}

void main() {
  final pool = MockVocabData.seedVocabularies();

  setUp(() {
    FeedbackService.instance = _SilentFeedback();
    SpeechService.instance = _NoSpeech();
  });
  tearDown(() => SpeechRecognitionService.instance = UnavailableSpeechRecognition());

  group('Game Đồng nghĩa và trái nghĩa', () {
    test('Chỉ lấy từ có dữ liệu quan hệ; đáp án khớp danh sách của từ', () {
      final noRelation = pool.first.copyWith(id: 'x', synonyms: const [], antonyms: const []);
      final qs = QuizQuestionFactory.build(
        mode: QuizMode.synonymAntonym,
        pool: [...pool, noRelation],
        count: 50,
        random: Random(1),
      );
      expect(qs.length, pool.length);
      for (final q in qs) {
        expect(q.options, ['Đồng nghĩa', 'Trái nghĩa']);
        final list = q.correctAnswer == 'Đồng nghĩa' ? q.vocab.synonyms : q.vocab.antonyms;
        expect(list, contains(q.pairWord));
      }
    });

    test('Không từ nào có dữ liệu → không có câu hỏi', () {
      const v = VocabularyModel(
        id: 'v', collectionId: 'c', term: 'apple', partOfSpeech: 'noun', ipa: '',
        definitionVi: 'quả táo', definitionEn: '', exampleSentence: '', cefrLevel: 'A1',
      );
      expect(QuizQuestionFactory.build(mode: QuizMode.synonymAntonym, pool: [v]), isEmpty);
    });

    test('Ôn tập hỗn hợp (Màn 16) không dùng 2 game mới', () {
      final qs = QuizQuestionFactory.buildMixed(pool: pool, count: 12, random: Random(2));
      expect(qs.map((q) => q.mode), everyElement(isIn(QuizMode.reviewModes)));
    });
  });

  group('Game Luyện phát âm', () {
    QuizController controllerFor(String term) {
      final vocab = pool.firstWhere((v) => v.term == term);
      final qs = QuizQuestionFactory.build(mode: QuizMode.pronunciation, pool: [vocab]);
      return QuizController(questions: qs);
    }

    test('Chấm theo phương án nghe được tốt nhất, không phân biệt hoa thường', () {
      final c = controllerFor('explore');
      c.submitSpoken(['explorer', 'Explore']);
      expect(c.lastRecord!.result, AnswerResult.correct);
      expect(c.lastRecord!.userAnswer, 'Explore');
    });

    test('Bỏ qua câu thì tính là sai', () {
      final c = controllerFor('explore');
      c.skip();
      expect(c.lastRecord!.result, AnswerResult.wrong);
    });

    testWidgets('Nói đúng → hiện "Chính xác!"', (tester) async {
      SpeechRecognitionService.instance = _FakeRecognizer(heard: ['souvenir']);
      final qs = QuizQuestionFactory.build(
        mode: QuizMode.pronunciation,
        pool: pool.where((v) => v.term == 'souvenir').toList(),
      );
      await tester.pumpWidget(MaterialApp(home: QuizSessionScreen(questions: qs)));
      await tester.tap(find.byIcon(Icons.mic_rounded).last);
      await tester.pumpAndSettle();
      expect(find.text('Chính xác!'), findsOneWidget);
    });

    testWidgets('Máy không hỗ trợ nhận dạng → báo lỗi và cho bỏ qua', (tester) async {
      SpeechRecognitionService.instance = _FakeRecognizer(failure: RecognitionFailure.unavailable);
      final qs = QuizQuestionFactory.build(mode: QuizMode.pronunciation, pool: pool.take(1).toList());
      await tester.pumpWidget(MaterialApp(home: QuizSessionScreen(questions: qs)));
      await tester.tap(find.byIcon(Icons.mic_rounded).last);
      await tester.pumpAndSettle();
      expect(find.textContaining('chưa hỗ trợ nhận dạng giọng nói'), findsOneWidget);

      // Thanh đếm ngược làm nội dung dài hơn khung test 800×600: cuộn tới nút trước khi bấm
      await tester.ensureVisible(find.text('Bỏ qua câu này'));
      await tester.tap(find.text('Bỏ qua câu này'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa đúng rồi'), findsOneWidget);
    });
  });
}
