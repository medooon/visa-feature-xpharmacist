import 'package:flutter/material.dart';
import 'package:flutterquiz/app/app.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'local_storage_manager.dart'; // We'll create this in the next step

void main() async => runApp(await initializeApp());

async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await LocalStorageManager.initializeHive();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Your app's root widget
}
