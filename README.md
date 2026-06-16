# Contador de Saltos

Aplicación Flutter que utiliza el acelerómetro del dispositivo para contar saltos en tiempo real.

## Características

- 🏃‍♂️ Detección automática de saltos mediante acelerómetro
- 📊 Contador de saltos en tiempo real
- ⚙️ Control deslizante de sensibilidad ajustable
- 📈 Vector de variación porcentual en tiempo real
- 📱 Visualización de datos del acelerómetro (X, Y, Z)
- 📤 Función para compartir resultados
- 🎨 Interfaz intuitiva y colorida (Material 3)
- 🔄 Monitoreo continuo en segundo plano mediante servicio persistente (*Foreground Service*)
- 🌗 Soporte completo de Tema Claro y Oscuro con alternancia en la barra superior

## Tecnologías utilizadas

- **Flutter** - Framework de desarrollo multiplataforma
- **Dart** - Lenguaje de programación
- **sensors_plus** - Plugin para acceso a sensores del dispositivo
- **share_plus** - Plugin para compartir contenido

## Instalación

### Requisitos previos
- Flutter SDK instalado
- Android Studio o VS Code
- Dispositivo Android/iOS o emulador

### Pasos de instalación

1. Clona el repositorio:
```bash
git clone https://github.com/tu-usuario/jump_counter.git
cd jump_counter
```

2. Instala las dependencias:
```bash
flutter pub get
```

3. Ejecuta la aplicación:
```bash
flutter run
```

## Cómo usar la aplicación

1. **Iniciar monitoreo**: Presiona el botón "Comenzar" para activar el contador
2. **Ajustar sensibilidad**: Usa el control deslizante para ajustar la sensibilidad de detección
3. **Realizar saltos**: La aplicación detectará automáticamente tus saltos
4. **Monitorear datos**: Observa en tiempo real los datos del acelerómetro y el vector de variación
5. **Compartir resultados**: Usa el botón de compartir para enviar tus resultados

## Construcción de la aplicación

### APK para Android
```bash
flutter build apk --release
```
El APK se generará en `build/app/outputs/flutter-apk/app-release.apk`

### Bundle AAB para Google Play Store
```bash
flutter build appbundle --release
```

### IPA para iOS (requiere Mac con Xcode)
```bash
flutter build ios --release
```

## Estructura del proyecto

```
lib/
├── main.dart                    # Punto de entrada y configuración de servicios
├── screens/
│   └── jump_counter_screen.dart # Interfaz de usuario adaptativa y controladora
└── services/
    ├── accelerometer_service.dart # Algoritmo de detección y filtrado de saltos
    └── background_service.dart    # Ciclo de vida y notificaciones del segundo plano
```

## Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Añadir nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## Licencia

Este proyecto está bajo la Licencia MIT - mira el archivo [LICENSE](LICENSE) para más detalles.

## Autor

- **Rod** - Desarrollo inicial

## Versión

- **v1.0.2** - Soporte de monitoreo en segundo plano y Tema Oscuro (Dark Mode)
- **v1.0.0** - Versión inicial con detección de saltos y control de sensibilidad
