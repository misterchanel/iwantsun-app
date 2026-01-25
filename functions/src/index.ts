import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import axios from "axios";

admin.initializeApp();

// Configuration
const OVERPASS_SERVERS = [
  "https://overpass-api.de/api/interpreter",
  "https://overpass.kumi.systems/api/interpreter",
  "https://overpass.openstreetmap.ru/api/interpreter",
  "https://overpass.openstreetmap.fr/api/interpreter", // Ajouté - France
  "https://overpass.nchc.org.tw/api/interpreter", // Ajouté - Taïwan (retesté)
  // Note: Certains serveurs peuvent être temporairement indisponibles
];

const MAX_RETRIES_PER_SERVER = 2; // 3 tentatives au total (1 initiale + 2 retries)
const RETRY_BACKOFF_MS = 1000; // Délai initial de 1 seconde
const MAX_RETRY_DELAY_MS = 5000; // Délai maximum de 5 secondes

const OPEN_METEO_API_URL = "https://api.open-meteo.com/v1/forecast";
const MAX_CITIES_TO_PROCESS = 60;
const CACHE_DURATION_HOURS = 24;
const MAX_SEARCH_RADIUS_KM = 200;

// APIs d'événements
const TICKETMASTER_API_URL = "https://app.ticketmaster.com/discovery/v2/events.json";
const TICKETMASTER_API_KEY = process.env.TICKETMASTER_API_KEY || ""; // À configurer dans Firebase
const OPENEVENTDATABASE_API_URL = "https://api.openeventdatabase.org/event";
const EVENTBRITE_API_URL = "https://www.eventbriteapi.com/v3/events/search/";
const EVENTBRITE_API_KEY = process.env.EVENTBRITE_API_KEY || ""; // À configurer dans Firebase

// Types
interface SearchParams {
  centerLatitude: number;
  centerLongitude: number;
  searchRadius: number;
  startDate: string;
  endDate: string;
  desiredMinTemperature?: number;
  desiredMaxTemperature?: number;
  desiredConditions: string[];
  timeSlots: string[];
}

interface City {
  id: string;
  name: string;
  country?: string;
  latitude: number;
  longitude: number;
  distance: number;
}

interface WeatherData {
  date: string;
  temperature: number;
  minTemperature: number;
  maxTemperature: number;
  condition: string;
  hourlyData: Array<{ hour: number; temperature: number; condition: string }>;
}

interface SearchResult {
  location: City;
  weatherForecast: {
    locationId: string;
    forecasts: WeatherData[];
    averageTemperature: number;
    weatherScore: number;
  };
  overallScore: number;
}

// Firestore
const db = admin.firestore();
db.settings({ ignoreUndefinedProperties: true });

/**
 * Main search function - utilise le mode BATCH pour Open-Meteo (très rapide)
 */
export const searchDestinations = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 120, // 2 minutes suffisent maintenant
    memory: "512MiB",
  },
  async (request) => {
    const data = request.data as SearchParams;

    // Validation des paramètres d'entrée
    if (data.searchRadius <= 0) {
      return { results: [], error: "searchRadius must be positive" };
    }

    if (data.searchRadius > MAX_SEARCH_RADIUS_KM) {
      data.searchRadius = MAX_SEARCH_RADIUS_KM;
    }

    const startDate = new Date(data.startDate);
    const endDate = new Date(data.endDate);
    if (startDate > endDate) {
      return { results: [], error: "startDate must be before endDate" };
    }

    if (data.desiredMinTemperature !== undefined && 
        data.desiredMaxTemperature !== undefined &&
        data.desiredMinTemperature > data.desiredMaxTemperature) {
      return { results: [], error: "desiredMinTemperature must be <= desiredMaxTemperature" };
    }

    console.log("Search request received:", JSON.stringify(data));
    const startTime = Date.now();

    try {
      // 1. Get cities
      let cities: City[];
      try {
        cities = await getCitiesFromOverpass(
          data.centerLatitude,
          data.centerLongitude,
          Math.min(data.searchRadius, MAX_SEARCH_RADIUS_KM)
        );
      } catch (overpassError: any) {
        // Erreur Overpass - retourner message d'erreur spécifique
        const errorMsg = overpassError?.message || String(overpassError);
        console.error("Overpass API error:", errorMsg);
        return {
          results: [],
          error: "Les serveurs de données géographiques sont temporairement indisponibles. Veuillez réessayer dans quelques instants. Si le problème persiste, essayez d'élargir votre zone de recherche."
        };
      }
      
      console.log(`Found ${cities.length} cities in ${Date.now() - startTime}ms`);

      if (cities.length === 0) {
        console.warn("No cities found in the search radius");
        return { 
          results: [], 
          error: "Aucune ville trouvée dans la zone de recherche. Essayez d'élargir le rayon de recherche ou de choisir une autre localisation."
        };
      }

      // 2. Get weather for ALL cities in ONE batch request (très rapide!)
      const citiesToProcess = cities.slice(0, MAX_CITIES_TO_PROCESS);
      const weatherStartTime = Date.now();

      const weatherMap = await getWeatherBatch(
        citiesToProcess,
        data.startDate,
        data.endDate
      );
      console.log(`Weather batch completed for ${citiesToProcess.length} cities in ${Date.now() - weatherStartTime}ms`);
      console.log(`Weather data available for ${weatherMap.size} cities`);

      // 3. Calculate scores and build results
      const results: SearchResult[] = [];
      const selectedHours = getSelectedHours(data.timeSlots);
      let filteredByWeather = 0;
      let filteredByConditions = 0;
      let filteredByTemperature = 0;

      for (const city of citiesToProcess) {
        const weather = weatherMap.get(city.id);
        if (!weather || weather.forecasts.length === 0) {
          filteredByWeather++;
          continue;
        }

        const weatherScore = calculateWeatherScore(weather.forecasts, data, selectedHours);

        // Filter by conditions
        if (data.desiredConditions.length > 0) {
          if (!matchesDesiredConditions(weather.forecasts, data.desiredConditions)) {
            filteredByConditions++;
            continue;
          }
        }

        // Filter by temperature with tolerance (5°C)
        if (data.desiredMinTemperature !== undefined || data.desiredMaxTemperature !== undefined) {
          const avgTemp = weather.avgTemp;
          const minTemp = data.desiredMinTemperature ?? -Infinity;
          const maxTemp = data.desiredMaxTemperature ?? Infinity;
          const tolerance = 5; // Tolérance de 5°C

          console.log(`City ${city.name}: avgTemp=${avgTemp.toFixed(1)}°C, desired range=[${minTemp}°C, ${maxTemp}°C], tolerance=${tolerance}°C`);
          
          if (avgTemp < minTemp - tolerance || avgTemp > maxTemp + tolerance) {
            filteredByTemperature++;
            console.log(`City ${city.name} filtered out by temperature (${avgTemp.toFixed(1)}°C outside range [${(minTemp - tolerance).toFixed(1)}°C, ${(maxTemp + tolerance).toFixed(1)}°C])`);
            continue; // Exclure si trop en dehors de la plage
          }
        }

        results.push({
          location: city,
          weatherForecast: {
            locationId: city.id,
            forecasts: weather.forecasts,
            averageTemperature: weather.avgTemp,
            weatherScore: weatherScore,
          },
          overallScore: weatherScore,
        });
      }

      console.log(`Filtering stats: ${filteredByWeather} cities without weather, ${filteredByConditions} filtered by conditions, ${filteredByTemperature} filtered by temperature`);

      // 4. Sort by score (descending), then by distance (ascending) if scores equal
      results.sort((a, b) => {
        if (Math.abs(b.overallScore - a.overallScore) > 0.01) {
          return b.overallScore - a.overallScore;
        }
        // En cas d'égalité de score, privilégier les plus proches
        return a.location.distance - b.location.distance;
      });

      const totalTime = Date.now() - startTime;
      console.log(`Returning ${results.length} results in ${totalTime}ms`);
      
      if (results.length === 0) {
        console.warn("No results after filtering. Stats:", {
          citiesFound: cities.length,
          citiesProcessed: citiesToProcess.length,
          weatherAvailable: weatherMap.size,
          filteredByWeather,
          filteredByConditions,
          filteredByTemperature,
          searchParams: {
            minTemp: data.desiredMinTemperature,
            maxTemp: data.desiredMaxTemperature,
            conditions: data.desiredConditions,
            timeSlots: data.timeSlots,
          }
        });
      }

      return { results: results.slice(0, 50), error: null };
    } catch (error) {
      console.error("Search error:", error);
      return { results: [], error: String(error) };
    }
  }
);

/**
 * BATCH weather request - fetches weather for ALL cities in ONE API call
 * Open-Meteo supports: latitude=lat1,lat2,lat3&longitude=lon1,lon2,lon3
 */
async function getWeatherBatch(
  cities: City[],
  startDate: string,
  endDate: string
): Promise<Map<string, { forecasts: WeatherData[]; avgTemp: number }>> {
  const resultMap = new Map<string, { forecasts: WeatherData[]; avgTemp: number }>();

  if (cities.length === 0) return resultMap;

  // Build comma-separated lat/lon strings
  const latitudes = cities.map(c => c.latitude.toFixed(4)).join(",");
  const longitudes = cities.map(c => c.longitude.toFixed(4)).join(",");

  try {
    const response = await axios.get(OPEN_METEO_API_URL, {
      params: {
        latitude: latitudes,
        longitude: longitudes,
        start_date: startDate,
        end_date: endDate,
        daily: "temperature_2m_max,temperature_2m_min,weathercode",
        hourly: "temperature_2m,weathercode",
        timezone: "auto",
      },
      timeout: 30000,
    });

    // Response is an array when multiple locations
    const dataArray = Array.isArray(response.data) ? response.data : [response.data];

    for (let i = 0; i < cities.length && i < dataArray.length; i++) {
      const cityData = dataArray[i];
      const city = cities[i];

      if (!cityData || !cityData.daily) {
        console.warn(`Missing weather data for city ${city.name} (${city.id})`);
        continue;
      }

      const forecasts = parseWeatherResponse(cityData);
      const avgTemp = forecasts.length > 0
        ? forecasts.reduce((sum, f) => sum + f.temperature, 0) / forecasts.length
        : 0;

      resultMap.set(city.id, { forecasts, avgTemp });
    }

    return resultMap;
  } catch (error) {
    console.error("Batch weather error:", error);
    return resultMap;
  }
}

/**
 * Get cities from Overpass API with caching
 */
async function getCitiesFromOverpass(
  lat: number,
  lon: number,
  radiusKm: number
): Promise<City[]> {
  // Utiliser une précision plus fine pour éviter les collisions de cache
  // 6 décimales = précision ~11 cm, rayon avec 1 décimale = précision 100m
  const cacheKey = `cities_${lat.toFixed(6)}_${lon.toFixed(6)}_${radiusKm.toFixed(1)}`;
  const cacheRef = db.collection("cache_cities").doc(cacheKey);
  const cached = await cacheRef.get();

  let expiredCities: City[] | null = null;

  if (cached.exists) {
    const data = cached.data();
    if (!data) {
      console.warn("Cache exists but data is null");
    } else {
      // Vérifier la cohérence du cache : le centre doit être proche (tolérance 100m)
      const cachedCenterLat = data.centerLatitude as number | undefined;
      const cachedCenterLon = data.centerLongitude as number | undefined;
      const cachedRadiusKm = data.radiusKm as number | undefined;
      
      let cacheValid = true;
      if (cachedCenterLat !== undefined && cachedCenterLon !== undefined) {
        const centerDistance = calculateDistance(lat, lon, cachedCenterLat, cachedCenterLon);
        // Tolérance de 100 mètres (0.1 km)
        if (centerDistance > 0.1) {
          console.warn(`Cache center mismatch: ${centerDistance.toFixed(3)}km difference (cached: ${cachedCenterLat}, ${cachedCenterLon}, current: ${lat}, ${lon}). Ignoring cache.`);
          cacheValid = false;
        }
      }
      
      // Vérifier que le rayon est similaire (tolérance 1 km)
      if (cacheValid && cachedRadiusKm !== undefined) {
        const radiusDiff = Math.abs(cachedRadiusKm - radiusKm);
        if (radiusDiff > 1.0) {
          console.warn(`Cache radius mismatch: ${radiusDiff.toFixed(1)}km difference (cached: ${cachedRadiusKm}, current: ${radiusKm}). Ignoring cache.`);
          cacheValid = false;
        }
      }
      
      if (cacheValid && data.cities && Date.now() - data.timestamp < CACHE_DURATION_HOURS * 3600000) {
        const cachedCities = data.cities as City[];
        // IMPORTANT: Re-filtrer et re-calculer les distances par rapport au centre actuel
        // car le cache peut contenir des villes d'une recherche précédente avec un centre légèrement différent
        const filteredCities = cachedCities
          .map(city => {
            const distance = calculateDistance(lat, lon, city.latitude, city.longitude);
            return { ...city, distance };
          })
          .filter(city => city.distance <= radiusKm)
          .sort((a, b) => a.distance - b.distance);
        
        console.log(`Cache hit for cities: ${filteredCities.length} cities after re-filtering (from ${cachedCities.length} cached)`);
        return filteredCities;
      } else if (cacheValid && data.cities) {
        // Cache expiré : sauvegarder pour fallback, mais aussi re-filtrer
        const cachedCities = data.cities as City[];
        expiredCities = cachedCities
          .map(city => {
            const distance = calculateDistance(lat, lon, city.latitude, city.longitude);
            return { ...city, distance };
          })
          .filter(city => city.distance <= radiusKm)
          .sort((a, b) => a.distance - b.distance);
        console.log(`Cache expired but available for fallback: ${expiredCities.length} cities after re-filtering (from ${cachedCities.length} cached)`);
      }
    }
  }

  const latDelta = radiusKm / 111.0;
  const lonDelta = radiusKm / (111.0 * Math.cos((lat * Math.PI) / 180));

  const query = `
[out:json][timeout:30];
(
  node["place"="city"](${lat - latDelta},${lon - lonDelta},${lat + latDelta},${lon + lonDelta});
  node["place"="town"](${lat - latDelta},${lon - lonDelta},${lat + latDelta},${lon + lonDelta});
  node["place"="village"](${lat - latDelta},${lon - lonDelta},${lat + latDelta},${lon + lonDelta});
);
out center;
`;

  const errors: string[] = [];
  
  // Fonction helper pour retry avec backoff exponentiel
  const tryOverpassServer = async (serverUrl: string, retryCount: number = 0): Promise<City[] | null> => {
    try {
      const attempt = retryCount + 1;
      if (retryCount > 0) {
        const delay = Math.min(RETRY_BACKOFF_MS * Math.pow(2, retryCount - 1), MAX_RETRY_DELAY_MS);
        console.log(`Retrying Overpass server ${serverUrl} (attempt ${attempt}/${MAX_RETRIES_PER_SERVER + 1}) after ${delay}ms delay`);
        await new Promise(resolve => setTimeout(resolve, delay));
      } else {
        console.log(`Trying Overpass server: ${serverUrl}`);
      }
      
      // Timeout plus long pour certains serveurs
      const timeout = serverUrl.includes('kumi.systems') ? 30000 : 20000;
      const response = await axios.post(serverUrl, query, {
        headers: { "Content-Type": "text/plain" },
        timeout: timeout,
      });

      const elements = response.data.elements || [];
      const cities: City[] = [];

      for (const element of elements) {
        const tags = element.tags || {};
        const name = tags.name || tags["name:fr"] || "";
        if (!name) continue;

        const cityLat = element.type === "node" ? element.lat : element.center?.lat;
        const cityLon = element.type === "node" ? element.lon : element.center?.lon;
        if (!cityLat || !cityLon) continue;

        const distance = calculateDistance(lat, lon, cityLat, cityLon);
        if (distance > radiusKm) continue;

        const cityData: City = {
          id: String(element.id),
          name,
          latitude: cityLat,
          longitude: cityLon,
          distance,
        };

        const country = tags["addr:country"] || tags["is_in:country"];
        if (country) cityData.country = country;

        cities.push(cityData);
      }

      cities.sort((a, b) => a.distance - b.distance);

      if (cities.length > 0) {
        // Stocker le centre et le rayon dans le cache pour validation future
        await cacheRef.set({ 
          cities, 
          centerLatitude: lat,
          centerLongitude: lon,
          radiusKm: radiusKm,
          timestamp: Date.now() 
        });
        console.log(`Successfully fetched ${cities.length} cities from ${serverUrl}${retryCount > 0 ? ` (after ${retryCount} retries)` : ''}`);
        return cities;
      } else {
        console.warn(`Server ${serverUrl} returned empty results`);
        return null;
      }
    } catch (error: any) {
      const errorMsg = error?.message || String(error);
      const statusCode = error?.response?.status;
      const fullError = statusCode ? `${errorMsg} (${statusCode})` : errorMsg;
      
      // Retry si erreur temporaire (timeout, 5xx, 429) et qu'on n'a pas atteint le max
      const isRetryable = retryCount < MAX_RETRIES_PER_SERVER && (
        error?.code === 'ECONNABORTED' || // Timeout
        statusCode >= 500 || // Erreur serveur
        statusCode === 429 || // Rate limit
        statusCode === 504 // Gateway timeout
      );
      
      if (isRetryable) {
        console.warn(`Overpass server ${serverUrl} failed (attempt ${retryCount + 1}): ${fullError}. Will retry...`);
        return tryOverpassServer(serverUrl, retryCount + 1);
      } else {
        console.warn(`Overpass server ${serverUrl} failed (final): ${fullError}`);
        errors.push(`${serverUrl}: ${fullError}`);
        return null;
      }
    }
  };

  // Essayer chaque serveur avec retry
  for (const serverUrl of OVERPASS_SERVERS) {
    const result = await tryOverpassServer(serverUrl);
    if (result && result.length > 0) {
      return result;
    }
  }

  // Si tous les serveurs ont échoué, utiliser le cache expiré si disponible
  // (déjà re-filtré dans le bloc précédent)
  if (expiredCities && expiredCities.length > 0) {
    // Mettre à jour le timestamp du cache expiré pour éviter de le réutiliser immédiatement
    await cacheRef.set({ 
      cities: expiredCities, 
      centerLatitude: lat,
      centerLongitude: lon,
      radiusKm: radiusKm,
      timestamp: Date.now() 
    });
    console.warn(`All Overpass servers failed. Using expired cache with ${expiredCities.length} cities (already filtered, timestamp updated). Errors: ${errors.join('; ')}`);
    return expiredCities;
  }

  // Si pas de cache expiré, retourner vide avec message d'erreur détaillé
  const errorMessage = `Tous les serveurs Overpass sont temporairement indisponibles. Veuillez réessayer dans quelques instants. Erreurs: ${errors.join('; ')}`;
  console.error(`All Overpass servers failed. No cache available. Errors: ${errors.join('; ')}`);
  throw new Error(errorMessage);
}

/**
 * Parse weather response for a single location
 */
function parseWeatherResponse(data: any): WeatherData[] {
  const daily = data.daily || {};
  const times = daily.time || [];
  const tempsMax = daily.temperature_2m_max || [];
  const tempsMin = daily.temperature_2m_min || [];
  const weatherCodes = daily.weathercode || [];

  const hourly = data.hourly || {};
  const hourlyTimes = hourly.time || [];
  const hourlyTemps = hourly.temperature_2m || [];
  const hourlyWeatherCodes = hourly.weathercode || [];

  const hourlyByDate: { [key: string]: Array<{ hour: number; temperature: number; condition: string }> } = {};

  for (let i = 0; i < hourlyTimes.length; i++) {
    const dt = new Date(hourlyTimes[i]);
    const dateKey = dt.toISOString().substring(0, 10);
    const hour = dt.getHours();
    const temp = hourlyTemps[i];

    if (temp == null) continue;
    if (!hourlyByDate[dateKey]) hourlyByDate[dateKey] = [];

    hourlyByDate[dateKey].push({
      hour,
      temperature: temp,
      condition: mapWeatherCode(hourlyWeatherCodes[i] || 0),
    });
  }

  const forecasts: WeatherData[] = [];

  for (let i = 0; i < times.length; i++) {
    const tempMax = tempsMax[i];
    const tempMin = tempsMin[i];
    if (tempMax == null || tempMin == null) continue;

    forecasts.push({
      date: times[i],
      temperature: (tempMax + tempMin) / 2,
      minTemperature: tempMin,
      maxTemperature: tempMax,
      condition: mapWeatherCode(weatherCodes[i] || 0),
      hourlyData: hourlyByDate[times[i]] || [],
    });
  }

  return forecasts;
}

function calculateWeatherScore(
  forecasts: WeatherData[],
  params: SearchParams,
  selectedHours: Set<number>
): number {
  if (forecasts.length === 0) return 0;

  const desiredMin = params.desiredMinTemperature ?? 20;
  const desiredMax = params.desiredMaxTemperature ?? 30;
  const desiredAvg = (desiredMin + desiredMax) / 2;

  let totalScore = 0;

  for (const forecast of forecasts) {
    const filtered = getFilteredWeatherData(forecast, selectedHours);
    const actualAvg = (filtered.minTemp + filtered.maxTemp) / 2;
    const tempDiff = Math.abs(actualAvg - desiredAvg);
    const tempScore = 100 * Math.exp(-tempDiff / 10);

    let conditionScore = 50;
    if (params.desiredConditions.length > 0) {
      for (const desired of params.desiredConditions) {
        conditionScore = Math.max(conditionScore, getConditionMatchScore(filtered.condition, desired));
      }
    }

    totalScore += tempScore * 0.35 + conditionScore * 0.5 + 70 * 0.15;
  }

  return totalScore / forecasts.length;
}

function getFilteredWeatherData(
  forecast: WeatherData,
  selectedHours: Set<number>
): { avgTemp: number; minTemp: number; maxTemp: number; condition: string } {
  if (forecast.hourlyData.length === 0 || selectedHours.size === 0) {
    return {
      avgTemp: forecast.temperature,
      minTemp: forecast.minTemperature,
      maxTemp: forecast.maxTemperature,
      condition: forecast.condition,
    };
  }

  const filtered = forecast.hourlyData.filter((h) => selectedHours.has(h.hour));
  if (filtered.length === 0) {
    return {
      avgTemp: forecast.temperature,
      minTemp: forecast.minTemperature,
      maxTemp: forecast.maxTemperature,
      condition: forecast.condition,
    };
  }

  const temps = filtered.map((h) => h.temperature);
  const conditionCounts: { [key: string]: number } = {};
  for (const h of filtered) {
    conditionCounts[h.condition] = (conditionCounts[h.condition] || 0) + 1;
  }

  let dominantCondition = forecast.condition;
  let maxCount = 0;
  for (const [cond, count] of Object.entries(conditionCounts)) {
    if (count > maxCount) {
      maxCount = count;
      dominantCondition = cond;
    }
  }

  return {
    avgTemp: temps.reduce((a, b) => a + b, 0) / temps.length,
    minTemp: Math.min(...temps),
    maxTemp: Math.max(...temps),
    condition: dominantCondition,
  };
}

export function getSelectedHours(timeSlots: string[]): Set<number> {
  const hours = new Set<number>();
  for (const slot of timeSlots) {
    switch (slot) {
      case "morning": [7, 8, 9, 10, 11].forEach((h) => hours.add(h)); break;
      case "afternoon": [12, 13, 14, 15, 16, 17].forEach((h) => hours.add(h)); break;
      case "evening": [18, 19, 20, 21].forEach((h) => hours.add(h)); break;
      case "night": [22, 23, 0, 1, 2, 3, 4, 5, 6].forEach((h) => hours.add(h)); break;
    }
  }
  return hours;
}

function matchesDesiredConditions(forecasts: WeatherData[], desiredConditions: string[]): boolean {
  if (desiredConditions.length === 0) return true;
  if (forecasts.length === 0) return false;

  // Vérifier que chaque jour a au moins une condition correspondante
  const daysMatching = forecasts.filter(forecast => {
    const condition = forecast.condition.toLowerCase();
    return desiredConditions.some(desired => {
      const desiredLower = desired.toLowerCase();
      return condition === desiredLower ||
             (condition === "partly_cloudy" && desiredLower === "clear") ||
             ((condition === "clear" || condition === "sunny") && 
              (desiredLower === "clear" || desiredLower === "sunny"));
    });
  }).length;

  // Au moins 50% des jours doivent correspondre aux conditions désirées
  const threshold = Math.ceil(forecasts.length * 0.5);
  return daysMatching >= threshold;
}

export function getConditionMatchScore(actual: string, desired: string): number {
  if (actual === desired) return 100;
  if ((actual === "clear" && desired === "partly_cloudy") || (actual === "partly_cloudy" && desired === "clear")) return 85;
  if ((actual === "clear" && desired === "cloudy") || (actual === "cloudy" && desired === "clear")) return 65;
  if (actual === "rain" || desired === "rain") return 35;
  return 50;
}

export function mapWeatherCode(code: number): string {
  if (code === 0) return "clear";
  if (code >= 1 && code <= 3) return "partly_cloudy";
  if (code >= 45 && code <= 48) return "cloudy";
  if (code >= 51 && code <= 67) return "rain";
  if (code >= 71 && code <= 77) return "snow";
  if (code >= 80 && code <= 82) return "rain";
  if (code >= 85 && code <= 86) return "snow";
  if (code >= 95 && code <= 99) return "rain";
  return "cloudy";
}

export function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a = Math.sin(dLat / 2) ** 2 + Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// ============================================================================
// NOUVELLES FONCTIONS POUR REMPLACER LES APPELS API DIRECTS DU CLIENT
// ============================================================================

const NOMINATIM_API_URL = "https://nominatim.openstreetmap.org";
const IPAPI_URL = "https://ipapi.co/json/";

/**
 * Search locations using Nominatim (géocodage)
 */
export const searchLocations = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (request) => {
    const query = request.data.query as string;

    if (!query || typeof query !== "string" || query.trim().length === 0) {
      return { locations: [], error: "Query is required" };
    }

    try {
      const response = await axios.get(`${NOMINATIM_API_URL}/search`, {
        params: {
          q: query,
          format: "json",
          limit: 20,
          addressdetails: 1,
          featuretype: "settlement",
        },
        headers: {
          "User-Agent": "IWantSun/1.0",
        },
        timeout: 25000,
      });

      if (response.status !== 200) {
        return { locations: [], error: `Nominatim returned status ${response.status}` };
      }

      const data = Array.isArray(response.data) ? response.data : [];
      const locations: Array<{
        id: string;
        name: string;
        country?: string;
        latitude: number;
        longitude: number;
      }> = [];
      const seenNames = new Set<string>();

      for (const item of data) {
        const type = item.type?.toString().toLowerCase();
        const classType = item.class?.toString().toLowerCase();
        const validTypes = ["city", "town", "village", "hamlet", "municipality", "administrative", "suburb", "locality"];
        const validClasses = ["place", "boundary"];

        if (!validTypes.includes(type) && !validClasses.includes(classType)) {
          continue;
        }

        const address = item.address || {};
        const cityKeys = ["city", "town", "village", "municipality", "hamlet", "locality", "suburb"];
        let name = "";

        for (const key of cityKeys) {
          if (address[key]) {
            name = address[key].toString();
            break;
          }
        }

        if (!name && item.display_name) {
          name = item.display_name.split(",")[0].trim();
        }

        if (!name) continue;

        const nameKey = name.toLowerCase();
        if (seenNames.has(nameKey)) continue;
        seenNames.add(nameKey);

        locations.push({
          id: String(item.place_id || ""),
          name,
          country: address.country?.toString(),
          latitude: parseFloat(item.lat),
          longitude: parseFloat(item.lon),
        });

        if (locations.length >= 10) break;
      }

      return { locations, error: null };
    } catch (error) {
      console.error("searchLocations error:", error);
      return { locations: [], error: String(error) };
    }
  }
);

/**
 * Geocode location using Nominatim (reverse geocoding)
 */
export const geocodeLocation = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (request) => {
    console.log("geocodeLocation called with:", JSON.stringify(request.data));
    const latitude = request.data.latitude as number;
    const longitude = request.data.longitude as number;

    if (typeof latitude !== "number" || typeof longitude !== "number") {
      console.error("Invalid latitude or longitude:", latitude, longitude);
      return { location: null, error: "Latitude and longitude are required" };
    }

    console.log(`Starting geocoding for coordinates: ${latitude}, ${longitude}`);
    // Essayer avec différents niveaux de zoom pour obtenir le meilleur résultat
    const zoomLevels = [18, 14, 10, 8]; // Du plus détaillé au moins détaillé
    
    for (const zoom of zoomLevels) {
      try {
        console.log(`Trying geocoding with zoom level ${zoom}`);
        const response = await axios.get(`${NOMINATIM_API_URL}/reverse`, {
          params: {
            lat: latitude,
            lon: longitude,
            format: "json",
            addressdetails: 1,
            zoom: zoom,
          },
          headers: {
            "User-Agent": "IWantSun/1.0",
          },
          timeout: 25000,
        });

        if (response.status !== 200) {
          if (zoom === zoomLevels[zoomLevels.length - 1]) {
            return { location: null, error: `Nominatim returned status ${response.status}` };
          }
          continue; // Essayer le niveau de zoom suivant
        }

        const data = response.data;
        const address = data.address || {};
        
        // Ordre de priorité pour trouver le nom de ville/village
        const cityKeys = [
          "city", "town", "village", "municipality", "hamlet", 
          "locality", "suburb", "county", "state_district", "region"
        ];
        let name = "";

        // Essayer d'abord les clés spécifiques de ville
        for (const key of cityKeys) {
          if (address[key]) {
            name = address[key].toString().trim();
            if (name) break;
          }
        }

        // Si pas trouvé, essayer avec display_name
        if (!name && data.display_name) {
          const displayParts = data.display_name.split(",");
          // Prendre le premier élément (généralement le nom de la ville)
          name = displayParts[0]?.trim() || "";
          
          // Si le premier élément est trop court ou générique, essayer le suivant
          if (name.length < 3 || 
              name.toLowerCase() === "united states" || 
              name.toLowerCase() === "france" ||
              name.toLowerCase() === "usa" ||
              name.toLowerCase() === "united kingdom") {
            name = displayParts[1]?.trim() || name;
          }
        }

        // Dernier recours : utiliser le type de lieu si disponible
        if (!name && data.type) {
          name = data.type.toString();
        }

        // Si on a trouvé un nom valide (pas juste des coordonnées), retourner le résultat
        if (name && name.length > 0 && !name.match(/^-?\d+\.?\d*,\s*-?\d+\.?\d*$/)) {
          console.log(`Found valid city name: ${name} with zoom ${zoom}`);
          return {
            location: {
              id: String(data.place_id || ""),
              name,
              country: address.country?.toString(),
              latitude,
              longitude,
            },
            error: null,
          };
        }
        
        console.log(`No valid name found with zoom ${zoom}, name was: "${name}"`);

        // Si on est au dernier niveau de zoom, retourner quand même un résultat
        if (zoom === zoomLevels[zoomLevels.length - 1]) {
          // Utiliser display_name comme dernier recours
          if (data.display_name) {
            const displayParts = data.display_name.split(",");
            // Prendre le premier élément non vide qui n'est pas un pays
            for (let i = 0; i < Math.min(displayParts.length, 3); i++) {
              const part = displayParts[i]?.trim();
              if (part && part.length > 0 && 
                  !part.match(/^-?\d+\.?\d*,\s*-?\d+\.?\d*$/) &&
                  !["France", "United States", "USA", "United Kingdom"].includes(part)) {
                name = part;
                break;
              }
            }
            // Si toujours rien, prendre le premier élément
            if (!name || name.length === 0) {
              name = displayParts[0]?.trim() || displayParts[1]?.trim() || "";
            }
          }
          
          // Si toujours pas de nom, utiliser les coordonnées comme fallback
          if (!name || name.length === 0) {
            name = `${latitude.toFixed(4)}, ${longitude.toFixed(4)}`;
            console.warn(`Could not extract city name for ${latitude}, ${longitude}. Using coordinates.`);
          } else {
            console.log(`Using fallback name: ${name}`);
          }

          return {
            location: {
              id: String(data.place_id || ""),
              name,
              country: address.country?.toString(),
              latitude,
              longitude,
            },
            error: null,
          };
        }
      } catch (error) {
        // Si c'est le dernier niveau de zoom, retourner l'erreur
        if (zoom === zoomLevels[zoomLevels.length - 1]) {
          console.error("geocodeLocation error:", error);
          return { location: null, error: String(error) };
        }
        // Sinon, continuer avec le niveau de zoom suivant
        continue;
      }
    }

    // Ne devrait jamais arriver ici, mais au cas où
    return { location: null, error: "Failed to geocode location after all attempts" };
  }
);

/**
 * Get nearby cities using Overpass API
 */
export const getNearbyCities = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 45,
    memory: "256MiB",
  },
  async (request) => {
    const latitude = request.data.latitude as number;
    const longitude = request.data.longitude as number;
    const radiusKm = request.data.radiusKm as number;

    if (typeof latitude !== "number" || typeof longitude !== "number" || typeof radiusKm !== "number") {
      return { cities: [], error: "latitude, longitude, and radiusKm are required" };
    }

    if (radiusKm <= 0 || radiusKm > MAX_SEARCH_RADIUS_KM) {
      return { cities: [], error: `radiusKm must be between 0 and ${MAX_SEARCH_RADIUS_KM}` };
    }

    try {
      const cities = await getCitiesFromOverpass(latitude, longitude, radiusKm);
      return { cities, error: null };
    } catch (error) {
      console.error("getNearbyCities error:", error);
      return { cities: [], error: String(error) };
    }
  }
);

/**
 * Get weather forecast for a single location using Open-Meteo
 */
export const getWeatherForecast = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (request) => {
    const latitude = request.data.latitude as number;
    const longitude = request.data.longitude as number;
    const startDate = request.data.startDate as string;
    const endDate = request.data.endDate as string;

    if (typeof latitude !== "number" || typeof longitude !== "number" || !startDate || !endDate) {
      return { forecasts: [], error: "latitude, longitude, startDate, and endDate are required" };
    }

    try {
      const response = await axios.get(OPEN_METEO_API_URL, {
        params: {
          latitude: latitude.toString(),
          longitude: longitude.toString(),
          start_date: startDate,
          end_date: endDate,
          daily: "temperature_2m_max,temperature_2m_min,weathercode",
          hourly: "temperature_2m,weathercode",
          timezone: "auto",
        },
        timeout: 25000,
      });

      if (response.status !== 200 || !response.data.daily) {
        return { forecasts: [], error: "Failed to fetch weather data" };
      }

      const forecasts = parseWeatherResponse(response.data);
      return { forecasts, error: null };
    } catch (error) {
      console.error("getWeatherForecast error:", error);
      return { forecasts: [], error: String(error) };
    }
  }
);

/**
 * Calculate average temperature for a location, period, and time slots
 * Returns min and max temperatures (average ± 5°C rounded)
 */
export const calculateAverageTemperature = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (request) => {
    const latitude = request.data.latitude as number;
    const longitude = request.data.longitude as number;
    const startDate = request.data.startDate as string;
    const endDate = request.data.endDate as string;
    const timeSlots = (request.data.timeSlots as string[]) || [];

    if (typeof latitude !== "number" || typeof longitude !== "number" || !startDate || !endDate) {
      return { 
        minTemperature: null, 
        maxTemperature: null, 
        averageTemperature: null,
        error: "latitude, longitude, startDate, and endDate are required" 
      };
    }

    try {
      // Récupérer les prévisions météo
      const response = await axios.get(OPEN_METEO_API_URL, {
        params: {
          latitude: latitude.toString(),
          longitude: longitude.toString(),
          start_date: startDate,
          end_date: endDate,
          daily: "temperature_2m_max,temperature_2m_min,weathercode",
          hourly: "temperature_2m,weathercode",
          timezone: "auto",
        },
        timeout: 25000,
      });

      if (response.status !== 200 || !response.data.daily) {
        return { 
          minTemperature: null, 
          maxTemperature: null, 
          averageTemperature: null,
          error: "Failed to fetch weather data" 
        };
      }

      const forecasts = parseWeatherResponse(response.data);
      
      // Obtenir les heures à considérer basées sur les créneaux sélectionnés
      const selectedHours = getSelectedHours(timeSlots);

      // Collecter toutes les températures filtrées par les créneaux horaires
      const temperatures: number[] = [];

      for (const forecast of forecasts) {
        // Si des créneaux horaires sont sélectionnés, filtrer par les heures
        if (selectedHours.size > 0 && forecast.hourlyData.length > 0) {
          // Filtrer les données horaires par les créneaux sélectionnés
          const filteredHourly = forecast.hourlyData.filter((h) => selectedHours.has(h.hour));

          if (filteredHourly.length > 0) {
            // Utiliser les températures des heures filtrées
            temperatures.push(...filteredHourly.map((h) => h.temperature));
          } else {
            // Si aucune heure ne correspond, utiliser la température moyenne du jour
            temperatures.push(forecast.temperature);
          }
        } else {
          // Pas de filtrage horaire, utiliser la température moyenne du jour
          temperatures.push(forecast.temperature);
        }
      }

      // Si on a des températures, calculer la moyenne
      if (temperatures.length > 0) {
        const average = temperatures.reduce((a, b) => a + b, 0) / temperatures.length;
        const roundedAverage = Math.round(average); // Arrondir à l'entier le plus proche

        // Min = moyenne - 5, Max = moyenne + 5
        const minTemp = roundedAverage - 5;
        const maxTemp = roundedAverage + 5;

        console.log(`Average temperature calculated: ${roundedAverage}°C (min: ${minTemp}°C, max: ${maxTemp}°C)`);

        return { 
          minTemperature: minTemp, 
          maxTemperature: maxTemp, 
          averageTemperature: roundedAverage,
          error: null 
        };
      } else {
        // Aucune température trouvée
        console.warn("No temperatures found for the given period and time slots");
        return { 
          minTemperature: null, 
          maxTemperature: null, 
          averageTemperature: null,
          error: "No temperatures found for the given period and time slots" 
        };
      }
    } catch (error) {
      console.error("calculateAverageTemperature error:", error);
      return { 
        minTemperature: null, 
        maxTemperature: null, 
        averageTemperature: null,
        error: String(error) 
      };
    }
  }
);

/**
 * Recherche d'événements dans une zone géographique
 */
interface EventSearchParams {
  centerLatitude: number;
  centerLongitude: number;
  searchRadius: number;
  startDate: string;
  endDate: string;
  eventTypes: string[]; // Types d'événements recherchés
  minPrice?: number; // Prix minimum (optionnel)
  maxPrice?: number; // Prix maximum (optionnel)
  sortByPopularity?: boolean; // Trier par popularité (optionnel)
}

interface Event {
  id: string;
  name: string;
  description?: string;
  type: string;
  latitude: number;
  longitude: number;
  startDate: string;
  endDate?: string;
  locationName?: string;
  city?: string;
  country?: string;
  distanceFromCenter: number;
  imageUrl?: string;
  websiteUrl?: string;
  price?: number;
  priceCurrency?: string;
}

export const searchEvents = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (request) => {
    const data = request.data as EventSearchParams;

    // Validation
    if (data.searchRadius <= 0 || data.searchRadius > MAX_SEARCH_RADIUS_KM) {
      return { events: [], error: "Invalid search radius" };
    }

    const startDate = new Date(data.startDate);
    const endDate = new Date(data.endDate);
    if (startDate > endDate) {
      return { events: [], error: "startDate must be before endDate" };
    }

    console.log("Event search request received:", JSON.stringify(data));

    try {
      // Vérifier le cache
      const cacheKey = `events_${data.centerLatitude.toFixed(6)}_${data.centerLongitude.toFixed(6)}_${data.searchRadius.toFixed(1)}_${startDate.toISOString().split('T')[0]}_${endDate.toISOString().split('T')[0]}_${data.eventTypes.sort().join(',')}`;
      const cacheRef = db.collection("cache_events").doc(cacheKey);
      const cached = await cacheRef.get();

      if (cached.exists) {
        const cacheData = cached.data();
        if (cacheData && Date.now() - cacheData.timestamp < CACHE_DURATION_HOURS * 3600000) {
          console.log("Cache hit for events");
          return { events: cacheData.events as Event[], error: null };
        }
      }

      const events: Event[] = [];
      const eventTypes = data.eventTypes.length > 0 ? data.eventTypes : [];
      
      // 1. Rechercher dans Ticketmaster (si clé API disponible)
      if (TICKETMASTER_API_KEY) {
        try {
          const ticketmasterEvents = await searchTicketmasterEvents(data, startDate, endDate, eventTypes);
          events.push(...ticketmasterEvents);
          console.log(`Found ${ticketmasterEvents.length} events from Ticketmaster`);
        } catch (error: any) {
          console.warn(`Ticketmaster API error: ${error.message}`);
        }
      } else {
        console.log("Ticketmaster API key not configured, skipping");
      }
      
      // 2. Rechercher dans OpenEventDatabase
      try {
        const openDataEvents = await searchOpenEventDatabase(data, startDate, endDate, eventTypes);
        events.push(...openDataEvents);
        console.log(`Found ${openDataEvents.length} events from OpenEventDatabase`);
      } catch (error: any) {
        console.warn(`OpenEventDatabase API error: ${error.message}`);
      }
      
      // 3. Rechercher dans Eventbrite (si clé API disponible)
      if (EVENTBRITE_API_KEY) {
        try {
          const eventbriteEvents = await searchEventbriteEvents(data, startDate, endDate, eventTypes);
          events.push(...eventbriteEvents);
          console.log(`Found ${eventbriteEvents.length} events from Eventbrite`);
        } catch (error: any) {
          console.warn(`Eventbrite API error: ${error.message}`);
        }
      } else {
        console.log("Eventbrite API key not configured, skipping");
      }
      
      // 4. Filtrer par distance et dédupliquer
      const filteredEvents = events
        .filter(event => {
          const distance = calculateDistance(
            data.centerLatitude,
            data.centerLongitude,
            event.latitude,
            event.longitude
          );
          return distance <= data.searchRadius;
        })
        .map(event => {
          const distance = calculateDistance(
            data.centerLatitude,
            data.centerLongitude,
            event.latitude,
            event.longitude
          );
          return { ...event, distanceFromCenter: distance };
        });
      
      // Dédupliquer par ID
      const uniqueEvents = Array.from(
        new Map(filteredEvents.map(event => [event.id, event])).values()
      );
      
      // Filtrer par prix si spécifié
      const priceFilteredEvents = uniqueEvents.filter(event => {
        if (data.minPrice !== undefined && (event.price === undefined || event.price < data.minPrice)) {
          return false;
        }
        if (data.maxPrice !== undefined && (event.price !== undefined && event.price > data.maxPrice)) {
          return false;
        }
        return true;
      });
      
      // Trier selon les préférences
      if (data.sortByPopularity) {
        // Trier par popularité (approximée par : événements avec prix = plus populaires, puis par distance)
        priceFilteredEvents.sort((a, b) => {
          const aHasPrice = a.price !== undefined ? 1 : 0;
          const bHasPrice = b.price !== undefined ? 1 : 0;
          if (aHasPrice !== bHasPrice) {
            return bHasPrice - aHasPrice; // Événements avec prix en premier
          }
          return a.distanceFromCenter - b.distanceFromCenter;
        });
      } else {
        // Trier par distance
        priceFilteredEvents.sort((a, b) => a.distanceFromCenter - b.distanceFromCenter);
      }
      
      // Mettre en cache
      await cacheRef.set({
        events: priceFilteredEvents,
        timestamp: Date.now(),
        centerLatitude: data.centerLatitude,
        centerLongitude: data.centerLongitude,
        searchRadius: data.searchRadius,
      });
      
      console.log(`Total unique events found: ${priceFilteredEvents.length} (after price filter: ${uniqueEvents.length})`);
      return { events: priceFilteredEvents, error: null };
    } catch (error) {
      console.error("searchEvents error:", error);
      return { events: [], error: String(error) };
    }
  }
);

/**
 * Recherche d'événements via Ticketmaster API
 */
async function searchTicketmasterEvents(
  params: EventSearchParams,
  startDate: Date,
  endDate: Date,
  eventTypes: string[]
): Promise<Event[]> {
  const events: Event[] = [];
  
  try {
    // Convertir les types d'événements en classifications Ticketmaster
    const classifications = mapEventTypesToTicketmasterClassifications(eventTypes);
    
    // Construire les paramètres de requête
    const queryParams: any = {
      apikey: TICKETMASTER_API_KEY,
      latlong: `${params.centerLatitude},${params.centerLongitude}`,
      radius: Math.round(params.searchRadius * 1000), // Convertir en mètres
      startDateTime: startDate.toISOString(),
      endDateTime: endDate.toISOString(),
      size: 200, // Maximum par page
      sort: 'distance,asc',
    };
    
    // Ajouter les classifications si spécifiées
    if (classifications.length > 0) {
      queryParams.classificationName = classifications.join(',');
    }
    
    const response = await axios.get(TICKETMASTER_API_URL, {
      params: queryParams,
      timeout: 15000,
    });
    
    if (response.data && response.data._embedded && response.data._embedded.events) {
      const ticketmasterEvents = response.data._embedded.events;
      
      for (const tmEvent of ticketmasterEvents) {
        try {
          // Extraire les coordonnées du lieu
          const venue = tmEvent._embedded?.venues?.[0];
          if (!venue || !venue.location) continue;
          
          const lat = parseFloat(venue.location.latitude);
          const lon = parseFloat(venue.location.longitude);
          
          if (isNaN(lat) || isNaN(lon)) continue;
          
          // Extraire la date de début
          const eventStartDate = tmEvent.dates?.start?.dateTime 
            ? new Date(tmEvent.dates.start.dateTime)
            : null;
          
          if (!eventStartDate) continue;
          
          // Mapper le type d'événement
          const eventType = mapTicketmasterClassificationToEventType(
            tmEvent.classifications?.[0]?.segment?.name,
            tmEvent.classifications?.[0]?.genre?.name
          );
          
          // Filtrer par type si spécifié
          if (eventTypes.length > 0 && !eventTypes.includes(eventType)) {
            continue;
          }
          
          const event: Event = {
            id: `tm_${tmEvent.id}`,
            name: tmEvent.name || 'Événement sans nom',
            description: tmEvent.info || tmEvent.description || undefined,
            type: eventType,
            latitude: lat,
            longitude: lon,
            startDate: eventStartDate.toISOString(),
            endDate: tmEvent.dates?.end?.dateTime 
              ? new Date(tmEvent.dates.end.dateTime).toISOString()
              : undefined,
            locationName: venue.name,
            city: venue.city?.name,
            country: venue.country?.name,
            distanceFromCenter: 0, // Sera calculé plus tard
            imageUrl: tmEvent.images?.[0]?.url,
            websiteUrl: tmEvent.url,
            price: tmEvent.priceRanges?.[0]?.min,
            priceCurrency: tmEvent.priceRanges?.[0]?.currency || 'EUR',
          };
          
          events.push(event);
        } catch (e: any) {
          console.warn(`Error parsing Ticketmaster event: ${e.message}`);
        }
      }
    }
  } catch (error: any) {
    console.error(`Ticketmaster API error: ${error.message}`);
    throw error;
  }
  
  return events;
}

/**
 * Recherche d'événements via OpenEventDatabase API
 */
async function searchOpenEventDatabase(
  params: EventSearchParams,
  startDate: Date,
  endDate: Date,
  eventTypes: string[]
): Promise<Event[]> {
  const events: Event[] = [];
  
  try {
    // Calculer la bounding box
    const latDelta = params.searchRadius / 111.0;
    const lonDelta = params.searchRadius / (111.0 * Math.cos((params.centerLatitude * Math.PI) / 180));
    
    const bbox = [
      params.centerLongitude - lonDelta, // minLon
      params.centerLatitude - latDelta,   // minLat
      params.centerLongitude + lonDelta,  // maxLon
      params.centerLatitude + latDelta,   // maxLat
    ].join(',');
    
    // Construire l'URL avec les paramètres
    const url = `${OPENEVENTDATABASE_API_URL}?bbox=${bbox}&limit=200`;
    
    const response = await axios.get(url, {
      timeout: 15000,
    });
    
    if (response.data && Array.isArray(response.data)) {
      for (const oedEvent of response.data) {
        try {
          // Vérifier que l'événement est dans la période
          const eventStart = oedEvent.when?.start 
            ? new Date(oedEvent.when.start)
            : null;
          
          if (!eventStart || eventStart < startDate || eventStart > endDate) {
            continue;
          }
          
          // Extraire les coordonnées
          const coordinates = oedEvent.where?.[0]?.coordinates;
          if (!coordinates || coordinates.length < 2) continue;
          
          const lon = parseFloat(coordinates[0]);
          const lat = parseFloat(coordinates[1]);
          
          if (isNaN(lat) || isNaN(lon)) continue;
          
          // Vérifier la distance
          const distance = calculateDistance(
            params.centerLatitude,
            params.centerLongitude,
            lat,
            lon
          );
          
          if (distance > params.searchRadius) continue;
          
          // Mapper le type d'événement
          const eventType = mapOpenEventDatabaseTypeToEventType(
            oedEvent.what?.[0]?.tags,
            oedEvent.what?.[0]?.name
          );
          
          // Filtrer par type si spécifié
          if (eventTypes.length > 0 && !eventTypes.includes(eventType)) {
            continue;
          }
          
          const event: Event = {
            id: `oed_${oedEvent.id || oedEvent._id || Date.now()}`,
            name: oedEvent.what?.[0]?.name || 'Événement sans nom',
            description: oedEvent.what?.[0]?.description || undefined,
            type: eventType,
            latitude: lat,
            longitude: lon,
            startDate: eventStart.toISOString(),
            endDate: oedEvent.when?.end 
              ? new Date(oedEvent.when.end).toISOString()
              : undefined,
            locationName: oedEvent.where?.[0]?.name,
            city: oedEvent.where?.[0]?.address?.locality,
            country: oedEvent.where?.[0]?.address?.country,
            distanceFromCenter: distance,
            websiteUrl: oedEvent.links?.[0]?.url,
          };
          
          events.push(event);
        } catch (e: any) {
          console.warn(`Error parsing OpenEventDatabase event: ${e.message}`);
        }
      }
    }
  } catch (error: any) {
    console.error(`OpenEventDatabase API error: ${error.message}`);
    throw error;
  }
  
  return events;
}

/**
 * Mappe les types d'événements vers les classifications Ticketmaster
 */
function mapEventTypesToTicketmasterClassifications(eventTypes: string[]): string[] {
  const mapping: { [key: string]: string[] } = {
    concert: ['Music'],
    festival: ['Music', 'Festival'],
    sport: ['Sports'],
    culture: ['Arts', 'Miscellaneous'],
    gastronomy: ['Miscellaneous'],
    market: ['Miscellaneous'],
    exhibition: ['Arts'],
    conference: ['Miscellaneous'],
    theater: ['Arts'],
    cinema: ['Film'],
  };
  
  const classifications: string[] = [];
  for (const eventType of eventTypes) {
    const mapped = mapping[eventType] || [];
    classifications.push(...mapped);
  }
  
  return [...new Set(classifications)]; // Dédupliquer
}

/**
 * Mappe la classification Ticketmaster vers notre type d'événement
 */
function mapTicketmasterClassificationToEventType(
  segment?: string,
  genre?: string
): string {
  const segmentLower = segment?.toLowerCase() || '';
  const genreLower = genre?.toLowerCase() || '';
  
  if (segmentLower.includes('music') || genreLower.includes('music')) {
    if (genreLower.includes('festival')) return 'festival';
    return 'concert';
  }
  
  if (segmentLower.includes('sport')) return 'sport';
  if (segmentLower.includes('art') || segmentLower.includes('theatre')) return 'theater';
  if (segmentLower.includes('film')) return 'cinema';
  if (segmentLower.includes('miscellaneous')) {
    if (genreLower.includes('food') || genreLower.includes('gastronomy')) return 'gastronomy';
    if (genreLower.includes('market')) return 'market';
    if (genreLower.includes('conference')) return 'conference';
    return 'culture';
  }
  
  return 'other';
}

/**
 * Recherche d'événements via Eventbrite API
 */
async function searchEventbriteEvents(
  params: EventSearchParams,
  startDate: Date,
  endDate: Date,
  eventTypes: string[]
): Promise<Event[]> {
  const events: Event[] = [];
  
  try {
    // Construire les paramètres de requête
    const queryParams: any = {
      token: EVENTBRITE_API_KEY,
      'location.latitude': params.centerLatitude.toString(),
      'location.longitude': params.centerLongitude.toString(),
      'location.within': `${Math.round(params.searchRadius)}km`,
      'start_date.range_start': startDate.toISOString(),
      'start_date.range_end': endDate.toISOString(),
      'expand': 'venue',
      'page_size': 100,
    };
    
    // Ajouter les catégories si spécifiées
    const categories = mapEventTypesToEventbriteCategories(eventTypes);
    if (categories.length > 0) {
      queryParams.categories = categories.join(',');
    }
    
    const response = await axios.get(EVENTBRITE_API_URL, {
      params: queryParams,
      headers: {
        'Authorization': `Bearer ${EVENTBRITE_API_KEY}`,
      },
      timeout: 15000,
    });
    
    if (response.data && response.data.events) {
      const eventbriteEvents = response.data.events;
      
      for (const ebEvent of eventbriteEvents) {
        try {
          // Extraire les coordonnées du lieu
          const venue = ebEvent.venue;
          if (!venue || !venue.latitude || !venue.longitude) continue;
          
          const lat = parseFloat(venue.latitude);
          const lon = parseFloat(venue.longitude);
          
          if (isNaN(lat) || isNaN(lon)) continue;
          
          // Extraire la date de début
          const eventStartDate = ebEvent.start?.utc 
            ? new Date(ebEvent.start.utc)
            : null;
          
          if (!eventStartDate) continue;
          
          // Mapper le type d'événement
          const eventType = mapEventbriteCategoryToEventType(
            ebEvent.category_id,
            ebEvent.name?.text
          );
          
          // Filtrer par type si spécifié
          if (eventTypes.length > 0 && !eventTypes.includes(eventType)) {
            continue;
          }
          
          // Extraire le prix
          let price: number | undefined;
          let priceCurrency: string | undefined;
          if (ebEvent.ticket_availability?.has_available_tickets && ebEvent.ticket_classes) {
            const freeTicket = ebEvent.ticket_classes.find((tc: any) => tc.free);
            if (!freeTicket && ebEvent.ticket_classes.length > 0) {
              const firstTicket = ebEvent.ticket_classes[0];
              price = firstTicket.cost?.value ? parseFloat(firstTicket.cost.value) / 100 : undefined;
              priceCurrency = firstTicket.cost?.currency || 'EUR';
            }
          }
          
          const event: Event = {
            id: `eb_${ebEvent.id}`,
            name: ebEvent.name?.text || 'Événement sans nom',
            description: ebEvent.description?.text || undefined,
            type: eventType,
            latitude: lat,
            longitude: lon,
            startDate: eventStartDate.toISOString(),
            endDate: ebEvent.end?.utc 
              ? new Date(ebEvent.end.utc).toISOString()
              : undefined,
            locationName: venue.name,
            city: venue.address?.city,
            country: venue.address?.country,
            distanceFromCenter: 0, // Sera calculé plus tard
            imageUrl: ebEvent.logo?.url,
            websiteUrl: ebEvent.url,
            price: price,
            priceCurrency: priceCurrency,
          };
          
          events.push(event);
        } catch (e: any) {
          console.warn(`Error parsing Eventbrite event: ${e.message}`);
        }
      }
    }
  } catch (error: any) {
    console.error(`Eventbrite API error: ${error.message}`);
    throw error;
  }
  
  return events;
}

/**
 * Mappe les types d'événements vers les catégories Eventbrite
 */
function mapEventTypesToEventbriteCategories(eventTypes: string[]): string[] {
  const mapping: { [key: string]: string[] } = {
    concert: ['103'], // Music
    festival: ['103'], // Music
    sport: ['108'], // Sports & Fitness
    culture: ['105'], // Arts
    gastronomy: ['110'], // Food & Drink
    market: ['113'], // Other
    exhibition: ['105'], // Arts
    conference: ['102'], // Business & Professional
    theater: ['105'], // Arts
    cinema: ['104'], // Film, Media & Entertainment
  };
  
  const categories: string[] = [];
  for (const eventType of eventTypes) {
    const mapped = mapping[eventType] || [];
    categories.push(...mapped);
  }
  
  return [...new Set(categories)]; // Dédupliquer
}

/**
 * Mappe la catégorie Eventbrite vers notre type d'événement
 */
function mapEventbriteCategoryToEventType(
  categoryId?: string,
  eventName?: string
): string {
  const nameLower = (eventName || '').toLowerCase();
  
  // Mapping par catégorie Eventbrite
  const categoryMapping: { [key: string]: string } = {
    '103': 'concert', // Music
    '108': 'sport', // Sports & Fitness
    '105': 'culture', // Arts
    '110': 'gastronomy', // Food & Drink
    '102': 'conference', // Business & Professional
    '104': 'cinema', // Film, Media & Entertainment
  };
  
  if (categoryId && categoryMapping[categoryId]) {
    const baseType = categoryMapping[categoryId];
    // Affiner selon le nom
    if (baseType === 'concert' && (nameLower.includes('festival') || nameLower.includes('fest'))) {
      return 'festival';
    }
    if (baseType === 'culture' && (nameLower.includes('théâtre') || nameLower.includes('theatre'))) {
      return 'theater';
    }
    if (baseType === 'culture' && (nameLower.includes('exposition') || nameLower.includes('exhibition'))) {
      return 'exhibition';
    }
    return baseType;
  }
  
  // Fallback sur le nom
  if (nameLower.includes('festival') || nameLower.includes('fest')) return 'festival';
  if (nameLower.includes('concert') || nameLower.includes('musique')) return 'concert';
  if (nameLower.includes('sport')) return 'sport';
  if (nameLower.includes('théâtre') || nameLower.includes('theatre')) return 'theater';
  if (nameLower.includes('cinéma') || nameLower.includes('cinema') || nameLower.includes('film')) return 'cinema';
  if (nameLower.includes('gastronomie') || nameLower.includes('food')) return 'gastronomy';
  if (nameLower.includes('marché') || nameLower.includes('market')) return 'market';
  if (nameLower.includes('conférence') || nameLower.includes('conference')) return 'conference';
  if (nameLower.includes('exposition') || nameLower.includes('exhibition')) return 'exhibition';
  
  return 'other';
}

/**
 * Mappe le type OpenEventDatabase vers notre type d'événement
 */
function mapOpenEventDatabaseTypeToEventType(
  tags?: string[],
  name?: string
): string {
  const tagsStr = (tags || []).join(' ').toLowerCase();
  const nameStr = (name || '').toLowerCase();
  const combined = `${tagsStr} ${nameStr}`;
  
  if (combined.includes('concert') || combined.includes('musique')) return 'concert';
  if (combined.includes('festival')) return 'festival';
  if (combined.includes('sport')) return 'sport';
  if (combined.includes('culture') || combined.includes('culturel')) return 'culture';
  if (combined.includes('gastronomie') || combined.includes('food')) return 'gastronomy';
  if (combined.includes('marché') || combined.includes('market')) return 'market';
  if (combined.includes('exposition') || combined.includes('exhibition')) return 'exhibition';
  if (combined.includes('conférence') || combined.includes('conference')) return 'conference';
  if (combined.includes('théâtre') || combined.includes('theatre')) return 'theater';
  if (combined.includes('cinéma') || combined.includes('cinema') || combined.includes('film')) return 'cinema';
  
  return 'other';
}

/**
 * Recherche d'activités (POI) via Overpass API
 */
interface ActivitySearchParams {
  centerLatitude: number;
  centerLongitude: number;
  searchRadius: number;
  activityTypes: string[]; // Types d'activités recherchées: beach, hiking, skiing, surfing, cycling, golf, camping
}

interface ActivityPOI {
  id: string;
  name: string;
  type: string;
  description?: string;
  latitude: number;
  longitude: number;
  distance: number;
  address?: string;
  website?: string;
  phone?: string;
  openingHours?: string;
}

export const searchActivities = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (request) => {
    const data = request.data as ActivitySearchParams;

    // Validation
    if (data.searchRadius <= 0 || data.searchRadius > MAX_SEARCH_RADIUS_KM) {
      return { activities: [], error: "Invalid search radius" };
    }

    if (!data.activityTypes || data.activityTypes.length === 0) {
      return { activities: [], error: "At least one activity type is required" };
    }

    console.log("Activity search request received:", JSON.stringify(data));

    try {
      // Vérifier le cache
      const cacheKey = `activities_${data.centerLatitude.toFixed(4)}_${data.centerLongitude.toFixed(4)}_${data.searchRadius.toFixed(0)}_${data.activityTypes.sort().join(',')}`;
      const cacheRef = db.collection("cache_activities").doc(cacheKey);
      const cached = await cacheRef.get();

      if (cached.exists) {
        const cacheData = cached.data();
        if (cacheData && Date.now() - cacheData.timestamp < CACHE_DURATION_HOURS * 3600000) {
          console.log("Cache hit for activities");
          return { activities: cacheData.activities as ActivityPOI[], error: null };
        }
      }

      // Construire la requête Overpass pour les types d'activités
      const overpassFilters = buildOverpassActivityFilters(data.activityTypes);

      if (overpassFilters.length === 0) {
        return { activities: [], error: "No valid activity types provided" };
      }

      const activities = await fetchActivitiesFromOverpass(
        data.centerLatitude,
        data.centerLongitude,
        data.searchRadius,
        overpassFilters
      );

      // Trier par distance
      activities.sort((a, b) => a.distance - b.distance);

      // Limiter à 100 résultats
      const limitedActivities = activities.slice(0, 100);

      // Mettre en cache
      await cacheRef.set({
        activities: limitedActivities,
        timestamp: Date.now(),
        centerLatitude: data.centerLatitude,
        centerLongitude: data.centerLongitude,
        searchRadius: data.searchRadius,
      });

      console.log(`Found ${limitedActivities.length} activities`);
      return { activities: limitedActivities, error: null };
    } catch (error) {
      console.error("searchActivities error:", error);
      return { activities: [], error: String(error) };
    }
  }
);

/**
 * Construit les filtres Overpass pour les types d'activités
 */
function buildOverpassActivityFilters(activityTypes: string[]): string[] {
  const filters: string[] = [];

  for (const activityType of activityTypes) {
    switch (activityType.toLowerCase()) {
      case 'beach':
        filters.push('node["natural"="beach"]');
        filters.push('way["natural"="beach"]');
        filters.push('node["leisure"="beach_resort"]');
        filters.push('way["leisure"="beach_resort"]');
        filters.push('node["amenity"="swimming_pool"]["access"!="private"]');
        break;
      case 'hiking':
        filters.push('node["tourism"="viewpoint"]');
        filters.push('node["natural"="peak"]');
        filters.push('relation["route"="hiking"]');
        filters.push('way["highway"="path"]["sac_scale"]');
        filters.push('node["information"="trailhead"]');
        break;
      case 'skiing':
        filters.push('node["aerialway"="station"]');
        filters.push('way["piste:type"]');
        filters.push('node["sport"="skiing"]');
        filters.push('way["landuse"="winter_sports"]');
        filters.push('relation["site"="piste"]');
        break;
      case 'surfing':
        filters.push('node["sport"="surfing"]');
        filters.push('node["sport"="kitesurfing"]');
        filters.push('node["sport"="windsurfing"]');
        filters.push('node["leisure"="water_park"]');
        filters.push('way["sport"="surfing"]');
        break;
      case 'cycling':
        filters.push('node["amenity"="bicycle_rental"]');
        filters.push('relation["route"="bicycle"]');
        filters.push('node["shop"="bicycle"]');
        filters.push('way["highway"="cycleway"]["name"]');
        break;
      case 'golf':
        filters.push('node["leisure"="golf_course"]');
        filters.push('way["leisure"="golf_course"]');
        filters.push('node["sport"="golf"]');
        break;
      case 'camping':
        filters.push('node["tourism"="camp_site"]');
        filters.push('way["tourism"="camp_site"]');
        filters.push('node["tourism"="caravan_site"]');
        filters.push('way["tourism"="caravan_site"]');
        break;
    }
  }

  return filters;
}

/**
 * Récupère les activités depuis Overpass API
 */
async function fetchActivitiesFromOverpass(
  lat: number,
  lon: number,
  radiusKm: number,
  filters: string[]
): Promise<ActivityPOI[]> {
  const radiusMeters = radiusKm * 1000;
  const activities: ActivityPOI[] = [];

  // Construire la requête Overpass avec tous les filtres
  const filterQueries = filters
    .map(filter => `${filter}(around:${radiusMeters},${lat},${lon});`)
    .join('\n');

  const query = `
[out:json][timeout:30];
(
${filterQueries}
);
out body center;
`;

  const errors: string[] = [];

  for (const serverUrl of OVERPASS_SERVERS) {
    try {
      console.log(`Fetching activities from ${serverUrl}`);

      const response = await axios.post(serverUrl, query, {
        headers: { "Content-Type": "text/plain" },
        timeout: 25000,
      });

      const elements = response.data.elements || [];

      for (const element of elements) {
        const tags = element.tags || {};
        const name = tags.name || tags["name:fr"] || tags["name:en"];

        // Ignorer les éléments sans nom (sauf pour certains types)
        if (!name && !tags.natural && !tags.aerialway) continue;

        const elemLat = element.type === "node" ? element.lat : (element.center?.lat ?? element.lat);
        const elemLon = element.type === "node" ? element.lon : (element.center?.lon ?? element.lon);

        if (!elemLat || !elemLon) continue;

        const distance = calculateDistance(lat, lon, elemLat, elemLon);
        if (distance > radiusKm) continue;

        // Déterminer le type d'activité
        const activityType = determineActivityType(tags);

        const activity: ActivityPOI = {
          id: `osm_${element.type}_${element.id}`,
          name: name || generateActivityName(tags, activityType),
          type: activityType,
          description: tags.description || tags["description:fr"] || undefined,
          latitude: elemLat,
          longitude: elemLon,
          distance: Math.round(distance * 10) / 10, // Arrondir à 1 décimale
          address: buildAddress(tags),
          website: tags.website || tags.url || undefined,
          phone: tags.phone || tags["contact:phone"] || undefined,
          openingHours: tags.opening_hours || undefined,
        };

        activities.push(activity);
      }

      console.log(`Found ${activities.length} activities from ${serverUrl}`);
      return activities;
    } catch (error: any) {
      const errorMsg = error?.message || String(error);
      console.warn(`Overpass server ${serverUrl} failed: ${errorMsg}`);
      errors.push(`${serverUrl}: ${errorMsg}`);
    }
  }

  console.error(`All Overpass servers failed for activities. Errors: ${errors.join('; ')}`);
  return activities;
}

/**
 * Détermine le type d'activité basé sur les tags OSM
 */
function determineActivityType(tags: any): string {
  if (tags.natural === "beach" || tags.leisure === "beach_resort") return "beach";
  if (tags.amenity === "swimming_pool") return "beach";

  if (tags.tourism === "viewpoint" || tags.natural === "peak") return "hiking";
  if (tags.route === "hiking" || tags.sac_scale) return "hiking";
  if (tags.information === "trailhead") return "hiking";

  if (tags.aerialway || tags["piste:type"] || tags.landuse === "winter_sports") return "skiing";
  if (tags.sport === "skiing") return "skiing";

  if (tags.sport === "surfing" || tags.sport === "kitesurfing" || tags.sport === "windsurfing") return "surfing";
  if (tags.leisure === "water_park") return "surfing";

  if (tags.amenity === "bicycle_rental" || tags.route === "bicycle") return "cycling";
  if (tags.shop === "bicycle" || tags.highway === "cycleway") return "cycling";

  if (tags.leisure === "golf_course" || tags.sport === "golf") return "golf";

  if (tags.tourism === "camp_site" || tags.tourism === "caravan_site") return "camping";

  return "other";
}

/**
 * Génère un nom pour les activités sans nom
 */
function generateActivityName(tags: any, activityType: string): string {
  const typeNames: { [key: string]: string } = {
    beach: "Plage",
    hiking: "Point de vue",
    skiing: "Station de ski",
    surfing: "Spot de surf",
    cycling: "Piste cyclable",
    golf: "Golf",
    camping: "Camping",
    other: "Activité",
  };

  const baseName = typeNames[activityType] || "Lieu";

  // Ajouter des détails si disponibles
  if (tags.natural === "peak" && tags.ele) {
    return `Sommet (${tags.ele}m)`;
  }
  if (tags.aerialway === "station") {
    return "Station de téléphérique";
  }
  if (tags["piste:type"]) {
    return `Piste ${tags["piste:difficulty"] || ""}`.trim();
  }

  return baseName;
}

/**
 * Construit l'adresse à partir des tags
 */
function buildAddress(tags: any): string | undefined {
  const parts: string[] = [];

  if (tags["addr:street"]) {
    if (tags["addr:housenumber"]) {
      parts.push(`${tags["addr:housenumber"]} ${tags["addr:street"]}`);
    } else {
      parts.push(tags["addr:street"]);
    }
  }
  if (tags["addr:city"]) parts.push(tags["addr:city"]);
  if (tags["addr:postcode"]) parts.push(tags["addr:postcode"]);

  return parts.length > 0 ? parts.join(", ") : undefined;
}

/**
 * NOTE: getHotels n'est plus utilisé dans l'application.
 * La fonctionnalité hôtels a été supprimée du flux principal de recherche.
 * Cette fonction peut être réactivée si nécessaire dans le futur.
 */
// export const getHotels = onCall(...)

/**
 * Get IP-based geolocation using ipapi.co
 */
export const getIpLocation = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 10,
    memory: "256MiB",
  },
  async (request) => {
    try {
      const response = await axios.get(IPAPI_URL, {
        timeout: 10000,
        validateStatus: (status) => status !== undefined && status < 500,
      });

      if (response.status !== 200) {
        return { location: null, error: `IP geolocation returned status ${response.status}` };
      }

      const data = response.data;
      return {
        location: {
          latitude: parseFloat(data.latitude) || 0,
          longitude: parseFloat(data.longitude) || 0,
          city: data.city || null,
          region: data.region || null,
          country: data.country_name || null,
          countryCode: data.country_code || null,
        },
        error: null,
      };
    } catch (error) {
      console.error("getIpLocation error:", error);
      return { location: null, error: String(error) };
    }
  }
);
