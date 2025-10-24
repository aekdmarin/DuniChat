import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dunichat_client/chat_page.dart';

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
      final res = await http.post(
        Uri.parse('https://dunichat.onrender.com/login'),
        headers: { 'Content-Type': 'application/json' },
        body: jsonEncode({
          'username': _userC.text.trim(),
          'password': _passC.text.trim(),
        }),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('username', _userC.text.trim());

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ChatPage()),
          );
        }
      } else {
        setState(() { _error = data['error'] ?? 'Error de login'; });
      }
    } catch (e) {
      setState(() { _error = "Error de conexión: $e"; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _signup() async {
    setState(() { _loading = true; _error = null; });

    try {
      final res = await http.post(
        Uri.parse('https://dunichat.onrender.com/signup'),
        headers: { 'Content-Type': 'application/json' },
        body: jsonEncode({
          'username': _userC.text.trim(),
          'password': _passC.text.trim(),
        }),
      );

      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario registrado. Ahora inicia sesión.'))
        );
      } else {
        final data = jsonDecode(res.body);
        setState(() { _error = data['error'] ?? 'Error creando usuario'; });
      }
    } catch (e) {
      setState(() { _error = "Error de conexión: $e"; });
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 70, color: Colors.indigo),
                const SizedBox(height: 16),
                const Text('DuniChat', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                TextField(
                  controller: _userC,
                  decoration: const InputDecoration(labelText: 'Usuario', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passC,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                _loading
                    ? const CircularProgressIndicator()
                    : Column(children: [
                        FilledButton(onPressed: _login, child: const Text('Iniciar sesión')),
                        TextButton(onPressed: _signup, child: const Text('Crear cuenta')),
                      ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
