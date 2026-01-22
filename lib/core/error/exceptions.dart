/// Exception de base pour les erreurs réseau
class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  NetworkException(this.message, [this.statusCode]);

  @override
  String toString() => 'NetworkException: $message (Code: $statusCode)';
}

/// Exception serveur (erreur API)
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException(this.message, [this.statusCode]);

  @override
  String toString() => 'ServerException: $message (Code: $statusCode)';
}

/// Exception cache
class CacheException implements Exception {
  final String message;

  CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

/// Exception de validation
class ValidationException implements Exception {
  final String message;

  ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}

/// Exception de timeout
class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}

/// Exception de rate limiting
class RateLimitException implements Exception {
  final String message;
  final DateTime? retryAfter;

  RateLimitException(this.message, [this.retryAfter]);

  @override
  String toString() =>
      'RateLimitException: $message ${retryAfter != null ? "(Retry after: $retryAfter)" : ""}';
}

/// Exception de clé API
class ApiKeyException implements Exception {
  final String message;

  ApiKeyException(this.message);

  @override
  String toString() => 'ApiKeyException: $message';
}

/// Types d'erreurs Firebase
enum FirebaseErrorType {
  noResults,
  networkError,
  timeout,
  invalidData,
  generic,
}

/// Exception Firebase
class FirebaseSearchException implements Exception {
  final String message;
  final FirebaseErrorType type;

  FirebaseSearchException(this.message, this.type);

  @override
  String toString() => 'FirebaseSearchException[$type]: $message';
}
