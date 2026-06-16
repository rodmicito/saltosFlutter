import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:share_plus/share_plus.dart';
import 'package:jump_counter/main.dart';
import 'dart:async';
import 'dart:math';

class JumpCounterScreen extends StatefulWidget {
  const JumpCounterScreen({Key? key}) : super(key: key);

  @override
  _JumpCounterScreenState createState() => _JumpCounterScreenState();
}

class _JumpCounterScreenState extends State<JumpCounterScreen> {
  StreamSubscription? _serviceSubscription;
  int _jumpCount = 0;
  bool _isMonitoring = false;
  
  // Valores para el control deslizante de sensibilidad
  double _sensitivity = 3.6;
  final double _minSensitivity = 1.0;
  final double _maxSensitivity = 6.0;
  
  // Datos del acelerómetro
  double _xValue = 0.0;
  double _yValue = 0.0;
  double _zValue = 0.0;
  double _magnitude = 0.0;
  
  // Vector de variación porcentual
  double _variationPercentage = 0.0;
  
  // Para el indicador visual de variación
  final double _maxVariationDisplay = 100.0;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _initBackgroundServiceListener();
  }

  void _requestNotificationPermission() {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void _initBackgroundServiceListener() async {
    _serviceSubscription = FlutterBackgroundService().on('update').listen((event) {
      if (event != null) {
        setState(() {
          _xValue = (event['x'] as num).toDouble();
          _yValue = (event['y'] as num).toDouble();
          _zValue = (event['z'] as num).toDouble();
          _magnitude = (event['magnitude'] as num).toDouble();
          _variationPercentage = (event['variationPercentage'] as num).toDouble();
          _jumpCount = event['jumpCount'] as int;
          _isMonitoring = event['isMonitoring'] as bool;
          _sensitivity = (event['sensitivity'] as num).toDouble();
        });
      }
    });

    // Solicitar el estado inicial en caso de que ya esté corriendo
    final isRunning = await FlutterBackgroundService().isRunning();
    if (isRunning) {
      FlutterBackgroundService().invoke('requestState');
    }
  }

  @override
  void dispose() {
    _serviceSubscription?.cancel();
    super.dispose();
  }

  void _toggleMonitoring() async {
    if (_isMonitoring) {
      FlutterBackgroundService().invoke('stopMonitoring');
      FlutterBackgroundService().invoke('stopSelf');
      setState(() {
        _isMonitoring = false;
      });
    } else {
      final isRunning = await FlutterBackgroundService().isRunning();
      if (!isRunning) {
        await FlutterBackgroundService().startService();
      }
      // Esperar brevemente a que el servicio esté listo
      Future.delayed(const Duration(milliseconds: 500), () {
        FlutterBackgroundService().invoke('startMonitoring');
        // Asegurar que use la sensibilidad actual de la UI
        FlutterBackgroundService().invoke('updateSensitivity', {'value': _sensitivity});
      });
    }
  }

  void _resetCounter() {
    FlutterBackgroundService().invoke('resetCounter');
  }

  void _shareResults() {
    Share.share(
      '¡He completado $_jumpCount saltos con la aplicación de Contador de Saltos!\nVariación máxima: ${_variationPercentage.toStringAsFixed(1)}%',
      subject: 'Mis resultados de saltos',
    );
  }
  
  void _updateSensitivity(double value) {
    setState(() {
      _sensitivity = value;
    });
    FlutterBackgroundService().invoke('updateSensitivity', {'value': value});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contador de Saltos'),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              themeNotifier.value = Theme.of(context).brightness == Brightness.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
            },
            tooltip: 'Cambiar tema',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareResults,
            tooltip: 'Compartir resultados',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Sección del contador
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'Número de saltos:',
                      style: TextStyle(fontSize: 20),
                    ),
                    Text(
                      '$_jumpCount',
                      style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _toggleMonitoring,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        backgroundColor: _isMonitoring
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      child: Text(_isMonitoring ? 'Detener' : 'Comenzar'),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: _resetCounter,
                      child: const Text('Reiniciar contador'),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              const Divider(),
              
              // Sección de ajuste de sensibilidad
              const Text(
                'Ajuste de sensibilidad:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Menos sensible'),
                  Expanded(
                    child: Slider(
                      value: _sensitivity,
                      min: _minSensitivity,
                      max: _maxSensitivity,
                      divisions: 25,
                      label: _sensitivity.toStringAsFixed(2),
                      onChanged: _updateSensitivity,
                    ),
                  ),
                  const Text('Más sensible'),
                ],
              ),
              Text(
                'Valor actual: ${_sensitivity.toStringAsFixed(2)}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              
              const SizedBox(height: 30),
              const Divider(),
              
              // Sección del vector de variación porcentual
              const Text(
                'Vector de variación (%):',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              
              // Indicador visual de la variación porcentual
              LinearProgressIndicator(
                value: _isMonitoring ? min(1.0, _variationPercentage / _maxVariationDisplay) : 0.0,
                minHeight: 15,
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getVariationColor(_variationPercentage),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Variación actual: ${_variationPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getVariationColor(_variationPercentage),
                ),
              ),
              Text(
                'Umbral para detección: ${(_sensitivity * 10).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 14),
              ),
              
              const SizedBox(height: 30),
              const Divider(),
              
              // Sección de datos del acelerómetro
              const Text(
                'Datos del acelerómetro:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('X: ${_xValue.toStringAsFixed(4)} m/s²'),
                      const SizedBox(height: 8),
                      Text('Y: ${_yValue.toStringAsFixed(4)} m/s²'),
                      const SizedBox(height: 8),
                      Text('Z: ${_zValue.toStringAsFixed(4)} m/s²'),
                      const SizedBox(height: 8),
                      Text(
                        'Magnitud: ${_magnitude.toStringAsFixed(4)} m/s²',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _isMonitoring
                          ? Text(
                              'Estado: Monitoreando...',
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.greenAccent
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Text(
                              'Estado: Detenido',
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.redAccent
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _shareResults,
                  icon: const Icon(Icons.share),
                  label: const Text('Compartir mis resultados'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.green[800]
                        : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Función para obtener un color basado en el porcentaje de variación
  Color _getVariationColor(double percentage) {
    if (percentage <= 10) {
      return Colors.green;
    } else if (percentage <= 30) {
      return Colors.blue;
    } else if (percentage <= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}