import 'package:hive/hive.dart';

part 'drug.g.dart'; // This will be generated automatically

@HiveType(typeId: 0)
class Drug extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String ke;

  @HiveField(2)
  final String tradeName;

  @HiveField(3)
  final String genericName;

  @HiveField(4)
  final String pharmacology;

  @HiveField(5)
  final String arabicName;

  @HiveField(6)
  final double price;

  @HiveField(7)
  final String company;

  @HiveField(8)
  final String description;

  @HiveField(9)
  final String route;

  @HiveField(10)
  final String temperature;

  @HiveField(11)
  final String otc;

  @HiveField(12)
  final String pharmacy;

  @HiveField(13)
  final String descriptionId;

  @HiveField(14)
  final bool isCalculated;

  Drug({
    required this.id,
    required this.ke,
    required this.tradeName,
    required this.genericName,
    required this.pharmacology,
    required this.arabicName,
    required this.price,
    required this.company,
    required this.description,
    required this.route,
    required this.temperature,
    required this.otc,
    required this.pharmacy,
    required this.descriptionId,
    required this.isCalculated,
  });

  factory Drug.fromJson(Map<String, dynamic> json) {
    return Drug(
      id: json['id'] ?? 'N/A',
      ke: json['ke'] ?? 'N/A',
      tradeName: json['trade_name'] ?? 'N/A',
      genericName: json['generic_name'] ?? 'N/A',
      pharmacology: json['pharmacology'] ?? 'N/A',
      arabicName: json['arabic'] ?? 'N/A',
      price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
      company: json['company'] ?? 'N/A',
      description: json['description'] ?? 'No description available.',
      route: json['route'] ?? 'N/A',
      temperature: json['temperature'] ?? 'N/A',
      otc: json['otc'] ?? 'N/A',
      pharmacy: json['pharmacy'] ?? 'N/A',
      descriptionId: json['description_id'] ?? 'N/A',
      isCalculated: json['is_calculated'] ?? false,
    );
  }
}
