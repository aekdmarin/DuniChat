import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userC = TextEditingController();
  final _passC = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Dio().post(
        'https://dunichat.onrender.com/login',
        data: {'username': _userC.text, 'password': _passC.text},
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', res.data['token']);
      await prefs.setString('username', _userC.text);
      if (context.mounted) context.go('/chats');
    } catch (e) {
      setState(() { _error = "Error: $e"; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat_bubble_outline, size: 80, color: Color(0xFFFF8746)),
              const SizedBox(height: 16),
              const Text('DuniChat', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(controller: _userC, decoration: const InputDecoration(labelText: 'Usuario')),
              const SizedBox(height: 12),
              TextField(controller: _passC, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña')),
              if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(onPressed: _login, child: const Text('Iniciar sesión')),
              TextButton(onPressed: () => context.go('/signup'), child: const Text('Crear cuenta')),
            ],
          ),
        ),
      ),
    );
  }
}
