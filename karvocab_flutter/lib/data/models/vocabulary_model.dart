/// Model Từ vựng (Vocabulary) chuẩn cấu trúc thiết kế KarVocab
class VocabularyModel {
  final String id;
  final String collectionId;
  final String term;
  final String partOfSpeech; // key trong PartOfSpeech.values (core/constants/part_of_speech.dart)
  final String ipa;
  final String definitionVi;
  final String definitionEn;
  final String exampleSentence;
  final String cefrLevel; // 'A1', 'A2', 'B1', 'B2', 'C1'
  final bool isMastered;

  /// Từ đồng nghĩa / trái nghĩa cho game "Đồng nghĩa và trái nghĩa" (Màn 10).
  /// Backend chưa có 2 cột này (cần BE thêm vào bảng `vocabularies`); rỗng = từ
  /// không tham gia game đó.
  final List<String> synonyms;
  final List<String> antonyms;

  /// Ghi chú riêng của người học (Màn 09 / 24). Backend chưa có cột này.
  final String note;

  const VocabularyModel({
    required this.id,
    required this.collectionId,
    required this.term,
    required this.partOfSpeech,
    required this.ipa,
    required this.definitionVi,
    required this.definitionEn,
    required this.exampleSentence,
    required this.cefrLevel,
    this.isMastered = false,
    this.synonyms = const [],
    this.antonyms = const [],
    this.note = '',
  });

  VocabularyModel copyWith({
    String? id,
    String? collectionId,
    String? term,
    String? partOfSpeech,
    String? ipa,
    String? definitionVi,
    String? definitionEn,
    String? exampleSentence,
    String? cefrLevel,
    bool? isMastered,
    List<String>? synonyms,
    List<String>? antonyms,
    String? note,
  }) {
    return VocabularyModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      term: term ?? this.term,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      ipa: ipa ?? this.ipa,
      definitionVi: definitionVi ?? this.definitionVi,
      definitionEn: definitionEn ?? this.definitionEn,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      isMastered: isMastered ?? this.isMastered,
      synonyms: synonyms ?? this.synonyms,
      antonyms: antonyms ?? this.antonyms,
      note: note ?? this.note,
    );
  }
}
