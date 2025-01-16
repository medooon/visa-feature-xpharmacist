// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drug.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DrugAdapter extends TypeAdapter<Drug> {
  @override
  final int typeId = 0;

  @override
  Drug read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Drug(
      tradeName: fields[0] as String,
      genericName: fields[1] as String,
      pharmacology: fields[2] as String,
      arabicName: fields[3] as String,
      price: fields[4] as double,
      company: fields[5] as String,
      description: fields[6] as String,
      route: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Drug obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.tradeName)
      ..writeByte(1)
      ..write(obj.genericName)
      ..writeByte(2)
      ..write(obj.pharmacology)
      ..writeByte(3)
      ..write(obj.arabicName)
      ..writeByte(4)
      ..write(obj.price)
      ..writeByte(5)
      ..write(obj.company)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.route);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrugAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
