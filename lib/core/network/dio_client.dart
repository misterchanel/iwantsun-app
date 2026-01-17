import 'package:dio/dio.dart';
import 'package:iwantsun/core/config/env_config.dart';
import 'package:iwantsun/core/network/dio_interceptors.dart';

/// Client Dio configuré avec intercepteurs
class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio _dio;

  factory DioClient() => _instance;

  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: Duration(seconds: EnvConfig.apiTimeoutSeconds),
        receiveTimeout: Duration(seconds: EnvConfig.apiTimeoutSeconds),
        sendTimeout: Duration(seconds: EnvConfig.apiTimeoutSeconds),
        headers: {
          'User-Agent': 'IWantSun/1.0',
        },
        validateStatus: (status) {
          // Accepter tous les codes de statut pour les gérer dans les intercepteurs
          return status != null && status < 500;
        },
      ),
    );

    // Ajouter les intercepteurs
    _dio.interceptors.addAll([
      HeaderInterceptor(),
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  /// Crée un client Dio avec une URL de base spécifique
  Dio createClient(String baseUrl) {
    final client = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(seconds: EnvConfig.apiTimeoutSeconds),
        receiveTimeout: Duration(seconds: EnvConfig.apiTimeoutSeconds),
        sendTimeout: Duration(seconds: EnvConfig.apiTimeoutSeconds),
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    client.interceptors.addAll([
      HeaderInterceptor(),
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);

    return client;
  }
}
