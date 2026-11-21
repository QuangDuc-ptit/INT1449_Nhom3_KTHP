import 'dart:math';

import '../mock/mock_vocab_data.dart';
import '../models/quiz_models.dart';
import '../models/vocabulary_model.dart';

/// Sinh câu hỏi cho 4 chế độ từ danh sách từ vựng (Demo offline — thay cho `GET /practice/questions`).
class QuizQuestionFactory {
  QuizQuestionFactory._();

  /// Tạo [count] câu hỏi cùng 1 chế độ từ [pool].
  static List<QuizQuestion> build({
    required QuizMode mode,
    required List<VocabularyModel> pool,
    int count = 10,
    Random? random,
  }) {
    final rnd = random ?? Random();
    final picked = List<VocabularyModel>.from(pool)..shuffle(rnd);
    final chosen = picked.take(count).toList();
    return [
      for (var i = 0; i < chosen.length; i++)
        _buildOne(i, mode, chosen[i], rnd),
    ];
  }

  /// Phiên ôn tập hỗn hợp: xoay vòng cả 4 chế độ (dùng cho Màn 16).
  static List<QuizQuestion> buildMixed({
    required List<VocabularyModel> pool,
    int count = 10,
    Random? random,
  }) {
    final rnd = random ?? Random();
    final picked = List<VocabularyModel>.from(pool)..shuffle(rnd);
    final chosen = picked.take(count).toList();
    const modes = QuizMode.values;
    return [
      for (var i = 0; i < chosen.length; i++)
        _buildOne(i, modes[i % modes.length], chosen[i], rnd),
    ];
  }

  /// Dựng lại câu hỏi cho các từ làm sai (Màn 26) — giữ nguyên chế độ cũ, xáo lại đáp án.
  static List<QuizQuestion> rebuildForRetry(
    List<QuizQuestion> missed, {
    Random? random,
  }) {
    final rnd = random ?? Random();
    final list = List<QuizQuestion>.from(missed)..shuffle(rnd);
    return [
      for (var i = 0; i < list.length; i++)
        _buildOne(i, list[i].mode, list[i].vocab, rnd, idPrefix: 'retry'),
    ];
  }

  static QuizQuestion _buildOne(
    int index,
    QuizMode mode,
    VocabularyModel vocab,
    Random rnd, {
    String idPrefix = 'q',
  }) {
    final id = '$idPrefix-$index-${vocab.id}';
    switch (mode) {
      case QuizMode.listenChoose:
        return QuizQuestion(
          id: id,
          vocab: vocab,
          mode: mode,
          options: _options(vocab, rnd, (v) => v.term),
          correctAnswer: vocab.term,
        );
      case QuizMode.meaningChoose:
        return QuizQuestion(
          id: id,
          vocab: vocab,
          mode: mode,
          options: _options(vocab, rnd, (v) => v.definitionVi),
          correctAnswer: vocab.definitionVi,
        );
      case QuizMode.listenType:
      case QuizMode.recallType:
        return QuizQuestion(
          id: id,
          vocab: vocab,
          mode: mode,
          options: const [],
          correctAnswer: vocab.term,
        );
    }
  }

  /// 1 đáp án đúng + tối đa 3 distractor (ưu tiên cùng từ loại), xáo ngẫu nhiên A/B/C/D.
  static List<String> _options(
    VocabularyModel vocab,
    Random rnd,
    String Function(VocabularyModel) pick,
  ) {
    final correct = pick(vocab);
    final others = MockVocabData.initialVocabularies
        .where((v) => v.id != vocab.id && pick(v) != correct)
        .toList()
      ..shuffle(rnd);

    final samePos = others.where((v) => v.partOfSpeech == vocab.partOfSpeech);
    final diffPos = others.where((v) => v.partOfSpeech != vocab.partOfSpeech);

    final distractors = <String>[];
    for (final v in [...samePos, ...diffPos]) {
      final text = pick(v);
      if (!distractors.contains(text)) distractors.add(text);
      if (distractors.length == 3) break;
    }

    return [correct, ...distractors]..shuffle(rnd);
  }
}
