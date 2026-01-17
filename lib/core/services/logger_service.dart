import 'package:logger/logger.dart';
import 'package:iwantsun/core/config/env_config.dart';

/// Service de logging centralisé
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  late final Logger _logger;

  factory AppLogger() => _instance;

  AppLogger._internal() {
    _initLogger();
  }

  void _initLogger() {
    if (!EnvConfig.enableLogging) {
      return;
    }

    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: false,
        printTime: true,
      ),
    );
  }

  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (EnvConfig.enableLogging) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  void info(String message) {
    if (EnvConfig.enableLogging) {
      _logger.i(message);
    }
  }

  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    if (EnvConfig.enableLogging) {
      _logger.w(message, error: error, stackTrace: stackTrace);
    }
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (EnvConfig.enableLogging) {
      _logger.e(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log une requête API
  void apiRequest(String method, String url, {Map<String, dynamic>? params}) {
    if (EnvConfig.enableLogging) {
      info('API Request: $method $url ${params != null ? "with params: $params" : ""}');
    }
  }

  /// Log une réponse API
  void apiResponse(String url, int statusCode, {dynamic data}) {
    if (EnvConfig.enableLogging) {
      info('API Response: $url - Status: $statusCode');
    }
  }

  /// Log une erreur API
  void apiError(String url, dynamic error, [StackTrace? stackTrace]) {
    if (EnvConfig.enableLogging) {
      this.error('API Error: $url', error, stackTrace);
    }
  }
}
