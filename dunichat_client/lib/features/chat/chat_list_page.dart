import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("DuniChat")),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text("Global"),
            subtitle: const Text("Sala pública"),
            onTap: () => context.go("/chat/global"),
          ),
        ],
      ),
    );
  }
}
