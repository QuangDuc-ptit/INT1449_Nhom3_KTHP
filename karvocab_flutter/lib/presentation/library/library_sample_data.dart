import 'library_ui_state.dart';

/// Dữ liệu mẫu của Màn 05 · Thư viện — chỉ dùng cho Preview và test giao diện.
class LibrarySampleData {
  LibrarySampleData._();

  static const List<Category> categories = [
    Category(id: 'academic', name: 'Học thuật'),
    Category(id: 'career', name: 'Sự nghiệp'),
    Category(id: 'life', name: 'Đời sống'),
    Category(id: 'travel', name: 'Du lịch'),
    Category(id: 'other', name: 'Khác'),
  ];

  /// 3 học phần với tiến độ khác nhau (75%, 33%, 0%).
  static const List<Course> courses = [
    Course(
      id: 'sample-1',
      name: 'Học thuật & IELTS Core',
      level: 'B2',
      wordCount: 40,
      masteredCount: 30,
      categoryId: 'academic',
    ),
    Course(
      id: 'sample-2',
      name: 'Từ vựng phỏng vấn xin việc và giao tiếp nơi công sở',
      level: 'B1',
      wordCount: 24,
      masteredCount: 8,
      categoryId: 'career',
    ),
    Course(
      id: 'sample-3',
      name: 'Tiếng Anh Du lịch',
      level: 'A2',
      wordCount: 0,
      masteredCount: 0,
      categoryId: 'travel',
    ),
  ];

  static const LibraryUiState full = LibraryUiState(categories: categories, courses: courses);

  /// Đang lọc theo nhóm "Học thuật".
  static final LibraryUiState filtered = LibraryUiState(
    categories: categories,
    selectedCategoryId: 'academic',
    courses: courses.where((c) => c.categoryId == 'academic').toList(),
  );

  /// Chưa có học phần nào.
  static const LibraryUiState empty = LibraryUiState(categories: categories);
}
