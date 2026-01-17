import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iwantsun/core/services/logger_service.dart';

/// Types de badges disponibles
enum BadgeType {
  explorer,      // Exploration
  collector,     // Collection de favoris
  traveler,      // Voyages
  social,        // Partage
  veteran,       // Ancienneté
  special,       // Événements spéciaux
}

/// Niveau de rareté des badges
enum BadgeRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

/// Définition d'un badge
class Badge {
  final String id;
  final String name;
  final String description;
  final String iconEmoji;
  final BadgeType type;
  final BadgeRarity rarity;
  final int requiredProgress;
  final DateTime? unlockedAt;
  final int currentProgress;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconEmoji,
    required this.type,
    required this.rarity,
    required this.requiredProgress,
    this.unlockedAt,
    this.currentProgress = 0,
  });

  bool get isUnlocked => unlockedAt != null;
  double get progressPercentage =>
      (currentProgress / requiredProgress).clamp(0.0, 1.0);

  Color get rarityColor {
    switch (rarity) {
      case BadgeRarity.common:
        return const Color(0xFF9E9E9E);
      case BadgeRarity.uncommon:
        return const Color(0xFF4CAF50);
      case BadgeRarity.rare:
        return const Color(0xFF2196F3);
      case BadgeRarity.epic:
        return const Color(0xFF9C27B0);
      case BadgeRarity.legendary:
        return const Color(0xFFFF9800);
    }
  }

  String get rarityName {
    switch (rarity) {
      case BadgeRarity.common:
        return 'Commun';
      case BadgeRarity.uncommon:
        return 'Peu commun';
      case BadgeRarity.rare:
        return 'Rare';
      case BadgeRarity.epic:
        return 'Épique';
      case BadgeRarity.legendary:
        return 'Légendaire';
    }
  }

  Badge copyWith({
    DateTime? unlockedAt,
    int? currentProgress,
  }) {
    return Badge(
      id: id,
      name: name,
      description: description,
      iconEmoji: iconEmoji,
      type: type,
      rarity: rarity,
      requiredProgress: requiredProgress,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      currentProgress: currentProgress ?? this.currentProgress,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'currentProgress': currentProgress,
  };
}

/// Statistiques de l'utilisateur
class UserStats {
  final int totalSearches;
  final int totalFavorites;
  final int totalCountriesExplored;
  final int totalDestinationsViewed;
  final int consecutiveDays;
  final int totalShares;
  final DateTime? firstUseDate;
  final DateTime? lastActiveDate;

  const UserStats({
    this.totalSearches = 0,
    this.totalFavorites = 0,
    this.totalCountriesExplored = 0,
    this.totalDestinationsViewed = 0,
    this.consecutiveDays = 0,
    this.totalShares = 0,
    this.firstUseDate,
    this.lastActiveDate,
  });

  int get level {
    final xp = totalXP;
    if (xp >= 10000) return 10;
    if (xp >= 5000) return 9;
    if (xp >= 2500) return 8;
    if (xp >= 1500) return 7;
    if (xp >= 1000) return 6;
    if (xp >= 600) return 5;
    if (xp >= 350) return 4;
    if (xp >= 150) return 3;
    if (xp >= 50) return 2;
    return 1;
  }

  int get totalXP {
    return (totalSearches * 10) +
           (totalFavorites * 25) +
           (totalCountriesExplored * 50) +
           (totalDestinationsViewed * 5) +
           (consecutiveDays * 15) +
           (totalShares * 20);
  }

  int get xpForNextLevel {
    switch (level) {
      case 1: return 50;
      case 2: return 150;
      case 3: return 350;
      case 4: return 600;
      case 5: return 1000;
      case 6: return 1500;
      case 7: return 2500;
      case 8: return 5000;
      case 9: return 10000;
      default: return 999999;
    }
  }

  double get levelProgress {
    final prevXP = level > 1 ? [0, 50, 150, 350, 600, 1000, 1500, 2500, 5000][level - 1] : 0;
    final nextXP = xpForNextLevel;
    return ((totalXP - prevXP) / (nextXP - prevXP)).clamp(0.0, 1.0);
  }

  String get levelTitle {
    switch (level) {
      case 1: return 'Débutant';
      case 2: return 'Explorateur';
      case 3: return 'Voyageur';
      case 4: return 'Aventurier';
      case 5: return 'Globe-trotter';
      case 6: return 'Nomade';
      case 7: return 'Expert';
      case 8: return 'Maître';
      case 9: return 'Légende';
      case 10: return 'Soleil Vivant';
      default: return 'Débutant';
    }
  }

  Map<String, dynamic> toJson() => {
    'totalSearches': totalSearches,
    'totalFavorites': totalFavorites,
    'totalCountriesExplored': totalCountriesExplored,
    'totalDestinationsViewed': totalDestinationsViewed,
    'consecutiveDays': consecutiveDays,
    'totalShares': totalShares,
    'firstUseDate': firstUseDate?.toIso8601String(),
    'lastActiveDate': lastActiveDate?.toIso8601String(),
  };

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalSearches: json['totalSearches'] as int? ?? 0,
      totalFavorites: json['totalFavorites'] as int? ?? 0,
      totalCountriesExplored: json['totalCountriesExplored'] as int? ?? 0,
      totalDestinationsViewed: json['totalDestinationsViewed'] as int? ?? 0,
      consecutiveDays: json['consecutiveDays'] as int? ?? 0,
      totalShares: json['totalShares'] as int? ?? 0,
      firstUseDate: json['firstUseDate'] != null
          ? DateTime.parse(json['firstUseDate'] as String)
          : null,
      lastActiveDate: json['lastActiveDate'] != null
          ? DateTime.parse(json['lastActiveDate'] as String)
          : null,
    );
  }

  UserStats copyWith({
    int? totalSearches,
    int? totalFavorites,
    int? totalCountriesExplored,
    int? totalDestinationsViewed,
    int? consecutiveDays,
    int? totalShares,
    DateTime? firstUseDate,
    DateTime? lastActiveDate,
  }) {
    return UserStats(
      totalSearches: totalSearches ?? this.totalSearches,
      totalFavorites: totalFavorites ?? this.totalFavorites,
      totalCountriesExplored: totalCountriesExplored ?? this.totalCountriesExplored,
      totalDestinationsViewed: totalDestinationsViewed ?? this.totalDestinationsViewed,
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      totalShares: totalShares ?? this.totalShares,
      firstUseDate: firstUseDate ?? this.firstUseDate,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }
}

/// Service de gamification
class GamificationService extends ChangeNotifier {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  final AppLogger _logger = AppLogger();
  static const String _statsKey = 'user_stats';
  static const String _badgesKey = 'user_badges';

  UserStats _stats = const UserStats();
  final Map<String, Badge> _badges = {};
  final List<Badge> _recentlyUnlocked = [];
  bool _isInitialized = false;

  UserStats get stats => _stats;
  List<Badge> get allBadges => _getAllBadges();
  List<Badge> get unlockedBadges => allBadges.where((b) => b.isUnlocked).toList();
  List<Badge> get lockedBadges => allBadges.where((b) => !b.isUnlocked).toList();
  List<Badge> get recentlyUnlocked => _recentlyUnlocked;
  bool get isInitialized => _isInitialized;

  /// Tous les badges disponibles
  List<Badge> _getAllBadges() {
    return [
      // Exploration
      _getBadge('first_search', 'Première Recherche', 'Effectuez votre première recherche', '🔍', BadgeType.explorer, BadgeRarity.common, 1),
      _getBadge('explorer_10', 'Curieux', 'Effectuez 10 recherches', '🧭', BadgeType.explorer, BadgeRarity.uncommon, 10),
      _getBadge('explorer_50', 'Explorateur', 'Effectuez 50 recherches', '🗺️', BadgeType.explorer, BadgeRarity.rare, 50),
      _getBadge('explorer_100', 'Grand Explorateur', 'Effectuez 100 recherches', '🌍', BadgeType.explorer, BadgeRarity.epic, 100),

      // Favoris
      _getBadge('first_fav', 'Premier Coup de Cœur', 'Ajoutez votre premier favori', '❤️', BadgeType.collector, BadgeRarity.common, 1),
      _getBadge('collector_5', 'Collectionneur', 'Ajoutez 5 favoris', '💝', BadgeType.collector, BadgeRarity.uncommon, 5),
      _getBadge('collector_20', 'Grand Collectionneur', 'Ajoutez 20 favoris', '💖', BadgeType.collector, BadgeRarity.rare, 20),
      _getBadge('collector_50', 'Maître Collectionneur', 'Ajoutez 50 favoris', '👑', BadgeType.collector, BadgeRarity.legendary, 50),

      // Pays
      _getBadge('world_3', 'Voyageur', 'Explorez 3 pays différents', '✈️', BadgeType.traveler, BadgeRarity.uncommon, 3),
      _getBadge('world_10', 'Globe-trotter', 'Explorez 10 pays différents', '🌎', BadgeType.traveler, BadgeRarity.rare, 10),
      _getBadge('world_25', 'Citoyen du Monde', 'Explorez 25 pays différents', '🌏', BadgeType.traveler, BadgeRarity.legendary, 25),

      // Partage
      _getBadge('first_share', 'Ambassadeur', 'Partagez votre première destination', '📤', BadgeType.social, BadgeRarity.common, 1),
      _getBadge('share_10', 'Influenceur', 'Partagez 10 destinations', '📢', BadgeType.social, BadgeRarity.rare, 10),

      // Fidélité
      _getBadge('days_7', 'Habitué', 'Utilisez l\'app 7 jours consécutifs', '📅', BadgeType.veteran, BadgeRarity.uncommon, 7),
      _getBadge('days_30', 'Fidèle', 'Utilisez l\'app 30 jours consécutifs', '🏆', BadgeType.veteran, BadgeRarity.epic, 30),

      // Spéciaux
      _getBadge('level_5', 'Expert Soleil', 'Atteignez le niveau 5', '☀️', BadgeType.special, BadgeRarity.rare, 5),
      _getBadge('level_10', 'Soleil Vivant', 'Atteignez le niveau 10', '🌟', BadgeType.special, BadgeRarity.legendary, 10),
    ];
  }

  Badge _getBadge(String id, String name, String desc, String emoji,
                  BadgeType type, BadgeRarity rarity, int required) {
    final saved = _badges[id];
    return Badge(
      id: id,
      name: name,
      description: desc,
      iconEmoji: emoji,
      type: type,
      rarity: rarity,
      requiredProgress: required,
      unlockedAt: saved?.unlockedAt,
      currentProgress: saved?.currentProgress ?? 0,
    );
  }

  /// Initialiser le service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Charger les stats
      final statsJson = prefs.getString(_statsKey);
      if (statsJson != null) {
        _stats = UserStats.fromJson(jsonDecode(statsJson) as Map<String, dynamic>);
      } else {
        _stats = UserStats(firstUseDate: DateTime.now(), lastActiveDate: DateTime.now());
      }

      // Charger les badges
      final badgesJson = prefs.getString(_badgesKey);
      if (badgesJson != null) {
        final badgesData = jsonDecode(badgesJson) as Map<String, dynamic>;
        for (final entry in badgesData.entries) {
          final data = entry.value as Map<String, dynamic>;
          _badges[entry.key] = Badge(
            id: entry.key,
            name: '',
            description: '',
            iconEmoji: '',
            type: BadgeType.special,
            rarity: BadgeRarity.common,
            requiredProgress: 1,
            unlockedAt: data['unlockedAt'] != null
                ? DateTime.parse(data['unlockedAt'] as String)
                : null,
            currentProgress: data['currentProgress'] as int? ?? 0,
          );
        }
      }

      // Vérifier les jours consécutifs
      _checkConsecutiveDays();

      _isInitialized = true;
      notifyListeners();
      _logger.info('GamificationService initialized');
    } catch (e) {
      _logger.error('Failed to initialize GamificationService', e);
      _isInitialized = true;
      notifyListeners();
    }
  }

  void _checkConsecutiveDays() {
    final lastActive = _stats.lastActiveDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastActive != null) {
      final lastDay = DateTime(lastActive.year, lastActive.month, lastActive.day);
      final diff = today.difference(lastDay).inDays;

      if (diff == 1) {
        _stats = _stats.copyWith(
          consecutiveDays: _stats.consecutiveDays + 1,
          lastActiveDate: now,
        );
      } else if (diff > 1) {
        _stats = _stats.copyWith(
          consecutiveDays: 1,
          lastActiveDate: now,
        );
      }
    } else {
      _stats = _stats.copyWith(
        consecutiveDays: 1,
        lastActiveDate: now,
      );
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_statsKey, jsonEncode(_stats.toJson()));

      final badgesData = <String, dynamic>{};
      for (final badge in _badges.entries) {
        badgesData[badge.key] = badge.value.toJson();
      }
      await prefs.setString(_badgesKey, jsonEncode(badgesData));
    } catch (e) {
      _logger.error('Failed to save gamification data', e);
    }
  }

  /// Enregistrer une recherche
  Future<void> recordSearch() async {
    _stats = _stats.copyWith(
      totalSearches: _stats.totalSearches + 1,
      lastActiveDate: DateTime.now(),
    );
    await _checkAndUnlockBadges();
    await _save();
    notifyListeners();
  }

  /// Enregistrer un favori ajouté
  Future<void> recordFavoriteAdded() async {
    _stats = _stats.copyWith(
      totalFavorites: _stats.totalFavorites + 1,
      lastActiveDate: DateTime.now(),
    );
    await _checkAndUnlockBadges();
    await _save();
    notifyListeners();
  }

  /// Enregistrer un pays exploré
  Future<void> recordCountryExplored() async {
    _stats = _stats.copyWith(
      totalCountriesExplored: _stats.totalCountriesExplored + 1,
      lastActiveDate: DateTime.now(),
    );
    await _checkAndUnlockBadges();
    await _save();
    notifyListeners();
  }

  /// Enregistrer un partage
  Future<void> recordShare() async {
    _stats = _stats.copyWith(
      totalShares: _stats.totalShares + 1,
      lastActiveDate: DateTime.now(),
    );
    await _checkAndUnlockBadges();
    await _save();
    notifyListeners();
  }

  /// Vérifier et débloquer les badges
  Future<void> _checkAndUnlockBadges() async {
    _recentlyUnlocked.clear();

    // Vérifier les badges de recherche
    _checkBadge('first_search', _stats.totalSearches);
    _checkBadge('explorer_10', _stats.totalSearches);
    _checkBadge('explorer_50', _stats.totalSearches);
    _checkBadge('explorer_100', _stats.totalSearches);

    // Vérifier les badges de favoris
    _checkBadge('first_fav', _stats.totalFavorites);
    _checkBadge('collector_5', _stats.totalFavorites);
    _checkBadge('collector_20', _stats.totalFavorites);
    _checkBadge('collector_50', _stats.totalFavorites);

    // Vérifier les badges de pays
    _checkBadge('world_3', _stats.totalCountriesExplored);
    _checkBadge('world_10', _stats.totalCountriesExplored);
    _checkBadge('world_25', _stats.totalCountriesExplored);

    // Vérifier les badges de partage
    _checkBadge('first_share', _stats.totalShares);
    _checkBadge('share_10', _stats.totalShares);

    // Vérifier les badges de fidélité
    _checkBadge('days_7', _stats.consecutiveDays);
    _checkBadge('days_30', _stats.consecutiveDays);

    // Vérifier les badges de niveau
    _checkBadge('level_5', _stats.level);
    _checkBadge('level_10', _stats.level);
  }

  void _checkBadge(String id, int progress) {
    final badge = allBadges.firstWhere((b) => b.id == id);

    // Mettre à jour le progress
    _badges[id] = badge.copyWith(currentProgress: progress);

    // Débloquer si nécessaire
    if (!badge.isUnlocked && progress >= badge.requiredProgress) {
      _badges[id] = badge.copyWith(
        unlockedAt: DateTime.now(),
        currentProgress: progress,
      );
      _recentlyUnlocked.add(_badges[id]!);
      _logger.info('Badge unlocked: ${badge.name}');
    }
  }

  /// Obtenir le badge le plus récent débloqué
  Badge? get lastUnlockedBadge =>
      _recentlyUnlocked.isNotEmpty ? _recentlyUnlocked.last : null;

  /// Effacer les badges récemment débloqués (après affichage)
  void clearRecentlyUnlocked() {
    _recentlyUnlocked.clear();
  }
}
