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
}
