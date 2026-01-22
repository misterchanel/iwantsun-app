import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import axios from "axios";

admin.initializeApp();

// Configuration
const OVERPASS_SERVERS = [
  "https://overpass-api.de/api/interpreter",
  "https://overpass.kumi.systems/api/interpreter",
  "https://overpass.openstreetmap.ru/api/interpreter",
  // Retiré : overpass-api.openstreetmap.fr (DNS error constant)
  // Retiré : overpass.nchc.org.tw (DNS error constant)
];

const OPEN_METEO_API_URL = "https://api.open-meteo.com/v1/forecast";
const MAX_CITIES_TO_PROCESS = 60;
const CACHE_DURATION_HOURS = 24;
const MAX_SEARCH_RADIUS_KM = 200;

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
      const cities = await getCitiesFromOverpass(
        data.centerLatitude,
        data.centerLongitude,
        Math.min(data.searchRadius, MAX_SEARCH_RADIUS_KM)
      );
      console.log(`Found ${cities.length} cities in ${Date.now() - startTime}ms`);

      if (cities.length === 0) {
        console.warn("No cities found in the search radius");
        return { 
          results: [], 
          error: "Les serveurs de données géographiques sont temporairement indisponibles. Veuillez réessayer dans quelques instants. Si le problème persiste, essayez d'élargir votre zone de recherche." 
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
  const cacheKey = `cities_${lat.toFixed(2)}_${lon.toFixed(2)}_${Math.round(radiusKm)}`;
  const cacheRef = db.collection("cache_cities").doc(cacheKey);
  const cached = await cacheRef.get();

  let expiredCities: City[] | null = null;

  if (cached.exists) {
    const data = cached.data();
    if (data && Date.now() - data.timestamp < CACHE_DURATION_HOURS * 3600000) {
      console.log("Cache hit for cities");
      return data.cities as City[];
    } else if (data && data.cities) {
      // Cache expiré : sauvegarder pour fallback
      expiredCities = data.cities as City[];
      console.log(`Cache expired but available for fallback (${expiredCities.length} cities)`);
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
  for (const serverUrl of OVERPASS_SERVERS) {
    try {
      console.log(`Trying Overpass server: ${serverUrl}`);
      // Timeout plus long pour le serveur de fallback (kumi.systems)
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
        await cacheRef.set({ cities, timestamp: Date.now() });
        console.log(`Successfully fetched ${cities.length} cities from ${serverUrl}`);
        return cities;
      } else {
        console.warn(`Server ${serverUrl} returned empty results`);
      }
    } catch (error: any) {
      const errorMsg = error?.message || String(error);
      errors.push(`${serverUrl}: ${errorMsg}`);
      console.warn(`Overpass server ${serverUrl} failed: ${errorMsg}`);
    }
  }

  // Si tous les serveurs ont échoué, utiliser le cache expiré si disponible
  if (expiredCities && expiredCities.length > 0) {
    console.warn(`All Overpass servers failed. Using expired cache with ${expiredCities.length} cities. Errors: ${errors.join('; ')}`);
    return expiredCities;
  }

  // Si pas de cache expiré, retourner vide
  console.error(`All Overpass servers failed. No cache available. Errors: ${errors.join('; ')}`);
  return [];
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
 * NOTE: getActivities n'est plus utilisé dans l'application.
 * La fonctionnalité activités est configurée (sélection des types d'activités dans l'UI)
 * mais les activités ne sont jamais récupérées depuis l'API pour être affichées.
 * ActivityRepository est configuré mais jamais appelé dans l'UI.
 * Cette fonction peut être réactivée si nécessaire dans le futur.
 */
// export const getActivities = onCall(...)

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
