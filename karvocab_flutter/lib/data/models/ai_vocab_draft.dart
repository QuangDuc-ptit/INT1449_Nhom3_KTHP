import 'vocabulary_model.dart';

/// Từ vựng do AI sinh ra, đang chờ người dùng duyệt ở Màn 14.
/// Cấu trúc khớp JSON Schema Gemini trong BE-SPECIFICATION (mục 3.4).
class AiVocabDraft {
  final String term;
  final String partOfSpeech;
  final String ipa;
  final String definitionEn;
  String definitionVi;
  String exampleSentence;
  final String cefrLevel;
  bool selected;

  AiVocabDraft({
    required this.term,
    required this.partOfSpeech,
    required this.ipa,
    required this.definitionEn,
    required this.definitionVi,
    required this.exampleSentence,
    required this.cefrLevel,
    this.selected = true, // Mặc định tick chọn 100%
  });

  factory AiVocabDraft.fromJson(Map<String, dynamic> json) => AiVocabDraft(
        term: json['term'] as String,
        partOfSpeech: json['partOfSpeech'] as String,
        ipa: (json['ipa'] as String?) ?? '',
        definitionEn: json['definitionEn'] as String,
        definitionVi: json['definitionVi'] as String,
        exampleSentence: json['exampleSentence'] as String,
        cefrLevel: json['cefrLevel'] as String,
      );

  VocabularyModel toVocabulary(String collectionId, String id) {
    return VocabularyModel(
      id: id,
      collectionId: collectionId,
      term: term,
      partOfSpeech: partOfSpeech,
      ipa: ipa,
      definitionVi: definitionVi,
      definitionEn: definitionEn,
      exampleSentence: exampleSentence,
      cefrLevel: cefrLevel,
    );
  }
}
