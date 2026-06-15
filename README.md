# Nivroy TIKI-TIKI Frontend

Flutter app multiplataforma con Material 3, tema oscuro y dashboard para controlar el backend.

## Plataformas creadas

- Android
- iOS
- Web
- macOS
- Windows

## Instalacion

```bash
flutter pub get
flutter run -d chrome --dart-define-from-file=.env
```

## Estructura

```text
lib/main.dart
lib/core/
lib/features/dashboard/
lib/features/rules/
lib/features/events/
lib/features/settings/
lib/services/
lib/models/
```

## Pantallas

- Dashboard: estados, usuario TikTok, URL de ServerTap y acciones principales.
- Rules: reglas de regalos a comandos, pruebas manuales por ServerTap y creacion de comandos propios.
- Events: eventos recibidos en tiempo real por WebSocket.
- Settings: URL del backend, usuario TikTok e IP/puerto Minecraft guardados con `shared_preferences`.

La URL por defecto del backend es `http://localhost:3000`.
