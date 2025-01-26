import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:flutterquiz/models/drug.dart';
import 'package:flutterquiz/models/data_version.dart';
import 'package:excel/excel.dart';

class DrugService {
  // Replace with your actual XLSX URL
  final String dataUrl = 'https://egypt.moazpharmacy.com/products.xlsx';

  // Fetch drug data from the server
  Future<Map<String, dynamic>> fetchRawDrugData() async {
    final response = await http.get(Uri.parse(dataUrl));

    if (response.statusCode == 200) {
      Uint8List bytes = response.bodyBytes;
      var excel = Excel.decodeBytes(bytes);

      // Initialize a map to store data from all sheets
      Map<String, dynamic> rawData = {
        'drugs': [],
        'version': '0.0.0', // Default version
        'last_updated': DateTime.now().toUtc().toIso8601String(), // Default date
      };

      // Parse metadata sheet
      var metadataSheet = excel.tables['metadata'];
      if (metadataSheet != null) {
        for (var row in metadataSheet.rows) {
          if (row[0]?.value == null) continue; // Skip header row
          String key = row[0]?.value.toString() ?? '';
          String value = row[1]?.value.toString() ?? '';
          if (key == 'version') {
            rawData['version'] = value;
          } else if (key == 'last_updated') {
            rawData['last_updated'] = value;
          }
        }
      }

      // Parse drugs sheet (egy)
      var drugsSheet = excel.tables['egy'];
      if (drugsSheet != null) {
        for (var row in drugsSheet.rows) {
          if (row[0]?.value == null) continue; // Skip header row
          rawData['drugs'].add({
            'id': row[0]?.value.toString() ?? '',
            'ke': row[1]?.value.toString() ?? '',
            'trade_name': row[2]?.value.toString() ?? '',
            'generic_name': row[3]?.value.toString() ?? '',
            'pharmacology': row[4]?.value.toString() ?? '',
            'arabic': row[5]?.value.toString() ?? '',
            'price': row[6]?.value ?? 0.0,
            'company': row[7]?.value.toString() ?? '',
            'description': row[8]?.value.toString() ?? '',
            'route': row[9]?.value.toString() ?? '',
            'temperature': row[10]?.value.toString() ?? '',
            'otc': row[11]?.value.toString() ?? '',
            'pharmacy': row[12]?.value.toString() ?? '',
            'description_id': row[13]?.value.toString() ?? '',
            'is_calculated': row[14]?.value == 1, // Assuming 1 for true, 0 for false
          });
        }
      }

      return rawData;
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

  // Check if local data exists
  Future<bool> hasLocalData() async {
    var drugsBox = Hive.box<Drug>('drugsBox');
    var versionBox = Hive.box<DataVersion>('dataVersionBox');

    // Check if both boxes are not empty
    return drugsBox.isNotEmpty && versionBox.isNotEmpty;
  }
}
