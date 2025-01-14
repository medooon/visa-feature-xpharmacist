


// lib/main.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'local_storage_manager.dart';
import 'product_service.dart';
import 'product_model.dart';
import 'package:flutterquiz/app/app.dart';

import 'package:flutterquiz/ui/screens/quiz/guess_the_word_quiz_screen.dart'; // We'll create this later

void main() async => runApp(await initializeApp());


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await LocalStorageManager.initializeHive();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Root of your application
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Macy Products',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ProductListScreen(),
    );
  }
}
