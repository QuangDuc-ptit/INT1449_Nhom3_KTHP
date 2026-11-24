import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/constants/app_strings.dart';
import 'fixtures/mock_vocab_data.dart';
import 'package:karvocab_flutter/data/repositories/collection_store.dart';
import 'package:karvocab_flutter/presentation/quiz/practice_mode_screen.dart';
import 'package:karvocab_flutter/presentation/quiz/quiz_session_screen.dart';
import 'package:karvocab_flutter/presentation/quiz/widgets/practice_widgets.dart';

CollectionStore _freshStore() => CollectionStore(
      collections: MockVocabData.seedCollections(),
      vocabularies: MockVocabData.seedVocabularies(),
      latency: Duration.zero,
    );

void main() {
  group('Màn 10 · Luyện tập', () {
    late CollectionStore store;

    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      store = _freshStore();
      await tester.pumpWidget(MaterialApp(home: PracticeModeScreen(store: store)));
    }

    /// Mở phần "Tuỳ chọn khác" (điện thoại mặc định thu gọn).
    Future<void> expandMore(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('practice_more')));
      await tester.pump();
    }

    testWidgets('Điện thoại: tuỳ chọn phụ thu gọn chỉ còn tiêu đề, chỉ báo khi thiếu từ; trò dễ lên trước',
        (tester) async {
      await pumpScreen(tester);

      expect(find.byKey(const Key('practice_status')), findsNothing);
      expect(find.text('Chưa thuộc · 20 từ · A-Z · Có đếm giờ'), findsNothing);
      // Học phần "hằng ngày" chỉ có 3 từ trong dữ liệu mẫu → báo phiên chỉ có 3 câu
      expect(find.text(AppStrings.practicePoolInfo(3, 20)), findsOneWidget);

      final titles = tester.widgetList<PracticeGameCard>(find.byType(PracticeGameCard)).map((c) => c.title).toList();
      expect(titles.first, 'Chọn nghĩa đúng');
      expect(titles.last, 'Luyện phát âm');

      await expandMore(tester);
      expect(find.byKey(const Key('practice_status')), findsOneWidget);
    });

    testWidgets('Giá trị ban đầu: bộ hằng ngày, Chưa thuộc, 20, A-Z đang chọn', (tester) async {
      await pumpScreen(tester);
      await expandMore(tester);

      expect(find.text('Giao tiếp & Đời sống hằng ngày'), findsOneWidget);
      expect(find.text('Chọn tối đa 3 học phần'), findsNothing); // chỉ còn trong sheet chọn học phần
      expect(find.text('Chưa thuộc'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);

      final buttons = tester.widgetList<PracticeOrderButton>(find.byType(PracticeOrderButton)).toList();
      expect(buttons.first.selected, isTrue);
      expect(buttons.last.selected, isFalse);
    });

    testWidgets('Bấm "Ngẫu nhiên" chuyển trạng thái chọn; ô chọn và nút ≥ 48dp', (tester) async {
      await pumpScreen(tester);
      await expandMore(tester);

      await tester.tap(find.text('Ngẫu nhiên'));
      await tester.pump();

      final buttons = tester.widgetList<PracticeOrderButton>(find.byType(PracticeOrderButton)).toList();
      expect(buttons.first.selected, isFalse);
      expect(buttons.last.selected, isTrue);

      expect(tester.getSize(find.byType(PracticeOrderButton).first).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(find.byKey(const Key('practice_count'))).height, greaterThanOrEqualTo(48));
    });

    testWidgets('Đổi "Số lượng từ" và "Trạng thái từ" qua bottom sheet', (tester) async {
      await pumpScreen(tester);
      await expandMore(tester);

      await tester.tap(find.byKey(const Key('practice_count')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('30'));
      await tester.pumpAndSettle();
      expect(find.text('30'), findsOneWidget);

      await tester.tap(find.byKey(const Key('practice_status')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tất cả'));
      await tester.pumpAndSettle();
      expect(find.text('Tất cả'), findsOneWidget);
    });

    testWidgets('Nguồn học phần chọn tối đa 3 bộ', (tester) async {
      await pumpScreen(tester);
      store.createCollection(title: 'Bộ thứ tư', description: '', category: 'life');
      await tester.pump();

      await tester.tap(find.byKey(const Key('practice_source')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Học thuật & IELTS Core'));
      await tester.tap(find.text('Tiếng Anh Du lịch & Trải nghiệm'));
      await tester.pump();

      final options = tester.widgetList<PracticeSheetOption>(find.byType(PracticeSheetOption)).toList();
      expect(options.where((o) => o.selected).length, 3);
      final fourth = options.firstWhere((o) => o.label == 'Bộ thứ tư');
      expect(fourth.enabled, isFalse);

      await tester.tap(find.text('Xong'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Học thuật & IELTS Core'), findsOneWidget);
    });

    testWidgets('Luyện phát âm, Đồng nghĩa và trái nghĩa mở phiên chơi', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Luyện phát âm'));
      await tester.pumpAndSettle();
      expect(find.byType(QuizSessionScreen), findsOneWidget);
      expect(find.text('Đọc to từ dưới đây'), findsOneWidget);
      Navigator.of(tester.element(find.byType(QuizSessionScreen))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đồng nghĩa và trái nghĩa'));
      await tester.pumpAndSettle();
      expect(find.text('Hai từ này có quan hệ gì với nhau?'), findsOneWidget);
    });

    testWidgets('Nghe và chọn từ, Nhớ từ qua nghĩa mở phiên quiz', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Nghe và chọn từ'));
      await tester.pumpAndSettle();
      expect(find.byType(QuizSessionScreen), findsOneWidget);

      Navigator.of(tester.element(find.byType(QuizSessionScreen))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nhớ từ qua nghĩa'));
      await tester.pumpAndSettle();
      expect(find.byType(QuizSessionScreen), findsOneWidget);
    });
  });
}
