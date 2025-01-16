// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_version.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DataVersionAdapter extends TypeAdapter<DataVersion> {
  @override
  final int typeId = 1;

  @override
  DataVersion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DataVersion(
      version: fields[0] as String,
      lastUpdated: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DataVersion obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.version)
      ..writeByte(1)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataVersionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
