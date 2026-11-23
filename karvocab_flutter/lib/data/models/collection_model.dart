/// Model Học phần (Collection) theo cấu trúc Figma & CSDL
class CollectionModel {
  final String id;
  final String title;
  final String description;
  final String category; // 'academic', 'career', 'life', 'travel', 'other'
  final String iconName;
  final int totalWords;

  /// Trình độ CEFR của học phần (A1 … C1), hiển thị ở Màn 05.
  final String level;

  /// Trình độ mặc định khi tạo học phần mới (form Màn 22 chưa có ô chọn trình độ).
  static const String defaultLevel = 'B1';

  /// Chủ đề mặc định khi tạo học phần mà không chọn: "Khác" (khớp BE).
  static const String defaultCategory = 'other';

  const CollectionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.iconName,
    required this.totalWords,
    this.level = defaultLevel,
  });

  CollectionModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? iconName,
    int? totalWords,
    String? level,
  }) {
    return CollectionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      iconName: iconName ?? this.iconName,
      totalWords: totalWords ?? this.totalWords,
      level: level ?? this.level,
    );
  }
}
