import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  final TextEditingController _drugController = TextEditingController();
  List<String> drugNames = [];
  List<String> interactions = [];
  bool isLoading = false;

  Future<String?> getRxCUI(String drugName) async {
    final trimmedName = drugName.trim();
    if (trimmedName.isEmpty) return null;
    
    try {
      final response = await http.get(
        Uri.parse('https://rxnav.nlm.nih.gov/REST/rxcui.json?name=$trimmedName'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final idGroup = data['idGroup'];
        if (idGroup != null && 
            idGroup['rxnormId'] != null && 
            (idGroup['rxnormId'] as List).isNotEmpty) {
          return idGroup['rxnormId'][0];
        }
      }
      return null;
    } catch (e) {
      print('Error fetching RxCUI: $e');
      return null;
    }
  }

  Future<void> checkInteractions() async {
    setState(() {
      isLoading = true;
      interactions.clear();
    });

    try {
      List<String> rxCuis = [];
      List<String> invalidDrugs = [];

      // Get RxCUIs with error tracking
      for (String drug in drugNames) {
        final rxcui = await getRxCUI(drug);
        if (rxcui != null) {
          rxCuis.add(rxcui);
        } else {
          invalidDrugs.add(drug);
        }
      }

      // Show invalid drug warnings
      if (invalidDrugs.isNotEmpty) {
        interactions.add('Warning: Could not find IDs for: ${invalidDrugs.join(', ')}');
      }

      // Validate minimum drug count
      if (rxCuis.length < 2) {
        interactions.add('At least 2 valid drugs required for interaction check');
        return;
      }

      // Check API limits
      if (rxCuis.length > 20) {
        interactions.add('Maximum 20 drugs allowed for interaction check');
        return;
      }

      // Fetch interactions
      final response = await http.get(
        Uri.parse('https://rxnav.nlm.nih.gov/REST/interaction/list.json?rxcuis=${rxCuis.join("+")}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final groups = data['fullInteractionTypeGroup'] as List?;
        
        if (groups != null && groups.isNotEmpty) {
          for (var group in groups.cast<Map<String, dynamic>>()) {
            final types = group['fullInteractionType'] as List?;
            if (types != null) {
              for (var type in types.cast<Map<String, dynamic>>()) {
                final pairs = type['interactionPair'] as List?;
                if (pairs != null) {
                  for (var pair in pairs.cast<Map<String, dynamic>>()) {
                    final desc = pair['description'] as String?;
                    if (desc != null && !interactions.contains(desc)) {
                      interactions.add(desc);
                    }
                  }
                }
              }
            }
          }
        }
        
        if (interactions.isEmpty) {
          interactions.add('No significant interactions found');
        }
      } else {
        interactions.add('Error fetching data (${response.statusCode})');
      }
    } catch (e) {
      interactions.add('Network error: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Drug Interaction Checker")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _drugController,
                    decoration: InputDecoration(
                      labelText: "Enter drug name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final name = _drugController.text.trim();
                    if (name.isNotEmpty) {
                      if (!drugNames.contains(name)) {
                        setState(() {
                          drugNames.add(name);
                          _drugController.clear();
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$name already added')),
                        );
                      }
                    }
                  },
                  child: Text("Add"),
                ),
              ],
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: drugNames.map((drug) => Chip(
                label: Text(drug),
                onDeleted: () => setState(() => drugNames.remove(drug)),
              )).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: drugNames.length >= 2 && !isLoading 
                  ? checkInteractions 
                  : null,
              child: Text("Check Interactions"),
            ),
            SizedBox(height: 20),
            Expanded(
              child: isLoading 
                  ? Center(child: CircularProgressIndicator())
                  : interactions.isEmpty
                      ? Center(child: Text("No results to display"))
                      : ListView.separated(
                          itemCount: interactions.length,
                          separatorBuilder: (_, __) => Divider(height: 1),
                          itemBuilder: (_, i) => ListTile(
                            leading: Icon(Icons.warning, color: Colors.orange),
                            title: Text(interactions[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
