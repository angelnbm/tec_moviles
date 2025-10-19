import 'package:flutter/material.dart';
import 'package:namer_app/pages/main_page.dart';
import 'package:namer_app/pages/registration_form_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginFormPage extends StatefulWidget {
  const LoginFormPage({super.key});

  @override
  State<LoginFormPage> createState() => _LoginFormPageState();
}

class _LoginFormPageState extends State<LoginFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/auth/login'), // URL del backend
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      Navigator.pop(context); // Cierra el diálogo de carga

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final user = responseData['user']; // Obtener el objeto 'user'
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainPage(user: user)),
          (route) => false,
        );
      } else {
        final error = json.decode(response.body)['message'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo conectar al servidor: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 50),
                SizedBox(
                  height: 80,
                  child: Center(child: Image.asset('assets/images/logo.png')),
                ),
                const SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.black87),
                    children: const [
                      TextSpan(text: 'LOSS '),
                      TextSpan(
                        text: 'UTALCA',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegistrationFormPage()),
                    );
                  },
                  child: const Text('¿No tienes cuenta? Regístrate'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loginUser,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Ingresar', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}