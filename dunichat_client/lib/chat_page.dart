import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _msgC = TextEditingController();
  final ScrollController _scrollC = ScrollController();
  final List<_ChatMsg> _messages = [];
  WebSocketChannel? _ch;
  bool _loading = false;

  String _username = 'anon';
  String _token = '';
  String _room = 'global';

  @override
  void initState() {
    super.initState();
    _initAndConnect();
  }

  @override
  void dispose() {
    _ch?.sink.close();
    _msgC.dispose();
    _scrollC.dispose();
    super.dispose();
  }

  Future<void> _initAndConnect() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username') ?? 'anon';
    _token    = prefs.getString('token') ?? '';

    await _loadHistory();
    await _connectWS();

    setState(() => _loading = false);
  }

  Future<void> _loadHistory() async {
    try {
      final url = Uri.parse("https://dunichat.onrender.com/history/$_room?limit=30");
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
            ts = parsed != null
                ? DateTime.fromMillisecondsSinceEpoch(parsed)
                : (DateTime.tryParse(rawTs) ?? DateTime.now());
          } else {
            ts = DateTime.now();
          }
          _messages.add(_ChatMsg(user: user, text: text, mine: user == _username, ts: ts));
        }
      } else {
        _messages.add(_ChatMsg(user: "⚠️", text: "Error historial: ${res.statusCode}", mine: false, ts: DateTime.now()));
      }
    } catch (e) {
      _messages.add(_ChatMsg(user: "⚠️", text: "Error historial: $e", mine: false, ts: DateTime.now()));
    }
    _scrollToEnd();
    setState(() {});
  }

  Future<void> _connectWS() async {
    final uri = Uri.parse('wss://dunichat.onrender.com/ws');
    _ch = WebSocketChannel.connect(uri);

    // handshake con token/usuario/sala
    _ch!.sink.add(jsonEncode({'token': _token, 'user': _username, 'room': _room, 'text': ''}));

    _ch!.stream.listen((event) {
      try {
        final msg = jsonDecode(event);
        final user = (msg['user'] ?? '?').toString();
        final text = (msg['text'] ?? '').toString();
        final tsRaw = msg['ts'];
        DateTime ts;
        if (tsRaw is num) {
          ts = DateTime.fromMillisecondsSinceEpoch(tsRaw.toInt());
        } else if (tsRaw is String) {
          final parsed = int.tryParse(tsRaw);
          ts = parsed != null
              ? DateTime.fromMillisecondsSinceEpoch(parsed)
              : (DateTime.tryParse(tsRaw) ?? DateTime.now());
        } else {
          ts = DateTime.now();
        }
        setState(() {
          _messages.add(_ChatMsg(user: user, text: text, mine: user == _username, ts: ts));
        });
        _scrollToEnd();
      } catch (_) {
        setState(() {
          _messages.add(_ChatMsg(user: "?", text: event.toString(), mine: false, ts: DateTime.now()));
        });
        _scrollToEnd();
      }
    }, onDone: () {
      setState(() {
        _messages.add(_ChatMsg(user: "🔴", text: "Conexión cerrada", mine: false, ts: DateTime.now()));
      });
    }, onError: (e) {
      setState(() {
        _messages.add(_ChatMsg(user: "⚠️", text: "Error WS: $e", mine: false, ts: DateTime.now()));
      });
    });
  }

  void _send() {
    if (_ch == null) return;
    final text = _msgC.text.trim();
    if (text.isEmpty) return;
    final msg = jsonEncode({'token': _token, 'user': _username, 'room': _room, 'text': text});
    _ch!.sink.add(msg);
    setState(() {
      _messages.add(_ChatMsg(user: _username, text: text, mine: true, ts: DateTime.now()));
    });
    _msgC.clear();
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollC.hasClients) {
        _scrollC.jumpTo(_scrollC.position.maxScrollExtent);
      }
    });
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Color _avatarColor(String user) {
    final palette = <Color>[
      Colors.indigo, Colors.teal, Colors.orange, Colors.pink, Colors.blueGrey,
      Colors.deepPurple, Colors.cyan, Colors.amber, Colors.lightBlue, Colors.green,
    ];
    int h = 0; for (final r in user.codeUnits) { h = (h * 31 + r) & 0x7fffffff; }
    return palette[h % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('DuniChat - $_username')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollC,
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
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
                                style: TextStyle(fontSize: 10, color: Colors.black.withOpacity(0.6)),
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
                        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: isMine
                            ? [bubble, const SizedBox(width: 6), avatar]
                            : [avatar, const SizedBox(width: 6), bubble],
                      );
                    },
                  ),
          ),
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

class _ChatMsg {
  final String user;
  final String text;
  final bool mine;
  final DateTime ts;
  _ChatMsg({required this.user, required this.text, required this.mine, required this.ts});
}
