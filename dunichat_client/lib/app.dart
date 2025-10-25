import 'package:flutter/material.dart';
import 'core/routes.dart';

class DuniChatApp extends StatelessWidget {
  const DuniChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DuniChat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFFFF0E4),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF8746)),
      ),
      onGenerateRoute: AppRoutes.generateRoute,
      initialRoute: AppRoutes.login,
    );
  }
}
