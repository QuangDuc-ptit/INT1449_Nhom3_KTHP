import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/constants/app_colors.dart';
import 'package:karvocab_flutter/core/constants/app_strings.dart';
import 'package:karvocab_flutter/core/utils/review_schedule.dart';
import 'package:karvocab_flutter/data/mock/mock_vocab_data.dart';
import 'package:karvocab_flutter/data/models/quiz_models.dart';
import 'package:karvocab_flutter/data/repositories/collection_store.dart';
import 'package:karvocab_flutter/data/repositories/dashboard_store.dart';
import 'package:karvocab_flutter/data/repositories/quiz_question_factory.dart';
import 'package:karvocab_flutter/presentation/dashboard/review_today_screen.dart';
import 'package:karvocab_flutter/presentation/library/library_sample_data.dart';
import 'package:karvocab_flutter/presentation/quiz/quiz_result_screen.dart';
import 'package:karvocab_flutter/presentation/screens/library_screen.dart';
import 'package:karvocab_flutter/presentation/screens/word_detail_screen.dart';

CollectionStore _freshStore() => CollectionStore(
      collections: MockVocabData.seedCollections(),
      vocabularies: MockVocabData.seedVocabularies(),
      latency: Duration.zero,
    );

QuizAnswerRecord _record(QuizQuestion q, AnswerResult result, {String? answer, bool timedOut = false}) =>
    QuizAnswerRecord(
      question: q,
      userAnswer: answer ?? (result == AnswerResult.wrong ? 'sai' : q.correctAnswer),
      result: result,
      responseTimeMs: 500,
      timedOut: timedOut,
    );

void main() {
  group('Lịch ôn lại', () {
    test('hôm nay / ngày mai / sau N ngày, tính theo ngày lịch', () {
      final now = DateTime(2026, 11, 24, 22);
      expect(reviewDueText(DateTime(2026, 11, 24, 8), now), AppStrings.reviewDueToday);
      expect(reviewDueText(DateTime(2026, 11, 20), now), AppStrings.reviewDueToday); // đã quá hạn
      expect(reviewDueText(DateTime(2026, 11, 25, 1), now), AppStrings.reviewDueTomorrow);
      expect(reviewDueText(DateTime(2026, 12, 1, 9), now), AppStrings.reviewDueInDays(7));
    });

    test('Màn 16: đến hạn hôm nay màu xanh, quá hạn 1–2 ngày màu cam, từ 3 ngày màu đỏ', () {
      final now = DateTime(2026, 11, 24, 9);
      final today = ReviewTodayScreen.overdueStyle(DateTime(2026, 11, 24, 7), now);
      expect(today.label, AppStrings.reviewDueNow);
      expect(today.text, AppColors.practicePrimary);

      final late = ReviewTodayScreen.overdueStyle(DateTime(2026, 11, 22, 20), now);
      expect(late.label, AppStrings.reviewOverdueDays(2));
      expect(late.text, AppColors.warningOrangeText);

      final urgent = ReviewTodayScreen.overdueStyle(DateTime(2026, 11, 20), now);
      expect(urgent.label, AppStrings.reviewOverdueDays(4));
      expect(urgent.text, AppColors.errorRedText);
    });
  });

  group('Màn 07 · Tiến độ học', () {
    testWidgets('Từ chưa học, rồi trả lời đúng thì thành "Đang học cấp 1/5" kèm lịch ôn', (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = _freshStore();
      final dashboard = DashboardStore.forTest();
      final word = store.wordsOf('col-1').firstWhere((w) => w.term == 'coherent');

      await tester.pumpWidget(MaterialApp(home: WordDetailScreen(vocabulary: word, store: store, dashboard: dashboard)));
      expect(find.text(AppStrings.wordDetailProgress), findsOneWidget);
      expect(find.text(AppStrings.wordProgressNew), findsOneWidget);

      final q = QuizQuestionFactory.build(mode: QuizMode.meaningChoose, pool: [word], count: 1).first;
      dashboard.recordSessionResult(
        QuizSummary(records: [_record(q, AnswerResult.correct)], durationSeconds: 5, clientSessionId: 'w'),
      );
      await tester.pump();
      expect(find.text(AppStrings.wordProgressLearning(1, Sm2Engine.maxLevel)), findsOneWidget);
      expect(find.text(AppStrings.reviewDueTomorrow), findsOneWidget);
    });
  });

  group('Màn 12 · Kết quả', () {
    testWidgets('Từ sai hiện câu đã trả lời (hoặc hết giờ / bỏ qua) và lịch ôn lại', (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final dashboard = DashboardStore.forTest();
      final qs = QuizQuestionFactory.build(
        mode: QuizMode.recallType,
        pool: MockVocabData.initialVocabularies.take(4).toList(),
        count: 4,
        shuffle: false,
      );
      final summary = QuizSummary(
        records: [
          _record(qs[0], AnswerResult.wrong, answer: 'cohernt'),
          _record(qs[1], AnswerResult.wrong, answer: '', timedOut: true),
          _record(qs[2], AnswerResult.wrong, answer: ''),
          _record(qs[3], AnswerResult.correct),
        ],
        durationSeconds: 40,
        clientSessionId: 'r',
      );
      dashboard.recordSessionResult(summary);

      await tester.pumpWidget(MaterialApp(home: QuizResultScreen(summary: summary, dashboard: dashboard)));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text(AppStrings.resultYourAnswer('cohernt')), findsOneWidget);
      expect(find.text(AppStrings.resultTimedOut), findsOneWidget);
      expect(find.text(AppStrings.resultSkipped), findsOneWidget);
      // Trả lời sai → SM-2 hẹn ôn lại sau 1 ngày
      expect(find.text(AppStrings.reviewDueTomorrow), findsNWidgets(3));
    });
  });

  testWidgets('Màn 05 · Nút tạo học phần có chữ "Tạo mới", vẫn có tooltip', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LibraryView(
        state: LibrarySampleData.full,
        onQueryChange: (_) {},
        onCategorySelect: (_) {},
        onCourseClick: (_) {},
        onCreateCourseClick: () {},
        onRetry: () {},
      ),
    ));
    expect(find.text(AppStrings.libraryCreateShort), findsOneWidget);
    expect(find.byTooltip(AppStrings.libraryCreateCourse), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('library_create_course'))).height, greaterThanOrEqualTo(48));
  });
}
