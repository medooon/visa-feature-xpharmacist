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
      id: fields[0] as String,
      ke: fields[1] as String,
      tradeName: fields[2] as String,
      genericName: fields[3] as String,
      pharmacology: fields[4] as String,
      arabicName: fields[5] as String,
      price: fields[6] as double,
      company: fields[7] as String,
      description: fields[8] as String,
      route: fields[9] as String,
      temperature: fields[10] as String,
      otc: fields[11] as String,
      pharmacy: fields[12] as String,
      descriptionId: fields[13] as String,
      isCalculated: fields[14] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Drug obj) {
    writer
      ..writeByte(15) // Number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.ke)
      ..writeByte(2)
      ..write(obj.tradeName)
      ..writeByte(3)
      ..write(obj.genericName)
      ..writeByte(4)
      ..write(obj.pharmacology)
      ..writeByte(5)
      ..write(obj.arabicName)
      ..writeByte(6)
      ..write(obj.price)
      ..writeByte(7)
      ..write(obj.company)
      ..writeByte(8)
      ..write(obj.description)
      ..writeByte(9)
      ..write(obj.route)
      ..writeByte(10)
      ..write(obj.temperature)
      ..writeByte(11)
      ..write(obj.otc)
      ..writeByte(12)
      ..write(obj.pharmacy)
      ..writeByte(13)
      ..write(obj.descriptionId)
      ..writeByte(14)
      ..write(obj.isCalculated);
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
