# Red TOSUR Android Launcher Customization

## Plan de tareas para corregir el ícono en Android
1. Verificar que `assets/android/app_icon.png` exista en el repositorio local proporcionado por diseño.
2. Confirmar que los recursos adaptativos `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` e `ic_launcher_round.xml` apunten al `@drawable/ic_launcher_foreground_bitmap` para mantener compatibilidad con el PNG.
3. Ajustar el manifiesto principal (`android/app/src/main/AndroidManifest.xml`) si el atributo `android:icon` no referencia a `@mipmap/ic_launcher`.
4. Ejecutar una compilación local (`flutter build apk`) para validar que el ícono actualizado se incluya en el paquete sin generar nuevos binarios en el repositorio.
5. Probar el instalable resultante en un dispositivo o emulador verificando el ícono mostrado en el lanzador de Android y en el panel de aplicaciones recientes.

## Cambiar el nombre mostrado
1. Abre `android/app/src/main/AndroidManifest.xml`.
2. Verifica que el atributo `android:label` del nodo `<application>` contenga `Red TOSUR`.
3. Sincroniza el proyecto o recompila la app para que el cambio se refleje en el lanzador de Android.

## Preparar el icono configurable
1. Asegúrate de que tu arte final no contenga transparencias ni bordes innecesarios. Trabaja siempre sobre un lienzo cuadrado con tu diseño centrado.
2. Convierte las versiones finales a formato PNG con fondo transparente. Desde macOS/Linux puedes ejecutar:

   ```bash
   magick app_icon.jpeg -resize 512x512 -background none -flatten app_icon.png
   ```

   En Windows usa `magick.exe` desde PowerShell con los mismos argumentos.
3. Guarda la imagen optimizada como `assets/android/app_icon.png`. El `pubspec.yaml` ya incluye la carpeta `assets/`, por lo que no necesitas más cambios.

## Actualizar el icono desde Flutter
1. Abre `lib/config/branding_config.dart` y ajusta `androidIconSource` si decidiste usar un nombre o ruta distinta.
2. Reinicia la aplicación. `_BrandingPreview` en la pantalla de login mostrará inmediatamente el PNG actualizado usando `BrandingConfig`.
3. Si deseas que el launcher de Android use un diseño distinto, modifica `android/app/src/main/res/drawable/app_icon.xml`, el vector de respaldo que ahora consume el `AndroidManifest.xml`.

## Personalizar el vector nativo
1. Abre `android/app/src/main/res/drawable/app_icon.xml`.
2. Ajusta los nodos `<path>` para adaptar los colores o la forma a tu identidad. Procura ocupar todo el viewport (`108x108`) para evitar anillos en el launcher.
3. Guarda el archivo y recompila la app para verificar el resultado.
