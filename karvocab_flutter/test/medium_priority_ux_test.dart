import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/constants/app_strings.dart';
import 'package:karvocab_flutter/data/mock/mock_vocab_data.dart';
import 'package:karvocab_flutter/data/models/quiz_models.dart';
import 'package:karvocab_flutter/data/repositories/collection_store.dart';
import 'package:karvocab_flutter/data/repositories/quiz_question_factory.dart';
import 'package:karvocab_flutter/presentation/quiz/practice_mode_screen.dart';
import 'package:karvocab_flutter/presentation/quiz/quiz_mode_views.dart';
import 'package:karvocab_flutter/presentation/quiz/widgets/feedback_banner.dart';
import 'package:karvocab_flutter/presentation/quiz/widgets/practice_widgets.dart';
import 'package:karvocab_flutter/presentation/screens/word_list_screen.dart';

QuizAnswerRecord _wrong(QuizQuestion q) =>
    QuizAnswerRecord(question: q, userAnswer: 'sai', result: AnswerResult.wrong, responseTimeMs: 500);

Future<void> _pumpBanner(WidgetTester tester, QuizAnswerRecord record) => tester.pumpWidget(
      MaterialApp(home: Scaffold(body: FeedbackBanner(record: record, onContinue: () {}, isLast: false))),
    );

void main() {
  group('Màn 11 · Phản hồi sai', () {
    testWidgets('Trắc nghiệm: không lặp "Đáp án đúng" (đã tô xanh trên lựa chọn)', (tester) async {
      final q = QuizQuestionFactory.build(
        mode: QuizMode.meaningChoose,
        pool: MockVocabData.initialVocabularies,
        count: 1,
      ).first;
      await _pumpBanner(tester, _wrong(q));
      expect(find.text(AppStrings.feedbackWrong), findsOneWidget);
      expect(find.text(AppStrings.feedbackCorrectAnswer), findsNothing);
    });

    testWidgets('Gõ chữ: vẫn hiện "Đáp án đúng" vì không có lựa chọn nào được tô', (tester) async {
      final q = QuizQuestionFactory.build(
        mode: QuizMode.recallType,
        pool: MockVocabData.initialVocabularies,
        count: 1,
      ).first;
      await _pumpBanner(tester, _wrong(q));
      expect(find.text(AppStrings.feedbackCorrectAnswer), findsOneWidget);
      expect(find.text(q.correctAnswer), findsWidgets);
    });
  });

  testWidgets('Màn 06 · Học phần trống: Axolotl + một nút thêm (ẩn FAB)', (tester) async {
    final store = CollectionStore(
      collections: MockVocabData.seedCollections(),
      vocabularies: MockVocabData.seedVocabularies(),
      latency: Duration.zero,
    );
    final empty = store.createCollection(title: 'Trống', description: '', category: 'other');
    await tester.pumpWidget(MaterialApp(home: WordListScreen(collection: empty, store: store)));
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.pets_rounded), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Thêm từ mới ngay'), findsOneWidget);
  });

  group('Màn 10 · Danh sách trò chơi', () {
    testWidgets('Mỗi trò một icon riêng, không thẻ nào trông như đang được chọn, các thẻ cao bằng nhau',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = CollectionStore(
        collections: MockVocabData.seedCollections(),
        vocabularies: MockVocabData.seedVocabularies(),
        latency: Duration.zero,
      );
      await tester.pumpWidget(MaterialApp(home: PracticeModeScreen(store: store)));

      final cards = tester.widgetList<PracticeGameCard>(find.byType(PracticeGameCard)).toList();
      final icons = cards.map((c) => c.icon).toSet();
      expect(icons.length, cards.length);
      expect(QuizMode.listenChoose.icon, isNot(QuizMode.listenType.icon));

      final heights = find.byType(PracticeGameCard).evaluate().map((e) => e.size!.height).toSet();
      expect(heights.length, 1);
    });
  });

  test('Dữ liệu mẫu: các cặp trái nghĩa dễ tranh cãi đã được bỏ', () {
    final byTerm = {for (final v in MockVocabData.initialVocabularies) v.term: v};
    expect(byTerm['explore']!.antonyms, isNot(contains('ignore')));
    expect(byTerm['opportunity']!.antonyms, isNot(contains('obstacle')));
    expect(byTerm['ambitious']!.antonyms, isNot(contains('lazy')));
  });
}
