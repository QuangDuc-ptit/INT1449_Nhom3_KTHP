import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/constants/app_strings.dart';
import 'package:karvocab_flutter/data/models/quiz_models.dart';
import 'package:karvocab_flutter/data/models/vocabulary_model.dart';
import 'package:karvocab_flutter/data/repositories/collection_store.dart';
import 'package:karvocab_flutter/data/repositories/dashboard_store.dart';
import 'package:karvocab_flutter/data/repositories/quiz_question_factory.dart';
import 'package:karvocab_flutter/presentation/dashboard/review_today_screen.dart';
import 'package:karvocab_flutter/presentation/library/library_controller.dart';

VocabularyModel _word(String collectionId, String term) => VocabularyModel(
  id: '',
  collectionId: collectionId,
  term: term,
  partOfSpeech: 'noun',
  ipa: '',
  definitionVi: 'nghĩa $term',
  definitionEn: '',
  exampleSentence: '',
  cefrLevel: 'A1',
);

void main() {
  testWidgets('Màn 16: từ mới chưa học vẫn mở được hàng đợi ôn tập (không crash)', (tester) async {
    final library = CollectionStore.instance..switchUser('reviewer@test.local');
    addTearDown(() => library.switchUser(null));
    final col = library.createCollection(title: 'Du lịch');
    library.addWord(_word(col.id, 'hotel'));
    library.addWord(_word(col.id, 'ticket'));

    await tester.pumpWidget(const MaterialApp(home: ReviewTodayScreen()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('hotel'), findsOneWidget);
    expect(find.text(AppStrings.reviewDueNow), findsNWidgets(2));
  });

  test('Từ lên level 5 của SM-2 được tính là đã thuộc ở Thư viện', () async {
    final library = CollectionStore(latency: Duration.zero);
    final col = library.createCollection(title: 'Du lịch');
    library.addWord(_word(col.id, 'hotel'));
    var now = DateTime(2026, 11, 1, 9);
    final dashboard = DashboardStore.forTest(clock: () => now, collections: library);
    final word = library.allWords.single;

    // Trả lời đúng mỗi lần đến hạn: level 1 → 5 (mastered).
    for (var i = 0; i < 5; i++) {
      final q = QuizQuestionFactory.build(mode: QuizMode.recallType, pool: library.allWords, count: 1).single;
      dashboard.recordSessionResult(QuizSummary(
        records: [QuizAnswerRecord(question: q, userAnswer: q.correctAnswer, result: AnswerResult.correct, responseTimeMs: 300)],
        durationSeconds: 3,
        clientSessionId: 'phien-$i',
      ));
      now = dashboard.progressOf(word.id)!.nextReviewAt;
    }
    expect(dashboard.isMastered(word.id), isTrue);

    final controller = LibraryController(store: library, dashboard: dashboard, debounce: Duration.zero);
    addTearDown(controller.dispose);
    await library.load();
    expect(controller.state.courses.single.masteredCount, 1);
  });
}
