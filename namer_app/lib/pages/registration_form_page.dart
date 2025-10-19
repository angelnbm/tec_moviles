import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegistrationFormPage extends StatefulWidget {
  const RegistrationFormPage({super.key});

  @override
  State<RegistrationFormPage> createState() => _RegistrationFormPageState();
}

class _RegistrationFormPageState extends State<RegistrationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Apellido', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: 'RUT', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  RutInputFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Campo requerido';
                  // TODO: Implementar validación de dígito verificador del RUT
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Correo electrónico', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Campo requerido';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Correo no válido';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                obscureText: true,
                validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Repetir Contraseña', border: OutlineInputBorder()),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Campo requerido';
                  if (value != _passwordController.text) return 'Las contraseñas no coinciden';
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Lógica de registro
                    Navigator.pop(context); // Volver a la pantalla de login
                  }
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Registrarse', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RutInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;
    if (text.isEmpty) return newValue;

    text = text.replaceAll(RegExp(r'[\.\-]'), '');
    String newText = '';

    if (text.length > 1) {
      String dv = text.substring(text.length - 1);
      String rut = text.substring(0, text.length - 1);
      String formattedRut = '';
      for (var i = rut.length - 1; i >= 0; i--) {
        formattedRut = rut[i] + formattedRut;
        if ((rut.length - i) % 3 == 0 && i != 0) {
          formattedRut = '.$formattedRut';
        }
      }
      newText = '$formattedRut-$dv';
    } else {
      newText = text;
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}