import 'package:hive/hive.dart';

part 'manifest.g.dart';

@HiveType(typeId: 0)
class Manifest {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final List<String> entities; // Rastgele ID'lerden oluşan liste

  Manifest({
    required this.id,
    required this.name,
    required this.description,
    required this.entities,
  });

  /// Manifest nesnesini Map<String, dynamic> formatına çevirir.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'entities': entities,
    };
  }

  /// Map<String, dynamic> formatından Manifest nesnesi oluşturur.
  factory Manifest.fromMap(Map<String, dynamic> map) {
    return Manifest(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      entities: List<String>.from(map['entities'] ?? []),
    );
  }
}
