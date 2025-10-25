import 'package:flutter/material.dart';
import 'package:dunichat_client/login.dart';
import 'package:dunichat_client/signup.dart';
import 'package:dunichat_client/features/chat/chat_conversation_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String chat = '/chat';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupPage());
      case chat:
        final args = settings.arguments as Map<String, dynamic>?;
        final room = args?['room'] ?? 'default';
        return MaterialPageRoute(
          builder: (_) => ChatConversationPage(room: room),
        );
      default:
        return MaterialPageRoute(builder: (_) => const LoginPage());
    }
  }
}
