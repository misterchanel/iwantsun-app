import 'package:dio/dio.dart';
import 'package:iwantsun/core/config/env_config.dart';
import 'package:iwantsun/core/constants/api_constants.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/core/error/exceptions.dart';

/// Service d'authentification pour l'API Amadeus
class AmadeusAuthService {
  static final AmadeusAuthService _instance = AmadeusAuthService._internal();
  final AppLogger _logger = AppLogger();
  final Dio _dio = Dio();

  String? _accessToken;
  DateTime? _tokenExpiry;

  factory AmadeusAuthService() => _instance;

  AmadeusAuthService._internal();

  /// Obtient un access token valide
  Future<String> getAccessToken() async {
    // Vérifier si on a déjà un token valide
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      _logger.debug('Using cached Amadeus access token');
      return _accessToken!;
    }

    // Sinon, obtenir un nouveau token
    _logger.info('Requesting new Amadeus access token');
    return await _requestNewToken();
  }

  /// Demande un nouveau token à l'API Amadeus
  Future<String> _requestNewToken() async {
    try {
      if (!EnvConfig.hasAmadeusConfig) {
        throw ApiKeyException(
          'Les clés API Amadeus ne sont pas configurées. '
          'Veuillez définir AMADEUS_API_KEY et AMADEUS_API_SECRET dans votre fichier .env',
        );
      }

      final response = await _dio.post(
        ApiConstants.amadeusAuthUrl,
        data: {
          'grant_type': 'client_credentials',
          'client_id': EnvConfig.amadeusApiKey,
          'client_secret': EnvConfig.amadeusApiSecret,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      if (response.statusCode == 200) {
        _accessToken = response.data['access_token'] as String;
        final expiresIn = response.data['expires_in'] as int;

        // Soustraire 60 secondes pour éviter d'utiliser un token expiré
        _tokenExpiry = DateTime.now().add(
          Duration(seconds: expiresIn - 60),
        );

        _logger.info('Amadeus access token obtained successfully');
        return _accessToken!;
      } else {
        throw ServerException(
          'Failed to obtain Amadeus access token',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logger.error('Failed to obtain Amadeus access token', e);

      if (e.response?.statusCode == 401) {
        throw ApiKeyException(
          'Clés API Amadeus invalides. Vérifiez votre configuration.',
        );
      }

      throw ServerException(
        'Erreur lors de l\'authentification Amadeus: ${e.message}',
        e.response?.statusCode,
      );
    } catch (e, stackTrace) {
      _logger.error('Unexpected error during Amadeus authentication', e, stackTrace);
      throw ServerException('Erreur inattendue lors de l\'authentification: $e');
    }
  }

  /// Réinitialise le token (force un nouveau token à la prochaine requête)
  void resetToken() {
    _accessToken = null;
    _tokenExpiry = null;
    _logger.debug('Amadeus access token reset');
  }
}
