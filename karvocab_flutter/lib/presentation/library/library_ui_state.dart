// Dữ liệu hiển thị của Màn 05 · Thư viện.
//
// Màn hình chỉ đọc state này, không tự lọc. Việc lọc theo ô tìm kiếm và
// theo nhóm làm ở `LibraryController` (hoặc dữ liệu mẫu cho Preview).

/// Nhóm lọc (Học thuật, Sự nghiệp, Đời sống…).
class Category {
  final String id;
  final String name;

  const Category({required this.id, required this.name});
}

/// Một học phần trong danh sách.
class Course {
  final String id;
  final String name;

  /// Trình độ CEFR, ví dụ "B1", "B2".
  final String level;
  final int wordCount;
  final int masteredCount;
  final String categoryId;

  const Course({
    required this.id,
    required this.name,
    required this.level,
    required this.wordCount,
    required this.masteredCount,
    required this.categoryId,
  });

  /// masteredCount / wordCount × 100, làm tròn; wordCount = 0 → 0%.
  int get progressPercent {
    if (wordCount <= 0) return 0;
    return (masteredCount * 100 / wordCount).round().clamp(0, 100);
  }
}

/// Trạng thái tải dữ liệu (giữ Loading / Error theo quy định rubric).
enum LibraryLoadStatus { loading, ready, error }

class LibraryUiState {
  /// Chữ đang có trong ô tìm kiếm.
  final String query;
  final List<Category> categories;

  /// `null` = chip "Tất cả".
  final String? selectedCategoryId;

  /// Danh sách ĐÃ lọc theo [query] và [selectedCategoryId].
  final List<Course> courses;

  final LibraryLoadStatus status;
  final String? errorMessage;

  const LibraryUiState({
    this.query = '',
    this.categories = const [],
    this.selectedCategoryId,
    this.courses = const [],
    this.status = LibraryLoadStatus.ready,
    this.errorMessage,
  });

  /// Danh sách trống vì đang tìm/lọc (khác với chưa có học phần nào).
  bool get isFiltering => query.trim().isNotEmpty || selectedCategoryId != null;
}
