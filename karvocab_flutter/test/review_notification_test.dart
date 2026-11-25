import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/constants/app_strings.dart';
import 'package:karvocab_flutter/data/models/quiz_models.dart';
import 'package:karvocab_flutter/data/repositories/collection_store.dart';
import 'package:karvocab_flutter/data/repositories/dashboard_store.dart';
import 'package:karvocab_flutter/data/repositories/quiz_question_factory.dart';
import 'package:karvocab_flutter/presentation/notifications/notification_ui_state.dart';
import 'package:karvocab_flutter/presentation/notifications/review_notification_builder.dart';

import 'fixtures/mock_vocab_data.dart';

/// Thông báo chỉ nhắc ôn tập: có từ đã học đến hạn mới báo (cùng luật job nhắc ôn của BE).
void main() {
  late DateTime clock;
  late CollectionStore library;
  late DashboardStore dashboard;

  setUp(() {
    clock = DateTime(2026, 11, 24, 9);
    library = CollectionStore(
      collections: MockVocabData.seedCollections(),
      vocabularies: MockVocabData.seedVocabularies(),
      latency: Duration.zero,
    );
    dashboard = DashboardStore.forTest(clock: () => clock, collections: library);
  });

  /// Học đúng [count] từ đầu tiên hôm nay → hẹn ôn ngày mai.
  void learn(int count) {
    final pool = library.allWords.take(count).toList();
    final qs = QuizQuestionFactory.build(mode: QuizMode.meaningChoose, pool: pool, count: count);
    dashboard.recordSessionResult(QuizSummary(
      records: [
        for (final q in qs)
          QuizAnswerRecord(question: q, userAnswer: q.correctAnswer, result: AnswerResult.correct, responseTimeMs: 400),
      ],
      durationSeconds: 10,
      clientSessionId: 's',
    ));
  }

  NotificationUiState state({String? readId}) =>
      ReviewNotificationBuilder.build(dashboard: dashboard, now: clock, readId: readId);

  test('Chỉ có từ mới chưa học thì không thông báo', () {
    expect(dashboard.dueVocabularies, isNotEmpty); // từ mới vẫn nằm trong hàng ôn
    expect(state().items, isEmpty);
  });

  test('Vừa học xong, chưa tới hạn ôn thì không thông báo', () {
    learn(3);
    expect(state().items, isEmpty);
  });

  test('Tới hạn ôn: một thông báo chưa đọc, đếm đúng số từ đã học đến hạn', () {
    learn(3);
    clock = clock.add(const Duration(days: 1, hours: 1));
    final s = state();
    expect(s.items, hasLength(1));
    expect(s.unreadCount, 1);
    expect(s.items.single.title, AppStrings.notificationReviewTitle);
    expect(s.items.single.preview, AppStrings.notificationReviewPreview(3));
    expect(s.items.single.id, ReviewNotificationBuilder.idFor(clock));
  });

  test('Đã đọc trong ngày thì hết chấm đỏ; sang ngày sau còn từ đến hạn thì lại chưa đọc', () {
    learn(2);
    clock = clock.add(const Duration(days: 1, hours: 1));
    final readToday = ReviewNotificationBuilder.idFor(clock);
    expect(state(readId: readToday).unreadCount, 0);

    clock = clock.add(const Duration(days: 1));
    expect(state(readId: readToday).unreadCount, 1);
  });

  test('Ôn xong hết từ đến hạn thì thông báo tự mất', () {
    learn(2);
    clock = clock.add(const Duration(days: 1, hours: 1));
    expect(state().items, hasLength(1));
    learn(2);
    expect(state().items, isEmpty);
  });
}

