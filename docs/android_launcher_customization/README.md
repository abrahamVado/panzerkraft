# Red TOSUR Android Launcher Customization

## Cambiar el nombre mostrado
1. Abre `android/app/src/main/AndroidManifest.xml`.
2. Verifica que el atributo `android:label` del nodo `<application>` contenga `Red TOSUR`.
3. Sincroniza el proyecto o recompila la app para que el cambio se refleje en el lanzador de Android.

## Reemplazar el ícono de la app
1. Prepara tus íconos en formato PNG cuadrado (recomendado 48x48, 72x72, 96x96, 144x144 y 192x192) o un archivo vectorial `.xml`.
2. Sustituye los archivos existentes en `android/app/src/main/res/drawable/` y `android/app/src/main/res/mipmap-anydpi-v26/` que comienzan con `ic_launcher` por tus versiones personalizadas. Respeta los nombres originales para evitar ajustes adicionales en el manifiesto.
3. Si trabajas con múltiples densidades, crea carpetas `mipmap-hdpi`, `mipmap-mdpi`, `mipmap-xhdpi`, `mipmap-xxhdpi` y `mipmap-xxxhdpi`, coloca los PNG correspondientes y actualiza el atributo `android:icon` a `@mipmap/ic_launcher` y `android:roundIcon` a `@mipmap/ic_launcher_round` en el manifiesto.
4. Alternativamente, agrega la dependencia `flutter_launcher_icons` a tu `pubspec.yaml` y ejecuta `flutter pub run flutter_launcher_icons` para generar todos los recursos automáticamente.
5. Limpia y vuelve a compilar tu aplicación (`flutter clean && flutter run`) para asegurarte de que los cambios de ícono se apliquen correctamente en los dispositivos Android.
