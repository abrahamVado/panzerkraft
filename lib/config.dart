
//1.- AppConfig centraliza las variables de entorno necesarias para integrar servicios externos.
class AppConfig {
  //2.- backendBaseUrl apunta al backend ciudadano utilizado para reportes y consultas.
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  //3.- googleMapsApiKey se inyecta desde el entorno para habilitar Places y Directions API.
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );
}
