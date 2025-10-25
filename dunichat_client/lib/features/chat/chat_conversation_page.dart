import "dart:convert";
import "package:flutter/material.dart";
import "package:web_socket_channel/web_socket_channel.dart";
import "package:web_socket_channel/status.dart" as status;

class ChatConversationPage extends StatefulWidget {
  final String room;
  const ChatConversationPage({super.key, required this.room});

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  late WebSocketChannel channel;
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  String username = "user_${DateTime.now().millisecondsSinceEpoch}";

  @override
  void initState() {
    super.initState();
    channel = WebSocketChannel.connect(Uri.parse("wss://dunichat.onrender.com/ws"));
    channel.stream.listen((data) {
      final msg = jsonDecode(data);
      setState(() {
        _messages.add({
          "text": msg["text"],
          "isMine": msg["sender"] == username,
          "time": DateTime.parse(msg["timestamp"] ?? DateTime.now().toString()),
        });
      });
    });
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final msg = {
      "sender": username,
      "room": widget.room,
      "text": text,
    };
    channel.sink.add(jsonEncode(msg));
    _controller.clear();
  }

  @override
  void dispose() {
    channel.sink.close(status.goingAway);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat - ${widget.room}"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg["isMine"]
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: msg["isMine"]
                          ? Colors.orangeAccent.withOpacity(0.8)
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(msg["text"]),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Escribe un mensaje...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepOrange),
                  onPressed: _handleSend,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
