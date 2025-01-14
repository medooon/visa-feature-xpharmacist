// lib/models/product_model.dart

class Product {
  final int id;
  final String tradeName;
  final String genericName;
  final String pharmacology;
  final String arabicName;
  final double price;
  final String company;
  final String description;
  final String route;

  Product({
    required this.id,
    required this.tradeName,
    required this.genericName,
    required this.pharmacology,
    required this.arabicName,
    required this.price,
    required this.company,
    required this.description,
    required this.route,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      tradeName: json['trade_name'],
      genericName: json['generic_name'],
      pharmacology: json['pharmacology'],
      arabicName: json['arabic_name'],
      price: (json['price'] as num).toDouble(),
      company: json['company'],
      description: json['description'],
      route: json['route'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trade_name': tradeName,
      'generic_name': genericName,
      'pharmacology': pharmacology,
      'arabic_name': arabicName,
      'price': price,
      'company': company,
      'description': description,
      'route': route,
    };
  }
}
