import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/constants/app_strings.dart';
import 'package:karvocab_flutter/core/widgets/app_button.dart';
import 'package:karvocab_flutter/data/mock/mock_vocab_data.dart';
import 'package:karvocab_flutter/data/repositories/collection_store.dart';
import 'package:karvocab_flutter/presentation/library/library_controller.dart';
import 'package:karvocab_flutter/presentation/library/library_sample_data.dart';
import 'package:karvocab_flutter/presentation/library/library_ui_state.dart';
import 'package:karvocab_flutter/presentation/screens/library_screen.dart';

void main() {
  group('Course.progressPercent', () {
    Course course(int words, int mastered) =>
        Course(id: 'x', name: 'x', level: 'B1', wordCount: words, masteredCount: mastered, categoryId: 'life');

    test('masteredCount / wordCount × 100, làm tròn; wordCount = 0 → 0%', () {
      expect(course(40, 30).progressPercent, 75);
      expect(course(24, 8).progressPercent, 33);
      expect(course(3, 2).progressPercent, 67);
      expect(course(0, 0).progressPercent, 0);
    });
  });

  group('Màn 05 · Thư viện (LibraryView)', () {
    Widget view(
      LibraryUiState state, {
      ValueChanged<String>? onQueryChange,
      ValueChanged<String?>? onCategorySelect,
      ValueChanged<String>? onCourseClick,
      VoidCallback? onCreateCourseClick,
    }) {
      return MaterialApp(
        home: LibraryView(
          state: state,
          onQueryChange: onQueryChange ?? (_) {},
          onCategorySelect: onCategorySelect ?? (_) {},
          onCourseClick: onCourseClick ?? (_) {},
          onCreateCourseClick: onCreateCourseClick ?? () {},
          onRetry: () {},
        ),
      );
    }

    testWidgets('Thẻ học phần: tên, trình độ, số từ, phần trăm; không có mô tả', (tester) async {
      await tester.pumpWidget(view(LibrarySampleData.full));

      expect(find.text(AppStrings.libraryTitle), findsOneWidget);
      expect(find.text('Học thuật & IELTS Core'), findsOneWidget);
      expect(find.text('B2'), findsOneWidget);
      expect(find.text('Học thuật · ${AppStrings.libraryWordCount(40)}'), findsOneWidget);
      expect(find.text(AppStrings.libraryProgressPercent(75)), findsOneWidget);
      expect(find.text(AppStrings.libraryProgressPercent(33)), findsOneWidget);
      expect(find.text(AppStrings.libraryProgressPercent(0)), findsOneWidget);
      expect(find.textContaining('thành thạo'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('Bấm cả thẻ gọi onCourseClick(id)', (tester) async {
      String? clicked;
      await tester.pumpWidget(view(LibrarySampleData.full, onCourseClick: (id) => clicked = id));

      await tester.tap(find.text('Sự nghiệp · ${AppStrings.libraryWordCount(24)}'));
      expect(clicked, 'sample-2');
    });

    testWidgets('Chip lấy từ categories, "Tất cả" đứng đầu và trả về null', (tester) async {
      final selected = <String?>[];
      await tester.pumpWidget(view(LibrarySampleData.filtered, onCategorySelect: selected.add));

      final all = tester.getTopLeft(find.text(AppStrings.libraryAllCategories)).dx;
      for (final c in LibrarySampleData.categories) {
        expect(find.text(c.name), findsOneWidget);
        expect(tester.getTopLeft(find.text(c.name)).dx, greaterThan(all));
      }

      await tester.tap(find.text('Sự nghiệp'));
      await tester.tap(find.text(AppStrings.libraryAllCategories));
      expect(selected, ['career', null]);
    });

    testWidgets('Chip có vùng chạm tối thiểu 48dp', (tester) async {
      final selected = <String?>[];
      await tester.pumpWidget(view(LibrarySampleData.full, onCategorySelect: selected.add));

      // Bấm sát mép trên vùng chạm (ngoài phần chip 36dp nhìn thấy).
      final chipCenter = tester.getCenter(find.text('Đời sống'));
      await tester.tapAt(chipCenter.translate(0, -22));
      expect(selected, ['life']);
    });

    testWidgets('Nút "x" chỉ hiện khi có chữ và xoá bằng onQueryChange("")', (tester) async {
      final queries = <String>[];
      await tester.pumpWidget(view(LibrarySampleData.full, onQueryChange: queries.add));
      expect(find.byKey(const Key('library_search_clear')), findsNothing);
      final field = tester.widget<TextField>(find.byKey(const Key('library_search')));
      expect(field.textInputAction, TextInputAction.search);

      await tester.pumpWidget(
        view(
          const LibraryUiState(query: 'ielts', categories: LibrarySampleData.categories),
          onQueryChange: queries.add,
        ),
      );
      await tester.tap(find.byKey(const Key('library_search_clear')));
      expect(queries, ['']);
    });

    testWidgets('Thẻ tổng quan: số từ đã thuộc / tổng số từ và số học phần; ẩn khi đang lọc', (tester) async {
      await tester.pumpWidget(view(LibrarySampleData.full));
      expect(find.byKey(const Key('library_overview')), findsOneWidget);
      expect(find.text(AppStrings.libraryOverviewMastered(38, 64)), findsOneWidget);
      expect(find.text(AppStrings.libraryOverviewCourses(3)), findsOneWidget);

      await tester.pumpWidget(view(LibrarySampleData.filtered));
      expect(find.byKey(const Key('library_overview')), findsNothing);
    });

    testWidgets('Thẻ học phần hiện chủ đề cạnh số từ', (tester) async {
      await tester.pumpWidget(view(LibrarySampleData.full));
      expect(find.text('Học thuật · ${AppStrings.libraryWordCount(40)}'), findsOneWidget);
    });

    testWidgets('Trống: linh vật + nút tạo học phần; không tìm thấy: nút xoá bộ lọc', (tester) async {
      var created = 0;
      final queries = <String>[];
      final selected = <String?>[];
      await tester.pumpWidget(view(LibrarySampleData.empty, onCreateCourseClick: () => created++));
      expect(find.text(AppStrings.libraryEmpty), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      await tester.tap(find.widgetWithText(AppButton, AppStrings.libraryCreateCourse));
      expect(created, 1);

      await tester.pumpWidget(
        view(
          const LibraryUiState(query: 'zzz', categories: LibrarySampleData.categories, selectedCategoryId: 'life'),
          onQueryChange: queries.add,
          onCategorySelect: selected.add,
        ),
      );
      expect(find.text(AppStrings.libraryNoResults), findsOneWidget);
      expect(find.text(AppStrings.libraryEmpty), findsNothing);
      await tester.tap(find.widgetWithText(AppButton, AppStrings.libraryClearFilters));
      expect(queries, ['']);
      expect(selected, [null]);
    });

    testWidgets('Màn rộng: thẻ học phần xếp 2 cột', (tester) async {
      tester.view.physicalSize = const Size(820, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(view(LibrarySampleData.full));

      final first = tester.getTopLeft(find.byType(CourseCard).at(0));
      final second = tester.getTopLeft(find.byType(CourseCard).at(1));
      expect(second.dy, first.dy);
      expect(second.dx, greaterThan(first.dx));
    });
  });

  group('LibraryController — lọc trên danh sách cục bộ', () {
    late CollectionStore store;
    late LibraryController controller;

    setUp(() async {
      store = CollectionStore(
        collections: MockVocabData.seedCollections(),
        vocabularies: MockVocabData.seedVocabularies(),
        latency: Duration.zero,
      );
      await store.load();
      controller = LibraryController(store: store, debounce: Duration.zero);
    });

    tearDown(() => controller.dispose());

    List<String> names() => controller.state.courses.map((c) => c.name).toList();

    test('Lọc theo nhóm; null = Tất cả', () {
      expect(names(), hasLength(3));
      controller.onCategorySelect('travel');
      expect(names(), ['Tiếng Anh Du lịch & Trải nghiệm']);
      controller.onCategorySelect(null);
      expect(names(), hasLength(3));
    });

    test('Lọc theo ô tìm kiếm sau debounce; xoá chữ thì hiện lại ngay', () async {
      controller.onQueryChange('sân bay');
      expect(controller.state.query, 'sân bay');
      await Future<void>.delayed(Duration.zero);
      expect(names(), ['Tiếng Anh Du lịch & Trải nghiệm']);

      controller.onQueryChange('');
      expect(names(), hasLength(3));
    });

    test('Course lấy level và số từ từ học phần', () {
      final first = controller.state.courses.first;
      expect(first.level, 'B2');
      expect(first.wordCount, store.collections.first.totalWords);
    });
  });
}
