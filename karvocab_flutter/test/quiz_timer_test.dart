import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/constants/app_strings.dart';
import 'package:karvocab_flutter/data/mock/mock_vocab_data.dart';
import 'package:karvocab_flutter/data/models/quiz_models.dart';
import 'package:karvocab_flutter/data/repositories/collection_store.dart';
import 'package:karvocab_flutter/data/repositories/quiz_question_factory.dart';
import 'package:karvocab_flutter/data/repositories/quiz_settings_store.dart';
import 'package:karvocab_flutter/data/services/feedback_service.dart';
import 'package:karvocab_flutter/presentation/quiz/practice_mode_screen.dart';
import 'package:karvocab_flutter/presentation/quiz/quiz_controller.dart';
import 'package:karvocab_flutter/presentation/quiz/quiz_session_screen.dart';

/// Ghi lại các âm đã phát thay vì phát thật.
class _RecordingFeedback extends FeedbackService {
  int ticks = 0;
  int incorrect = 0;
  final List<double> volumes = [];

  @override
  Future<void> playCorrect() async => volumes.add(volume);

  @override
  Future<void> playIncorrect() async {
    incorrect++;
    volumes.add(volume);
  }

  @override
  Future<void> playTick() async {
    ticks++;
    volumes.add(volume);
  }
}

List<QuizQuestion> _questions(QuizMode mode, {int count = 2}) => QuizQuestionFactory.build(
      mode: mode,
      pool: MockVocabData.seedVocabularies(),
      count: count,
    );

void main() {
  late _RecordingFeedback feedback;

  setUp(() {
    feedback = _RecordingFeedback();
    FeedbackService.instance = feedback;
  });

  group('QuizSettingsStore — thời gian & âm lượng', () {
    test('mặc định theo từng trò: chọn nghĩa 35s, trò gõ dài hơn trò chọn', () {
      final s = QuizSettingsStore();
      expect(s.secondsFor(QuizMode.meaningChoose), 35);
      expect(s.secondsFor(QuizMode.recallType), greaterThan(s.secondsFor(QuizMode.meaningChoose)));
      expect(s.secondsFor(QuizMode.synonymAntonym), lessThan(s.secondsFor(QuizMode.listenChoose)));
      expect(s.timeLimitFor(QuizMode.meaningChoose), 35);
      expect(s.isDefault, isTrue);
    });

    test('chỉnh theo bước 5 giây, giữ trong 10–120; tắt đếm ngược thì không giới hạn', () {
      final s = QuizSettingsStore();
      s.increaseSeconds(QuizMode.meaningChoose);
      expect(s.secondsFor(QuizMode.meaningChoose), 40);
      s.setSeconds(QuizMode.meaningChoose, 3);
      expect(s.secondsFor(QuizMode.meaningChoose), QuizSettingsStore.minSeconds);
      s.setSeconds(QuizMode.meaningChoose, 999);
      expect(s.secondsFor(QuizMode.meaningChoose), QuizSettingsStore.maxSeconds);
      s.setSeconds(QuizMode.meaningChoose, 33);
      expect(s.secondsFor(QuizMode.meaningChoose), 35);

      s.setTimerEnabled(false);
      expect(s.timeLimitFor(QuizMode.meaningChoose), isNull);
      s.resetDefaults();
      expect(s.isDefault, isTrue);
    });

    test('âm lượng bước 10%, không vượt 0–100% và không sai số khi bấm nhiều lần', () {
      final s = QuizSettingsStore();
      for (var i = 0; i < 20; i++) {
        s.increaseVolume();
      }
      expect(s.volume, 1.0);
      for (var i = 0; i < 3; i++) {
        s.decreaseVolume();
      }
      expect(s.volume, 0.7);
      expect(s.volumePercent, 70);
      s.setVolume(-1);
      expect(s.volume, 0.0);
    });
  });

  group('QuizController — đếm ngược mỗi câu', () {
    testWidgets('hết giờ → tính sai, đánh dấu timedOut; 5 giây cuối có 5 tiếng tích tắc', (tester) async {
      final settings = QuizSettingsStore()..setSeconds(QuizMode.meaningChoose, 10);
      final c = QuizController(
        questions: _questions(QuizMode.meaningChoose),
        feedback: feedback,
        settings: settings,
      );
      addTearDown(c.dispose);
      expect(c.remainingSeconds, 10);

      await tester.pump(const Duration(seconds: 4));
      expect(c.remainingSeconds, 6);
      expect(c.isTimeWarning, isFalse);
      expect(feedback.ticks, 0);

      await tester.pump(const Duration(seconds: 1));
      expect(c.isTimeWarning, isTrue);
      expect(feedback.ticks, 1);

      await tester.pump(const Duration(seconds: 5));
      expect(c.isAnswered, isTrue);
      expect(c.lastRecord!.timedOut, isTrue);
      expect(c.lastRecord!.result, AnswerResult.wrong);
      expect(feedback.ticks, 5);
      expect(feedback.incorrect, 1);

      // Đã hết giờ thì đồng hồ dừng, không phát thêm
      await tester.pump(const Duration(seconds: 5));
      expect(feedback.ticks, 5);
    });

    testWidgets('trả lời trước khi hết giờ thì dừng đồng hồ; câu kế đếm lại từ đầu', (tester) async {
      final settings = QuizSettingsStore()..setSeconds(QuizMode.listenChoose, 20);
      final c = QuizController(
        questions: _questions(QuizMode.listenChoose),
        feedback: feedback,
        settings: settings,
      );
      addTearDown(c.dispose);

      await tester.pump(const Duration(seconds: 3));
      c.submitChoice(c.current.correctAnswer);
      await tester.pump(const Duration(seconds: 30));
      expect(c.remainingSeconds, 17);
      expect(c.lastRecord!.timedOut, isFalse);

      c.next();
      expect(c.remainingSeconds, 20);
    });

    testWidgets('tạm dừng thì không đếm; tắt đếm ngược thì không có đồng hồ', (tester) async {
      final settings = QuizSettingsStore();
      final c = QuizController(
        questions: _questions(QuizMode.meaningChoose),
        feedback: feedback,
        settings: settings,
      );
      addTearDown(c.dispose);

      c.pause();
      await tester.pump(const Duration(seconds: 60));
      expect(c.remainingSeconds, 35);
      expect(c.isAnswered, isFalse);
      c.resume();
      await tester.pump(const Duration(seconds: 2));
      expect(c.remainingSeconds, 33);

      settings.setTimerEnabled(false);
      final untimed = QuizController(
        questions: _questions(QuizMode.meaningChoose),
        feedback: feedback,
        settings: settings,
      );
      addTearDown(untimed.dispose);
      expect(untimed.isTimed, isFalse);
      await tester.pump(const Duration(minutes: 5));
      expect(untimed.isAnswered, isFalse);
    });

    testWidgets('âm thanh phát theo âm lượng người dùng chọn', (tester) async {
      final settings = QuizSettingsStore()..setVolume(0.3);
      final qs = QuizQuestionFactory.build(
        mode: QuizMode.meaningChoose,
        pool: MockVocabData.seedVocabularies(),
        count: 1,
      );
      final c = QuizController(questions: qs, feedback: feedback, settings: settings);
      addTearDown(c.dispose);
      c.submitChoice(c.current.correctAnswer);
      expect(feedback.volumes.last, 0.3);
    });
  });

  group('Giao diện đếm ngược', () {
    testWidgets('Màn làm bài hiện số giây, hết giờ hiện "Hết giờ!" kèm đáp án đúng', (tester) async {
      final settings = QuizSettingsStore()..setSeconds(QuizMode.meaningChoose, 10);
      await tester.pumpWidget(MaterialApp(
        home: QuizSessionScreen(questions: _questions(QuizMode.meaningChoose), settings: settings),
      ));
      expect(find.text(AppStrings.secondsShort(10)), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      expect(find.text(AppStrings.secondsShort(7)), findsOneWidget);

      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.feedbackTimeUp), findsOneWidget);
      expect(find.text(AppStrings.feedbackCorrectAnswer), findsOneWidget);
    });

    testWidgets('Nút loa mở chỉnh âm lượng và tạm dừng đồng hồ trong lúc chỉnh', (tester) async {
      final settings = QuizSettingsStore();
      await tester.pumpWidget(MaterialApp(
        home: QuizSessionScreen(questions: _questions(QuizMode.meaningChoose), settings: settings),
      ));
      await tester.tap(find.byKey(const Key('quiz_volume')));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.quizPaused), findsOneWidget);

      await tester.tap(find.byKey(const Key('volume_decrease')));
      await tester.pump();
      expect(settings.volumePercent, 60);
      expect(find.text(AppStrings.volumePercent(60)), findsOneWidget);

      await tester.pump(const Duration(seconds: 50)); // đang chỉnh âm lượng → không hết giờ
      expect(find.text(AppStrings.feedbackTimeUp), findsNothing);
    });

    testWidgets('Màn 10: thẻ trò chơi hiện giây/câu; đổi thời gian trong sheet cập nhật ngay', (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final settings = QuizSettingsStore();
      final store = CollectionStore(
        collections: MockVocabData.seedCollections(),
        vocabularies: MockVocabData.seedVocabularies(),
        latency: Duration.zero,
      );
      await tester.pumpWidget(MaterialApp(home: PracticeModeScreen(store: store, quizSettings: settings)));
      expect(find.text(AppStrings.practiceGameSeconds(35)), findsOneWidget);
      expect(find.text(AppStrings.practiceTimerPerGame), findsOneWidget);

      await tester.tap(find.byKey(const Key('practice_timer')));
      await tester.pumpAndSettle();
      final row = find.byKey(Key('quiz_timer_${QuizMode.meaningChoose.name}'));
      await tester.tap(find.descendant(of: row, matching: find.byIcon(Icons.add_circle_outline_rounded)));
      await tester.pump();
      expect(settings.secondsFor(QuizMode.meaningChoose), 40);

      await tester.tap(find.byKey(const Key('quiz_timer_switch')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('quiz_settings_done')));
      await tester.pumpAndSettle();
      expect(settings.timerEnabled, isFalse);
      expect(find.text(AppStrings.practiceTimerOff), findsOneWidget);
      expect(find.textContaining('giây/câu'), findsNothing);
    });
  });
}
