import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMine;
  final DateTime? timestamp;

  const MessageBubble({
    super.key,
    required this.text,
    this.isMine = false,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isMine
        ? const Color(0xFFFFD1A9) // Mensaje propio (durazno)
        : Colors.white.withOpacity(0.8); // Mensaje recibido (blanco cálido)

    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final borderRadius = isMine
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF6B3A28),
              fontSize: 15,
              height: 1.3,
            ),
          ),
        ),
        if (timestamp != null)
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 16),
            child: Text(
              "${timestamp!.hour.toString().padLeft(2, '0')}:${timestamp!.minute.toString().padLeft(2, '0')}",
              style: TextStyle(
                fontSize: 11,
                color: Colors.brown.withOpacity(0.5),
              ),
            ),
          ),
      ],
    );
  }
}
