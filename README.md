# Panzerkraft Demo (Flutter)

Esta aplicación es una plantilla de demostración creada con Flutter para mostrar un flujo de una sola pantalla adaptable. Está lista para compilar en Android sin configuraciones externas.

## Características
- Pantalla de inicio con componentes Material 3.
- Diseño adaptable para móviles y pantallas anchas.
- Barra de navegación inferior con tres estados de contenido.
- Código simplificado para extender fácilmente con tus propios módulos.

## Lanzador de Android
Para utilizar tu ícono sin márgenes:
1. Sustituye el archivo `android/app/src/main/res/drawable/launcher_full_bleed.xml` por tu PNG completo (con el mismo nombre `launcher_full_bleed.png`).
2. Asegúrate de que la imagen ocupe el ancho y alto completos (sin transparencia alrededor).
3. Limpia el proyecto con `flutter clean` antes de reconstruir si cambias los recursos.

Los archivos `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` e `ic_launcher_round.xml` ya referencian el recurso de primer plano sin aplicar recortes adicionales.

## Requisitos previos
- Flutter SDK 3.9.2 o superior.
- Dart SDK incluido con Flutter.

## Puesta en marcha
```bash
flutter pub get
flutter run
```

## Estructura
- `lib/main.dart`: Contiene la interfaz principal y los widgets de la demo.
- `android/`: Configuración mínima para compilar en Android, incluyendo instrucciones del ícono.
