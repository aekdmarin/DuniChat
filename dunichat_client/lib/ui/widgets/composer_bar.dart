import 'package:flutter/material.dart';

class ComposerBar extends StatefulWidget {
  final void Function(String) onSend;

  const ComposerBar({super.key, required this.onSend});

  @override
  State<ComposerBar> createState() => _ComposerBarState();
}

class _ComposerBarState extends State<ComposerBar> {
  final _controller = TextEditingController();

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Escribe un mensaje...",
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded, color: Color(0xFFFF8746)),
            onPressed: _handleSend,
          ),
        ],
      ),
    );
  }
}
