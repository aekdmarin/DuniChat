import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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

class _ChatPageState extends State<ChatPage> {
  late TextEditingController _userC, _roomC, _msgC, _urlC;
  WebSocketChannel? _ch;
  final List<String> _log = [];

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
    super.dispose();
  }

  void _connect() {
    _ch?.sink.close();
    final uri = Uri.parse(_urlC.text.trim());
    _ch = WebSocketChannel.connect(uri);
    setState(() => _log.add('🟢 Conectando a $uri ...'));
    _ch!.stream.listen((event) {
      setState(() => _log.add('📩 $event'));
    }, onDone: () {
      setState(() => _log.add('🔴 Conexión cerrada'));
    }, onError: (e) {
      setState(() => _log.add('⚠️ Error: $e'));
    });

    final hello = jsonEncode({"user": _userC.text, "room": _roomC.text, "text": ""});
    _ch!.sink.add(hello);
  }

  void _send() {
    if (_ch == null) return;
    final msg = jsonEncode({
      "user": _userC.text,
      "room": _roomC.text,
      "text": _msgC.text,
    });
    _ch!.sink.add(msg);
    setState(() => _log.add('📤 ${_msgC.text}'));
    _msgC.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DuniChat (Flutter)')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          TextField(controller: _urlC, decoration: const InputDecoration(labelText: 'WS URL (wss://...)')),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8)),
              child: ListView.builder(
                itemCount: _log.length,
                itemBuilder: (_, i) => Text(_log[i]),
              ),
            ),
          ),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _msgC,
                    decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...'))),
            const SizedBox(width: 8),
            FilledButton(onPressed: _send, child: const Text('Enviar')),
          ]),
        ]),
      ),
    );
  }
}
