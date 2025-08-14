import 'package:flutter/material.dart';
import 'package:jump_counter/services/accelerometer_service.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math';

class JumpCounterScreen extends StatefulWidget {
  const JumpCounterScreen({Key? key}) : super(key: key);

  @override
  _JumpCounterScreenState createState() => _JumpCounterScreenState();
}

class _JumpCounterScreenState extends State<JumpCounterScreen> {
  final AccelerometerService _accelerometerService = AccelerometerService();
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
    _accelerometerService.initialize();
    _accelerometerService.onJumpDetected = _onJumpDetected;
    _accelerometerService.onAccelerometerData = _onAccelerometerData;
    _accelerometerService.onVariationPercentage = _onVariationPercentage;
    _sensitivity = _accelerometerService.jumpThreshold;
  }
  
  void _onAccelerometerData(AccelerometerEvent event) {
    setState(() {
      _xValue = event.x;
      _yValue = event.y;
      _zValue = event.z;
      _magnitude = _calculateMagnitude(event.x, event.y, event.z);
    });
  }
  
  void _onVariationPercentage(double percentage) {
    setState(() {
      _variationPercentage = percentage;
    });
  }
  
  double _calculateMagnitude(double x, double y, double z) {
    return sqrt(x * x + y * y + z * z);
  }

  @override
  void dispose() {
    _accelerometerService.dispose();
    super.dispose();
  }

  void _onJumpDetected() {
    setState(() {
      _jumpCount++;
    });
  }

  void _toggleMonitoring() {
    setState(() {
      _isMonitoring = !_isMonitoring;
      if (_isMonitoring) {
        _accelerometerService.startMonitoring();
      } else {
        _accelerometerService.stopMonitoring();
      }
    });
  }

  void _resetCounter() {
    setState(() {
      _jumpCount = 0;
    });
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
      _accelerometerService.jumpThreshold = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contador de Saltos'),
        actions: [
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
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        backgroundColor: _isMonitoring ? Colors.red[700] : Colors.blue[700],
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isMonitoring ? 'Detener' : 'Comenzar'),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: _resetCounter,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue[300],
                      ),
                      child: const Text('Reiniciar contador'),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              Divider(color: Colors.grey[700]),
              
              // Sección de ajuste de sensibilidad
              Text(
                'Ajuste de sensibilidad:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[300]),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('Menos sensible', style: TextStyle(color: Colors.grey[400])),
                  Expanded(
                    child: Slider(
                      value: _sensitivity,
                      min: _minSensitivity,
                      max: _maxSensitivity,
                      divisions: 25,
                      label: _sensitivity.toStringAsFixed(2),
                      activeColor: Colors.blue[400],
                      inactiveColor: Colors.grey[700],
                      onChanged: _updateSensitivity,
                    ),
                  ),
                  Text('Más sensible', style: TextStyle(color: Colors.grey[400])),
                ],
              ),
              Text(
                'Valor actual: ${_sensitivity.toStringAsFixed(2)}',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[300]),
              ),
              
              const SizedBox(height: 30),
              Divider(color: Colors.grey[700]),
              
              // Sección del vector de variación porcentual
              Text(
                'Vector de variación (%):',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[300]),
              ),
              const SizedBox(height: 10),
              
              // Indicador visual de la variación porcentual
              LinearProgressIndicator(
                value: _isMonitoring ? min(1.0, _variationPercentage / _maxVariationDisplay) : 0.0,
                minHeight: 15,
                backgroundColor: Colors.grey[800],
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
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
              
              const SizedBox(height: 30),
              Divider(color: Colors.grey[700]),
              
              // Sección de datos del acelerómetro
              Text(
                'Datos del acelerómetro:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[300]),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 4,
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('X: ${_xValue.toStringAsFixed(4)} m/s²', style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('Y: ${_yValue.toStringAsFixed(4)} m/s²', style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('Z: ${_zValue.toStringAsFixed(4)} m/s²', style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 8),
                      Text(
                        'Magnitud: ${_magnitude.toStringAsFixed(4)} m/s²',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[300]),
                      ),
                      const SizedBox(height: 12),
                      _isMonitoring
                          ? Text('Estado: Monitoreando...',
                              style: TextStyle(color: Colors.green[400]))
                          : Text('Estado: Detenido',
                              style: TextStyle(color: Colors.red[400])),
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
                    backgroundColor: Colors.green[700],
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