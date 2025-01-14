import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class GuessTheWordQuizScreen extends StatefulWidget {
  const GuessTheWordQuizScreen({Key? key}) : super(key: key);

  /// If you need a static route to use in your routes.dart or similar:
  static Route route(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => const GuessTheWordQuizScreen(),
      settings: settings,
    );
  }

  @override
  State<GuessTheWordQuizScreen> createState() => _GuessTheWordQuizScreenState();
}

class _GuessTheWordQuizScreenState extends State<GuessTheWordQuizScreen> {
  // URL of your JSON file
  final String _jsonUrl = 'https://x-pharmacist.com/Drug.json';

  // All drugs loaded from the server
  List<dynamic> _allDrugs = [];
  // Filtered drugs based on the current search or "similar"
  List<dynamic> _filteredDrugs = [];

  // The current search text
  String _searchQuery = '';

  // By default, we search "tradeName"; toggle can switch to "genericName"
  String _searchField = 'tradeName';

  // The drug the user has selected (for "Similar" & "Image" buttons)
  Map<String, dynamic>? _selectedDrug;

  @override
  void initState() {
    super.initState();
    _fetchDrugs();
  }

  /// Fetch the list of drugs from the server
  Future<void> _fetchDrugs() async {
    try {
      final response = await http.get(Uri.parse(_jsonUrl));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          _allDrugs = jsonData;
          // Don't show any results until user searches
          _filteredDrugs = [];
        });
      } else {
        throw Exception('Failed to load data from $_jsonUrl');
      }
    } catch (e) {
      debugPrint('Error fetching drug list: $e');
    }
  }

  /// Called whenever the user types something in the search bar
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterDrugs(query);
  }

  /// Toggle between searching by tradeName or genericName
  void _toggleSearchField() {
    setState(() {
      if (_searchField == 'tradeName') {
        _searchField = 'genericName';
      } else {
        _searchField = 'tradeName';
      }
    });
    _filterDrugs(_searchQuery);
  }

  /// The core filtering logic:
  void _filterDrugs(String query) {
    if (query.isEmpty) {
      setState(() => _filteredDrugs = []);
      return;
    }

    final lowerQuery = query.toLowerCase();
    final hasWildcard =
        lowerQuery.contains('*') ||
        lowerQuery.contains('.') ||
        lowerQuery.contains(' ');

    final results = _allDrugs.where((drug) {
      final fieldValue = (drug[_searchField] ?? '').toString().toLowerCase();

      if (hasWildcard) {
        String pattern = RegExp.escape(lowerQuery)
            .replaceAll(r'\*', '.*')
            .replaceAll(r'\ ', '.*');
        final regExp = RegExp(pattern, caseSensitive: false);
        return regExp.hasMatch(fieldValue);
      } else {
        return fieldValue.startsWith(lowerQuery);
      }
    }).toList();

    setState(() => _filteredDrugs = results);
  }

  /// Called when user taps on a drug in the list
  void _onDrugSelected(Map<String, dynamic> drug) {
    setState(() {
      _selectedDrug = drug;
    });
  }

  /// Show similar drugs (same genericName) if a drug is selected
  void _onSimilarPressed() {
    if (_selectedDrug == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No drug selected')),
      );
      return;
    }

    final selectedGeneric =
        (_selectedDrug!['genericName'] ?? '').toString().toLowerCase();

    final similarDrugs = _allDrugs.where((drug) {
      final genericName =
          (drug['genericName'] ?? '').toString().toLowerCase();
      return genericName == selectedGeneric;
    }).toList();

    setState(() => _filteredDrugs = similarDrugs);
  }

  /// Show Google Images (in-app) if a drug is selected
  Future<void> _onImagePressed() async {
    if (_selectedDrug == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No drug selected')),
      );
      return;
    }

    final tradeName = _selectedDrug!['tradeName'] ?? 'N/A';
    final googleImagesUrl = 'https://www.google.com/search?tbm=isch&q=$tradeName';

    // Launch in an in-app WebView
    if (await canLaunchUrl(Uri.parse(googleImagesUrl))) {
      await launchUrl(Uri.parse(googleImagesUrl),
          mode: LaunchMode.inAppWebView);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch $googleImagesUrl'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colors for styling
    final cardBackgroundColor = Colors.blue.shade700;
    // 1) Make trade name font orange-yellow color (and bold)
    final tradeNameStyle = const TextStyle(
      color: Color(0xFFFFCC00), // example orange-yellow
      fontWeight: FontWeight.bold,
    );
    // Keep other styles
    final genericNameStyle = const TextStyle(color: Colors.white);
    final priceStyle = const TextStyle(color: Colors.white);

    return Scaffold(
      // 2) Remove "X Pharmacist" from the screen bar
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Saudi Drug Index',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Row: search bar + toggle button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Expanded search bar
                Expanded(
                  child: TextField(
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText:
                          'Search by ${_searchField == "tradeName" ? "Trade Name" : "Generic Name"}...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Toggle button
                ElevatedButton(
                  onPressed: _toggleSearchField,
                  child: Text(
                    _searchField == 'tradeName'
                        ? 'Switch to Generic'
                        : 'Switch to Trade',
                  ),
                ),
              ],
            ),
          ),

          // Expanded list of search results
          Expanded(
            child: _filteredDrugs.isEmpty
                ? const Center(
                    child: Text('No drugs to show. Type something to search.'),
                  )
                : ListView.builder(
                    itemCount: _filteredDrugs.length,
                    itemBuilder: (context, index) {
                      final drug = _filteredDrugs[index];
                      final tradeName = (drug['tradeName'] ?? '').toString();
                      final genericName =
                          (drug['genericName'] ?? '').toString();

                      // 3) Instead of showing price, show "OTC" or "Presc"
                      //    based on drug['num'] == 1 or 0
                      final numVal = drug['num'];
                      String trailingText = '';
                      if (numVal == 1) {
                        trailingText = 'OTC';
                      } else if (numVal == 0) {
                        trailingText = 'Presc';
                      }

                      return Card(
                        color: cardBackgroundColor,
                        child: ListTile(
                          title: Text(tradeName, style: tradeNameStyle),
                          subtitle: Text(genericName, style: genericNameStyle),
                          trailing: Text(trailingText, style: priceStyle),
                          onTap: () => _onDrugSelected(drug),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom bar with 3 buttons (unchanged except for final color edits from previous steps)
          Container(
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Column(
              children: [
                // Full-width description button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      foregroundColor: Colors.orange, // orange text
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // Add any action if needed
                    },
                    child: Text(
                      _selectedDrug != null
                          ? (_selectedDrug!['tradeName'] ?? '')
                          : '',
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Row with 2 buttons side by side
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _onSimilarPressed,
                        child: const Text('Similar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _onImagePressed,
                        child: const Text('Image'),
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
