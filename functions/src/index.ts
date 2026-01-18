import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import axios from "axios";

admin.initializeApp();

// Configuration
const OVERPASS_API_URL = "https://overpass-api.de/api/interpreter";
const OPEN_METEO_API_URL = "https://api.open-meteo.com/v1/forecast";
const MIN_CITIES = 20;
const MAX_CITIES_TO_PROCESS = 60;
const CACHE_DURATION_HOURS = 24;

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

// Firestore cache reference
const db = admin.firestore();

/**
 * Main search function - callable from Flutter app
 */
export const searchDestinations = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 60,
    memory: "512MiB",
  },
  async (request) => {
    const data = request.data as SearchParams;
    console.log("Search request received:", JSON.stringify(data));

    try {
      // 1. Get cities (with cache)
      const cities = await getCitiesWithExpansion(data);
      console.log(`Found ${cities.length} cities`);

      if (cities.length === 0) {
        return { results: [], error: null };
      }

      // 2. Get weather for all cities in parallel
      const weatherPromises = cities.slice(0, MAX_CITIES_TO_PROCESS).map((city) =>
        getWeatherWithCache(city, data.startDate, data.endDate)
      );
      const weatherResults = await Promise.allSettled(weatherPromises);

      // 3. Calculate scores and build results
      const results: SearchResult[] = [];
      const selectedHours = getSelectedHours(data.timeSlots);

      for (let i = 0; i < weatherResults.length; i++) {
        const weatherResult = weatherResults[i];
        if (weatherResult.status === "fulfilled" && weatherResult.value) {
          const city = cities[i];
          const weather = weatherResult.value;

          if (weather.forecasts.length === 0) continue;

          const weatherScore = calculateWeatherScore(
            weather.forecasts,
            data,
            selectedHours
          );

          // Filter by conditions if specified
          if (data.desiredConditions.length > 0) {
            if (!matchesDesiredConditions(weather.forecasts, data.desiredConditions)) {
              continue;
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
      }

      // 4. Sort by score descending
      results.sort((a, b) => b.overallScore - a.overallScore);

      console.log(`Returning ${results.length} results`);
      return { results: results.slice(0, 50), error: null };
    } catch (error) {
      console.error("Search error:", error);
      return { results: [], error: String(error) };
    }
  });

/**
 * Get cities with automatic radius expansion to ensure minimum results
 */
async function getCitiesWithExpansion(params: SearchParams): Promise<City[]> {
  let radius = params.searchRadius;
  let cities: City[] = [];
  const maxRadius = Math.min(params.searchRadius * 3, 500);

  while (cities.length < MIN_CITIES && radius <= maxRadius) {
    cities = await getCitiesFromOverpass(
      params.centerLatitude,
      params.centerLongitude,
      radius
    );

    if (cities.length < MIN_CITIES) {
      radius = Math.min(radius * 1.5, maxRadius);
      console.log(`Expanding search radius to ${radius}km (found ${cities.length} cities)`);
    }
  }

  return cities;
}

/**
 * Get cities from Overpass API with Firestore caching
 */
async function getCitiesFromOverpass(
  lat: number,
  lon: number,
  radiusKm: number
): Promise<City[]> {
  // Check cache first
  const cacheKey = `cities_${lat.toFixed(2)}_${lon.toFixed(2)}_${Math.round(radiusKm)}`;
  const cacheRef = db.collection("cache_cities").doc(cacheKey);
  const cached = await cacheRef.get();

  if (cached.exists) {
    const data = cached.data();
    if (data && Date.now() - data.timestamp < CACHE_DURATION_HOURS * 3600000) {
      console.log("Cache hit for cities");
      return data.cities as City[];
    }
  }

  // Calculate bounding box
  const latDelta = radiusKm / 111.0;
  const lonDelta = radiusKm / (111.0 * Math.cos((lat * Math.PI) / 180));

  const query = `
[out:json][timeout:30];
(
  node["place"="city"](${lat - latDelta},${lon - lonDelta},${lat + latDelta},${lon + lonDelta});
  node["place"="town"](${lat - latDelta},${lon - lonDelta},${lat + latDelta},${lon + lonDelta});
  node["place"="village"](${lat - latDelta},${lon - lonDelta},${lat + latDelta},${lon + lonDelta});
  way["place"="city"](${lat - latDelta},${lon - lonDelta},${lat + latDelta},${lon + lonDelta});
  way["place"="town"](${lat - latDelta},${lon - lonDelta},${lat + latDelta},${lon + lonDelta});
  way["place"="village"](${lat - latDelta},${lon - lonDelta},${lat + latDelta},${lon + lonDelta});
);
out center;
`;

  try {
    const response = await axios.post(OVERPASS_API_URL, query, {
      headers: { "Content-Type": "text/plain" },
      timeout: 35000,
    });

    const elements = response.data.elements || [];
    const cities: City[] = [];

    for (const element of elements) {
      const tags = element.tags || {};
      const place = tags.place;
      if (place !== "city" && place !== "town" && place !== "village") continue;

      const name = tags.name || tags["name:fr"] || "";
      if (!name) continue;

      let cityLat: number, cityLon: number;
      if (element.type === "node") {
        cityLat = element.lat;
        cityLon = element.lon;
      } else if (element.center) {
        cityLat = element.center.lat;
        cityLon = element.center.lon;
      } else {
        continue;
      }

      const distance = calculateDistance(lat, lon, cityLat, cityLon);
      if (distance > radiusKm) continue;

      cities.push({
        id: String(element.id),
        name,
        country: tags["addr:country"] || tags["is_in:country"],
        latitude: cityLat,
        longitude: cityLon,
        distance,
      });
    }

    // Sort by distance
    cities.sort((a, b) => a.distance - b.distance);

    // Cache results
    if (cities.length > 0) {
      await cacheRef.set({
        cities,
        timestamp: Date.now(),
      });
    }

    return cities;
  } catch (error) {
    console.error("Overpass API error:", error);
    return [];
  }
}

/**
 * Get weather data with caching
 */
async function getWeatherWithCache(
  city: City,
  startDate: string,
  endDate: string
): Promise<{ forecasts: WeatherData[]; avgTemp: number } | null> {
  // Check cache
  const cacheKey = `weather_${city.latitude.toFixed(2)}_${city.longitude.toFixed(2)}_${startDate}_${endDate}`;
  const cacheRef = db.collection("cache_weather").doc(cacheKey);
  const cached = await cacheRef.get();

  if (cached.exists) {
    const data = cached.data();
    if (data && Date.now() - data.timestamp < CACHE_DURATION_HOURS * 3600000) {
      return data.weather;
    }
  }

  try {
    const response = await axios.get(OPEN_METEO_API_URL, {
      params: {
        latitude: city.latitude,
        longitude: city.longitude,
        start_date: startDate,
        end_date: endDate,
        daily: "temperature_2m_max,temperature_2m_min,weathercode",
        hourly: "temperature_2m,weathercode",
        timezone: "auto",
      },
      timeout: 10000,
    });

    const forecasts = parseWeatherResponse(response.data, startDate, endDate);
    const avgTemp =
      forecasts.length > 0
        ? forecasts.reduce((sum, f) => sum + f.temperature, 0) / forecasts.length
        : 0;

    const result = { forecasts, avgTemp };

    // Cache results
    await cacheRef.set({
      weather: result,
      timestamp: Date.now(),
    });

    return result;
  } catch (error) {
    console.error(`Weather error for ${city.name}:`, error);
    return null;
  }
}

/**
 * Parse Open-Meteo response
 */
function parseWeatherResponse(
  data: any,
  startDate: string,
  endDate: string
): WeatherData[] {
  const daily = data.daily || {};
  const times = daily.time || [];
  const tempsMax = daily.temperature_2m_max || [];
  const tempsMin = daily.temperature_2m_min || [];
  const weatherCodes = daily.weathercode || [];

  const hourly = data.hourly || {};
  const hourlyTimes = hourly.time || [];
  const hourlyTemps = hourly.temperature_2m || [];
  const hourlyWeatherCodes = hourly.weathercode || [];

  // Build hourly data map
  const hourlyByDate: { [key: string]: Array<{ hour: number; temperature: number; condition: string }> } = {};
  for (let i = 0; i < hourlyTimes.length; i++) {
    const dt = new Date(hourlyTimes[i]);
    const dateKey = dt.toISOString().substring(0, 10);
    const hour = dt.getHours();
    const temp = hourlyTemps[i];
    const code = hourlyWeatherCodes[i] || 0;

    if (temp == null) continue;

    if (!hourlyByDate[dateKey]) hourlyByDate[dateKey] = [];
    hourlyByDate[dateKey].push({
      hour,
      temperature: temp,
      condition: mapWeatherCode(code),
    });
  }

  const forecasts: WeatherData[] = [];
  for (let i = 0; i < times.length && i < tempsMax.length; i++) {
    const dateStr = times[i];
    const tempMax = tempsMax[i];
    const tempMin = tempsMin[i];

    if (tempMax == null || tempMin == null) continue;
    if (tempMax < -60 || tempMax > 60 || tempMin < -60 || tempMin > 60) continue;

    forecasts.push({
      date: dateStr,
      temperature: (tempMax + tempMin) / 2,
      minTemperature: tempMin,
      maxTemperature: tempMax,
      condition: mapWeatherCode(weatherCodes[i] || 0),
      hourlyData: hourlyByDate[dateStr] || [],
    });
  }

  return forecasts;
}

/**
 * Calculate weather score
 */
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
    // Filter by selected hours
    const filteredData = getFilteredWeatherData(forecast, selectedHours);

    // Temperature score (35%)
    const actualAvg = (filteredData.minTemp + filteredData.maxTemp) / 2;
    const tempDiff = Math.abs(actualAvg - desiredAvg);
    const tempScore = 100 * Math.exp(-tempDiff / 10);

    // Condition score (50%)
    let conditionScore = 50; // default
    if (params.desiredConditions.length > 0) {
      for (const desired of params.desiredConditions) {
        const score = getConditionMatchScore(filteredData.condition, desired);
        conditionScore = Math.max(conditionScore, score);
      }
    } else {
      conditionScore = getConditionMatchScore(filteredData.condition, "clear");
    }

    // Stability score (15%) - simplified
    const stabilityScore = 70;

    totalScore += tempScore * 0.35 + conditionScore * 0.5 + stabilityScore * 0.15;
  }

  return totalScore / forecasts.length;
}

/**
 * Filter weather data by selected time slots
 */
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
  const avgTemp = temps.reduce((a, b) => a + b, 0) / temps.length;
  const minTemp = Math.min(...temps);
  const maxTemp = Math.max(...temps);

  // Dominant condition
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

  return { avgTemp, minTemp, maxTemp, condition: dominantCondition };
}

/**
 * Get selected hours from time slots
 */
function getSelectedHours(timeSlots: string[]): Set<number> {
  const hours = new Set<number>();
  for (const slot of timeSlots) {
    switch (slot) {
      case "morning":
        [7, 8, 9, 10, 11].forEach((h) => hours.add(h));
        break;
      case "afternoon":
        [12, 13, 14, 15, 16, 17].forEach((h) => hours.add(h));
        break;
      case "evening":
        [18, 19, 20, 21].forEach((h) => hours.add(h));
        break;
      case "night":
        [22, 23, 0, 1, 2, 3, 4, 5, 6].forEach((h) => hours.add(h));
        break;
    }
  }
  return hours;
}

/**
 * Check if forecasts match desired conditions
 */
function matchesDesiredConditions(
  forecasts: WeatherData[],
  desiredConditions: string[]
): boolean {
  const conditionCounts: { [key: string]: number } = {};
  for (const f of forecasts) {
    conditionCounts[f.condition] = (conditionCounts[f.condition] || 0) + 1;
  }

  let dominant = "";
  let maxCount = 0;
  for (const [cond, count] of Object.entries(conditionCounts)) {
    if (count > maxCount) {
      maxCount = count;
      dominant = cond;
    }
  }

  for (const desired of desiredConditions) {
    if (conditionsMatch(dominant, desired.toLowerCase())) {
      return true;
    }
  }
  return false;
}

function conditionsMatch(actual: string, desired: string): boolean {
  if (actual === desired) return true;
  if (
    (actual === "clear" || actual === "sunny") &&
    (desired === "clear" || desired === "sunny")
  ) {
    return true;
  }
  if (actual === "partly_cloudy" && desired === "clear") return true;
  return false;
}

function getConditionMatchScore(actual: string, desired: string): number {
  if (actual === desired) return 100;
  if (
    (actual === "clear" && desired === "partly_cloudy") ||
    (actual === "partly_cloudy" && desired === "clear")
  ) {
    return 85;
  }
  if (
    (actual === "clear" && desired === "cloudy") ||
    (actual === "cloudy" && desired === "clear")
  ) {
    return 65;
  }
  if (actual === "rain" || desired === "rain") return 35;
  return 50;
}

function mapWeatherCode(code: number): string {
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

function calculateDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}
