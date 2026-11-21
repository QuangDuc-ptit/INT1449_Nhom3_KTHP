import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/utils/fuzzy_match.dart';
import 'package:karvocab_flutter/core/utils/session_id.dart';
import 'package:karvocab_flutter/data/mock/mock_vocab_data.dart';
import 'package:karvocab_flutter/data/models/quiz_models.dart';
import 'package:karvocab_flutter/data/repositories/ai_vocab_repository.dart';
import 'package:karvocab_flutter/data/repositories/dashboard_store.dart';
import 'package:karvocab_flutter/data/repositories/quiz_question_factory.dart';
import 'package:karvocab_flutter/data/services/feedback_service.dart';
import 'package:karvocab_flutter/data/models/ai_vocab_draft.dart';
import 'package:karvocab_flutter/presentation/ai_vocab/ai_generate_screen.dart';
import 'package:karvocab_flutter/presentation/quiz/practice_mode_screen.dart';
import 'package:karvocab_flutter/presentation/quiz/quiz_controller.dart';
import 'package:karvocab_flutter/presentation/quiz/quiz_session_screen.dart';
import 'package:karvocab_flutter/presentation/quiz/widgets/quiz_option_tile.dart';

class _SilentFeedback extends FeedbackService {
  @override
  Future<void> playCorrect() async {}

  @override
  Future<void> playIncorrect() async {}
}

class _FailingAiRepository implements AiVocabRepository {
  @override
  Future<List<AiVocabDraft>> generate({
    required String topic,
    required String cefrLevel,
    required int wordCount,
  }) async {
    throw Exception('offline');
  }
}

void main() {
  setUp(() {
    FeedbackService.instance = _SilentFeedback();
  });

  group('Track B — Fuzzy matching (Màn 19 & 20)', () {
    test('levenshtein tính đúng khoảng cách', () {
      expect(levenshtein('kitten', 'sitting'), 3);
      expect(levenshtein('abc', 'abc'), 0);
      expect(levenshtein('', 'abc'), 3);
    });

    test('trim + lowercase trước khi so sánh', () {
      expect(evaluateTypedAnswer('  Coherent ', 'coherent'), AnswerResult.correct);
    });

    test('từ dài > 6 ký tự sai 1 ký tự → suýt đúng', () {
      expect(evaluateTypedAnswer('coherant', 'coherent'), AnswerResult.almost);
    });

    test('theo BE: từ ≥ 3 ký tự sai 1 ký tự vẫn được chấp nhận (suýt đúng)', () {
      expect(evaluateTypedAnswer('rost', 'roast'), AnswerResult.almost);
      expect(evaluateTypedAnswer('cot', 'cat'), AnswerResult.almost);
    });

    test('từ 2 ký tự sai 1 ký tự, hoặc sai ≥ 2 ký tự → sai', () {
      expect(evaluateTypedAnswer('ax', 'at'), AnswerResult.wrong);
      expect(evaluateTypedAnswer('coharant', 'coherent'), AnswerResult.wrong);
    });
  });

  group('Track B — Quiz question factory', () {
    test('trắc nghiệm có đúng 4 đáp án, chứa đáp án đúng, không trùng lặp', () {
      final qs = QuizQuestionFactory.build(
        mode: QuizMode.meaningChoose,
        pool: MockVocabData.initialVocabularies,
        count: 8,
      );
      expect(qs.length, 8);
      for (final q in qs) {
        expect(q.options.length, 4);
        expect(q.options.toSet().length, 4);
        expect(q.options, contains(q.correctAnswer));
      }
    });

    test('chế độ gõ chữ không có danh sách đáp án', () {
      final qs = QuizQuestionFactory.build(
        mode: QuizMode.recallType,
        pool: MockVocabData.initialVocabularies,
        count: 3,
      );
      expect(qs.every((q) => q.options.isEmpty), isTrue);
      expect(qs.every((q) => q.correctAnswer == q.vocab.term), isTrue);
    });

    test('buildMixed xoay vòng đủ 4 chế độ', () {
      final qs = QuizQuestionFactory.buildMixed(
        pool: MockVocabData.initialVocabularies,
        count: 8,
      );
      expect(qs.map((q) => q.mode).toSet().length, 4);
    });
  });

  group('Track B — Quiz controller', () {
    test('chấm đúng/sai và tạo tổng kết', () {
      final qs = QuizQuestionFactory.build(
        mode: QuizMode.listenChoose,
        pool: MockVocabData.initialVocabularies,
        count: 2,
      );
      final c = QuizController(questions: qs, feedback: _SilentFeedback());

      c.submitChoice(qs[0].correctAnswer);
      expect(c.lastRecord!.result, AnswerResult.correct);
      expect(c.next(), isTrue);

      c.submitChoice('đáp án sai chắc chắn');
      expect(c.lastRecord!.result, AnswerResult.wrong);
      expect(c.next(), isFalse);

      final summary = c.buildSummary();
      expect(summary.total, 2);
      expect(summary.correctCount, 1);
      expect(summary.accuracyPercent, 50);
      expect(summary.missedQuestions.length, 1);
      c.dispose();
    });

    test('không cho trả lời 2 lần trong cùng 1 câu', () {
      final qs = QuizQuestionFactory.build(
        mode: QuizMode.meaningChoose,
        pool: MockVocabData.initialVocabularies,
        count: 1,
      );
      final c = QuizController(questions: qs, feedback: _SilentFeedback());
      c.submitChoice(qs[0].correctAnswer);
      c.submitChoice('khác');
      expect(c.records.length, 1);
      c.dispose();
    });
  });

  group('Track B — SM-2 & Dashboard', () {
    test('trả lời đúng: tăng level, interval 1 → 3 ngày, ease tăng', () {
      final now = DateTime(2026, 11, 19);
      final p1 = Sm2Engine.apply(Sm2Engine.initial(now), true, now);
      expect(p1.repetitionLevel, 1);
      expect(p1.intervalDays, 1);
      final p2 = Sm2Engine.apply(p1, true, now);
      expect(p2.intervalDays, 3);
      expect(p2.easeFactor, 2.5); // tối đa 2.5
    });

    test('đạt level 5 → mastered; trả lời sai → reset về 0, interval 1', () {
      final now = DateTime(2026, 11, 19);
      var p = Sm2Engine.initial(now);
      for (var i = 0; i < 5; i++) {
        p = Sm2Engine.apply(p, true, now);
      }
      expect(p.mastered, isTrue);
      expect(p.intervalDays, 35);

      final wrong = Sm2Engine.apply(p, false, now);
      expect(wrong.repetitionLevel, 0);
      expect(wrong.intervalDays, 1);
      expect(wrong.mastered, isFalse);
      expect(wrong.easeFactor, closeTo(2.3, 0.001));
    });

    test('recordSessionResult cộng tiến độ ngày và tăng streak (≥ 5 từ)', () {
      final store = DashboardStore.forTest();
      final streakBefore = store.streak;
      final reviewedBefore = store.reviewedToday;

      final qs = QuizQuestionFactory.build(
        mode: QuizMode.meaningChoose,
        pool: MockVocabData.initialVocabularies,
        count: 5,
      );
      final records = [
        for (final q in qs)
          QuizAnswerRecord(
            question: q,
            userAnswer: q.correctAnswer,
            result: AnswerResult.correct,
            responseTimeMs: 1000,
          ),
      ];
      store.recordSessionResult(QuizSummary(
        records: records,
        durationSeconds: 30,
        clientSessionId: 'test-session',
      ));

      expect(store.reviewedToday, reviewedBefore + 5);
      expect(store.streak, streakBefore + 1);
      expect(store.studiedToday, isTrue);
    });
  });

  group('Track B — Đối chiếu FE-BE', () {
    test('apiKey khớp tên chế độ của BE', () {
      expect(QuizMode.listenChoose.apiKey, 'listen_choose');
      expect(QuizMode.listenType.apiKey, 'listen_type');
      expect(QuizMode.meaningChoose.apiKey, 'choose_meaning');
      expect(QuizMode.recallType.apiKey, 'type_meaning');
    });

    test('clientSessionId là UUID v4 và khác nhau giữa các phiên', () {
      final a = generateClientSessionId();
      final b = generateClientSessionId();
      final uuid = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(uuid.hasMatch(a), isTrue);
      expect(a, isNot(b));
    });

    test('mục tiêu ngày bị giới hạn trong 5–30', () {
      final store = DashboardStore.forTest();
      store.setDailyGoal(1);
      expect(store.dailyGoal, 5);
      store.setDailyGoal(99);
      expect(store.dailyGoal, 30);
    });

    test('chống học dồn: chỉ tính câu đầu tiên của mỗi từ và từ chưa đến hạn không lên level', () {
      final store = DashboardStore.forTest();
      final due = store.dueVocabularies.first;
      final dueBefore = store.progressOf(due.id)!;
      final q = QuizQuestionFactory.build(
        mode: QuizMode.meaningChoose,
        pool: [due],
        count: 1,
      ).first;
      QuizAnswerRecord rec(AnswerResult r) => QuizAnswerRecord(
            question: q,
            userAnswer: 'x',
            result: r,
            responseTimeMs: 500,
          );

      // Sai trước rồi đúng sau trong cùng phiên → chỉ câu sai được tính
      store.recordSessionResult(QuizSummary(
        records: [rec(AnswerResult.wrong), rec(AnswerResult.correct)],
        durationSeconds: 5,
        clientSessionId: 's1',
      ));
      final afterWrong = store.progressOf(due.id)!;
      expect(afterWrong.repetitionLevel, 0);
      expect(afterWrong.intervalDays, 1);
      expect(dueBefore.nextReviewAt.isAfter(afterWrong.nextReviewAt), isFalse);

      // Từ đã hẹn ôn ngày mai: trả lời đúng ngay hôm nay không được lên level
      store.recordSessionResult(QuizSummary(
        records: [rec(AnswerResult.correct)],
        durationSeconds: 5,
        clientSessionId: 's2',
        isRetry: true,
      ));
      expect(store.progressOf(due.id)!.repetitionLevel, 0);
    });

    test('AiVocabDraft đọc ipaUk/ipaUs và mặc định bỏ chọn từ đã có', () {
      final d = AiVocabDraft.fromJson({
        'term': 'roast',
        'partOfSpeech': 'verb',
        'ipaUs': '/roʊst/',
        'definitionEn': 'x',
        'definitionVi': 'Rang',
        'exampleSentence': 'y',
        'cefrLevel': 'B1',
        'existsInCollection': true,
      });
      expect(d.ipa, '/roʊst/');
      expect(d.selected, isFalse);
    });

    test('map errorCode của BE sang thông báo tiếng Việt cho Màn 13', () {
      expect(
        AiGenerateScreen.aiErrorMessage(
          const AiVocabException('RATE_LIMITED', retryAfterSeconds: 12),
        ),
        contains('12 giây'),
      );
      expect(
        AiGenerateScreen.aiErrorMessage(const AiVocabException('AI_TIMEOUT')),
        contains('quá lâu'),
      );
    });
  });

  group('Track B — Widget tests', () {
    testWidgets('Màn 10 hiển thị đủ 4 chế độ luyện tập', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: PracticeModeScreen()));

      expect(find.text('Nghe chọn từ'), findsOneWidget);
      expect(find.text('Nghe và điền từ'), findsOneWidget);
      expect(find.text('Chọn nghĩa đúng'), findsOneWidget);
      expect(find.text('Nhớ từ qua nghĩa'), findsOneWidget);
    });

    testWidgets('Màn 25: chọn đáp án → hiện banner phản hồi, nút ≥ 48dp', (tester) async {
      final qs = QuizQuestionFactory.build(
        mode: QuizMode.meaningChoose,
        pool: MockVocabData.initialVocabularies,
        count: 2,
      );
      await tester.pumpWidget(MaterialApp(home: QuizSessionScreen(questions: qs)));

      final tile = find.byType(QuizOptionTile).first;
      expect(tester.getSize(tile).height, greaterThanOrEqualTo(48));

      await tester.tap(tile);
      await tester.pump();

      expect(find.text('Tiếp tục'), findsOneWidget);
    });

    testWidgets('Màn 13: lỗi AI → hiện Error State có nút Thử lại', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AiGenerateScreen(repository: _FailingAiRepository())),
      );

      await tester.enterText(find.byType(TextField), 'Travel');
      await tester.pump();
      await tester.tap(find.text('Tạo từ vựng ngay'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Tạo từ vựng thất bại'), findsOneWidget);
      expect(find.text('Thử lại ngay'), findsOneWidget);
    });
  });
}
