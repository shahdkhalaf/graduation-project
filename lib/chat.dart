// lib/chat.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatAssistScreen extends StatefulWidget {
  const ChatAssistScreen({Key? key}) : super(key: key);

  @override
  _ChatAssistScreenState createState() => _ChatAssistScreenState();
}

class _ChatAssistScreenState extends State<ChatAssistScreen> {
  final List<ChatMessage> _messages = [
    ChatMessage(text: "Hello! How can I help you today?", isUser: false),
  ];
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  static const String _chatbotBaseUrl =
      "https://1aad-156-212-124-122.ngrok-free.app/api/query";
  static const String _chatPath = "/api/query";

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isSending = true;
      _controller.clear();
    });

    try {
      // builds: https://4001-156-212-124-122.ngrok-free.app/api/query
      final uri = Uri.parse(_chatbotBaseUrl);
      final payload = {"question": text};

      print("📤 Sending POST to $uri");
      print("📝 Payload: ${jsonEncode(payload)}");

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      print("📥 Status Code: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final bodyJson = jsonDecode(response.body) as Map<String, dynamic>;
        final botReply = bodyJson["answer"]?.toString() ??
            "Sorry, I didn’t see an answer field.";
        setState(() {
          _messages.add(ChatMessage(text: botReply, isUser: false));
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(
            text: "Error: chatbot responded with ${response.statusCode}",
            isUser: false,
          ));
        });
      }
    } catch (e) {
      print("❌ Exception while calling chatbot: $e");
      setState(() {
        _messages.add(ChatMessage(
          text: "Oops—couldn’t reach the chatbot. Please try again.",
          isUser: false,
        ));
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF175579),
              child: Image.asset(
                'assets/img_1.png',
                width: 32,
                height: 32,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "SALKAH Assist",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Conversation bubbles ──
            Expanded(
              child: ListView.builder(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: _buildChatBubble(msg),
                  );
                },
              ),
            ),

            // ── Quick suggestions ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildQuickSuggestion("Suggest a route"),
                  const SizedBox(width: 8),
                  _buildQuickSuggestion("Trending topics"),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Input + Send ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Message SALKAHAssist…",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _isSending ? null : _sendMessage,
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: _isSending
                          ? Colors.grey.shade300
                          : const Color(0xFF175579),
                      child: Icon(
                        _isSending ? Icons.hourglass_empty : Icons.send,
                        color: _isSending ? Colors.grey : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    final bubbleColor =
    msg.isUser ? const Color(0xFF175579) : Colors.grey.shade200;
    final textColor = msg.isUser ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(maxWidth: 250),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        msg.text,
        style: TextStyle(color: textColor),
      ),
    );
  }

  Widget _buildQuickSuggestion(String label) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: () => _controller.text = label,
      child: Text(label, style: const TextStyle(color: Colors.black)),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}
