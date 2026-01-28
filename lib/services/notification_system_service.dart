import 'package:vibration/vibration.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/// 📳 Servicio de Notificaciones del Sistema con Vibración
class NotificationSystemService {
  static final NotificationSystemService _instance = NotificationSystemService._internal();
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  factory NotificationSystemService() {
    return _instance;
  }

  NotificationSystemService._internal() {
    _initializePlugin();
  }

  void _initializePlugin() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    print('🔔 Notificación tocada: ${notificationResponse.payload}');
  }

  /// 📬 Mostrar notificación de cotización con vibración
  Future<void> showQuotationNotification({
    required String technicianName,
    required double amount,
    required String serviceType,
  }) async {
    try {
      // Vibrar 3 veces (patrón de "nueva cotización")
      await _vibrate(pattern: [100, 200, 100, 200, 100, 200]);

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'quotation_channel',
        'Cotizaciones',
        channelDescription: 'Notificaciones de nuevas cotizaciones',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      );

      const DarwinNotificationDetails iosPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        0,
        '✅ Nueva Cotización',
        'Técnico: $technicianName\nServicio: $serviceType\nMonto: \$$amount',
        platformChannelSpecifics,
        payload: 'quotation_$technicianName',
      );

      print('✅ Notificación de cotización mostrada');
    } catch (e) {
      print('❌ Error mostrando notificación: $e');
    }
  }

  /// 🎉 Notificación cuando una cotización es aceptada
  Future<void> showQuotationAcceptedNotification({
    required String clientName,
    required double amount,
    required String quotationId,
  }) async {
    try {
      // Vibrar con patrón de "éxito" (cotización aceptada)
      await _vibrate(pattern: [100, 100, 100, 100, 200, 200]);

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'quotation_accepted_channel',
        'Cotizaciones Aceptadas',
        channelDescription: 'Notificaciones cuando aceptan tus cotizaciones',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        color: Color.fromARGB(255, 76, 175, 80), // Verde
      );

      const DarwinNotificationDetails iosPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        2,
        '🎉 ¡Cotización Aceptada!',
        '$clientName aceptó tu cotización de \$$amount',
        platformChannelSpecifics,
        payload: 'quotation_accepted_$quotationId',
      );

      print('✅ Notificación de cotización aceptada mostrada');
    } catch (e) {
      print('❌ Error mostrando notificación de aceptación: $e');
    }
  }

  /// 💳 Notificación de pago confirmado
  Future<void> showPaymentConfirmedNotification({
    required String workId,
    required double amount,
  }) async {
    try {
      // Vibrar 2 veces (patrón de "pago confirmado")
      await _vibrate(pattern: [150, 150, 150]);

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'payment_channel',
        'Pagos',
        channelDescription: 'Notificaciones de pagos confirmados',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        1,
        '💳 Pago Confirmado',
        'Tu pago de \$$amount ha sido procesado exitosamente',
        platformChannelSpecifics,
        payload: 'payment_$workId',
      );

      print('✅ Notificación de pago mostrada');
    } catch (e) {
      print('❌ Error mostrando notificación de pago: $e');
    }
  }

  /// 💬 Notificación de nuevo mensaje en chat
  Future<void> showChatNotification({
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    try {
      // Vibrar 1 vez (patrón corto para mensaje)
      await _vibrate(pattern: [100]);

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'chat_channel',
        'Mensajes',
        channelDescription: 'Notificaciones de mensajes de chat',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        2,
        '💬 Nuevo mensaje de $senderName',
        message,
        platformChannelSpecifics,
        payload: 'chat_$chatId',
      );

      print('✅ Notificación de chat mostrada');
    } catch (e) {
      print('❌ Error mostrando notificación de chat: $e');
    }
  }

  /// 🎯 Notificación de trabajo iniciado
  Future<void> showWorkStartedNotification({
    required String technicianName,
    required String serviceType,
  }) async {
    try {
      // Vibrar doble
      await _vibrate(pattern: [80, 100, 80]);

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'work_channel',
        'Trabajos',
        channelDescription: 'Notificaciones de trabajos',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        3,
        '🎯 Trabajo Iniciado',
        'Técnico: $technicianName\nServicio: $serviceType',
        platformChannelSpecifics,
        payload: 'work_started',
      );

      print('✅ Notificación de trabajo iniciado mostrada');
    } catch (e) {
      print('❌ Error mostrando notificación de trabajo: $e');
    }
  }

  /// 📳 Función auxiliar para vibración con patrón
  Future<void> _vibrate({required List<int> pattern}) async {
    try {
      // Verificar si el dispositivo soporta vibración
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(pattern: pattern);
      }
    } catch (e) {
      print('⚠️ Error vibrando: $e');
    }
  }

  /// 🔔 Vibración simple (haptic feedback)
  Future<void> simpleVibrate({int milliseconds = 100}) async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: milliseconds);
      }
    } catch (e) {
      print('⚠️ Error en vibración simple: $e');
    }
  }

  /// ⛔ Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      print('✅ Todas las notificaciones canceladas');
    } catch (e) {
      print('❌ Error cancelando notificaciones: $e');
    }
  }

  /// 💬 Notificación de nuevo mensaje en chat
  Future<void> showChatMessageNotification({
    required String senderName,
    required String messagePreview,
    required String workId,
    required bool appIsOpen,
  }) async {
    try {
      // Vibración para mensaje de chat
      await _vibrate(pattern: [50, 100, 50]);

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'chat_channel',
        'Mensajes',
        channelDescription: 'Notificaciones de chat',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        workId.hashCode, // ID único por trabajo
        '💬 Mensaje de $senderName',
        messagePreview,
        platformChannelSpecifics,
        payload: 'chat_$workId',
      );

      print('✅ Notificación de chat mostrada');
    } catch (e) {
      print('❌ Error mostrando notificación de chat: $e');
    }
  }

  /// 🎯 Notificación para inicialización de chat
  Future<void> showChatInitializedNotification({
    required String otherUserName,
    required String workId,
  }) async {
    try {
      // Vibración para chat inicializado
      await _vibrate(pattern: [100, 50, 100, 50, 100]);

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'chat_init_channel',
        'Chat Inicializado',
        channelDescription: 'Notificaciones de inicio de chat',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        999,
        '🎯 Chat Inicializado',
        'Ahora puedes comunicarte con $otherUserName',
        platformChannelSpecifics,
        payload: 'chat_init_$workId',
      );

      print('✅ Notificación de chat inicializado mostrada');
    } catch (e) {
      print('❌ Error mostrando notificación: $e');
    }
  }
}
