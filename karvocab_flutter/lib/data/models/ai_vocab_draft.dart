import 'vocabulary_model.dart';

/// Từ vựng do AI sinh ra, đang chờ người dùng duyệt ở Màn 14.
/// Theo BE: phiên âm tách `ipaUk` / `ipaUs` (có thể null).
class AiVocabDraft {
  final String term;
  final String partOfSpeech; // noun | verb | adj | adv | idiom
  final String? ipaUk;
  final String? ipaUs;
  final String definitionEn;
  String definitionVi;
  String exampleSentence;
  final String cefrLevel;

  /// BE đánh dấu từ đã có trong học phần đích (gửi `collectionId` khi sinh).
  /// Trường này KHÔNG được gửi lại trong `POST /vocabularies/batch-save`.
  final bool existsInCollection;
  bool selected;

  AiVocabDraft({
    required this.term,
    required this.partOfSpeech,
    this.ipaUk,
    this.ipaUs,
    required this.definitionEn,
    required this.definitionVi,
    required this.exampleSentence,
    required this.cefrLevel,
    this.existsInCollection = false,
    bool? selected,
  }) : selected = selected ?? !existsInCollection; // Mặc định tick, trừ từ đã có

  /// Phiên âm hiển thị: `ipaUk ?? ipaUs`.
  String get ipa => ipaUk ?? ipaUs ?? '';

  factory AiVocabDraft.fromJson(Map<String, dynamic> json) => AiVocabDraft(
        term: json['term'] as String,
        partOfSpeech: json['partOfSpeech'] as String,
        ipaUk: (json['ipaUk'] ?? json['ipa']) as String?,
        ipaUs: json['ipaUs'] as String?,
        definitionEn: (json['definitionEn'] as String?) ?? '',
        definitionVi: json['definitionVi'] as String,
        exampleSentence: (json['exampleSentence'] as String?) ?? '',
        cefrLevel: json['cefrLevel'] as String,
        existsInCollection: (json['existsInCollection'] as bool?) ?? false,
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
