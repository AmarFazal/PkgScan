// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manifest.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ManifestAdapter extends TypeAdapter<Manifest> {
  @override
  final int typeId = 0;

  @override
  Manifest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Manifest(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      entities: (fields[3] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Manifest obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.entities);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManifestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
