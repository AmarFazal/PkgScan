class AppConfig {
  static const String url = 'https://itemizer-api.soniclister.ca'; // Backend Base URL
  static const String baseUrl = 'https://itemizer-api.soniclister.ca/api/v1'; // Backend Base URL
  static const String authUrl = '$baseUrl/auth'; // Auth URL
  static const String manifestsUrl = '$baseUrl/manifests'; // Manifests URL
  static const String entitiesUrl = '$baseUrl/entities'; // Entities URL
  static const String recordsUrl = '$baseUrl/records'; // Entities URL
  static const String socketUrl = 'wss://itemizer-api.soniclister.ca/record_status'; // Entities URL
}
