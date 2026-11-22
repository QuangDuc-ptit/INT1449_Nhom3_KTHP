import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../../core/utils/debouncer.dart';
import '../../data/repositories/collection_store.dart';
import '../widgets/collection_form_sheet.dart';
import 'library_ui_state.dart';

/// State holder của Màn 05 · Thư viện.
///
/// Đọc [CollectionStore], giữ chữ tìm kiếm và nhóm đang chọn, rồi dựng
/// [LibraryUiState] đã lọc. Lọc làm trên danh sách cục bộ (`store.search`,
/// theo tên + mô tả), ô tìm kiếm có debounce 300ms.
class LibraryController extends ChangeNotifier {
  LibraryController({
    required this._store,
    String? initialCategoryId,
    Duration debounce = const Duration(milliseconds: 300),
  })  : _selectedCategoryId = initialCategoryId,
        _debouncer = Debouncer(delay: debounce) {
    _store.addListener(notifyListeners);
  }

  final CollectionStore _store;
  final Debouncer _debouncer;

  String _query = '';

  /// Chữ đã hết thời gian debounce — dùng để lọc.
  String _appliedQuery = '';
  String? _selectedCategoryId;

  static final List<Category> _categories = [
    for (final entry in CollectionCategories.labels.entries) Category(id: entry.key, name: entry.value),
  ];

  LibraryUiState get state {
    return LibraryUiState(
      query: _query,
      categories: _categories,
      selectedCategoryId: _selectedCategoryId,
      courses: _store.status == LoadStatus.ready ? _filteredCourses() : const [],
      status: switch (_store.status) {
        LoadStatus.initial || LoadStatus.loading => LibraryLoadStatus.loading,
        LoadStatus.error => LibraryLoadStatus.error,
        LoadStatus.ready => LibraryLoadStatus.ready,
      },
      errorMessage: _store.errorMessage,
    );
  }

  List<Course> _filteredCourses() {
    final collections = _store.search(query: _appliedQuery, category: _selectedCategoryId ?? 'all');
    return [
      for (final c in collections)
        Course(
          id: c.id,
          name: c.title,
          level: c.level,
          wordCount: c.totalWords,
          masteredCount: _store.wordsOf(c.id).where((w) => w.isMastered).length,
          categoryId: c.category,
        ),
    ];
  }

  /// Gọi sau frame đầu (tránh notify khi cây widget đang build).
  void ensureLoaded() => _store.ensureLoaded();

  Future<void> retry() => _store.load();

  Future<void> refresh() => _store.load(silent: true);

  void onQueryChange(String text) {
    _query = text;
    if (text.trim().isEmpty) {
      // Xoá chữ (nút "x") → hiện lại danh sách ngay, không chờ debounce.
      _debouncer.cancel();
      _appliedQuery = '';
    } else {
      _debouncer.run(() {
        _appliedQuery = text.trim();
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void onCategorySelect(String? categoryId) {
    if (categoryId == _selectedCategoryId) return;
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  @override
  void dispose() {
    _store.removeListener(notifyListeners);
    _debouncer.dispose();
    super.dispose();
  }
}
