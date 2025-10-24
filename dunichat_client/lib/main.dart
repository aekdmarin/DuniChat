import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const DuniChatApp());

class DuniChatApp extends StatelessWidget {
  const DuniChatApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DuniChat',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class Message {
  final String user;
  final String text;
  final bool mine;
  Message({required this.user, required this.text, required this.mine});
}

class _ChatPageState extends State<ChatPage> {
  late TextEditingController _userC, _roomC, _msgC, _urlC;
  WebSocketChannel? _ch;
  final List<Message> _messages = [];
  final ScrollController _scrollC = ScrollController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _userC = TextEditingController(text: 'david');
    _roomC = TextEditingController(text: 'global');
    _msgC  = TextEditingController();
    _urlC  = TextEditingController(text: 'wss://dunichat.onrender.com/ws');
  }

  @override
  void dispose() {
    _userC.dispose();
    _roomC.dispose();
    _msgC.dispose();
    _urlC.dispose();
    _ch?.sink.close();
    _scrollC.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final room = _roomC.text.trim().isEmpty ? "global" : _roomC.text.trim();
    final url = Uri.parse("https://dunichat.onrender.com/history/=30");

    setState(() {
      _loading = true;
      _messages.clear();
    });

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        for (final msg in data.reversed) {
          final user = msg["user"] ?? "?";
          final text = msg["text"] ?? "";
          _messages.add(Message(user: user, text: text, mine: user == _userC.text));
        }
      }
    } catch (e) {
      _messages.add(Message(user: "⚠️", text: "Error al cargar historial: \", mine: false));
    }

    setState(() => _loading = false);
    _scrollToEnd();
  }

  void _scrollToEnd() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollC.hasClients) {
        _scrollC.jumpTo(_scrollC.position.maxScrollExtent);
      }
    });
  }

  void _connect() async {
    await _loadHistory();
    _ch?.sink.close();
    final uri = Uri.parse(_urlC.text.trim());
    _ch = WebSocketChannel.connect(uri);
    setState(() {});
    _ch!.stream.listen((event) {
      final msg = jsonDecode(event);
      if (msg is Map && msg.containsKey("text")) {
        setState(() {
          _messages.add(Message(
            user: msg["user"] ?? "?",
            text: msg["text"] ?? "",
            mine: msg["user"] == _userC.text,
          ));
        });
        _scrollToEnd();
      }
    }, onDone: () {
      setState(() {
        _messages.add(Message(user: "🔴", text: "Conexión cerrada", mine: false));
      });
    }, onError: (e) {
      setState(() {
        _messages.add(Message(user: "⚠️", text: "Error WS: \", mine: false));
      });
    });

    final hello = jsonEncode({"user": _userC.text, "room": _roomC.text, "text": ""});
    _ch!.sink.add(hello);
  }

  void _send() {
    if (_ch == null) return;
    final msgText = _msgC.text.trim();
    if (msgText.isEmpty) return;
    final msg = jsonEncode({
      "user": _userC.text,
      "room": _roomC.text,
      "text": msgText,
    });
    _ch!.sink.add(msg);
    setState(() {
      _messages.add(Message(user: _userC.text, text: msgText, mine: true));
    });
    _msgC.clear();
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DuniChat 💬')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(children: [
          Row(children: [
            Expanded(child: TextField(controller: _userC, decoration: const InputDecoration(labelText: 'Usuario'))),
            const SizedBox(width: 8),
            SizedBox(width: 140, child: TextField(controller: _roomC, decoration: const InputDecoration(labelText: 'Sala'))),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _connect, child: const Text('Conectar')),
          ]),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollC,
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final m = _messages[i];
                        final align = m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
                        final bgColor = m.mine ? Colors.blue[200] : Colors.grey[300];
                        final txtColor = Colors.black87;
                        return Column(
                          crossAxisAlignment: align,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(": ", style: TextStyle(color: txtColor)),
                            )
                          ],
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _msgC,
                    decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...', border: OutlineInputBorder()))),
            const SizedBox(width: 6),
            FilledButton(onPressed: _send, child: const Text('Enviar')),
          ]),
        ]),
      ),
    );
  }
}
