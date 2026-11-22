/// Loại từ của một mục từ vựng: giá trị lưu/gửi API ([key]), nhãn đầy đủ để chọn
/// trong form ([label]) và viết tắt hiển thị cạnh từ ([abbr], vd `[n.]`).
///
/// Backend (`backend/prisma/schema.prisma`, enum `PartOfSpeech`) hiện chỉ nhận
/// `noun | verb | adj | adv | idiom`. Các loại còn lại cần BE mở rộng enum trước
/// khi nối API (Sprint 3); key dưới đây giữ đúng tên 5 giá trị cũ để không lệch.
class PartOfSpeech {
  final String key;
  final String label;
  final String abbr;

  const PartOfSpeech(this.key, this.label, this.abbr);

  /// Phần tiếng Việt của nhãn, vd "Tính từ" (hiện trong ô đã chọn ở Màn 09 / 24).
  String get shortLabel => label.split(' (').first;

  static const List<PartOfSpeech> values = [
    PartOfSpeech('noun', 'Danh từ (Noun)', 'n.'),
    PartOfSpeech('verb', 'Động từ (Verb)', 'v.'),
    PartOfSpeech('adj', 'Tính từ (Adjective)', 'adj.'),
    PartOfSpeech('adv', 'Trạng từ (Adverb)', 'adv.'),
    PartOfSpeech('pronoun', 'Đại từ (Pronoun)', 'pron.'),
    PartOfSpeech('preposition', 'Giới từ (Preposition)', 'prep.'),
    PartOfSpeech('conjunction', 'Liên từ (Conjunction)', 'conj.'),
    PartOfSpeech('interjection', 'Thán từ (Interjection)', 'interj.'),
    PartOfSpeech('determiner', 'Từ hạn định (Determiner)', 'det.'),
    PartOfSpeech('phrasal_verb', 'Cụm động từ (Phrasal Verb)', 'phr. v.'),
    PartOfSpeech('idiom', 'Thành ngữ (Idiom)', 'idiom'),
    PartOfSpeech('collocation', 'Cụm từ kết hợp (Collocation)', 'colloc.'),
    PartOfSpeech('phrase', 'Cụm từ (Phrase)', 'phr.'),
  ];

  static const String defaultKey = 'noun';

  /// Tìm theo key; key lạ (vd AI trả về giá trị khác) thì trả null.
  static PartOfSpeech? of(String key) {
    for (final p in values) {
      if (p.key == key) return p;
    }
    return null;
  }

  /// Viết tắt trong ngoặc vuông, vd `[n.]`. Key lạ thì hiện nguyên key.
  static String bracket(String key) => '[${of(key)?.abbr ?? key}]';

  /// Nhãn ngắn tiếng Việt theo khoá API (vd `adj` -> "Tính từ").
  static String shortLabelOf(String key) => of(key)?.shortLabel ?? key;
}
