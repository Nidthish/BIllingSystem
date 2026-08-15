class Category {
  final int? categoryId;
  final String categoryName;
  final String? description;

  Category({
    this.categoryId,
    required this.categoryName,
    this.description,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      categoryId: (map['category_id'] as num?)?.toInt(),
      categoryName: map['category_name'] ?? '',
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      'description': description,
    };
  }
}
