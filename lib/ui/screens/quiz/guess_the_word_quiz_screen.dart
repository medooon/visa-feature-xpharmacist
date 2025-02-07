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
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final String _apiKey = 'sk-6a9ba7e065a94c58bf6ebf4ad859c7a9';
  bool _isLoading = false;

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    final userMessage = _controller.text;
    _controller.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
      ));
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://api.deepseek.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a medical expert assistant for pharmacists. '
                  'Provide accurate, evidence-based information about medications, '
                  'drug interactions, dosage recommendations, and patient counseling. '
                  'Include references to clinical guidelines when appropriate.'
            },
            {'role': 'user', 'content': userMessage}
          ],
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botResponse = data['choices'][0]['message']['content'];
        
        setState(() {
          _messages.add(ChatMessage(
            text: botResponse,
            isUser: false,
          ));
        });
      } else {
        _showError('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy Medical Assistant'),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _messages[index],
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          _buildInputArea(),
          _buildDisclaimer(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ask about medications, interactions, dosages...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            color: Colors.blue[800],
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Text(
        'Note: This information is for professional reference only. '
        'Always verify with clinical guidelines and use professional judgment.',
        style: TextStyle(color: Colors.grey, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser ? Colors.blue[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.blue[900] : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
