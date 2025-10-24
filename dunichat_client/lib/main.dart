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
  final DateTime ts;
  Message({
    required this.user,
    required this.text,
    required this.mine,
    required this.ts,
  });
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

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Color _avatarColor(String user) {
    final palette = <Color>[
      Colors.indigo, Colors.teal, Colors.orange, Colors.pink, Colors.blueGrey,
      Colors.deepPurple, Colors.cyan, Colors.amber, Colors.lightBlue, Colors.green,
    ];
    int h = 0;
    for (final r in user.codeUnits) { h = (h * 31 + r) & 0x7fffffff; }
    return palette[h % palette.length];
  }

  Future<void> _loadHistory() async {
    final room = _roomC.text.trim().isEmpty ? "global" : _roomC.text.trim();
    final url = Uri.parse("https://dunichat.onrender.com/history/$room?limit=30");

    setState(() {
      _loading = true;
      _messages.clear();
    });

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        for (final msg in data.reversed) {
          final user = (msg["user"] ?? "?").toString();
          final text = (msg["text"] ?? "").toString();
          final dynamic rawTs = msg["ts"];
DateTime ts;
if (rawTs is num) {
  ts = DateTime.fromMillisecondsSinceEpoch(rawTs.toInt());
} else if (rawTs is String) {
  final parsed = int.tryParse(rawTs);
  if (parsed != null) {
    ts = DateTime.fromMillisecondsSinceEpoch(parsed);
  } else {
    ts = DateTime.tryParse(rawTs) ?? DateTime.now();
  }
} else {
  ts = DateTime.now();
}
          _messages.add(Message(
            user: user,
            text: text,
            mine: user == _userC.text,
            ts: ts,
          ));
        }
      } else {
        _messages.add(Message(
          user: "âš ï¸",
          text: "Error cargando historial: ${res.statusCode}",
          mine: false,
          ts: DateTime.now(),
        ));
      }
    } catch (e) {
      _messages.add(Message(
        user: "âš ï¸",
        text: "Error cargando historial: $e",
        mine: false,
        ts: DateTime.now(),
      ));
    }

    setState(() => _loading = false);
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
      try {
        final msg = jsonDecode(event);
        if (msg is Map && msg.containsKey("text")) {
          final user = (msg["user"] ?? "?").toString();
          final text = (msg["text"] ?? "").toString();
          final dynamic rawTs = msg["ts"];
DateTime ts;
if (rawTs is num) {
  ts = DateTime.fromMillisecondsSinceEpoch(rawTs.toInt());
} else if (rawTs is String) {
  final parsed = int.tryParse(rawTs);
  if (parsed != null) {
    ts = DateTime.fromMillisecondsSinceEpoch(parsed);
  } else {
    ts = DateTime.tryParse(rawTs) ?? DateTime.now();
  }
} else {
  ts = DateTime.now();
}
          setState(() {
            _messages.add(Message(
              user: user,
              text: text,
              mine: user == _userC.text,
              ts: ts,
            ));
          });
          _scrollToEnd();
        }
      } catch (_) {
        setState(() {
          _messages.add(Message(
            user: "?",
            text: event.toString(),
            mine: false,
            ts: DateTime.now(),
          ));
        });
        _scrollToEnd();
      }
    }, onDone: () {
      setState(() {
        _messages.add(Message(
          user: "ðŸ”´",
          text: "ConexiÃ³n cerrada",
          mine: false,
          ts: DateTime.now(),
        ));
      });
    }, onError: (e) {
      setState(() {
        _messages.add(Message(
          user: "âš ï¸",
          text: "Error WS: $e",
          mine: false,
          ts: DateTime.now(),
        ));
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
      _messages.add(Message(
        user: _userC.text,
        text: msgText,
        mine: true,
        ts: DateTime.now(),
      ));
    });
    _msgC.clear();
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DuniChat ðŸ’¬')),
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
                        final isMine = m.mine;

                        final bubble = Container(
                          constraints: const BoxConstraints(maxWidth: 320),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isMine ? Colors.blue[200] : Colors.grey[300],
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: Radius.circular(isMine ? 12 : 0),
                              bottomRight: Radius.circular(isMine ? 0 : 12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMine)
                                Text(m.user, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(m.text),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  _fmtTime(m.ts),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.black.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );

                        final avatar = CircleAvatar(
                          radius: 16,
                          backgroundColor: _avatarColor(m.user),
                          child: Text(
                            (m.user.isNotEmpty ? m.user[0].toUpperCase() : '?'),
                            style: const TextStyle(color: Colors.white),
                          ),
                        );

                        return Row(
                          mainAxisAlignment:
                              isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: isMine
                              ? [bubble, const SizedBox(width: 6), avatar]
                              : [avatar, const SizedBox(width: 6), bubble],
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
                  hintText: 'Escribe un mensaje...',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 6),
            FilledButton(onPressed: _send, child: const Text('Enviar')),
          ]),
        ]),
      ),
    );
  }
}

