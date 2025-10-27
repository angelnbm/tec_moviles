import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String? _baseUrl;

  static String get baseUrl {
    if (_baseUrl != null && _baseUrl!.isNotEmpty) {
      return _baseUrl!;
    }
    const fromEnv = String.fromEnvironment('BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    // Si no se proporciona, usa la IP del emulador como valor por defecto.
    const defaultUrl = 'http://10.0.2.2:5000/api';
    return defaultUrl;
  }

  static Future<void> initBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('base_url');
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('base_url', url);
    _baseUrl = url;
  }

  // Token management
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(userData));
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }

  // Auth endpoints
  static Future<Map<String, dynamic>> register({
    required String name,
    required String lastName,
    required String rut,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'lastName': lastName,
          'rut': rut,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await saveToken(data['token']);
        await saveUserData(data['user']);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['msg'] ?? 'Error al registrar'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveToken(data['token']);
        await saveUserData(data['user']);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['msg'] ?? 'Error al iniciar sesión'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<void> logout() async {
    await removeToken();
    await clearUserData();
  }

  static Future<String?> _fileToBase64(String filePath, String mimeType) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        return 'data:$mimeType;base64,$base64String';
      }
      return null;
    } catch (e) {
      print('Error convirtiendo archivo a Base64: $e');
      return null;
    }
  }

  // Reports endpoints
  static Future<Map<String, dynamic>> createReport({
    required String title,
    required String description,
    required String category,
    required String location,
    required double latitude,
    required double longitude,
    String? imageUrl,
    String? audioUrl,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No autenticado'};
      }
      // Si hay una ruta de archivo de audio, súbelo primero
      String? processedAudioUrl;
      if (audioUrl != null && audioUrl.startsWith('/')) {
        processedAudioUrl = await _fileToBase64(audioUrl, 'audio/aac');
      } else {
        processedAudioUrl = audioUrl;
      }

      // Convertir imagen a Base64 si es una ruta de archivo local
      String? processedImageUrl;
      if (imageUrl != null && imageUrl.startsWith('/')) {
        processedImageUrl = await _fileToBase64(imageUrl, 'image/jpeg');
      } else {
        processedImageUrl = imageUrl;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/reports'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode({
          'title': title,
          'description': description,
          'category': category,
          'location': location,
          'latitude': latitude,
          'longitude': longitude,
          'imageUrl': processedImageUrl,
          'audioUrl': processedAudioUrl,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['msg'] ?? 'Error al crear reporte'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAllReports() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Error al cargar reportes'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMyReports() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No autenticado'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/reports/my-reports'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Error al cargar mis reportes'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateReport({
    required String reportId,
    String? title,
    String? description,
    String? category,
    String? location,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? status,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No autenticado'};
      }

      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (category != null) body['category'] = category;
      if (location != null) body['location'] = location;
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      if (imageUrl != null) body['imageUrl'] = imageUrl;
      if (status != null) body['status'] = status;

      final response = await http.put(
        Uri.parse('$baseUrl/reports/$reportId'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['msg'] ?? 'Error al actualizar reporte'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteReport(String reportId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No autenticado'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/reports/$reportId'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['msg'] ?? 'Error al eliminar reporte'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Profile endpoints
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No autenticado'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Update local user data
        await saveUserData(data);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['msg'] ?? 'Error al obtener perfil'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? lastName,
    String? profileImage,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No autenticado'};
      }

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (lastName != null) body['lastName'] = lastName;
      if (profileImage != null) body['profileImage'] = profileImage;

      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Update local user data
        await saveUserData(data);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['msg'] ?? 'Error al actualizar perfil'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
