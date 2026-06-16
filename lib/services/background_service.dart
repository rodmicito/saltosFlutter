import 'dart:async';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:jump_counter/services/accelerometer_service.dart';
import 'package:sensors_plus/sensors_plus.dart';

const String notificationChannelId = 'jump_counter_foreground';
const int notificationId = 888;

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    'Contador de Saltos en Segundo Plano',
    description: 'Mantiene el conteo de saltos activo cuando la app está minimizada.',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'Contador de Saltos',
      initialNotificationContent: 'Presiona Comenzar para iniciar',
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopSelf').listen((event) {
    service.stopSelf();
  });

  // Estado local en el Isolate
  int jumpCount = 0;
  bool isMonitoring = false;
  double x = 0.0;
  double y = 0.0;
  double z = 0.0;
  double magnitude = 0.0;
  double variationPercentage = 0.0;

  final AccelerometerService accelerometerService = AccelerometerService();
  accelerometerService.initialize();

  void updateNotification() {
    if (service is AndroidServiceInstance) {
      if (isMonitoring) {
        service.setForegroundNotificationInfo(
          title: 'Contador de Saltos Activo',
          content: 'Saltos: $jumpCount | Variación: ${variationPercentage.toStringAsFixed(1)}%',
        );
      } else {
        service.setForegroundNotificationInfo(
          title: 'Contador de Saltos Detenido',
          content: 'Total de saltos registrados: $jumpCount',
        );
      }
    }
  }

  void sendStateToUI() {
    service.invoke('update', {
      'x': x,
      'y': y,
      'z': z,
      'magnitude': magnitude,
      'variationPercentage': variationPercentage,
      'jumpCount': jumpCount,
      'isMonitoring': isMonitoring,
      'sensitivity': accelerometerService.jumpThreshold,
    });
  }

  accelerometerService.onAccelerometerData = (AccelerometerEvent event) {
    x = event.x;
    y = event.y;
    z = event.z;
    magnitude = sqrt(x * x + y * y + z * z);
    sendStateToUI();
  };

  accelerometerService.onVariationPercentage = (double percentage) {
    variationPercentage = percentage;
    sendStateToUI();
  };

  accelerometerService.onJumpDetected = () {
    jumpCount++;
    updateNotification();
    sendStateToUI();
  };

  // Listeners de comandos
  service.on('startMonitoring').listen((event) {
    if (!isMonitoring) {
      isMonitoring = true;
      accelerometerService.startMonitoring();
      updateNotification();
      sendStateToUI();
    }
  });

  service.on('stopMonitoring').listen((event) {
    if (isMonitoring) {
      isMonitoring = false;
      accelerometerService.stopMonitoring();
      updateNotification();
      sendStateToUI();
    }
  });

  service.on('resetCounter').listen((event) {
    jumpCount = 0;
    updateNotification();
    sendStateToUI();
  });

  service.on('updateSensitivity').listen((event) {
    if (event != null && event['value'] != null) {
      double val = (event['value'] as num).toDouble();
      accelerometerService.jumpThreshold = val;
      sendStateToUI();
    }
  });

  service.on('requestState').listen((event) {
    sendStateToUI();
  });

  // Enviar estado inicial al conectar la UI
  sendStateToUI();
}
