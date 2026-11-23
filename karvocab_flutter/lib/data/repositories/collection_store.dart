import 'package:flutter/foundation.dart';

import '../mock/mock_vocab_data.dart';
import '../models/collection_model.dart';
import '../models/vocabulary_model.dart';

/// Trạng thái tải dữ liệu của một màn hình danh sách (Loading / Error / Ready).
enum LoadStatus { initial, loading, ready, error }

/// Store trung tâm của module Thư viện (Track A — FE1).
///
/// - Là nguồn dữ liệu duy nhất cho Màn 05, 06, 07, 09, 22, 24, 28 và thống kê Màn 15.
/// - Hiện thực hợp đồng tích hợp đặc tả §5.1: `addWords(collectionId, words)`
///   để Track B (Lưu từ AI — Màn 14) gọi vào.
/// - Mặc định thao tác trên danh sách sống của [MockVocabData] (chế độ Demo/offline);
///   Sprint 3 sẽ thay phần `load()` bằng API backend thật.
class CollectionStore extends ChangeNotifier {
  CollectionStore({
    required this._collections,
    required this._vocabularies,
    this.latency = const Duration(milliseconds: 400),
  });

  /// Instance dùng chung toàn app (Demo Mode dùng dữ liệu mock).
  static final CollectionStore instance = CollectionStore(
    collections: MockVocabData.initialCollections,
    vocabularies: MockVocabData.initialVocabularies,
  );

  final List<CollectionModel> _collections;
  final List<VocabularyModel> _vocabularies;

  /// Độ trễ giả lập mạng khi tải dữ liệu.
  final Duration latency;

  /// Bật để giả lập lỗi mạng ở lần `load()` tiếp theo (kiểm thử Error State).
  bool simulateNetworkError = false;

  LoadStatus _status = LoadStatus.initial;
  String? _errorMessage;
  int _idSeq = 0;

  LoadStatus get status => _status;
  String? get errorMessage => _errorMessage;

  List<CollectionModel> get collections => List.unmodifiable(_collections);
  int get totalWordCount => _vocabularies.length;

  // ---------------------------------------------------------------------------
  // Tải dữ liệu
  // ---------------------------------------------------------------------------

  /// Tải danh sách học phần. [silent] = true (kéo để làm mới) giữ nguyên dữ liệu đang hiển thị
  /// thay vì chuyển sang Loading State.
  Future<void> load({bool silent = false}) async {
    if (!silent || _status != LoadStatus.ready) {
      _status = LoadStatus.loading;
      _errorMessage = null;
      notifyListeners();
    }

    await Future<void>.delayed(latency);

    if (simulateNetworkError) {
      simulateNetworkError = false;
      _status = LoadStatus.error;
      _errorMessage = 'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng và thử lại.';
    } else {
      _syncAllCounts();
      _status = LoadStatus.ready;
    }
    notifyListeners();
  }

  /// Chỉ tải khi chưa từng tải thành công (tránh nháy Loading khi quay lại tab).
  Future<void> ensureLoaded() async {
    if (_status == LoadStatus.initial || _status == LoadStatus.error) {
      await load();
    }
  }

  // ---------------------------------------------------------------------------
  // Truy vấn
  // ---------------------------------------------------------------------------

  CollectionModel? findCollection(String id) {
    for (final c in _collections) {
      if (c.id == id) return c;
    }
    return null;
  }

  VocabularyModel? findWord(String id) {
    for (final w in _vocabularies) {
      if (w.id == id) return w;
    }
    return null;
  }

  /// Lọc học phần theo chủ đề và từ khoá (tên + mô tả, không phân biệt hoa thường).
  List<CollectionModel> search({String query = '', String category = 'all'}) {
    final q = query.trim().toLowerCase();
    return _collections.where((c) {
      final matchesCategory = category == 'all' || c.category == category;
      final matchesQuery = q.isEmpty ||
          c.title.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<VocabularyModel> wordsOf(String collectionId, {String query = ''}) {
    final q = query.trim().toLowerCase();
    return _vocabularies.where((w) {
      if (w.collectionId != collectionId) return false;
      if (q.isEmpty) return true;
      return w.term.toLowerCase().contains(q) ||
          w.definitionVi.toLowerCase().contains(q) ||
          w.definitionEn.toLowerCase().contains(q);
    }).toList();
  }

  bool isTitleTaken(String title, {String? excludeId}) {
    final t = title.trim().toLowerCase();
    return _collections.any((c) => c.id != excludeId && c.title.trim().toLowerCase() == t);
  }

  bool isTermTaken(String collectionId, String term, {String? excludeId}) {
    final t = term.trim().toLowerCase();
    return _vocabularies.any((w) =>
        w.collectionId == collectionId && w.id != excludeId && w.term.trim().toLowerCase() == t);
  }

  // ---------------------------------------------------------------------------
  // Học phần (Màn 22)
  // ---------------------------------------------------------------------------

  /// Tạo học phần mới, chèn lên đầu danh sách.
  /// Ném [ArgumentError] nếu tên trùng với học phần đã có.
  CollectionModel createCollection({
    required String title,
    String description = '',
    String category = 'academic',
  }) {
    final cleanTitle = title.trim();
    if (isTitleTaken(cleanTitle)) {
      throw ArgumentError('Tên học phần "$cleanTitle" đã tồn tại');
    }
    final collection = CollectionModel(
      id: _newId('col'),
      title: cleanTitle,
      description: description.trim().isEmpty ? 'Bộ sưu tập từ vựng cá nhân' : description.trim(),
      category: category,
      iconName: iconForCategory(category),
      totalWords: 0,
    );
    _collections.insert(0, collection);
    notifyListeners();
    return collection;
  }

  /// Sửa tên, mô tả, chủ đề của học phần. Ném [ArgumentError] nếu tên trùng
  /// học phần khác; trả về `null` nếu không tìm thấy.
  CollectionModel? updateCollection(
    String id, {
    required String title,
    String description = '',
    String category = 'academic',
  }) {
    final index = _collections.indexWhere((c) => c.id == id);
    if (index == -1) return null;
    final cleanTitle = title.trim();
    if (isTitleTaken(cleanTitle, excludeId: id)) {
      throw ArgumentError('Tên học phần "$cleanTitle" đã tồn tại');
    }
    final updated = _collections[index].copyWith(
      title: cleanTitle,
      description: description.trim().isEmpty ? 'Bộ sưu tập từ vựng cá nhân' : description.trim(),
      category: category,
      iconName: iconForCategory(category),
    );
    _collections[index] = updated;
    notifyListeners();
    return updated;
  }

  /// Xoá học phần cùng toàn bộ từ vựng trong đó. Trả về học phần vừa xoá hoặc `null`.
  CollectionModel? deleteCollection(String id) {
    final index = _collections.indexWhere((c) => c.id == id);
    if (index == -1) return null;
    final removed = _collections.removeAt(index);
    _vocabularies.removeWhere((w) => w.collectionId == id);
    notifyListeners();
    return removed;
  }

  static String iconForCategory(String category) {
    switch (category) {
      case 'academic':
        return 'school_rounded';
      case 'travel':
        return 'flight_takeoff_rounded';
      case 'life':
        return 'chat_bubble_outline_rounded';
      case 'career':
        return 'work_outline_rounded';
      default:
        return 'folder_special_rounded';
    }
  }

  // ---------------------------------------------------------------------------
  // Từ vựng (Màn 24, 09, 28)
  // ---------------------------------------------------------------------------

  /// Thêm một từ. Nếu `id` rỗng sẽ tự sinh id mới. Trả về bản ghi đã lưu.
  VocabularyModel addWord(VocabularyModel word) {
    final saved = word.id.isEmpty ? word.copyWith(id: _newId('voc')) : word;
    _vocabularies.insert(0, saved);
    _syncCount(saved.collectionId);
    notifyListeners();
    return saved;
  }

  /// Hợp đồng tích hợp với Track B (Màn 14 — Lưu từ AI vào học phần).
  void addWords(String collectionId, List<VocabularyModel> words) {
    for (final w in words) {
      final withId = w.id.isEmpty ? w.copyWith(id: _newId('voc')) : w;
      _vocabularies.add(withId.copyWith(collectionId: collectionId));
    }
    _syncCount(collectionId);
    notifyListeners();
  }

  /// Cập nhật một từ đã có. Trả về `false` nếu không tìm thấy.
  bool updateWord(VocabularyModel word) {
    final index = _vocabularies.indexWhere((w) => w.id == word.id);
    if (index == -1) return false;
    final previousCollection = _vocabularies[index].collectionId;
    _vocabularies[index] = word;
    _syncCount(previousCollection);
    if (previousCollection != word.collectionId) _syncCount(word.collectionId);
    notifyListeners();
    return true;
  }

  /// Xoá một từ, trả về bản ghi vừa xoá (để hỗ trợ "Hoàn tác") hoặc `null`.
  VocabularyModel? deleteWord(String id) {
    final index = _vocabularies.indexWhere((w) => w.id == id);
    if (index == -1) return null;
    final removed = _vocabularies.removeAt(index);
    _syncCount(removed.collectionId);
    notifyListeners();
    return removed;
  }

  /// Khôi phục một từ vừa xoá (nút "Hoàn tác" trên Toast).
  void restoreWord(VocabularyModel word) {
    if (findWord(word.id) != null) return;
    _vocabularies.insert(0, word);
    _syncCount(word.collectionId);
    notifyListeners();
  }

  /// Đưa store về dữ liệu gốc (Demo / kiểm thử).
  void resetToSeed() {
    _collections
      ..clear()
      ..addAll(MockVocabData.seedCollections());
    _vocabularies
      ..clear()
      ..addAll(MockVocabData.seedVocabularies());
    _status = LoadStatus.initial;
    _errorMessage = null;
    simulateNetworkError = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Nội bộ
  // ---------------------------------------------------------------------------

  String _newId(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_idSeq++}';

  void _syncCount(String collectionId) {
    final index = _collections.indexWhere((c) => c.id == collectionId);
    if (index == -1) return;
    final count = _vocabularies.where((w) => w.collectionId == collectionId).length;
    _collections[index] = _collections[index].copyWith(totalWords: count);
  }

  void _syncAllCounts() {
    for (final c in List<CollectionModel>.from(_collections)) {
      _syncCount(c.id);
    }
  }
}
