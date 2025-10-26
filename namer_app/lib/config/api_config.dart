import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
  // Detectar automáticamente la URL según la plataforma
  static String get baseUrl {
    if (kIsWeb) {
      // Para navegadores web (Chrome, Edge, Firefox)
      return 'http://localhost:5000';
    } else {
      // Para Android emulador
      try {
        if (Platform.isAndroid) {
          return 'http://10.0.2.2:5000';
        } else if (Platform.isIOS) {
          // Para iOS simulator
          return 'http://localhost:5000';
        }
      } catch (e) {
        // Fallback
        return 'http://localhost:5000';
      }
    }
    // Fallback por defecto
    return 'http://localhost:5000';
  }
  
  static const String apiVersion = '/api';
  
  // Endpoints
  static String get loginEndpoint => '$baseUrl$apiVersion/auth/login';
  static String get registerEndpoint => '$baseUrl$apiVersion/auth/register';
  
  // Timeout
  static const Duration timeout = Duration(seconds: 10);
  
  // Para debugging: mostrar qué URL se está usando
  static void printCurrentUrl() {
    print('🌐 API Base URL: $baseUrl');
    print('📱 Platform: ${kIsWeb ? "Web" : "Mobile/Desktop"}');
  }
}
