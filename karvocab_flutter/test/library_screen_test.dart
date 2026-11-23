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

    testWidgets('Thẻ học phần chỉ có icon, tên và số từ', (tester) async {
      await tester.pumpWidget(view(LibrarySampleData.full));

      expect(find.text(AppStrings.libraryTitle), findsOneWidget);
      expect(find.text('Học thuật & IELTS Core'), findsOneWidget);
      expect(find.text(AppStrings.libraryWordCount(40)), findsOneWidget);
      // Không còn trình độ, chủ đề, phần trăm trên thẻ.
      expect(find.text('B2'), findsNothing);
      expect(find.text('Học thuật · ${AppStrings.libraryWordCount(40)}'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      // Không truyền onCourseMenuClick thì không có nút ⋮.
      expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
    });

    testWidgets('Nút ⋮ trên thẻ gọi onCourseMenuClick(id), không mở học phần', (tester) async {
      final menus = <String>[];
      final opened = <String>[];
      await tester.pumpWidget(MaterialApp(
        home: LibraryView(
          state: LibrarySampleData.full,
          onQueryChange: (_) {},
          onCategorySelect: (_) {},
          onCourseClick: opened.add,
          onCourseMenuClick: menus.add,
          onCreateCourseClick: () {},
          onRetry: () {},
        ),
      ));
      await tester.tap(find.byKey(const Key('course_menu_sample-2')));
      expect(menus, ['sample-2']);
      expect(opened, isEmpty);
    });

    testWidgets('Bấm cả thẻ gọi onCourseClick(id)', (tester) async {
      String? clicked;
      await tester.pumpWidget(view(LibrarySampleData.full, onCourseClick: (id) => clicked = id));

      await tester.tap(find.text(AppStrings.libraryWordCount(24)));
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

  group('Sửa / xoá học phần', () {
    late CollectionStore store;

    setUp(() async {
      store = CollectionStore(
        collections: MockVocabData.seedCollections(),
        vocabularies: MockVocabData.seedVocabularies(),
        latency: Duration.zero,
      );
      await store.load();
    });

    test('updateCollection đổi tên, chủ đề; chặn tên trùng', () {
      final first = store.collections.first;
      final second = store.collections[1];
      final updated = store.updateCollection(first.id, title: 'Tên mới', category: 'travel')!;
      expect(updated.title, 'Tên mới');
      expect(updated.category, 'travel');
      expect(store.findCollection(first.id)!.title, 'Tên mới');
      // Giữ nguyên tên của chính nó thì không bị coi là trùng.
      expect(store.updateCollection(first.id, title: 'tên mới'), isNotNull);
      expect(() => store.updateCollection(first.id, title: second.title), throwsArgumentError);
    });

    test('deleteCollection xoá học phần và các từ trong đó', () {
      final target = store.collections.first;
      final wordsBefore = store.totalWordCount;
      final count = store.wordsOf(target.id).length;
      expect(count, greaterThan(0));

      expect(store.deleteCollection(target.id)?.id, target.id);
      expect(store.findCollection(target.id), isNull);
      expect(store.wordsOf(target.id), isEmpty);
      expect(store.totalWordCount, wordsBefore - count);
      expect(store.deleteCollection(target.id), isNull);
    });

    Future<void> openMenu(WidgetTester tester, String id) async {
      await tester.pumpWidget(MaterialApp(home: LibraryScreen(store: store)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('course_menu_$id')));
      await tester.pumpAndSettle();
    }

    testWidgets('Menu ⋮ → Sửa học phần: form điền sẵn, lưu tên mới', (tester) async {
      final target = store.collections.first;
      await openMenu(tester, target.id);
      await tester.tap(find.byKey(const Key('collection_action_edit')));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.collectionEdit), findsOneWidget);
      final titleField = find.widgetWithText(TextField, target.title);
      expect(titleField, findsOneWidget);
      await tester.enterText(titleField, 'IELTS nâng cao');
      await tester.tap(find.byKey(const Key('collection_form_submit')));
      await tester.pumpAndSettle();

      expect(store.findCollection(target.id)!.title, 'IELTS nâng cao');
      expect(find.text('IELTS nâng cao'), findsWidgets);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Menu ⋮ → Xoá học phần: hỏi xác nhận, Huỷ thì giữ, Xoá thì mất', (tester) async {
      final target = store.collections.first;
      await openMenu(tester, target.id);
      await tester.tap(find.byKey(const Key('collection_action_delete')));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.collectionDeleteTitle(target.title)), findsOneWidget);
      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();
      expect(store.findCollection(target.id), isNotNull);

      await tester.tap(find.byKey(Key('course_menu_${target.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('collection_action_delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, AppStrings.collectionDelete));
      await tester.pumpAndSettle();

      expect(store.findCollection(target.id), isNull);
      expect(find.byKey(Key('course_menu_${target.id}')), findsNothing);
      await tester.pump(const Duration(seconds: 4));
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
