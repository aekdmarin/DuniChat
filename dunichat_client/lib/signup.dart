import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _userC = TextEditingController();
  final _passC = TextEditingController();
  bool _loading = false;
  String? _msg;

  Future<void> _signup() async {
    setState(() {
      _loading = true;
      _msg = null;
    });

    try {
      final res = await http.post(
        Uri.parse('https://dunichat.onrender.com/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _userC.text.trim(),
          'password': _passC.text.trim(),
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        setState(() {
          _msg = "✅ Usuario registrado correctamente";
        });
      } else {
        setState(() {
          _msg = "⚠️ ${data['error'] ?? 'Error creando usuario'}";
        });
      }
    } catch (e) {
      setState(() {
        _msg = "❌ Error de conexión: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear cuenta"),
        backgroundColor: Colors.indigo,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add_alt, size: 70, color: Colors.indigo),
                const SizedBox(height: 20),
                TextField(
                  controller: _userC,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passC,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                if (_msg != null)
                  Text(
                    _msg!,
                    style: TextStyle(
                      color: _msg!.startsWith('✅') ? Colors.green : Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 16),
                _loading
                    ? const CircularProgressIndicator()
                    : Column(
                        children: [
                          FilledButton(
                            onPressed: _signup,
                            child: const Text('Registrar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Volver al inicio de sesión'),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
