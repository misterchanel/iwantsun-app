import 'package:dio/dio.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/core/error/exceptions.dart';

/// Intercepteur pour logger les requêtes et réponses API
class LoggingInterceptor extends Interceptor {
  final AppLogger _logger = AppLogger();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.apiRequest(
      options.method,
      options.uri.toString(),
      params: options.queryParameters,
    );
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.apiResponse(
      response.requestOptions.uri.toString(),
      response.statusCode ?? 0,
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.apiError(
      err.requestOptions.uri.toString(),
      err.message,
      err.stackTrace,
    );
    super.onError(err, handler);
  }
}

/// Intercepteur pour gérer les erreurs et les transformer en exceptions personnalisées
class ErrorInterceptor extends Interceptor {
  final AppLogger _logger = AppLogger();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    Exception exception;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        exception = TimeoutException('La requête a expiré. Veuillez réessayer.');
        break;

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final message = _getErrorMessage(err.response);

        if (statusCode == 429) {
          exception = RateLimitException(
            'Trop de requêtes. Veuillez patienter avant de réessayer.',
            _getRetryAfter(err.response),
          );
        } else if (statusCode == 401 || statusCode == 403) {
          exception = ApiKeyException(
            'Clé API invalide ou manquante. Veuillez vérifier votre configuration.',
          );
        } else if (statusCode != null && statusCode >= 500) {
          exception = ServerException(
            'Erreur serveur. Veuillez réessayer plus tard.',
            statusCode,
          );
        } else {
          exception = ServerException(message, statusCode);
        }
        break;

      case DioExceptionType.cancel:
        exception = NetworkException('La requête a été annulée.');
        break;

      case DioExceptionType.connectionError:
        exception = NetworkException(
          'Erreur de connexion. Vérifiez votre connexion Internet.',
        );
        break;

      default:
        exception = NetworkException(
          'Une erreur réseau est survenue: ${err.message}',
        );
    }

    _logger.error('API Error intercepted', exception);
    handler.reject(DioException(
      requestOptions: err.requestOptions,
      error: exception,
      type: err.type,
      response: err.response,
    ));
  }

  String _getErrorMessage(Response? response) {
    if (response?.data is Map) {
      final data = response!.data as Map<String, dynamic>;
      return data['message'] ??
          data['error'] ??
          data['detail'] ??
          'Une erreur est survenue';
    }
    return 'Une erreur est survenue';
  }

  DateTime? _getRetryAfter(Response? response) {
    if (response?.headers.value('retry-after') != null) {
      try {
        final seconds = int.parse(response!.headers.value('retry-after')!);
        return DateTime.now().add(Duration(seconds: seconds));
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}

/// Intercepteur pour ajouter des headers personnalisés
class HeaderInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Ajouter des headers communs à toutes les requêtes (ne pas écraser les headers existants)
    options.headers.putIfAbsent('Accept', () => 'application/json');
    
    // Ne pas définir Content-Type par défaut si déjà défini
    if (!options.headers.containsKey('Content-Type')) {
      options.headers['Content-Type'] = 'application/json';
    }

    super.onRequest(options, handler);
  }
}
