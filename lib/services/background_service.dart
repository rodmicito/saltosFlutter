import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';

class BackgroundService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    final service = FlutterBackgroundService();
    
    // Configurar notificaciones locales
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _notificationsPlugin.initialize(initializationSettings);

    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'jump_counter_bg',
        initialNotificationTitle: 'Contador de Saltos',
        initialNotificationContent: 'Monitoreando saltos en segundo plano',
        foregroundServiceNotificationId: 888,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    
    int jumpCount = 0;
    double jumpThreshold = 3.6;
    StreamSubscription<AccelerometerEvent>? subscription;
    DateTime lastJumpTime = DateTime.now();
    AccelerometerEvent? lastEvent;
    
    // Escuchar comandos desde la aplicación principal
    service.on('setThreshold').listen((event) {
      jumpThreshold = event!['threshold'];
    });

    service.on('startMonitoring').listen((event) async {
      subscription = accelerometerEvents.listen((AccelerometerEvent event) {
        // Detectar saltos
        if (lastEvent != null) {
          double deltaX = event.x - lastEvent!.x;
          double deltaY = event.y - lastEvent!.y;
          double deltaZ = event.z - lastEvent!.z;
          
          double magnitudeDelta = sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ);
          double variationPercentage = (magnitudeDelta / 9.8) * 100.0;
          
          DateTime now = DateTime.now();
          bool isSignificantVariation = variationPercentage > jumpThreshold * 10;
          
          if (isSignificantVariation && 
              now.difference(lastJumpTime).inMilliseconds > 500) {
            jumpCount++;
            lastJumpTime = now;
            
            // Enviar actualización a la aplicación principal
            service.invoke('jumpDetected', {'count': jumpCount});
            
            // Mostrar notificación cada 10 saltos
            if (jumpCount % 10 == 0) {
              _showNotification(jumpCount);
            }
          }
        }
        lastEvent = event;
      });
    });

    service.on('stopMonitoring').listen((event) {
      subscription?.cancel();
      subscription = null;
    });

    service.on('resetCount').listen((event) {
      jumpCount = 0;
      service.invoke('countReset', {'count': jumpCount});
    });

    service.on('getCount').listen((event) {
      service.invoke('currentCount', {'count': jumpCount});
    });

    service.on('stopService').listen((event) {
      subscription?.cancel();
      service.stopSelf();
    });
  }

  static Future<void> _showNotification(int jumpCount) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'jump_counter_alerts',
      'Alertas de Saltos',
      channelDescription: 'Notificaciones de progreso de saltos',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _notificationsPlugin.show(
      0,
      'Contador de Saltos',
      '¡Has completado $jumpCount saltos!',
      notificationDetails,
    );
  }

  static Future<void> startService() async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  static void startMonitoring() {
    final service = FlutterBackgroundService();
    service.invoke('startMonitoring');
  }

  static void stopMonitoring() {
    final service = FlutterBackgroundService();
    service.invoke('stopMonitoring');
  }

  static void setThreshold(double threshold) {
    final service = FlutterBackgroundService();
    service.invoke('setThreshold', {'threshold': threshold});
  }

  static void resetCount() {
    final service = FlutterBackgroundService();
    service.invoke('resetCount');
  }

  static void getCount() {
    final service = FlutterBackgroundService();
    service.invoke('getCount');
  }
}
