import { describe, it, expect } from '@jest/globals';
import * as admin from 'firebase-admin';
import { CallableRequest } from 'firebase-functions/v2/https';
import { searchDestinations } from '../index';

// Initialiser Firebase Admin pour les tests
if (!admin.apps.length) {
  admin.initializeApp();
}

// Coordonnées de Lyon (ville de référence)
const LYON_LAT = 45.7640;
const LYON_LON = 4.8357;

// Dates de test (7 jours à partir d'aujourd'hui)
const getStartDate = (): string => {
  const date = new Date();
  date.setDate(date.getDate() + 1); // Demain
  return date.toISOString().split('T')[0];
};

const getEndDate = (): string => {
  const date = new Date();
  date.setDate(date.getDate() + 7); // Dans 7 jours
  return date.toISOString().split('T')[0];
};

// Helper pour créer une requête de test
const createTestRequest = (data: any): CallableRequest<any> => {
  return {
    data,
    auth: {
      uid: 'test-user',
      token: {} as any,
    },
    rawRequest: {} as any,
  } as CallableRequest<any>;
};

// Helper pour valider la structure d'un résultat
const validateSearchResult = (result: any, testName: string): void => {
  // Validation de la structure Location
  expect(result.location).toBeDefined();
  expect(typeof result.location.id).toBe('string');
  expect(typeof result.location.name).toBe('string');
  expect(typeof result.location.latitude).toBe('number');
  expect(typeof result.location.longitude).toBe('number');
  expect(typeof result.location.distance).toBe('number');
  expect(result.location.distance).toBeGreaterThanOrEqual(0);

  // Validation des coordonnées de Lyon (45.5-46.0, 4.5-5.2 environ)
  if (testName.includes('Lyon')) {
    expect(result.location.latitude).toBeGreaterThanOrEqual(45.0);
    expect(result.location.latitude).toBeLessThanOrEqual(46.0);
    expect(result.location.longitude).toBeGreaterThanOrEqual(4.5);
    expect(result.location.longitude).toBeLessThanOrEqual(5.2);
  }

  // Validation de la structure WeatherForecast
  expect(result.weatherForecast).toBeDefined();
  expect(result.weatherForecast.locationId).toBe(result.location.id);
  expect(Array.isArray(result.weatherForecast.forecasts)).toBe(true);
  expect(result.weatherForecast.forecasts.length).toBeGreaterThan(0);
  expect(typeof result.weatherForecast.averageTemperature).toBe('number');
  expect(typeof result.weatherForecast.weatherScore).toBe('number');
  expect(result.weatherForecast.weatherScore).toBeGreaterThanOrEqual(0);
  expect(result.weatherForecast.weatherScore).toBeLessThanOrEqual(100);

  // Validation de overallScore
  expect(typeof result.overallScore).toBe('number');
  expect(result.overallScore).toBeGreaterThanOrEqual(0);
  expect(result.overallScore).toBeLessThanOrEqual(100);
  expect(result.overallScore).toBe(result.weatherForecast.weatherScore);

  // Validation de chaque prévision météo
  for (let i = 0; i < result.weatherForecast.forecasts.length; i++) {
    const forecast = result.weatherForecast.forecasts[i];
    expect(typeof forecast.date).toBe('string');
    expect(typeof forecast.temperature).toBe('number');
    expect(typeof forecast.minTemperature).toBe('number');
    expect(typeof forecast.maxTemperature).toBe('number');
    expect(typeof forecast.condition).toBe('string');
    expect(['clear', 'partly_cloudy', 'cloudy', 'rain', 'snow']).toContain(forecast.condition);
    expect(Array.isArray(forecast.hourlyData)).toBe(true);

    // Validation température : min <= avg <= max
    expect(forecast.minTemperature).toBeLessThanOrEqual(forecast.temperature);
    expect(forecast.maxTemperature).toBeGreaterThanOrEqual(forecast.temperature);
  }
};

describe('searchDestinations - Tests avec Lyon', () => {
  const startDate = getStartDate();
  const endDate = getEndDate();

  describe('Test 1: Recherche basique - Lyon, rayon 20km, toutes conditions', () => {
    it('doit retourner des résultats avec structure valide', async () => {
      const request = createTestRequest({
        centerLatitude: LYON_LAT,
        centerLongitude: LYON_LON,
        searchRadius: 20,
        startDate,
        endDate,
        desiredConditions: ['clear', 'partly_cloudy', 'cloudy', 'rain'],
        timeSlots: ['morning', 'afternoon', 'evening', 'night'],
      });

      const result = await searchDestinations(request);

      expect(result.error).toBeNull();
      expect(result.results).toBeDefined();
      expect(Array.isArray(result.results)).toBe(true);
      expect(result.results.length).toBeGreaterThanOrEqual(10);
      expect(result.results.length).toBeLessThanOrEqual(50);

      // Vérifier que Lyon est dans les résultats
      const lyonResult = result.results.find((r: any) =>
        r.location.name.toLowerCase().includes('lyon')
      );
      expect(lyonResult).toBeDefined();

      // Valider la structure de tous les résultats
      result.results.forEach((r: any, index: number) => {
        validateSearchResult(r, `Test 1 - Result ${index}`);
      });

      // Vérifier que les résultats sont triés par score décroissant
      for (let i = 1; i < result.results.length; i++) {
        expect(result.results[i - 1].overallScore)
          .toBeGreaterThanOrEqual(result.results[i].overallScore);
      }
    }, 120000); // Timeout de 2 minutes
  });

  describe('Test 2: Recherche avec filtres température - Lyon, 15-25°C', () => {
    it('doit retourner des résultats avec températures dans la plage', async () => {
      const request = createTestRequest({
        centerLatitude: LYON_LAT,
        centerLongitude: LYON_LON,
        searchRadius: 30,
        startDate,
        endDate,
        desiredMinTemperature: 15,
        desiredMaxTemperature: 25,
        desiredConditions: ['clear', 'partly_cloudy'],
        timeSlots: ['morning', 'afternoon'],
      });

      const result = await searchDestinations(request);

      expect(result.error).toBeNull();
      expect(result.results.length).toBeGreaterThan(0);

      // Vérifier que les températures moyennes sont cohérentes
      result.results.forEach((r: any) => {
        validateSearchResult(r, 'Test 2');
        expect(r.weatherForecast.averageTemperature).toBeGreaterThan(-10);
        expect(r.weatherForecast.averageTemperature).toBeLessThan(40);
      });
    }, 120000);
  });

  describe('Test 3: Recherche condition spécifique - Ciel dégagé uniquement', () => {
    it('doit filtrer par condition météo', async () => {
      const request = createTestRequest({
        centerLatitude: LYON_LAT,
        centerLongitude: LYON_LON,
        searchRadius: 40,
        startDate,
        endDate,
        desiredConditions: ['clear'],
        timeSlots: ['morning', 'afternoon'],
      });

      const result = await searchDestinations(request);

      expect(result.error).toBeNull();

      // Si des résultats sont retournés, vérifier qu'ils respectent le filtre de condition
      if (result.results.length > 0) {
        result.results.forEach((r: any) => {
          validateSearchResult(r, 'Test 3');
          // Vérifier que la condition dominante est clear ou partly_cloudy (tolérance)
          const dominantCondition = r.weatherForecast.forecasts
            .reduce((acc: any, f: any) => {
              acc[f.condition] = (acc[f.condition] || 0) + 1;
              return acc;
            }, {});
          const maxCondition = Object.keys(dominantCondition).reduce((a, b) =>
            dominantCondition[a] > dominantCondition[b] ? a : b
          );
          expect(['clear', 'partly_cloudy']).toContain(maxCondition);
        });
      }
    }, 120000);
  });

  describe('Test 4: Validation des valeurs globales', () => {
    it('doit avoir des scores cohérents et des données complètes', async () => {
      const request = createTestRequest({
        centerLatitude: LYON_LAT,
        centerLongitude: LYON_LON,
        searchRadius: 25,
        startDate,
        endDate,
        desiredConditions: ['clear', 'partly_cloudy', 'cloudy'],
        timeSlots: ['morning', 'afternoon', 'evening'],
      });

      const result = await searchDestinations(request);

      expect(result.error).toBeNull();
      expect(result.results.length).toBeGreaterThan(0);

      // Statistiques globales
      const scores = result.results.map((r: any) => r.overallScore);
      const avgScores = result.results.map((r: any) => r.weatherForecast.averageTemperature);
      const distances = result.results.map((r: any) => r.location.distance);

      // Scores doivent être variés
      const scoreRange = Math.max(...scores) - Math.min(...scores);
      expect(scoreRange).toBeGreaterThan(5);

      // Températures moyennes doivent être cohérentes
      const avgTemp = avgScores.reduce((a, b) => a + b, 0) / avgScores.length;
      expect(avgTemp).toBeGreaterThan(-10);
      expect(avgTemp).toBeLessThan(40);

      // Distances doivent être dans le rayon
      const maxDistance = Math.max(...distances);
      expect(maxDistance).toBeLessThanOrEqual(26);

      // Le meilleur score doit être le premier
      const bestScore = Math.max(...scores);
      expect(result.results[0].overallScore).toBe(bestScore);
    }, 120000);
  });

  describe('Test 5: Validation des villes conservées', () => {
    it('doit conserver Lyon et les villes principales autour', async () => {
      const request = createTestRequest({
        centerLatitude: LYON_LAT,
        centerLongitude: LYON_LON,
        searchRadius: 30,
        startDate,
        endDate,
        desiredConditions: ['clear', 'partly_cloudy', 'cloudy', 'rain'],
        timeSlots: ['morning', 'afternoon', 'evening', 'night'],
      });

      const result = await searchDestinations(request);

      expect(result.error).toBeNull();

      const cityNames = result.results.map((r: any) => r.location.name.toLowerCase());

      // Vérifier que Lyon est présent (ou une variante)
      const lyonVariants = ['lyon', 'lion'];
      const hasLyon = lyonVariants.some(variant =>
        cityNames.some(name => name.includes(variant))
      );
      expect(hasLyon).toBe(true);

      // Vérifier l'unicité des villes
      const uniqueCities = new Set(cityNames);
      expect(uniqueCities.size).toBe(cityNames.length);

      // Vérifier que les villes ont des noms valides
      result.results.forEach((r: any) => {
        expect(r.location.name.length).toBeGreaterThan(0);
        expect(r.location.name.trim()).not.toBe('');
      });
    }, 120000);
  });

  describe('Test 6: Edge cases - Rayon max (200km)', () => {
    it('doit limiter le rayon à 200km max', async () => {
      const request = createTestRequest({
        centerLatitude: LYON_LAT,
        centerLongitude: LYON_LON,
        searchRadius: 300, // Plus grand que le max
        startDate,
        endDate,
        desiredConditions: ['clear', 'partly_cloudy', 'cloudy', 'rain'],
        timeSlots: ['morning', 'afternoon'],
      });

      const result = await searchDestinations(request);

      expect(result.error).toBeNull();
      // Le rayon doit être limité à 200km
      if (result.results.length > 0) {
        const maxDistance = Math.max(...result.results.map((r: any) => r.location.distance));
        expect(maxDistance).toBeLessThanOrEqual(202);
      }
    }, 120000);
  });

  describe('Test 7: Validation paramètres d\'entrée', () => {
    it('doit valider les paramètres d\'entrée incorrects', async () => {
      // Test avec rayon négatif
      const request1 = createTestRequest({
        centerLatitude: LYON_LAT,
        centerLongitude: LYON_LON,
        searchRadius: -10,
        startDate,
        endDate,
        desiredConditions: [],
        timeSlots: [],
      });

      const result1 = await searchDestinations.run(request1);
      expect(result1.error).toBeDefined();
      expect(result1.error).toContain('positive');

      // Test avec dates inversées
      const request2 = createTestRequest({
        centerLatitude: LYON_LAT,
        centerLongitude: LYON_LON,
        searchRadius: 20,
        startDate: endDate,
        endDate: startDate,
        desiredConditions: [],
        timeSlots: [],
      });

      const result2 = await searchDestinations.run(request2);
      expect(result2.error).toBeDefined();
      expect(result2.error).toContain('before');
    }, 30000);
  });
});
