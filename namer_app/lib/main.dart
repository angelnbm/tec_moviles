import 'package:flutter/material.dart';
import 'package:namer_app/pages/login_page.dart';
import 'package:namer_app/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.initBaseUrl();
  runApp(const LossUtalApp());
}

class LossUtalApp extends StatelessWidget {
  const LossUtalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loss UTAL',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const LoginPage(),
    );
  }
}