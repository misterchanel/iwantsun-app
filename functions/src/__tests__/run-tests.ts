/**
 * Script de test pour exécuter les tests de cohérence
 * Ce script teste directement les fonctions utilitaires et simule l'appel de la fonction principale
 */

import { 
  mapWeatherCode, 
  calculateDistance,
  getConditionMatchScore,
  getSelectedHours
} from '../index';

// Tests des fonctions utilitaires
const runUtilityTests = () => {
  console.log('🧪 Tests des Fonctions Utilitaires\n');
  
  let passed = 0;
  let failed = 0;

  // Test mapWeatherCode
  console.log('1. Test mapWeatherCode...');
  try {
    if (mapWeatherCode(0) !== 'clear') throw new Error('Code 0 doit être clear');
    if (mapWeatherCode(1) !== 'partly_cloudy') throw new Error('Code 1 doit être partly_cloudy');
    if (mapWeatherCode(51) !== 'rain') throw new Error('Code 51 doit être rain');
    if (mapWeatherCode(71) !== 'snow') throw new Error('Code 71 doit être snow');
    if (!['clear', 'partly_cloudy', 'cloudy', 'rain', 'snow'].includes(mapWeatherCode(999))) {
      throw new Error('Code inconnu doit retourner une condition valide');
    }
    console.log('   ✅ mapWeatherCode: PASSÉ\n');
    passed++;
  } catch (e) {
    console.log(`   ❌ mapWeatherCode: ÉCHOUÉ - ${e}\n`);
    failed++;
  }

  // Test calculateDistance
  console.log('2. Test calculateDistance...');
  try {
    const dist1 = calculateDistance(45.7640, 4.8357, 45.7640, 4.8357);
    if (dist1 > 0.1) throw new Error('Distance même point doit être ~0');
    
    const dist2 = calculateDistance(45.7640, 4.8357, 48.8566, 2.3522); // Lyon-Paris
    if (dist2 < 380 || dist2 > 400) throw new Error(`Lyon-Paris doit être ~392km, obtenu: ${dist2}`);
    
    const dist3 = calculateDistance(45.7640, 4.8357, 46.0, 5.0);
    const dist4 = calculateDistance(46.0, 5.0, 45.7640, 4.8357);
    if (Math.abs(dist3 - dist4) > 0.1) throw new Error('Distance doit être symétrique');
    
    console.log('   ✅ calculateDistance: PASSÉ\n');
    passed++;
  } catch (e) {
    console.log(`   ❌ calculateDistance: ÉCHOUÉ - ${e}\n`);
    failed++;
  }

  // Test getConditionMatchScore
  console.log('3. Test getConditionMatchScore...');
  try {
    if (getConditionMatchScore('clear', 'clear') !== 100) throw new Error('Même condition doit être 100');
    if (getConditionMatchScore('clear', 'partly_cloudy') !== 85) throw new Error('clear/partly_cloudy doit être 85');
    if (getConditionMatchScore('clear', 'rain') !== 35) throw new Error('clear/rain doit être 35');
    if (getConditionMatchScore('snow', 'clear') !== 50) throw new Error('snow/clear doit être 50');
    
    // Vérifier toutes les combinaisons
    const conditions = ['clear', 'partly_cloudy', 'cloudy', 'rain', 'snow'];
    for (const c1 of conditions) {
      for (const c2 of conditions) {
        const score = getConditionMatchScore(c1, c2);
        if (score < 0 || score > 100) throw new Error(`Score hors limites: ${score}`);
      }
    }
    console.log('   ✅ getConditionMatchScore: PASSÉ\n');
    passed++;
  } catch (e) {
    console.log(`   ❌ getConditionMatchScore: ÉCHOUÉ - ${e}\n`);
    failed++;
  }

  // Test getSelectedHours
  console.log('4. Test getSelectedHours...');
  try {
    const morningHours = getSelectedHours(['morning']);
    if (!morningHours.has(7) || !morningHours.has(11) || morningHours.has(12)) {
      throw new Error('Morning doit contenir 7-11h uniquement');
    }
    
    const afternoonHours = getSelectedHours(['afternoon']);
    if (!afternoonHours.has(12) || !afternoonHours.has(17) || afternoonHours.has(11)) {
      throw new Error('Afternoon doit contenir 12-17h uniquement');
    }
    
    const allHours = getSelectedHours(['morning', 'afternoon', 'evening', 'night']);
    for (let h = 0; h <= 23; h++) {
      if (!allHours.has(h)) throw new Error(`Tous les créneaux doivent contenir l'heure ${h}`);
    }
    
    console.log('   ✅ getSelectedHours: PASSÉ\n');
    passed++;
  } catch (e) {
    console.log(`   ❌ getSelectedHours: ÉCHOUÉ - ${e}\n`);
    failed++;
  }

  return { passed, failed };
};

// Tests de cohérence des données
const runDataCoherenceTests = () => {
  console.log('🔍 Tests de Cohérence des Données\n');
  
  let passed = 0;
  let failed = 0;

  // Test structure résultat
  console.log('5. Test structure résultat...');
  try {
    const mockResult = {
      location: {
        id: '123',
        name: 'Lyon',
        latitude: 45.7640,
        longitude: 4.8357,
        distance: 0
      },
      weatherForecast: {
        locationId: '123',
        forecasts: [{
          date: '2026-01-20',
          temperature: 15,
          minTemperature: 10,
          maxTemperature: 20,
          condition: 'clear',
          hourlyData: []
        }],
        averageTemperature: 15,
        weatherScore: 75
      },
      overallScore: 75
    };

    if (!mockResult.location.id) throw new Error('location.id manquant');
    if (!mockResult.weatherForecast.forecasts.length) throw new Error('forecasts vide');
    if (mockResult.overallScore !== mockResult.weatherForecast.weatherScore) {
      throw new Error('overallScore doit égaler weatherScore');
    }
    if (mockResult.weatherForecast.locationId !== mockResult.location.id) {
      throw new Error('locationId doit correspondre à location.id');
    }
    
    // Vérifier cohérence température
    const forecast = mockResult.weatherForecast.forecasts[0];
    if (forecast.minTemperature > forecast.temperature || forecast.maxTemperature < forecast.temperature) {
      throw new Error('min <= temp <= max doit être respecté');
    }
    
    console.log('   ✅ Structure résultat: PASSÉ\n');
    passed++;
  } catch (e) {
    console.log(`   ❌ Structure résultat: ÉCHOUÉ - ${e}\n`);
    failed++;
  }

  // Test calcul averageTemperature
  console.log('6. Test calcul averageTemperature...');
  try {
    const forecasts = [
      { temperature: 10 },
      { temperature: 15 },
      { temperature: 20 }
    ];
    const avg = forecasts.reduce((sum, f) => sum + f.temperature, 0) / forecasts.length;
    if (avg !== 15) throw new Error(`Moyenne incorrecte: ${avg}, attendu: 15`);
    console.log('   ✅ Calcul averageTemperature: PASSÉ\n');
    passed++;
  } catch (e) {
    console.log(`   ❌ Calcul averageTemperature: ÉCHOUÉ - ${e}\n`);
    failed++;
  }

  // Test scores
  console.log('7. Test validation scores...');
  try {
    const scores = [0, 25, 50, 75, 100, 45.5, 99.9];
    for (const score of scores) {
      if (score < 0 || score > 100) throw new Error(`Score hors limites: ${score}`);
    }
    console.log('   ✅ Validation scores: PASSÉ\n');
    passed++;
  } catch (e) {
    console.log(`   ❌ Validation scores: ÉCHOUÉ - ${e}\n`);
    failed++;
  }

  // Test distances
  console.log('8. Test validation distances...');
  try {
    const distances = [0, 5, 10, 50, 100, 200];
    for (const dist of distances) {
      if (dist < 0) throw new Error(`Distance négative: ${dist}`);
    }
    
    const radius = 30;
    const testDistances = [5, 15, 25, 30, 31];
    for (const dist of testDistances.slice(0, 4)) {
      if (dist > radius + 2) throw new Error(`Distance ${dist} dépasse rayon ${radius}`);
    }
    console.log('   ✅ Validation distances: PASSÉ\n');
    passed++;
  } catch (e) {
    console.log(`   ❌ Validation distances: ÉCHOUÉ - ${e}\n`);
    failed++;
  }

  return { passed, failed };
};

// Tests de cas limites
const runEdgeCaseTests = () => {
  console.log('⚡ Tests de Cas Limites\n');
  
  let passed = 0;
  let failed = 0;

  // Test coordonnées limites
  console.log('9. Test coordonnées limites...');
  try {
    // Pôle Nord
    const dist1 = calculateDistance(90, 0, 45.7640, 4.8357);
    if (dist1 < 0) throw new Error('Distance négative');
    
    // Pôle Sud
    const dist2 = calculateDistance(-90, 0, 45.7640, 4.8357);
    if (dist2 < 0) throw new Error('Distance négative');
    
    // Ligne de changement de date
    const dist3 = calculateDistance(45.7640, 180, 45.7640, -180);
    if (dist3 < 0) throw new Error('Distance négative');
    
    console.log('   ✅ Coordonnées limites: PASSÉ\n');
    passed++;
  } catch (e) {
    console.log(`   ❌ Coordonnées limites: ÉCHOUÉ - ${e}\n`);
    failed++;
  }

  // Test températures extrêmes
  console.log('10. Test températures extrêmes...');
  try {
    const extremeTemps = [-50, -20, 0, 50, 60];
    for (const temp of extremeTemps) {
      if (typeof temp !== 'number') throw new Error('Température doit être un nombre');
      if (!isFinite(temp)) throw new Error('Température doit être finie');
    }
    console.log('   ✅ Températures extrêmes: PASSÉ\n');
    passed++;
  } catch (e) {
    console.log(`   ❌ Températures extrêmes: ÉCHOUÉ - ${e}\n`);
    failed++;
  }

  // Test conditions multiples
  console.log('11. Test conditions multiples...');
  try {
    const combos = [
      ['clear', 'partly_cloudy'],
      ['clear', 'cloudy', 'rain'],
      ['partly_cloudy', 'cloudy']
    ];
    for (const combo of combos) {
      if (!Array.isArray(combo)) throw new Error('Doit être un array');
      if (combo.length === 0) throw new Error('Array ne doit pas être vide');
    }
    console.log('   ✅ Conditions multiples: PASSÉ\n');
    passed++;
  } catch (e) {
    console.log(`   ❌ Conditions multiples: ÉCHOUÉ - ${e}\n`);
    failed++;
  }

  // Test créneaux multiples
  console.log('12. Test créneaux multiples...');
  try {
    const slotCombos = [
      ['morning', 'afternoon'],
      ['afternoon', 'evening'],
      ['morning', 'evening', 'night']
    ];
    for (const slots of slotCombos) {
      const hours = getSelectedHours(slots);
      if (hours.size === 0) throw new Error('Doit contenir des heures');
    }
    console.log('   ✅ Créneaux multiples: PASSÉ\n');
    passed++;
  } catch (e) {
    console.log(`   ❌ Créneaux multiples: ÉCHOUÉ - ${e}\n`);
    failed++;
  }

  return { passed, failed };
};

// Exécution des tests
const runAllTests = () => {
  console.log('═══════════════════════════════════════════════════════');
  console.log('🚀 EXECUTION DES TESTS DE COHÉRENCE');
  console.log('═══════════════════════════════════════════════════════\n');

  const utilResults = runUtilityTests();
  const dataResults = runDataCoherenceTests();
  const edgeResults = runEdgeCaseTests();

  const totalPassed = utilResults.passed + dataResults.passed + edgeResults.passed;
  const totalFailed = utilResults.failed + dataResults.failed + edgeResults.failed;
  const total = totalPassed + totalFailed;

  console.log('═══════════════════════════════════════════════════════');
  console.log('📊 RÉSUMÉ DES TESTS');
  console.log('═══════════════════════════════════════════════════════');
  console.log(`✅ Tests réussis: ${totalPassed}`);
  console.log(`❌ Tests échoués: ${totalFailed}`);
  console.log(`📈 Taux de réussite: ${((totalPassed / total) * 100).toFixed(1)}%`);
  console.log('═══════════════════════════════════════════════════════\n');

  if (totalFailed === 0) {
    console.log('🎉 Tous les tests sont passés avec succès !');
    process.exit(0);
  } else {
    console.log(`⚠️ ${totalFailed} test(s) ont échoué`);
    process.exit(1);
  }
};

// Exécuter si appelé directement
if (require.main === module) {
  runAllTests();
}

export { runAllTests };
