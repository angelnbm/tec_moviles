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
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          // Manejar clic en notificación local (App en primer plano)
          // Aquí necesitaríamos parsear el payload si lo guardamos como string
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
          payload: message.data.toString(), // Pasar datos al payload local
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

  void _handleMessage(RemoteMessage message) {
    if (message.data['type'] == 'chat_message') {
      final conversationId = message.data['conversationId'];
      final otherUserName = message.data['otherUserName'];
      final reportTitle = message.data['reportTitle'];

      if (conversationId != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ConversationPage(
              conversationId: conversationId,
              otherUserName: otherUserName ?? 'Usuario',
              reportTitle: reportTitle ?? 'Reporte',
              // La imagen no viene en la notif, se cargará por defecto o null
              otherUserProfileImage: null, 
            ),
          ),
        );
      }
    }
  }
}