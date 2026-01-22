# 🔧 Configuration Firebase pour IWantSun

Ce document liste les configurations Firebase nécessaires pour le projet.

## ✅ Configurations Appliquées dans le Code

### 1. Firestore - Ignorer les Valeurs Undefined

**Configuration** : `ignoreUndefinedProperties: true`

**Emplacement** : `functions/src/index.ts`

```typescript
const db = admin.firestore();
db.settings({ ignoreUndefinedProperties: true });
```

**Effet** : Firestore ignorera automatiquement les champs `undefined` au lieu de lancer une erreur.

**Note** : Le code filtre déjà les `undefined` (notamment pour `country`), mais cette configuration sert de sécurité supplémentaire.

### 2. Cloud Functions - Configuration

**Région** : `europe-west1`

**Timeout** : 60 secondes

**Mémoire** : 512MiB

**Emplacement** : `functions/src/index.ts`

```typescript
export const searchDestinations = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 60,
    memory: "512MiB",
  },
  // ...
);
```

### 3. Authentification Anonyme

**Configuration** : Activée dans l'app Flutter

**Emplacement** : `lib/main.dart`

```dart
await auth.signInAnonymously();
```

**Effet** : Permet de sécuriser les appels Cloud Functions sans authentification utilisateur complète.

## 📋 Configurations à Vérifier dans Firebase Console

### 1. Firestore Rules

**Fichier** : `firestore.rules`

**État actuel** : Les collections de cache sont protégées (seul l'Admin SDK peut y accéder)

**Vérification** :
1. Aller dans Firebase Console > Firestore Database > Rules
2. Vérifier que les règles correspondent à `firestore.rules`
3. Déployer les règles si nécessaire : `firebase deploy --only firestore:rules`

### 2. Cloud Functions - Permissions

**Vérification** :
1. Aller dans Firebase Console > Functions
2. Vérifier que `searchDestinations` est déployée et active
3. Vérifier les permissions IAM pour `cloudfunctions.invoker`

### 3. Firestore - Indexes

**Vérification** :
1. Aller dans Firebase Console > Firestore Database > Indexes
2. Vérifier qu'aucun index composite n'est requis (les collections de cache utilisent des clés simples)

### 4. Authentification - Méthodes de Connexion

**Vérification** :
1. Aller dans Firebase Console > Authentication > Sign-in method
2. Vérifier que "Anonymous" est **activé**
3. Si non activé, l'activer

### 5. Quotas et Limites

**Vérification** :
1. Aller dans Firebase Console > Usage and billing
2. Vérifier les quotas Firestore (lectures/écritures)
3. Vérifier les quotas Cloud Functions (invocations, durée d'exécution)

## 🛠️ Commandes de Déploiement

### Déployer les Règles Firestore

```bash
firebase deploy --only firestore:rules
```

### Déployer les Cloud Functions

```bash
cd functions
firebase deploy --only functions:searchDestinations
```

### Déployer Tout

```bash
firebase deploy
```

## 🔍 Vérifications Post-Déploiement

### 1. Vérifier les Logs Cloud Functions

```bash
cd functions
firebase functions:log --only searchDestinations
```

### 2. Tester la Cloud Function

Dans Firebase Console > Functions > `searchDestinations` > Testing

### 3. Vérifier Firestore

Dans Firebase Console > Firestore Database :
- Vérifier que les collections `cache_cities` et `cache_weather` existent
- Vérifier qu'elles sont remplies correctement (pas de `undefined`)

## ⚠️ Problèmes Courants

### Erreur : "Cannot use undefined as a Firestore value"

**Cause** : Le code tente d'écrire un champ `undefined` dans Firestore.

**Solution** :
1. Vérifier que `db.settings({ ignoreUndefinedProperties: true })` est appelé
2. Vérifier que le code filtre les `undefined` avant d'écrire dans Firestore

### Erreur : "Permission denied" sur Firestore

**Cause** : Les règles Firestore bloquent l'accès.

**Solution** :
1. Vérifier que les règles Firestore sont déployées
2. Vérifier que l'Admin SDK est utilisé dans Cloud Functions (pas besoin de règles pour l'Admin SDK)

### Erreur : "Function not found"

**Cause** : La Cloud Function n'est pas déployée ou la région est incorrecte.

**Solution** :
1. Vérifier que la fonction est déployée : `firebase functions:list`
2. Vérifier que la région dans le code correspond à celle de l'app Flutter

## 📝 Résumé

| Configuration | Emplacement | Status |
|--------------|-------------|--------|
| `ignoreUndefinedProperties` | `functions/src/index.ts` | ✅ Configuré |
| Région Cloud Functions | `functions/src/index.ts` | ✅ `europe-west1` |
| Timeout Cloud Functions | `functions/src/index.ts` | ✅ 60 secondes |
| Authentification anonyme | `lib/main.dart` | ✅ Activée |
| Firestore Rules | `firestore.rules` | ✅ Protégées |

---

**Date de mise à jour** : 18 Janvier 2026