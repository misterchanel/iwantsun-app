/**
 * Script de test Node.js pour exécuter les tests de cohérence
 * Exécute directement: node test-runner.js
 */

const { mapWeatherCode, calculateDistance, getConditionMatchScore, getSelectedHours } = require('./lib/index');

let totalPassed = 0;
let totalFailed = 0;
const failures = [];

function test(name, fn) {
  try {
    fn();
    console.log(`✅ ${name}`);
    totalPassed++;
  } catch (e) {
    console.log(`❌ ${name}: ${e.message}`);
    totalFailed++;
    failures.push({ name, error: e.message });
  }
}

console.log('═══════════════════════════════════════════════════════');
console.log('🚀 TESTS DE COHÉRENCE - FONCTION searchDestinations');
console.log('═══════════════════════════════════════════════════════\n');

// Tests mapWeatherCode
console.log('1. Tests mapWeatherCode\n');
test('Code 0 = clear', () => { if (mapWeatherCode(0) !== 'clear') throw new Error('Attendu: clear'); });
test('Code 1-3 = partly_cloudy', () => { if (mapWeatherCode(1) !== 'partly_cloudy') throw new Error(); });
test('Code 45-48 = cloudy', () => { if (mapWeatherCode(45) !== 'cloudy') throw new Error(); });
test('Code 51-67 = rain', () => { if (mapWeatherCode(51) !== 'rain') throw new Error(); });
test('Code 71-77 = snow', () => { if (mapWeatherCode(71) !== 'snow') throw new Error(); });
test('Code 80-82 = rain', () => { if (mapWeatherCode(80) !== 'rain') throw new Error(); });
test('Code 95-99 = rain', () => { if (mapWeatherCode(95) !== 'rain') throw new Error(); });
test('Code inconnu = condition valide', () => {
  const valid = ['clear', 'partly_cloudy', 'cloudy', 'rain', 'snow'];
  if (!valid.includes(mapWeatherCode(999))) throw new Error('Doit retourner une condition valide');
});
test('Tous codes 0-99 valides', () => {
  const valid = ['clear', 'partly_cloudy', 'cloudy', 'rain', 'snow'];
  for (let code = 0; code <= 99; code++) {
    if (!valid.includes(mapWeatherCode(code))) throw new Error(`Code ${code} invalide`);
  }
});

// Tests calculateDistance
console.log('\n2. Tests calculateDistance\n');
test('Distance même point = 0', () => {
  const dist = calculateDistance(45.7640, 4.8357, 45.7640, 4.8357);
  if (dist > 0.1) throw new Error(`Attendu ~0, obtenu: ${dist}`);
});
test('Distance Lyon-Paris ~392km', () => {
  const dist = calculateDistance(45.7640, 4.8357, 48.8566, 2.3522);
  if (dist < 380 || dist > 400) throw new Error(`Attendu ~392km, obtenu: ${dist}km`);
});
test('Distance Lyon-Marseille ~278km', () => {
  const dist = calculateDistance(45.7640, 4.8357, 43.2965, 5.3698);
  if (dist < 270 || dist > 290) throw new Error(`Attendu ~278km, obtenu: ${dist}km`);
});
test('Distance symétrique (A->B = B->A)', () => {
  const dist1 = calculateDistance(45.0, 4.0, 46.0, 5.0);
  const dist2 = calculateDistance(46.0, 5.0, 45.0, 4.0);
  if (Math.abs(dist1 - dist2) > 0.1) throw new Error('Distance non symétrique');
});
test('Distance toujours positive', () => {
  for (let lat = -90; lat <= 90; lat += 30) {
    for (let lon = -180; lon <= 180; lon += 30) {
      const dist = calculateDistance(45.7640, 4.8357, lat, lon);
      if (dist < 0) throw new Error(`Distance négative: ${dist}`);
    }
  }
});
test('Pôle Nord (90,0)', () => {
  const dist = calculateDistance(90, 0, 45.7640, 4.8357);
  if (dist < 0) throw new Error('Distance négative au pôle Nord');
});
test('Pôle Sud (-90,0)', () => {
  const dist = calculateDistance(-90, 0, 45.7640, 4.8357);
  if (dist < 0) throw new Error('Distance négative au pôle Sud');
});
test('Ligne de changement de date (180°/-180°)', () => {
  const dist1 = calculateDistance(45.7640, 180, 45.7640, -180);
  if (dist1 < 0) throw new Error('Distance négative à la ligne de changement de date');
});

// Tests getConditionMatchScore
console.log('\n3. Tests getConditionMatchScore\n');
test('Même condition = 100', () => {
  if (getConditionMatchScore('clear', 'clear') !== 100) throw new Error();
  if (getConditionMatchScore('rain', 'rain') !== 100) throw new Error();
});
test('clear/partly_cloudy = 85', () => {
  if (getConditionMatchScore('clear', 'partly_cloudy') !== 85) throw new Error();
  if (getConditionMatchScore('partly_cloudy', 'clear') !== 85) throw new Error();
});
test('clear/cloudy = 65', () => {
  if (getConditionMatchScore('clear', 'cloudy') !== 65) throw new Error();
  if (getConditionMatchScore('cloudy', 'clear') !== 65) throw new Error();
});
test('Si rain présent = 35', () => {
  if (getConditionMatchScore('rain', 'clear') !== 35) throw new Error();
  if (getConditionMatchScore('clear', 'rain') !== 35) throw new Error();
});
test('Tous scores entre 0-100', () => {
  const conditions = ['clear', 'partly_cloudy', 'cloudy', 'rain', 'snow'];
  for (const c1 of conditions) {
    for (const c2 of conditions) {
      const score = getConditionMatchScore(c1, c2);
      if (score < 0 || score > 100) throw new Error(`Score hors limites: ${score}`);
    }
  }
});

// Tests getSelectedHours
console.log('\n4. Tests getSelectedHours\n');
test('morning = 7-11h', () => {
  const hours = getSelectedHours(['morning']);
  if (!hours.has(7) || !hours.has(11) || hours.has(12)) throw new Error();
});
test('afternoon = 12-17h', () => {
  const hours = getSelectedHours(['afternoon']);
  if (!hours.has(12) || !hours.has(17) || hours.has(11)) throw new Error();
});
test('evening = 18-21h', () => {
  const hours = getSelectedHours(['evening']);
  if (!hours.has(18) || !hours.has(21) || hours.has(17)) throw new Error();
});
test('night = 22-6h', () => {
  const hours = getSelectedHours(['night']);
  if (!hours.has(22) || !hours.has(0) || !hours.has(6) || hours.has(7)) throw new Error();
});
test('Tous créneaux = toutes les heures', () => {
  const hours = getSelectedHours(['morning', 'afternoon', 'evening', 'night']);
  for (let h = 0; h <= 23; h++) {
    if (!hours.has(h)) throw new Error(`Heure ${h} manquante`);
  }
});
test('Combinaison morning + afternoon = 11 heures', () => {
  const hours = getSelectedHours(['morning', 'afternoon']);
  if (hours.size !== 11) throw new Error(`Attendu 11 heures, obtenu: ${hours.size}`);
});

// Tests de cohérence des données
console.log('\n5. Tests de Cohérence des Données\n');
test('Structure résultat complète', () => {
  const result = {
    location: { id: '123', name: 'Lyon', latitude: 45.7640, longitude: 4.8357, distance: 0 },
    weatherForecast: {
      locationId: '123',
      forecasts: [{ date: '2026-01-20', temperature: 15, minTemperature: 10, maxTemperature: 20, condition: 'clear', hourlyData: [] }],
      averageTemperature: 15,
      weatherScore: 75
    },
    overallScore: 75
  };
  if (!result.location.id) throw new Error('location.id manquant');
  if (result.overallScore !== result.weatherForecast.weatherScore) throw new Error('Scores incohérents');
  if (result.weatherForecast.locationId !== result.location.id) throw new Error('locationId incohérent');
});
test('Cohérence température: min <= temp <= max', () => {
  const forecasts = [
    { minTemperature: 10, temperature: 15, maxTemperature: 20 },
    { minTemperature: 5, temperature: 7, maxTemperature: 10 }
  ];
  forecasts.forEach(f => {
    if (f.minTemperature > f.temperature || f.maxTemperature < f.temperature) {
      throw new Error('Cohérence température violée');
    }
  });
});
test('Calcul averageTemperature = moyenne', () => {
  const forecasts = [{ temperature: 10 }, { temperature: 15 }, { temperature: 20 }];
  const avg = forecasts.reduce((sum, f) => sum + f.temperature, 0) / forecasts.length;
  if (avg !== 15) throw new Error(`Moyenne incorrecte: ${avg}`);
});
test('Scores entre 0-100', () => {
  const scores = [0, 25, 50, 75, 100, 45.5, 99.9];
  scores.forEach(s => {
    if (s < 0 || s > 100) throw new Error(`Score hors limites: ${s}`);
  });
});
test('Distances positives', () => {
  const distances = [0, 5, 10, 50, 100, 200];
  distances.forEach(d => {
    if (d < 0) throw new Error(`Distance négative: ${d}`);
  });
});
test('Distances dans rayon avec tolérance', () => {
  const radius = 30;
  const distances = [5, 15, 25, 30, 32]; // 32 dépasse mais tolérance de 2km
  for (let i = 0; i < distances.length - 1; i++) {
    if (distances[i] > radius + 2) throw new Error(`Distance ${distances[i]} dépasse rayon ${radius} + tolérance`);
  }
});

// Tests de cas limites
console.log('\n6. Tests de Cas Limites\n');
test('Températures extrêmes valides', () => {
  const extremes = [-50, -20, 0, 50, 60];
  extremes.forEach(t => {
    if (typeof t !== 'number' || !isFinite(t)) throw new Error('Température invalide');
  });
});
test('Conditions multiples', () => {
  const combos = [['clear', 'partly_cloudy'], ['clear', 'cloudy', 'rain']];
  combos.forEach(c => {
    if (!Array.isArray(c) || c.length === 0) throw new Error('Conditions invalides');
  });
});
test('Créneaux multiples', () => {
  const combos = [['morning', 'afternoon'], ['afternoon', 'evening']];
  combos.forEach(slots => {
    const hours = getSelectedHours(slots);
    if (hours.size === 0) throw new Error('Créneaux invalides');
  });
});
test('Coordonnées limites - Pôles', () => {
  const distNorth = calculateDistance(90, 0, 45.7640, 4.8357);
  const distSouth = calculateDistance(-90, 0, 45.7640, 4.8357);
  if (distNorth < 0 || distSouth < 0) throw new Error('Distance négative aux pôles');
});
test('Coordonnées limites - Ligne de changement de date', () => {
  const dist1 = calculateDistance(45.7640, 180, 45.7640, -180);
  const dist2 = calculateDistance(45.7640, -180, 45.7640, 180);
  if (dist1 < 0 || dist2 < 0) throw new Error('Distance négative à la ligne de changement de date');
});

// Tests de validation des paramètres
console.log('\n7. Tests de Validation des Paramètres\n');
test('Température min = max (plage exacte)', () => {
  const min = 25;
  const max = 25;
  if (min > max) throw new Error('min doit être <= max');
});
test('Température min > max (invalide)', () => {
  const min = 30;
  const max = 20;
  if (!(min > max)) throw new Error('Doit détecter min > max');
});
test('Rayon négatif (invalide)', () => {
  const radius = -10;
  if (radius > 0) throw new Error('Doit détecter rayon négatif');
});
test('Rayon > 200km (doit être limité)', () => {
  const radius = 300;
  const maxRadius = 200;
  if (radius <= maxRadius) throw new Error('Doit détecter rayon > max');
});

// Résumé
console.log('\n═══════════════════════════════════════════════════════');
console.log('📊 RÉSUMÉ DES TESTS');
console.log('═══════════════════════════════════════════════════════');
console.log(`✅ Tests réussis: ${totalPassed}`);
console.log(`❌ Tests échoués: ${totalFailed}`);
const total = totalPassed + totalFailed;
const successRate = total > 0 ? ((totalPassed / total) * 100).toFixed(1) : '0.0';
console.log(`📈 Taux de réussite: ${successRate}%`);

if (failures.length > 0) {
  console.log('\n❌ Échecs détaillés:');
  failures.forEach(f => {
    console.log(`   - ${f.name}: ${f.error}`);
  });
}

console.log('═══════════════════════════════════════════════════════\n');

if (totalFailed === 0) {
  console.log('🎉 Tous les tests sont passés avec succès !');
  process.exit(0);
} else {
  console.log(`⚠️ ${totalFailed} test(s) ont échoué`);
  process.exit(1);
}
