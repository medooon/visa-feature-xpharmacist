// lib/services/drug_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:flutterquiz/models/drug.dart';

class DrugService {
  // Replace with your actual JSON URL
  final String dataUrl = 'https://egypt.moazpharmacy.com/products.json';

  // Fetch drug data from the server
  Future<Map<String, dynamic>> fetchRawDrugData() async {
    final response = await http.get(Uri.parse(dataUrl));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load drug data');
    }
  }

  // Store drug data locally using Hive
  Future<void> storeDrugData(List<Drug> drugs, String version, DateTime lastUpdated) async {
    var drugsBox = Hive.box<Drug>('drugsBox');
    var versionBox = Hive.box<DataVersion>('dataVersionBox');

    await drugsBox.clear(); // Clear existing data
    await drugsBox.addAll(drugs);

    // Store version info
    await versionBox.clear();
    await versionBox.add(DataVersion(version: version, lastUpdated: lastUpdated));
  }

  // Combined method to fetch and store data with versioning
  Future<void> fetchAndStoreDrugs() async {
    try {
      Map<String, dynamic> rawData = await fetchRawDrugData();

      String version = rawData['version'] ?? '0.0.0';
      String lastUpdatedStr = rawData['last_updated'] ?? DateTime.now().toUtc().toIso8601String();
      DateTime lastUpdated = DateTime.parse(lastUpdatedStr);

      List<dynamic> drugsJson = rawData['drugs'] ?? [];
      List<Drug> drugs = drugsJson.map((item) => Drug.fromJson(item)).toList();

      await storeDrugData(drugs, version, lastUpdated);
    } catch (e) {
      print('Error fetching and storing drugs: $e');
      rethrow;
    }
  }

  // Retrieve all drugs from local storage
  List<Drug> getAllDrugs() {
    var box = Hive.box<Drug>('drugsBox');
    return box.values.toList();
  }

  // Get current local version
  DataVersion? getLocalVersion() {
    var box = Hive.box<DataVersion>('dataVersionBox');
    return box.isNotEmpty ? box.getAt(0) : null;
  }

  // Check if remote version is newer than local
  Future<bool> isRemoteDataNewer() async {
    try {
      Map<String, dynamic> rawData = await fetchRawDrugData();

      String remoteVersion = rawData['version'] ?? '0.0.0';

      DataVersion? localVersion = getLocalVersion();
      String localVersionStr = localVersion?.version ?? '0.0.0';

      return _isVersionNewer(remoteVersion, localVersionStr);
    } catch (e) {
      print('Error checking data version: $e');
      return false; // Assume no update if there's an error
    }
  }

  // Helper method to compare semantic versions
  bool _isVersionNewer(String remote, String local) {
    List<int> remoteParts = remote.split('.').map(int.parse).toList();
    List<int> localParts = local.split('.').map(int.parse).toList();

    for (int i = 0; i < remoteParts.length; i++) {
      if (i >= localParts.length) return true;
      if (remoteParts[i] > localParts[i]) return true;
      if (remoteParts[i] < localParts[i]) return false;
    }
    return false;
  }
}
