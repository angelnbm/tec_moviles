import 'package:flutter/material.dart';
import 'package:namer_app/pages/login_form_page.dart';
import 'package:namer_app/pages/main_page.dart';
import 'package:namer_app/pages/settings_page.dart';
import 'package:namer_app/services/api_service.dart';
import 'package:namer_app/services/biometric_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final lastUserId = await BiometricService.getLastUserId();
    if (lastUserId != null) {
      final isEnabled = await BiometricService.getBiometricPreference(lastUserId);
      final canAuth = await BiometricService.canAuthenticate();
      if (mounted) {
        setState(() {
          _canUseBiometrics = isEnabled && canAuth;
        });
      }
    }
  }

  Future<void> _loginWithBiometrics() async {
    final didAuthenticate = await BiometricService.authenticate('Inicia sesión con tu huella');
    if (didAuthenticate) {
      final token = await ApiService.getToken();
      final user = await ApiService.getUserData();
      if (token != null && user != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainPage(user: user)),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo iniciar sesión. Por favor, ingresa tus credenciales.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings, color: Colors.grey),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
          tooltip: 'Configuración',
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.shade50,
              Colors.white,
              Colors.grey.shade50,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo con animación sutil y fondo blanco
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      height: 170,
                      width: 170,
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.15),
                            blurRadius: 25,
                            spreadRadius: 5,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        color: null,
                        colorBlendMode: null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  // Título con mejor estilo usando los colores de la UTAL
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.5,
                            height: 1.2,
                          ),
                      children: const [
                        TextSpan(text: 'LOSS '),
                        TextSpan(
                          text: 'UTALCA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD32F2F), // Rojo UTAL
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Objetos perdidos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 60),
                  // Botón de iniciar sesión con colores UTAL
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F), // Rojo UTAL
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        shadowColor: const Color(0xFFD32F2F).withOpacity(0.5),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginFormPage(),
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Iniciar sesión',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_canUseBiometrics) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _loginWithBiometrics,
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Iniciar con huella'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD32F2F),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFFD32F2F), width: 1.8),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Botón de invitado mejorado
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD32F2F), // Rojo UTAL
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(
                          color: Color(0xFFD32F2F),
                          width: 1.8,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainPage(),
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.explore, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Explorar como invitado',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  // Footer con información de la universidad
                  Column(
                    children: [
                      Icon(
                        Icons.school,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '© 2025 Universidad de Talca',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sistema de Objetos Perdidos',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}