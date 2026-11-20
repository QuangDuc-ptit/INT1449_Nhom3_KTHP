import '../../data/models/vocabulary_model.dart';

/// Điểm duy nhất Track B đọc phiên âm của từ.
/// Khi FE1 đổi `VocabularyModel` sang `ipaUk` / `ipaUs` (FE-BE-ALIGNMENT mục 3),
/// chỉ cần sửa 1 dòng dưới đây thành `v.ipaUk ?? v.ipaUs ?? ''`.
extension VocabDisplayX on VocabularyModel {
  String get ipaText => ipa;
}
