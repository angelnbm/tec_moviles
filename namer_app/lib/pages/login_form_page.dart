import 'package:flutter/material.dart';
import 'package:namer_app/pages/registration_form_page.dart';

class LoginFormPage extends StatelessWidget {
  const LoginFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: Colors.black,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
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
                onPressed: () {
                  // Lógica de inicio de sesión
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Ingresar', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}