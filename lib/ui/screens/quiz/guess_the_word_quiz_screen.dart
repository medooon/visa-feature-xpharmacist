import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutterquiz/models/drug.dart';
import 'package:flutterquiz/services/drug_service.dart';
import 'package:flutterquiz/models/data_version.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';  // Added import


class GuessTheWordQuizScreen extends StatefulWidget {
  const GuessTheWordQuizScreen({Key? key}) : super(key: key);

  static Route route(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => const GuessTheWordQuizScreen(),
      settings: settings,
    );
  }

  @override
  _GuessTheWordQuizScreenState createState() => _GuessTheWordQuizScreenState();
}

class _GuessTheWordQuizScreenState extends State<GuessTheWordQuizScreen> {
  final DrugService _drugService = DrugService();
  List<Drug> allDrugs = [];
  List<Drug> filteredDrugs = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  String errorMessage = '';
  String currentVersion = 'N/A';
  String searchCriteria = 'Trade Name';
  Drug? selectedDrug;
  String? selectedCountry;

  final String versionUrl = 'https://x-pharmacist.com/version.json';

  @override
  void initState() {
    super.initState();
    selectedCountry = 'Egypt'; // Set Egypt as default
    loadDrugs();
    searchController.addListener(_search);
  }

  @override
  void dispose() {
    searchController.removeListener(_search);
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadDrugs() async {
    try {
      bool hasLocalData = await _drugService.hasLocalData();

      if (!hasLocalData) {
        await _drugService.fetchAndStoreDrugs();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data fetched from the server.')),
        );
      }

      setState(() {
        allDrugs = _drugService.getAllDrugs();
        filteredDrugs = [];
        DataVersion? localVersion = _drugService.getLocalVersion();
        currentVersion = localVersion?.version ?? 'Unknown';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load drugs: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      Map<String, dynamic> versionInfo = await fetchVersionInfo();
      String remoteVersion = versionInfo['version'] ?? 'Unknown';

      DataVersion? localVersion = _drugService.getLocalVersion();
      String localVersionStr = localVersion?.version ?? 'Unknown';

      if (_isVersionNewer(remoteVersion, localVersionStr)) {
        await _showUpdateDialog(remoteVersion);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data is already up to date.')),
        );
      }

      setState(() {
        allDrugs = _drugService.getAllDrugs();
        _search();
        DataVersion? localVersion = _drugService.getLocalVersion();
        currentVersion = localVersion?.version ?? 'Unknown';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'No internet connection or there is a problem';
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Future<Map<String, dynamic>> fetchVersionInfo() async {
    try {
      final response = await http.get(Uri.parse(versionUrl));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load version info');
      }
    } catch (e) {
      throw Exception('No internet connection or there is a problem');
    }
  }

  Future<void> _showUpdateDialog(String remoteVersion) async {
    DataVersion? localVersion = _drugService.getLocalVersion();
    String localVersionStr = localVersion?.version ?? 'Unknown';

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Version Available'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Version: $localVersionStr'),
              Text('New Version: $remoteVersion'),
              const SizedBox(height: 10),
              const Text('Updating will take a minute. Do you want to proceed?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _refreshData();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

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

  void _onDrugTap(Drug drug) {
    setState(() {
      selectedDrug = drug;
    });
  }

  void _showSimilarDrugs() {
    if (selectedDrug == null) return;

    List<Drug> similarDrugs = allDrugs
        .where((drug) =>
            drug.genericName.toLowerCase() ==
            selectedDrug!.genericName.toLowerCase())
        .toList();

    if (selectedCountry != null) {
      similarDrugs = similarDrugs.where((drug) {
        List<String> keValues = drug.ke.split(',');
        return selectedCountry == 'Egypt' 
            ? (keValues.contains('1') || keValues.contains('2'))
            : (keValues.contains('1') || keValues.contains('3'));
      }).toList();
    }

    setState(() => filteredDrugs = similarDrugs);
  }

  void _showAlternativeDrugs() {
    if (selectedDrug == null) return;

    List<Drug> alternativeDrugs = allDrugs
        .where((drug) =>
            drug.pharmacology.toLowerCase() ==
            selectedDrug!.pharmacology.toLowerCase())
        .toList();

    if (selectedCountry != null) {
      alternativeDrugs = alternativeDrugs.where((drug) {
        List<String> keValues = drug.ke.split(',');
        return selectedCountry == 'Egypt' 
            ? (keValues.contains('1') || keValues.contains('2'))
            : (keValues.contains('1') || keValues.contains('3'));
      }).toList();
    }

    setState(() => filteredDrugs = alternativeDrugs);
  }

  Future<void> _showDrugImage() async {
    if (selectedDrug == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No drug selected')),
      );
      return;
    }

    final tradeName = selectedDrug!.tradeName ?? 'N/A';
    final googleImagesUrl = 'https://www.google.com/search?tbm=isch&q=$tradeName';

    if (await canLaunchUrl(Uri.parse(googleImagesUrl))) {
      await launchUrl(Uri.parse(googleImagesUrl), mode: LaunchMode.inAppWebView);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $googleImagesUrl')),
      );
    }
  }

  void _onDescriptionButtonClick() {
    if (selectedDrug == null) return;

    if (selectedDrug!.descriptionId.isNotEmpty) {
      Drug? descriptionDrug = allDrugs.firstWhere(
        (drug) => drug.id == selectedDrug!.descriptionId,
        orElse: () => selectedDrug!,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DrugDetailScreen(drug: descriptionDrug),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DrugDetailScreen(drug: selectedDrug!),
        ),
      );
    }
  }

  void _filterByCountry(String country) {
    searchController.clear();
    setState(() {
      selectedCountry = country;
      filteredDrugs = [];
    });
  }

void _search() {
  final query = searchController.text.toLowerCase().trim();

  // Only show results when query has 2+ characters
  if (query.length < 2) {
    setState(() => filteredDrugs = []);
    return;
  }

  // Original search logic below (keep everything else the same)
  String pattern = '^' + query.replaceAll(' ', '.*');  
RegExp regex = RegExp(pattern, caseSensitive: false);
 // String pattern = query.replaceAll(' ', '.*').replaceAll('*', '.*');
 // RegExp regex = RegExp(pattern, caseSensitive: false);

  List<Drug> tempList = allDrugs.where((drug) {
    String fieldToSearch;
    switch (searchCriteria) {
      case 'Generic Name':
        fieldToSearch = drug.genericName.toLowerCase();
        break;
      case 'Pharmacology':
        fieldToSearch = drug.pharmacology.toLowerCase();
        break;
      default:
        fieldToSearch = drug.tradeName.toLowerCase();
    }
    return regex.hasMatch(fieldToSearch);
  }).toList();

  if (selectedCountry != null) {
    tempList = tempList.where((drug) {
      List<String> keValues = drug.ke.split(',');
      return selectedCountry == 'Egypt'
          ? (keValues.contains('1') || keValues.contains('2'))
          : (keValues.contains('1') || keValues.contains('3'));
    }).toList();
  }

  setState(() => filteredDrugs = tempList);
}

  Widget _getOtcIndicator(String otc) {
    if (selectedCountry != 'Saudi') return const SizedBox.shrink();
    if (otc == 'o') return const Text('OTC', style: TextStyle(fontSize: 12, color: Colors.green));
    if (otc == 'p') return const Text('Presc', style: TextStyle(fontSize: 12, color: Colors.red));
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => _filterByCountry('Egypt'),
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedCountry == 'Egypt' ? Colors.green : Colors.grey[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: const Text(
              'Egypt',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => _filterByCountry('Saudi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedCountry == 'Saudi' ? Colors.green : Colors.grey[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: const Text(
              'Saudi',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              onTap: () => searchController.clear(),
                              decoration: InputDecoration(
                                labelText: 'Search',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                  borderSide: const BorderSide(width: 0.5)),
                                filled: true,
                                fillColor: Colors.grey[200],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          DropdownButton<String>(
                            value: searchCriteria,
                            dropdownColor: Colors.grey[100],
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                            ),
                            isExpanded: true,
                            hint: const Row(
                              children: [
                                Icon(Icons.filter_list, size: 20),
                                SizedBox(width: 8),
                                Text('Filter by'),
                              ],
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Trade Name', child: Text('Trade Name')),
                              DropdownMenuItem(value: 'Generic Name', child: Text('Generic Name')),
                              DropdownMenuItem(value: 'Pharmacology', child: Text('Pharmacology')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  searchCriteria = value;
                                  _search();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filteredDrugs.isNotEmpty
                          ? ListView.builder(
                              itemCount: filteredDrugs.length,
                              itemBuilder: (context, index) {
                                final drug = filteredDrugs[index];
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: ListTile(
                                    title: Text(
                                      drug.tradeName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Text(drug.genericName),
                                    trailing: _getOtcIndicator(drug.otc),
                                    onTap: () => _onDrugTap(drug),
                                  ),
                                );
                              },
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                               SvgPicture.asset('assets/images/app_logo.svg', // Updated path
                               height: 66,
                               width: 168,
                                   ),
                                      const SizedBox(height: 20),
                                       const Text(
                               'The First Complete App For Pharmacist',
                                      style: TextStyle(
                                             fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                   color: Colors.blueGrey,
                                ),
                             textAlign: TextAlign.center,
                        ),
                      ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 16.0),
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: selectedDrug != null ? _onDescriptionButtonClick : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedDrug != null ? Colors.blue[800] : Colors.grey,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (selectedDrug != null) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      selectedDrug!.tradeName,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    selectedDrug!.pharmacology,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ] else ...[
                                  const Text(
                                    'Description',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: selectedDrug != null ? _showSimilarDrugs : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[600],
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Similar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: selectedDrug != null ? _showAlternativeDrugs : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Alternative',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: selectedDrug != null ? _showDrugImage : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[600],
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Image',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}


class DrugDetailScreen extends StatelessWidget {
  final Drug drug;

  const DrugDetailScreen({Key? key, required this.drug}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(drug.tradeName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                drug.tradeName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Generic Name:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              Text(
                drug.genericName,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              const Text(
                'Pharmacology:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              Text(
                drug.pharmacology,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              const Text(
                'Company:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              Text(
                drug.company,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              const Text(
                'Route:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              Text(
                drug.route,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              const Text(
                'Description:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 5),
              Text(drug.description, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
