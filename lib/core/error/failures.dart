import 'package:equatable/equatable.dart';

/// Classe de base abstraite pour représenter les échecs
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure(this.message, [this.statusCode]);

  @override
  List<Object?> get props => [message, statusCode];
}

/// Échec lors d'une requête serveur
class ServerFailure extends Failure {
  const ServerFailure(String message, [int? statusCode])
      : super(message, statusCode);
}

/// Échec lors d'une requête de cache
class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

/// Échec de connexion réseau
class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message);
}

/// Échec de validation
class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

/// Échec dû à un dépassement du délai d'attente
class TimeoutFailure extends Failure {
  const TimeoutFailure(String message) : super(message);
}

/// Échec dû à un rate limiting
class RateLimitFailure extends Failure {
  const RateLimitFailure(String message) : super(message);
}

/// Échec dû à une clé API invalide ou manquante
class ApiKeyFailure extends Failure {
  const ApiKeyFailure(String message) : super(message);
}

/// Échec inattendu
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(String message) : super(message);
}
