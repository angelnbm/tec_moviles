import 'package:flutter/material.dart';
import 'package:namer_app/services/api_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  
  int _currentStep = 0; // 0: Email, 1: Code, 2: New Password
  bool _isLoading = false;
  bool _obscurePass = true;

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    // Siempre avanzamos al siguiente paso por seguridad (según requerimiento)
    // aunque el backend valida internamente
    await ApiService.sendRecoveryCode(_emailController.text.trim());
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _currentStep = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Si la cuenta existe, se ha enviado un código.')),
      );
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.isEmpty) return;

    setState(() => _isLoading = true);
    
    final result = await ApiService.verifyRecoveryCode(
      _emailController.text.trim(), 
      _codeController.text.trim()
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        setState(() => _currentStep = 2);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await ApiService.resetPassword(
      _emailController.text.trim(),
      _codeController.text.trim(),
      _passController.text
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña actualizada correctamente'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Volver al login
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(
                _currentStep == 0 ? Icons.email_outlined : 
                _currentStep == 1 ? Icons.lock_clock_outlined : Icons.lock_reset,
                size: 80,
                color: const Color(0xFFD32F2F),
              ),
              const SizedBox(height: 30),
              
              if (_currentStep == 0) ...[
                const Text(
                  'Ingresa tu correo electrónico para recibir un código de recuperación.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: const Icon(Icons.email, color: Color(0xFFD32F2F)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v!.isEmpty || !v.contains('@') ? 'Correo inválido' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Enviar Código'),
                ),
              ] else if (_currentStep == 1) ...[
                Text(
                  'Ingresa el código enviado a ${_emailController.text}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Código de 6 dígitos',
                    prefixIcon: const Icon(Icons.numbers, color: Color(0xFFD32F2F)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Verificar Código'),
                ),
              ] else ...[
                const Text(
                  'Crea una nueva contraseña.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _passController,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña',
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFFD32F2F)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPassController,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    labelText: 'Repetir Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFD32F2F)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v != _passController.text ? 'Las contraseñas no coinciden' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Restablecer Contraseña'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}