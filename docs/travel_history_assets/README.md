# Travel history thumbnails

Sigue estos pasos para que las tarjetas del historial muestren una fotografía:

1. Coloca tus imágenes en la carpeta `assets/images/travel_history/`.
2. Asegúrate de incluir al menos un archivo llamado `default_thumbnail.png`; el widget usa ese recurso por omisión.
3. Si deseas personalizar imágenes por viaje, reemplaza `default_thumbnail.png` por una versión diferente después de cada despliegue.
4. Las miniaturas funcionan mejor con una relación 4:3 y un tamaño mínimo sugerido de 800x600 píxeles.
5. Ejecuta `flutter pub get` y reconstruye la aplicación para que Flutter incluya los nuevos archivos.
