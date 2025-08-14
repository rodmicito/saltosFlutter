import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  static const String _androidProviderName = 'JumpCounterWidgetProvider';
  static const String _jumpCountKey = 'jump_count';
  static const String _lastUpdateKey = 'last_update';
  static const String _statusKey = 'status';

  /// Inicializa el widget de pantalla principal
  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId('group.com.example.jump_counter');
      await updateWidget(0, false);
    } catch (e) {
      print('Error initializing home widget: $e');
    }
  }

  /// Actualiza el widget con el contador de saltos actual
  static Future<void> updateWidget(int jumpCount, bool isMonitoring) async {
    try {
      // Guardar datos para el widget
      await HomeWidget.saveWidgetData<int>(_jumpCountKey, jumpCount);
      await HomeWidget.saveWidgetData<String>(
        _lastUpdateKey, 
        DateTime.now().toString().substring(11, 16), // Solo hora y minutos
      );
      await HomeWidget.saveWidgetData<String>(
        _statusKey, 
        isMonitoring ? 'ACTIVO' : 'PAUSADO',
      );

      // Actualizar el widget en Android
      await HomeWidget.updateWidget(
        name: _androidProviderName,
        androidName: _androidProviderName,
      );
    } catch (e) {
      print('Error updating home widget: $e');
    }
  }

  /// Obtiene el contador actual del widget
  static Future<int> getCurrentCount() async {
    try {
      return await HomeWidget.getWidgetData<int>(_jumpCountKey, defaultValue: 0) ?? 0;
    } catch (e) {
      print('Error getting widget data: $e');
      return 0;
    }
  }

  /// Maneja cuando el usuario toca el widget
  static Future<void> handleWidgetClick() async {
    try {
      // Esto abrirá la aplicación cuando se toque el widget
      await HomeWidget.getWidgetData<String>('app_launch');
    } catch (e) {
      print('Error handling widget click: $e');
    }
  }

  /// Registra el callback para cuando se toque el widget
  static void registerWidgetCallback() {
    HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) {
        handleWidgetClick();
      }
    });
  }
}
