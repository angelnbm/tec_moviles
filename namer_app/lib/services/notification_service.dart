import 'dart:convert'; // IMPORTANTE: Agregar para jsonEncode y jsonDecode
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:namer_app/pages/conversation_page.dart';
import 'package:namer_app/services/api_service.dart';

// Necesario para manejar notificaciones en background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Key global para navegación sin contexto
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> init() async {
    // 1. Solicitar permisos
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permiso de notificaciones concedido');
      
      // 2. Obtener Token y enviarlo al backend
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        await ApiService.updateFcmToken(token);
      }

      // Listener para refresco de token
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        ApiService.updateFcmToken(newToken);
      });
    }

    // 3. Configurar notificaciones locales (para mostrar cuando la app está abierta)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(
      initializationSettings,
      // MANEJAR CLIC EN NOTIFICACIÓN LOCAL (APP ABIERTA)
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            // Decodificar el String JSON a Map
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            _handleMessageData(data);
          } catch (e) {
            print('Error al procesar payload de notificación: $e');
          }
        }
      },
    );

    // 4. Configurar Handlers de Firebase
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // App en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'Notificaciones Importantes',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          // IMPORTANTE: Convertir los datos a String JSON para pasarlos al payload
          payload: jsonEncode(message.data), 
        );
      }
    });

    // App abierta desde background (Click en notificación)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // App abierta desde estado terminado (Click en notificación)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
  }

  // Wrapper para mensajes remotos (Background/Terminated)
  void _handleMessage(RemoteMessage message) {
    _handleMessageData(message.data);
  }

  // Lógica centralizada de navegación
  void _handleMessageData(Map<String, dynamic> data) {
    if (data['type'] == 'chat_message') {
      final conversationId = data['conversationId'];
      final otherUserName = data['otherUserName'];
      final reportTitle = data['reportTitle'];

      if (conversationId != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ConversationPage(
              conversationId: conversationId,
              otherUserName: otherUserName ?? 'Usuario',
              reportTitle: reportTitle ?? 'Reporte',
              otherUserProfileImage: null, 
            ),
          ),
        );
      }
    }
  }
}