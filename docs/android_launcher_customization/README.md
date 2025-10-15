# Red TOSUR Android Launcher Customization

## Cambiar el nombre mostrado
1. Abre `android/app/src/main/AndroidManifest.xml`.
2. Verifica que el atributo `android:label` del nodo `<application>` contenga `Red TOSUR`.
3. Sincroniza el proyecto o recompila la app para que el cambio se refleje en el lanzador de Android.

## Preparar iconos sin márgenes
1. Asegúrate de que tu arte final no contenga transparencias ni bordes innecesarios. Trabaja siempre sobre un lienzo cuadrado con tu diseño centrado.
2. Convierte las versiones finales a formato PNG. Android Launcher solo admite PNG o vectores con transparencia; los archivos `.jpeg` no conservan transparencia y el sistema los convertirá provocando bordes no deseados. Desde macOS/Linux puedes ejecutar:

   ```bash
   magick ic_launcher.jpeg -resize 512x512 -background none -flatten ic_launcher.png
   ```

   En Windows usa `magick.exe` desde PowerShell con los mismos argumentos.
3. Exporta variantes cuadradas de 512x512, 192x192, 144x144, 96x96, 72x72 y 48x48 para cubrir todas las densidades estándar.

## Reemplazar los recursos del launcher
1. Copia los PNG a las carpetas `android/app/src/main/res/mipmap-<densidad>/` conservando los nombres `ic_launcher.png` e `ic_launcher_round.png`.
2. Para Android 8.0+ actualiza también `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` y `ic_launcher_round.xml` si quieres usar un PNG distinto como foreground. Ejemplo de `ic_launcher.xml` cuando el PNG ya no tiene márgenes adicionales:

   ```xml
   <adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
       <background android:drawable="@mipmap/ic_launcher" />
       <foreground android:drawable="@mipmap/ic_launcher" />
   </adaptive-icon>
   ```

3. Ejecuta `flutter clean && flutter run` para limpiar caches y comprobar que los iconos actualizados se muestran sin anillos ni rellenos extra.

## Usar un vector sin espacio libre
1. Abre `android/app/src/main/res/drawable/ic_launcher_foreground.xml` si prefieres un vector en lugar de PNG.
2. Ajusta el atributo `android:pathData` para ocupar el viewport completo; por ejemplo, `M54,0a54,54 0 1,0 0,108a54,54 0 1,0 0,-108z` dibuja un círculo que toca los bordes del icono adaptativo.
3. Guarda el archivo y recompila la app para verificar que no quedan márgenes visibles.
