//Category
class Category {
  final int? id;
  final String name;
  final int? parentId;

  Category({this.id, required this.name, this.parentId});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
    };
  }

  static Category fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      parentId: map['parent_id'] as int?,
    );
  }
}