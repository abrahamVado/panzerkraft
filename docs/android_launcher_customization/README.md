# Red TOSUR Android Launcher Customization

## Cambiar el nombre mostrado
1. Abre `android/app/src/main/AndroidManifest.xml`.
2. Verifica que el atributo `android:label` del nodo `<application>` contenga `Red TOSUR`.
3. Sincroniza el proyecto o recompila la app para que el cambio se refleje en el lanzador de Android.

## Preparar iconos sin márgenes
1. Asegúrate de que tu arte final no contenga transparencias ni bordes innecesarios. Trabaja siempre sobre un lienzo cuadrado con tu diseño centrado.
2. Convierte cada versión final a formato PNG. Android Launcher solo admite PNG cuando se quiere un bitmap sin adaptaciones automáticas; los archivos `.jpeg` pierden transparencia y el sistema añade bordes al convertirlos.
3. Exporta variantes cuadradas de 512x512, 192x192, 144x144, 96x96, 72x72 y 48x48 para cubrir todas las densidades estándar.

## Reemplazar los recursos del launcher
1. Copia tus archivos `ic_launcher.png` en cada carpeta `android/app/src/main/res/mipmap-<densidad>/` justo antes de compilar. El repositorio incluye un `.gitignore` en esas carpetas para que GitHub no bloquee los PNG.
2. Duplica el mismo archivo como `ic_launcher_round.png` si no necesitas un diseño circular distinto; Git lo seguirá ignorando.
3. Confirma que no existan archivos `ic_launcher.xml` o vectores antiguos; el manifest ahora apunta directamente a los bitmaps.
4. Ejecuta `flutter clean && flutter run` tras copiar los PNG locales para comprobar que los iconos se muestran sin anillos ni rellenos extra.
