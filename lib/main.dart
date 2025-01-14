import 'package:flutter/material.dart';
import 'package:flutterquiz/app/app.dart';
import 'package:hive_flutter/hive_flutter.dart';


void main() async => runApp(await initializeApp());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter(); // Initialize Hive
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProductListScreen(),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<dynamic> products = [];

  @override
  void initState() {
    super.initState();
    fetchAndStoreProducts();
  }

  Future<void> fetchAndStoreProducts() async {
    final box = await Hive.openBox('productsBox');

    if (box.isEmpty) {
      // Fetch JSON from server
      final response = await Uri.parse('https://yourdomain.com/products.json').readAsString();
      final data = json.decode(response);
      await box.put('products', data); // Save products to Hive
    }

    // Load products from Hive
    setState(() {
      products = box.get('products', defaultValue: []);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Products')),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            title: Text(product['trade_name']),
            subtitle: Text(product['generic_name']),
          );
        },
      ),
    );
  }
}

