import 'dart:math';

import '../../core/constants/app_strings.dart';
import '../models/quiz_models.dart';
import '../models/vocabulary_model.dart';
import 'collection_store.dart';

/// Sinh câu hỏi cho 4 chế độ từ danh sách từ vựng (Demo offline — thay cho `GET /practice/questions`).
class QuizQuestionFactory {
  QuizQuestionFactory._();

  /// Tạo [count] câu hỏi cùng 1 chế độ từ [pool].
  /// [shuffle] = false giữ nguyên thứ tự của [pool] (Màn 10 · "Theo thứ tự (A-Z)").
  static List<QuizQuestion> build({
    required QuizMode mode,
    required List<VocabularyModel> pool,
    int count = 10,
    Random? random,
    bool shuffle = true,
  }) {
    final rnd = random ?? Random();
    final picked = pool.where((v) => supports(mode, v)).toList();
    if (shuffle) picked.shuffle(rnd);
    final chosen = picked.take(count).toList();
    return [
      for (var i = 0; i < chosen.length; i++)
        _buildOne(i, mode, chosen[i], rnd, _sourceFor(pool)),
    ];
  }

  /// Từ [vocab] có dùng được cho [mode] không. Game đồng nghĩa / trái nghĩa
  /// chỉ nhận từ đã có dữ liệu quan hệ; các chế độ khác nhận mọi từ.
  static bool supports(QuizMode mode, VocabularyModel vocab) {
    if (mode != QuizMode.synonymAntonym) return true;
    return vocab.synonyms.isNotEmpty || vocab.antonyms.isNotEmpty;
  }

  /// Phiên ôn tập hỗn hợp: xoay vòng 4 chế độ cơ bản (dùng cho Màn 16).
  static List<QuizQuestion> buildMixed({
    required List<VocabularyModel> pool,
    int count = 10,
    Random? random,
  }) {
    final rnd = random ?? Random();
    final picked = List<VocabularyModel>.from(pool)..shuffle(rnd);
    final chosen = picked.take(count).toList();
    const modes = QuizMode.reviewModes;
    return [
      for (var i = 0; i < chosen.length; i++)
        _buildOne(i, modes[i % modes.length], chosen[i], rnd, _sourceFor(pool)),
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
        _buildOne(i, list[i].mode, list[i].vocab, rnd, _sourceFor([for (final q in list) q.vocab]), idPrefix: 'retry'),
    ];
  }

  /// Nguồn đáp án nhiễu: các từ trong phiên + mọi từ trong thư viện của người dùng (bỏ trùng).
  static List<VocabularyModel> _sourceFor(List<VocabularyModel> pool) {
    final seen = <String>{};
    return [
      for (final v in [...pool, ...CollectionStore.instance.allWords])
        if (seen.add(v.id)) v,
    ];
  }

  static QuizQuestion _buildOne(
    int index,
    QuizMode mode,
    VocabularyModel vocab,
    Random rnd,
    List<VocabularyModel> source, {
    String idPrefix = 'q',
  }) {
    final id = '$idPrefix-$index-${vocab.id}';
    switch (mode) {
      case QuizMode.listenChoose:
        return QuizQuestion(
          id: id,
          vocab: vocab,
          mode: mode,
          options: _options(vocab, rnd, source, (v) => v.term),
          correctAnswer: vocab.term,
        );
      case QuizMode.meaningChoose:
        return QuizQuestion(
          id: id,
          vocab: vocab,
          mode: mode,
          options: _options(vocab, rnd, source, (v) => v.definitionVi),
          correctAnswer: vocab.definitionVi,
        );
      case QuizMode.synonymAntonym:
        return _relationQuestion(id, vocab, rnd);
      case QuizMode.listenType:
      case QuizMode.recallType:
      case QuizMode.pronunciation:
        return QuizQuestion(
          id: id,
          vocab: vocab,
          mode: mode,
          options: const [],
          correctAnswer: vocab.term,
        );
    }
  }

  /// Ghép [vocab] với 1 từ đồng nghĩa hoặc trái nghĩa (chọn ngẫu nhiên nếu có cả hai).
  /// Hai lựa chọn luôn theo thứ tự cố định: A = Đồng nghĩa, B = Trái nghĩa.
  static QuizQuestion _relationQuestion(String id, VocabularyModel vocab, Random rnd) {
    final useSynonym = vocab.antonyms.isEmpty ||
        (vocab.synonyms.isNotEmpty && rnd.nextBool());
    final list = useSynonym ? vocab.synonyms : vocab.antonyms;
    return QuizQuestion(
      id: id,
      vocab: vocab,
      mode: QuizMode.synonymAntonym,
      options: const [AppStrings.relationSynonym, AppStrings.relationAntonym],
      correctAnswer: useSynonym ? AppStrings.relationSynonym : AppStrings.relationAntonym,
      pairWord: list[rnd.nextInt(list.length)],
    );
  }

  /// 1 đáp án đúng + tối đa 3 distractor (ưu tiên cùng từ loại), xáo ngẫu nhiên A/B/C/D.
  static List<String> _options(
    VocabularyModel vocab,
    Random rnd,
    List<VocabularyModel> source,
    String Function(VocabularyModel) pick,
  ) {
    final correct = pick(vocab);
    final others = source
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
