// lib/models/drug.dart

import 'package:hive/hive.dart';

part 'drug.g.dart'; // This will be generated automatically

@HiveType(typeId: 0)
class Drug extends HiveObject {
  @HiveField(0)
  final String tradeName;

  @HiveField(1)
  final String genericName;

  @HiveField(2)
  final String pharmacology;

  @HiveField(3)
  final String arabicName;

  @HiveField(4)
  final double price;

  @HiveField(5)
  final String company;

  @HiveField(6)
  final String description;

  @HiveField(7)
  final String route;

  Drug({
    required this.tradeName,
    required this.genericName,
    required this.pharmacology,
    required this.arabicName,
    required this.price,
    required this.company,
    required this.description,
    required this.route,
  });

factory Drug.fromJson(Map<String, dynamic> json) {
  return Drug(
    tradeName: json['trade_name'] ?? 'N/A',
    genericName: json['generic_name'] ?? 'N/A',
    pharmacology: json['pharmacology'] ?? 'N/A',
    arabicName: json['arabic_name'] ?? 'N/A',
    price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
    company: json['company'] ?? 'N/A',
    description: json['description'] ?? 'No description available.',
    route: json['route'] ?? 'N/A',
  );
}

