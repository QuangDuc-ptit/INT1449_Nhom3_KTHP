/// Model Từ vựng (Vocabulary) chuẩn cấu trúc thiết kế KarVocab
class VocabularyModel {
  final String id;
  final String collectionId;
  final String term;
  final String partOfSpeech; // 'noun', 'verb', 'adj', 'adv'
  final String ipa;
  final String definitionVi;
  final String definitionEn;
  final String exampleSentence;
  final String cefrLevel; // 'A1', 'A2', 'B1', 'B2', 'C1'
  final bool isMastered;

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
    );
  }
}
