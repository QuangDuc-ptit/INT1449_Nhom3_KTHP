import '../../core/constants/app_strings.dart';
import '../models/collection_model.dart';
import '../models/vocabulary_model.dart';
import 'collection_store.dart';

/// Cầu nối tích hợp giữa Track B (AI Vocab) và Track A (Thư viện).
/// Đặc tả §5.1: FE2 chỉ gọi `addWords(collectionId, words)`; phần bên trong
/// chuyển hết sang [CollectionStore] của FE1 để Thư viện (Màn 05/06) cập nhật ngay.
/// Chữ ký các hàm giữ nguyên như bản FE2 viết ban đầu.
class CollectionBridge {
  CollectionBridge._();

  /// Store đích. Test có thể gán store riêng rồi trả lại [CollectionStore.instance].
  static CollectionStore store = CollectionStore.instance;

  static List<CollectionModel> get collections => store.collections;

  /// Tạo học phần mới, trả về id. Nếu tên đã có thì thêm hậu tố " (2)", " (3)"…
  /// vì Màn 22 của FE1 không cho trùng tên học phần.
  static String createCollection(String title) {
    final base = title.trim();
    var name = base;
    for (var n = 2; store.isTitleTaken(name); n++) {
      name = '$base ($n)';
    }
    return store
        .createCollection(title: name, description: AppStrings.aiCollectionDescription)
        .id;
  }

  /// Thêm danh sách từ vào học phần (cập nhật `totalWords` và báo cho Thư viện).
  static void addWords(String collectionId, List<VocabularyModel> words) =>
      store.addWords(collectionId, words);
}
