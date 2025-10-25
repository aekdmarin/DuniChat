import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _userC = TextEditingController();
  final _passC = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _signup() async {
    setState(() { _loading = true; _error = null; });
    try {
      await Dio().post(
        'https://dunichat.onrender.com/signup',
        data: {'username': _userC.text, 'password': _passC.text},
      );
      if (context.mounted) context.go('/login');
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
              const Text('Crear cuenta', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(controller: _userC, decoration: const InputDecoration(labelText: 'Usuario')),
              const SizedBox(height: 12),
              TextField(controller: _passC, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña')),
              if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(onPressed: _signup, child: const Text('Registrarse')),
              TextButton(onPressed: () => context.go('/login'), child: const Text('Volver')),
            ],
          ),
        ),
      ),
    );
  }
}
