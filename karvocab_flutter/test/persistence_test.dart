import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/constants/app_strings.dart';
import 'package:karvocab_flutter/data/local/local_store.dart';
import 'package:karvocab_flutter/data/models/learning_badge.dart';
import 'package:karvocab_flutter/data/models/quiz_models.dart';
import 'package:karvocab_flutter/data/models/vocabulary_model.dart';
import 'package:karvocab_flutter/data/repositories/auth_repository.dart';
import 'package:karvocab_flutter/data/repositories/collection_store.dart';
import 'package:karvocab_flutter/data/repositories/dashboard_store.dart';
import 'package:karvocab_flutter/data/repositories/quiz_question_factory.dart';
import 'package:karvocab_flutter/data/repositories/quiz_settings_store.dart';
import 'package:karvocab_flutter/presentation/screens/profile_screen.dart';

/// "Tải lại app" = tạo store mới trên cùng một [LocalStore].
void main() {
  VocabularyModel word(String term) => VocabularyModel(
    id: '',
    collectionId: '',
    term: term,
    partOfSpeech: 'noun',
    ipa: '',
    definitionVi: 'nghĩa $term',
    definitionEn: '',
    exampleSentence: '',
    cefrLevel: 'A2',
  );

  group('Lưu dữ liệu trên máy', () {
    test('Học phần và từ vựng còn nguyên sau khi mở lại app', () {
      final disk = MemoryLocalStore();
      final before = CollectionStore(storage: disk, latency: Duration.zero);
      expect(before.collections, isEmpty); // không có dữ liệu giả
      final col = before.createCollection(title: 'Du lịch');
      before.addWords(col.id, [word('airport'), word('luggage')]);

      final after = CollectionStore(storage: disk, latency: Duration.zero);
      expect(after.collections.single.title, 'Du lịch');
      expect(after.wordsOf(col.id).map((w) => w.term), ['airport', 'luggage']);
    });

    test('Tiến độ SM-2, mục tiêu ngày, chuỗi ngày và lịch sử tuần còn nguyên sau khi mở lại app', () {
      final disk = MemoryLocalStore();
      final library = CollectionStore(storage: disk, latency: Duration.zero);
      final col = library.createCollection(title: 'Công việc');
      library.addWords(col.id, [word('deadline'), word('meeting')]);
      final now = DateTime(2026, 11, 24, 9);
      final dashboard = DashboardStore.forTest(clock: () => now, collections: library, storage: disk);
      expect(dashboard.dueVocabularies, hasLength(2)); // từ mới đến hạn ngay

      final qs = QuizQuestionFactory.build(mode: QuizMode.meaningChoose, pool: library.allWords, count: 2);
      dashboard.recordSessionResult(
        QuizSummary(
          records: [
            for (final q in qs)
              QuizAnswerRecord(
                question: q,
                userAnswer: q.correctAnswer,
                result: AnswerResult.correct,
                responseTimeMs: 400,
              ),
          ],
          durationSeconds: 8,
          clientSessionId: 's',
        ),
      );
      dashboard.setDailyGoal(15);

      final reopened = DashboardStore.forTest(clock: () => now, collections: library, storage: disk);
      expect(reopened.streak, 1);
      expect(reopened.reviewedToday, 2);
      expect(reopened.learnedOn(now), 2);
      expect(reopened.dailyGoal, 15);
      expect(reopened.isLearned(library.allWords.first.id), isTrue);
      expect(reopened.dueVocabularies, isEmpty); // đã ôn xong, hẹn ngày mai
    });

    test('Tài khoản đăng ký và phiên đăng nhập được nhớ; mật khẩu không lưu dạng chữ thường', () async {
      final disk = MemoryLocalStore();
      final auth = AuthRepository(latency: Duration.zero, storage: disk);
      await auth.register(fullName: 'Lan', email: 'lan@test.com', password: 'Hocvien123');

      expect(disk.read(StorageKeys.accounts), isNot(contains('Hocvien123')));

      final reopened = AuthRepository(latency: Duration.zero, storage: disk);
      expect(await reopened.restoreSession(), isTrue);
      expect(reopened.currentUser!.fullName, 'Lan');

      reopened.logout();
      final third = AuthRepository(latency: Duration.zero, storage: disk);
      expect(await third.restoreSession(), isFalse); // đã đăng xuất
      await third.login('lan@test.com', 'Hocvien123'); // tài khoản vẫn còn
      await expectLater(third.login('lan@test.com', 'sai-mat-khau'), throwsA(isA<AuthException>()));
    });

    test('Cài đặt luyện tập (đếm giờ, âm lượng) còn nguyên sau khi mở lại app', () {
      final disk = MemoryLocalStore();
      QuizSettingsStore(storage: disk)
        ..setTimerEnabled(false)
        ..setVolume(0.3)
        ..setSeconds(QuizMode.recallType, 60);

      final reopened = QuizSettingsStore(storage: disk);
      expect(reopened.timerEnabled, isFalse);
      expect(reopened.volume, 0.3);
      expect(reopened.secondsFor(QuizMode.recallType), 60);
    });

    test('Dữ liệu lưu bị hỏng thì bắt đầu trống, không treo app', () {
      final disk = MemoryLocalStore()
        ..write(StorageKeys.collections, '{hỏng')
        ..write(StorageKeys.dashboard, '[1,2');
      expect(CollectionStore(storage: disk).collections, isEmpty);
      expect(DashboardStore.forTest(storage: disk).streak, 0);
    });
  });

  group('Màn 15 · Huy hiệu', () {
    test('Mở khoá theo mốc: chuỗi 7 ngày, 100 từ, trên 5 học phần', () {
      final locked = LearningBadge.evaluate(highestStreak: 3, wordsLearned: 99, collections: 5);
      expect(locked.map((b) => b.unlocked), [false, false, false]);
      final open = LearningBadge.evaluate(highestStreak: 7, wordsLearned: 100, collections: 6);
      expect(open.map((b) => b.unlocked), [true, true, true]);
      expect(locked.first.shownProgress, 3);
    });

    testWidgets('Tài khoản mới: 3 huy hiệu đều xám kèm điều kiện mở', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final auth = AuthRepository(latency: Duration.zero);
      await tester.runAsync(() => auth.login(AuthRepository.demoEmail, AuthRepository.demoPassword));
      final store = CollectionStore(latency: Duration.zero);
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            authRepository: auth,
            store: store,
            dashboard: DashboardStore.forTest(collections: store),
          ),
        ),
      );

      expect(find.text(AppStrings.profileBadges), findsOneWidget);
      for (final kind in LearningBadgeKind.values) {
        expect(find.byKey(Key('badge_${kind.name}')), findsOneWidget);
      }
      expect(find.text('${AppStrings.badgeStreak7Condition} · 0/7'), findsOneWidget);
      expect(find.text('${AppStrings.badgeFirst100Condition} · 0/100'), findsOneWidget);
      expect(find.text('${AppStrings.badgeExplorerCondition} · 0/6'), findsOneWidget);
    });
  });
}
