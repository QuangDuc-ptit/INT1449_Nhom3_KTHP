/// Model Học phần (Collection) theo cấu trúc Figma & CSDL
class CollectionModel {
  final String id;
  final String title;
  final String description;
  final String category; // 'academic', 'career', 'life', 'travel'
  final String iconName;
  final int totalWords;

  const CollectionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.iconName,
    required this.totalWords,
  });

  CollectionModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? iconName,
    int? totalWords,
  }) {
    return CollectionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      iconName: iconName ?? this.iconName,
      totalWords: totalWords ?? this.totalWords,
    );
  }
}
