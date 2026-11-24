import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/data/mock/mock_vocab_data.dart';
import 'package:karvocab_flutter/data/models/quiz_models.dart';
import 'package:karvocab_flutter/data/models/vocabulary_model.dart';
import 'package:karvocab_flutter/data/repositories/auth_repository.dart';
import 'package:karvocab_flutter/data/repositories/collection_bridge.dart';
import 'package:karvocab_flutter/data/repositories/collection_store.dart';
import 'package:karvocab_flutter/data/repositories/dashboard_store.dart';
import 'package:karvocab_flutter/data/repositories/quiz_question_factory.dart';
import 'package:karvocab_flutter/data/repositories/track_sync.dart';
import 'package:karvocab_flutter/presentation/home/home_state_builder.dart';

/// Kiểm thử phần nối Track A (FE1) ↔ Track B (FE2).
CollectionStore _freshStore() => CollectionStore(
      collections: MockVocabData.seedCollections(),
      vocabularies: MockVocabData.seedVocabularies(),
      latency: Duration.zero,
    );

VocabularyModel _aiWord(String id, {String term = 'boarding pass'}) => VocabularyModel(
      id: id,
      collectionId: '',
      term: term,
      partOfSpeech: 'noun',
      ipa: '/ˈbɔːdɪŋ pɑːs/',
      definitionVi: 'thẻ lên máy bay',
      definitionEn: 'A card that lets you board a plane.',
      exampleSentence: 'Show your boarding pass at the gate.',
      cefrLevel: 'A2',
    );

void main() {
  group('CollectionBridge → CollectionStore (FE spec §5.1)', () {
    late CollectionStore store;
    var notified = 0;

    setUp(() {
      store = _freshStore();
      notified = 0;
      store.addListener(() => notified++);
      CollectionBridge.store = store;
    });
    tearDown(() => CollectionBridge.store = CollectionStore.instance);

    test('addWords đi qua store: Thư viện được báo và số từ tăng', () {
      final before = store.findCollection('col-1')!.totalWords;
      CollectionBridge.addWords(
        'col-1',
        [_aiWord('voc-ai-1'), _aiWord('', term: 'layover')],
      );

      expect(notified, greaterThan(0));
      expect(store.findCollection('col-1')!.totalWords, before + 2);
      final added = store.wordsOf('col-1').where((w) => w.term == 'boarding pass' || w.term == 'layover');
      expect(added.length, 2);
      expect(added.every((w) => w.id.isNotEmpty && w.collectionId == 'col-1'), isTrue);
    });

    test('addWords bỏ qua từ đã có (không phân biệt hoa thường, kể cả trùng trong cùng lần lưu) như BE', () {
      CollectionBridge.addWords('col-1', [_aiWord('voc-ai-1')]);
      final before = store.findCollection('col-1')!.totalWords;

      final skipped = CollectionBridge.addWords('col-1', [
        _aiWord('voc-ai-2', term: '  Boarding   PASS '),
        _aiWord('voc-ai-3', term: 'gate'),
        _aiWord('voc-ai-4', term: 'GATE'),
      ]);

      expect(skipped, ['  Boarding   PASS ', 'GATE']);
      expect(store.findCollection('col-1')!.totalWords, before + 1);
      expect(store.wordsOf('col-1').where((w) => w.term.toLowerCase() == 'gate').length, 1);
    });

    test('createCollection tạo học phần trong store, tự thêm hậu tố khi trùng tên', () {
      final first = CollectionBridge.createCollection('AI · Airport');
      final second = CollectionBridge.createCollection('AI · Airport');

      expect(store.findCollection(first)!.title, 'AI · Airport');
      expect(store.findCollection(second)!.title, 'AI · Airport (2)');
      expect(CollectionBridge.collections.map((c) => c.id), containsAll([first, second]));
    });
  });

  group('HomeStateBuilder (Màn 04 lấy số liệu thật)', () {
    test('tổng số từ, học phần lấy từ CollectionStore; streak, từ cần ôn từ DashboardStore', () {
      final store = _freshStore();
      final dashboard = DashboardStore.forTest();
      final state = HomeStateBuilder.build(
        collections: store,
        dashboard: dashboard,
        now: DateTime(2026, 11, 20), // Thứ Sáu
      );

      expect(state.totalWords, store.totalWordCount);
      expect(state.streakDays, dashboard.streak);
      expect(state.wordsToReview, dashboard.dueVocabularies.length);
      expect(state.courses.length, store.collections.length);
      expect(state.todayIndex, 4);
      expect(state.weeklyStats[4], dashboard.reviewedToday);
      expect(state.weeklyStats.sublist(5), [null, null]);
    });
  });

  group('TrackSync (mục tiêu ngày & streak)', () {
    test('đổi mục tiêu ở Cài đặt → Trang chủ; streak sau quiz → Hồ sơ', () async {
      final auth = AuthRepository(latency: Duration.zero, random: Random(1));
      final dashboard = DashboardStore.forTest();
      TrackSync.attach(auth: auth, dashboard: dashboard);
      await auth.login(AuthRepository.demoEmail, AuthRepository.demoPassword);

      auth.updateProfile(auth.currentUser!.copyWith(dailyGoalWords: 20));
      expect(dashboard.dailyGoal, 20);

      final questions = QuizQuestionFactory.build(
        mode: QuizMode.meaningChoose,
        pool: MockVocabData.initialVocabularies,
        count: 5,
        random: Random(2),
      );
      final streakBefore = dashboard.streak;
      dashboard.recordSessionResult(QuizSummary(
        records: [
          for (final q in questions)
            QuizAnswerRecord(
              question: q,
              userAnswer: q.correctAnswer,
              result: AnswerResult.correct,
              responseTimeMs: 1000,
            ),
        ],
        durationSeconds: 30,
        clientSessionId: 'test-session',
      ));

      expect(dashboard.streak, streakBefore + 1);
      expect(auth.currentUser!.currentStreak, dashboard.streak);
    });
  });
}
