# Configuration de l'affiliation Booking.com

Ce guide vous explique comment configurer votre ID d'affilié Booking.com pour générer des commissions sur les réservations d'hôtels via l'application IWantSun.

## Étape 1: Rejoindre le programme d'affiliation Booking.com

1. Rendez-vous sur: https://www.booking.com/affiliate-program/
2. Cliquez sur "Join now" ou "Rejoindre maintenant"
3. Remplissez le formulaire d'inscription avec vos informations:
   - Type de site: Application mobile
   - Description: Application de recherche de destinations ensoleillées
   - Trafic mensuel estimé
   - Informations de paiement

4. Attendez l'approbation de Booking.com (peut prendre quelques jours)

## Étape 2: Obtenir votre ID d'affilié (AID)

Une fois votre compte approuvé:

1. Connectez-vous à votre compte partenaire Booking.com
2. Accédez à votre tableau de bord partenaire
3. Votre **Affiliate ID (AID)** sera visible dans votre profil ou dans la section "Outils"
4. C'est un nombre comme: `123456` ou `1234567`

## Étape 3: Configurer l'ID dans l'application

1. Ouvrez le fichier: `lib/core/config/affiliate_config.dart`

2. Localisez cette ligne:
   ```dart
   static const String bookingAffiliateId = 'VOTRE_ID_AFFILIE';
   ```

3. Remplacez `VOTRE_ID_AFFILIE` par votre ID d'affilié réel:
   ```dart
   static const String bookingAffiliateId = '123456';
   ```

4. Sauvegardez le fichier

5. Recompilez l'application:
   ```bash
   flutter build apk --release
   ```

## Étape 4: Tester l'intégration

1. Installez la nouvelle version de l'application
2. Recherchez une destination
3. Cliquez sur "Hôtels autour de [ville]"
4. Cliquez sur "Voir les détails" pour un hôtel
5. Vérifiez que l'URL contient `&aid=VOTRE_ID` (vous pouvez voir l'URL dans le navigateur)

## Comment fonctionnent les commissions?

- Lorsqu'un utilisateur clique sur "Voir les détails" d'un hôtel, il est redirigé vers Booking.com
- Grâce à votre ID d'affilié dans l'URL, Booking.com attribue la réservation à votre compte
- Si l'utilisateur effectue une réservation dans les 30 jours, vous recevez une commission
- Les commissions varient généralement entre 25% et 40% du montant que Booking.com gagne

## Suivi des performances

1. Connectez-vous à votre compte partenaire Booking.com
2. Consultez les statistiques:
   - Nombre de clics
   - Nombre de réservations
   - Commissions générées
   - Taux de conversion

## Optimisation

Pour maximiser vos commissions:

- Assurez-vous que les dates de check-in/check-out sont correctement configurées
- Les liens incluent déjà les coordonnées GPS pour une meilleure précision
- Les utilisateurs sont dirigés vers les hôtels les plus proches de leur destination

## Support

- Support Booking.com: https://affiliate.booking.com/help
- Documentation API: https://connect.booking.com/

---

**Note importante:** Sans configuration de l'ID d'affilié, l'application fonctionnera toujours mais vous ne recevrez pas de commissions sur les réservations.
