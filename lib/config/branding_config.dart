//1.- BrandingConfig expone rutas editables para logotipos e imágenes personalizadas.
class BrandingConfig {
  //2.- appLogoSource define el origen del logotipo principal mostrado en la app.
  static const String appLogoSource = String.fromEnvironment(
    'APP_LOGO_SOURCE',
    defaultValue: 'assets/images/branding/logo.png',
  );

  //3.- androidIconSource referencia el ícono cuadrado utilizado por el lanzador Android.
  static const String androidIconSource = String.fromEnvironment(
    'ANDROID_APP_ICON_SOURCE',
    defaultValue: 'assets/android/app_icon.png',
  );

  //4.- travelHistoryFallbackSource establece la miniatura por defecto para viajes.
  static const String travelHistoryFallbackSource = String.fromEnvironment(
    'TRAVEL_HISTORY_FALLBACK_SOURCE',
    defaultValue: 'assets/images/travel_history/default_thumbnail.png',
  );

  //5.- mediaBaseUrl permite apuntar a archivos alojados en Drupal u orígenes remotos.
  static const String mediaBaseUrl = String.fromEnvironment(
    'BRANDING_MEDIA_BASE_URL',
    defaultValue: '',
  );

  //6.- _travelHistoryVehicleGallery enumera imágenes cíclicas para el historial.
  static const List<String> _travelHistoryVehicleGallery = [
    String.fromEnvironment(
      'TRAVEL_HISTORY_IMAGE_1',
      defaultValue: 'assets/images/travel_history/vehicle_1.jpg',
    ),
    String.fromEnvironment(
      'TRAVEL_HISTORY_IMAGE_2',
      defaultValue: 'assets/images/travel_history/vehicle_2.jpg',
    ),
    String.fromEnvironment(
      'TRAVEL_HISTORY_IMAGE_3',
      defaultValue: 'assets/images/travel_history/vehicle_3.jpg',
    ),
    String.fromEnvironment(
      'TRAVEL_HISTORY_IMAGE_4',
      defaultValue: 'assets/images/travel_history/vehicle_4.jpg',
    ),
    String.fromEnvironment(
      'TRAVEL_HISTORY_IMAGE_5',
      defaultValue: 'assets/images/travel_history/vehicle_5.jpg',
    ),
    String.fromEnvironment(
      'TRAVEL_HISTORY_IMAGE_6',
      defaultValue: 'assets/images/travel_history/vehicle_6.jpg',
    ),
  ];

  //7.- resolveMediaPath ajusta rutas relativas usando el dominio configurado.
  static String resolveMediaPath(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '';
    }
    if (isRemoteSource(trimmed)) {
      return trimmed;
    }
    if (trimmed.startsWith('//')) {
      return 'https:$trimmed';
    }
    final base = mediaBaseUrl.trim();
    if (trimmed.startsWith('/')) {
      if (base.isEmpty) {
        return '';
      }
      final normalizedBase = base.endsWith('/') ? base : '$base/';
      final normalizedPath = trimmed.replaceFirst(RegExp(r'^/+'), '');
      return '$normalizedBase$normalizedPath';
    }
    return trimmed;
  }

  //8.- resolvedTravelHistoryFallbackSource entrega la miniatura lista para usarse.
  static String resolvedTravelHistoryFallbackSource() {
    final resolved = resolveMediaPath(travelHistoryFallbackSource);
    return resolved.isEmpty ? travelHistoryFallbackSource : resolved;
  }

  //9.- travelHistoryVehicleGallery filtra elementos vacíos y evita duplicados triviales.
  static List<String> travelHistoryVehicleGallery() {
    final sanitized = <String>[];
    for (final asset in _travelHistoryVehicleGallery) {
      final resolved = resolveMediaPath(asset);
      if (resolved.isEmpty) {
        continue;
      }
      if (!sanitized.contains(resolved)) {
        sanitized.add(resolved);
      }
    }
    if (sanitized.isEmpty) {
      sanitized.add(resolvedTravelHistoryFallbackSource());
    }
    return List.unmodifiable(sanitized);
  }

  //10.- isRemoteSource identifica rutas absolutas que deben cargarse vía red.
  static bool isRemoteSource(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.startsWith('http://') ||
        normalized.startsWith('https://') ||
        normalized.startsWith('data:');
  }
}
