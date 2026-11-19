import '../mock/mock_vocab_data.dart';
import '../models/collection_model.dart';
import '../models/vocabulary_model.dart';

/// Cầu nối tích hợp giữa Track B (AI Vocab) và Track A (Thư viện).
/// Đặc tả §5.1: FE2 chỉ gọi `addWords(collectionId, words)`; FE1 sẽ thay phần
/// triển khai bên trong bằng store thật của Thư viện khi họ hoàn thiện.
class CollectionBridge {
  CollectionBridge._();

  static List<CollectionModel> get collections =>
      List.unmodifiable(MockVocabData.initialCollections);

  /// Tạo học phần mới, trả về id.
  static String createCollection(String title) {
    final id = 'col-ai-${DateTime.now().microsecondsSinceEpoch}';
    MockVocabData.initialCollections.insert(
      0,
      CollectionModel(
        id: id,
        title: title,
        description: 'Học phần được tạo bằng AI',
        category: 'academic',
        iconName: 'school_rounded',
        totalWords: 0,
      ),
    );
    return id;
  }

  /// Thêm danh sách từ vào học phần và cập nhật `totalWords`.
  static void addWords(String collectionId, List<VocabularyModel> words) {
    MockVocabData.initialVocabularies.addAll(words);
    final list = MockVocabData.initialCollections;
    final index = list.indexWhere((c) => c.id == collectionId);
    if (index != -1) {
      list[index] = list[index].copyWith(
        totalWords: list[index].totalWords + words.length,
      );
    }
  }
}
