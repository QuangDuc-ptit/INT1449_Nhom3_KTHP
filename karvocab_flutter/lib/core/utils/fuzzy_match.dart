import '../../data/models/quiz_models.dart';

final RegExp _whitespace = RegExp(r'\s+');

/// Chuẩn hoá chuỗi như BE (`grading.ts`): trim, gộp khoảng trắng liên tiếp
/// thành một dấu cách, lowercase. BE còn chuẩn hoá Unicode NFC; Dart core không
/// có sẵn NFC, nhưng đáp án gõ là từ tiếng Anh nên không ảnh hưởng.
String normalizeAnswer(String input) =>
    input.trim().replaceAll(_whitespace, ' ').toLowerCase();

/// Khoảng cách Levenshtein giữa 2 chuỗi.
int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final curr = List<int>.filled(b.length + 1, 0);
    curr[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      final deletion = prev[j] + 1;
      final insertion = curr[j - 1] + 1;
      final substitution = prev[j - 1] + cost;
      var best = deletion < insertion ? deletion : insertion;
      if (substitution < best) best = substitution;
      curr[j] = best;
    }
    prev = curr;
  }
  return prev[b.length];
}

/// Chấm đáp án gõ chữ:
/// - Khớp tuyệt đối sau chuẩn hoá → correct
/// - Từ từ 3 ký tự trở lên và sai đúng 1 ký tự → almost ("Suýt đúng!"), khớp quy tắc chấm của BE
/// - Còn lại → wrong
AnswerResult evaluateTypedAnswer(String userInput, String correctTerm) {
  final user = normalizeAnswer(userInput);
  final correct = normalizeAnswer(correctTerm);
  if (user.isEmpty) return AnswerResult.wrong;
  if (user == correct) return AnswerResult.correct;
  if (correct.length >= 3 && levenshtein(user, correct) == 1) {
    return AnswerResult.almost;
  }
  return AnswerResult.wrong;
}
