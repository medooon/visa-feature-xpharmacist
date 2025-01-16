// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutterquiz/app/app.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutterquiz/models/drug.dart';
import 'package:flutterquiz/models/data_version.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(DrugAdapter());
  Hive.registerAdapter(DataVersionAdapter());

  // Open Hive boxes
  await Hive.openBox<Drug>('drugsBox');
  await Hive.openBox<DataVersion>('dataVersionBox');

  // Initialize and run the app
  runApp(await initializeApp());
}
