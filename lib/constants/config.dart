class AppConfig {
  static const String url = 'https://24a9-103-215-211-179.ngrok-free.app'; // Backend Base URL
  static const String baseUrl = 'https://24a9-103-215-211-179.ngrok-free.app/api/v1'; // Backend Base URL
  static const String authUrl = '$baseUrl/auth'; // Auth URL
  static const String manifestsUrl = '$baseUrl/manifests'; // Manifests URL
  static const String entitiesUrl = '$baseUrl/entities'; // Entities URL
  static const String recordsUrl = '$baseUrl/records'; // Entities URL
  static const String socketUrl = '$url/record_status'; // Entities URL
}
