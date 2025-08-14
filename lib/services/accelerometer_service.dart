import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';

class AccelerometerService {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  Function? onJumpDetected;
  Function(AccelerometerEvent)? onAccelerometerData;
  Function(double)? onVariationPercentage;
  
  // Umbral para detectar un salto (en G's) - Duplicado
  double _jumpThreshold = 3.6;
  
  // Tiempo mínimo entre saltos (para evitar doble conteo)
  final int _debounceMs = 500;
  DateTime _lastJumpTime = DateTime.now();
  
  // Variables para calcular la variación
  AccelerometerEvent? _lastEvent;
  double _variationPercentage = 0.0;
  
  // Valor base de aceleración en reposo (aprox. 9.8 m/s²)
  final double _baseAcceleration = 9.8;
  
  // Factor de escala para la variación porcentual
  final double _variationScaleFactor = 100.0;
  
  bool _isMonitoring = false;
  
  // Getter y setter para el umbral de salto
  double get jumpThreshold => _jumpThreshold;
  set jumpThreshold(double value) {
    _jumpThreshold = value;
  }
  
  // Getter para el porcentaje de variación
  double get variationPercentage => _variationPercentage;
  
  void initialize() {
    // Inicializar cualquier configuración necesaria
  }
  
  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _lastEvent = null;
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      // Enviar datos del acelerómetro en tiempo real
      if (onAccelerometerData != null) {
        onAccelerometerData!(event);
      }
      
      // Calcular variación porcentual
      _calculateVariationPercentage(event);
      
      _processAccelerometerData(event);
    });
  }
  
  void _calculateVariationPercentage(AccelerometerEvent currentEvent) {
    if (_lastEvent != null) {
      double deltaX = currentEvent.x - _lastEvent!.x;
      double deltaY = currentEvent.y - _lastEvent!.y;
      double deltaZ = currentEvent.z - _lastEvent!.z;
      
      // Magnitud del vector de cambio
      double magnitudeDelta = sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ);
      
      // Normalizar como porcentaje respecto a la aceleración base
      _variationPercentage = (magnitudeDelta / _baseAcceleration) * _variationScaleFactor;
      
      // Limitar a un valor razonable (0-100%)
      _variationPercentage = min(100.0, _variationPercentage);
      
      if (onVariationPercentage != null) {
        onVariationPercentage!(_variationPercentage);
      }
    }
    
    _lastEvent = currentEvent;
  }
  
  void stopMonitoring() {
    if (!_isMonitoring) return;
    
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _isMonitoring = false;
  }
  
  void dispose() {
    stopMonitoring();
  }
  
  void _processAccelerometerData(AccelerometerEvent event) {
    // Calcular la magnitud total de la aceleración
    double accelerationMagnitude = _calculateMagnitude(event.x, event.y, event.z);
    
    // Restar la gravedad (aproximadamente 9.8 m/s^2)
    double acceleration = accelerationMagnitude - 9.8;
    
    // Usar la variación porcentual como criterio adicional para detectar saltos
    bool isSignificantVariation = _variationPercentage > _jumpThreshold * 10;
    
    // Verificar si la aceleración supera el umbral y ha pasado suficiente tiempo desde el último salto
    DateTime now = DateTime.now();
    if ((acceleration > _jumpThreshold || isSignificantVariation) && 
        now.difference(_lastJumpTime).inMilliseconds > _debounceMs) {
      _lastJumpTime = now;
      if (onJumpDetected != null) {
        onJumpDetected!();
      }
    }
  }
  
  double _calculateMagnitude(double x, double y, double z) {
    return sqrt(x * x + y * y + z * z);
  }
}