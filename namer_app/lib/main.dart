import 'package:firebase_core/firebase_core.dart'; // Importar
import 'package:flutter/material.dart';
import 'package:namer_app/pages/login_page.dart';
import 'package:namer_app/services/api_service.dart';
import 'package:namer_app/services/notification_service.dart'; // Importar

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.initBaseUrl();
  
  // Inicializar Firebase
  await Firebase.initializeApp();
  
  // Inicializar Notificaciones
  await NotificationService().init();

  runApp(const LossUtalApp());
}

class LossUtalApp extends StatelessWidget {
  const LossUtalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Asignar la llave de navegación global
      navigatorKey: NotificationService.navigatorKey, 
      title: 'Loss UTAL',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const LoginPage(),
    );
  }
}