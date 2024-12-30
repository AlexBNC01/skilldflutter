// container model
class WarehouseContainer {
  final int? id;
  final String name;

  WarehouseContainer({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  static WarehouseContainer fromMap(Map<String, dynamic> map) {
    return WarehouseContainer(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
  }
}