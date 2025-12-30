// lib/services/ai_prediction_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match.dart';
import '../models/prediction.dart';
import 'api_service.dart';

class AIPredictionService {
  static String get _openAiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Duration _timeout = Duration(seconds: 30);
  static const Duration _cacheExpiry = Duration(hours: 6);
  static bool get isConfigured => _openAiKey.isNotEmpty;

  // ==================== MAIN PREDICTION GETTER ====================

  static Future<List<Prediction>> getPredictions() async {
    try {
      print('🤖 Fetching predictions...');

      // Try AI predictions first if configured
      if (isConfigured) {
        final aiPredictions = await _getAIPredictions();
        if (aiPredictions.isNotEmpty) {
          print('✅ Using ${aiPredictions.length} AI predictions');
          return aiPredictions;
        }
      }

      // Fallback to basic predictions
      print('⚙️ Generating basic predictions...');
      return await _getBasicPredictions();
    } catch (e) {
      print('❌ Error: $e');
      return await _getBasicPredictions();
    }
  }

  // ==================== AI PREDICTIONS ====================

  static Future<List<Prediction>> _getAIPredictions() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      print('🔍 Checking for cached predictions since: $startOfDay');

      final snapshot = await _firestore
          .collection('ai_predictions')
          .where('created_at', isGreaterThan: Timestamp.fromDate(startOfDay))
          .where('status', isEqualTo: 'pending')
          .orderBy('created_at')
          .orderBy('confidence', descending: true)
          .limit(50)
          .get()
          .timeout(const Duration(seconds: 10));

      print('📊 Found ${snapshot.docs.length} cached AI predictions');

      if (snapshot.docs.isNotEmpty) {
        print('✅ Using ${snapshot.docs.length} existing AI predictions');
        return snapshot.docs
            .map((doc) => Prediction.fromJson({...doc.data(), 'id': doc.id}))
            .toList();
      }

      // Check if we already generated today
      print('⚠️ No cached predictions found. Checking if we should generate...');
      final generatedToday = await _checkIfGeneratedToday();
      if (generatedToday) {
        print('⚠️ Already generated predictions today but query returned empty. Using fallback.');
        return await _getBasicPredictions();
      }

      // Generate new AI predictions
      print('🔄 Generating new AI predictions...');
      final matches = await ApiService.getTodayMatches();
      final upcomingMatches = matches
          .where(
            (m) => m.status == 'upcoming' && m.dateTime.isAfter(DateTime.now()),
          )
          .take(15) // Limit to top 15 matches to save API costs
          .toList();

      if (upcomingMatches.isEmpty) {
        print('⚠️ No upcoming matches found');
        return [];
      }

      final predictions = await _generateAIPredictions(upcomingMatches);

      if (predictions.isNotEmpty) {
        await _storeAIPredictions(predictions);
        await _markAsGeneratedToday();
      }

      return predictions;
    } catch (e) {
      print('❌ AI prediction error: $e');
      return [];
    }
  }

  // ✅ NEW: Track if we've already generated today
  static Future<bool> _checkIfGeneratedToday() async {
    try {
      final doc = await _firestore
          .collection('prediction_metadata')
          .doc('generation_tracker')
          .get();

      if (!doc.exists) return false;

      final lastGenerated = (doc.data()?['last_generated'] as Timestamp?)?.toDate();
      if (lastGenerated == null) return false;

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      return lastGenerated.isAfter(todayStart);
    } catch (e) {
      return false;
    }
  }

  static Future<void> _markAsGeneratedToday() async {
    try {
      await _firestore
          .collection('prediction_metadata')
          .doc('generation_tracker')
          .set({
        'last_generated': FieldValue.serverTimestamp(),
        'generated_at': FieldValue.serverTimestamp(),
      });
      print('✅ Marked as generated today');
    } catch (e) {
      print('⚠️ Could not mark generation: $e');
    }
  }

  static Future<List<Prediction>> _generateAIPredictions(
    List<Match> matches,
  ) async {
    final predictions = <Prediction>[];

    print('🎯 Generating AI predictions for ${matches.length} matches');

    // Process in batches of 3 to avoid rate limits
    for (int i = 0; i < matches.length; i += 3) {
      final batch = matches.sublist(
        i,
        (i + 3 > matches.length) ? matches.length : i + 3,
      );

      for (var match in batch) {
        try {
          print('  🔄 ${match.homeTeam} vs ${match.awayTeam}...');
          final prediction = await _generateSingleAIPrediction(match);
          if (prediction != null) {
            predictions.add(prediction);
            print('  ✅ Generated (${prediction.pick} @ ${prediction.odds})');
          } else {
            print('  ⚠️ Failed');
          }
        } catch (e) {
          print('  ❌ Error: $e');
        }
      }

      // Delay between batches to respect rate limits
      if (i + 3 < matches.length) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    print('✅ Generated ${predictions.length}/${matches.length} AI predictions');
    return predictions;
  }

  static Future<Prediction?> _generateSingleAIPrediction(Match match) async {
    try {
      final prompt = _buildAIPrompt(match);

      final response = await http
          .post(
            Uri.parse('https://api.openai.com/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_openAiKey',
            },
            body: json.encode({
              'model': 'gpt-3.5-turbo',
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are an expert football analyst. Analyze matches considering: team form, head-to-head records, home advantage, league position, tactical matchups, injury news, and historical goal patterns. Provide data-driven predictions with specific reasoning.',
                },
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.7,
              'max_tokens': 400,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        print('❌ OpenAI API Error: ${response.statusCode} - ${response.body}');
        return null;
      }

      final data = json.decode(response.body);
      final content = data['choices'][0]['message']['content'];

      // Parse JSON response from AI
      final predictionData = _parseAIResponse(content);

      if (predictionData == null) {
        print(
          '⚠️ Could not parse AI response for ${match.homeTeam} vs ${match.awayTeam}',
        );
        return null;
      }

      final confidence = predictionData['confidence'] ?? 70;
      final pick = predictionData['pick'] ?? 'Unknown';

      // ✅ GET ACTUAL ODDS FROM MATCH DATA BASED ON THE PICK
      double actualOdds = _getActualOddsForPick(match, pick);

      return Prediction(
        id: 'ai_${match.id}_${DateTime.now().millisecondsSinceEpoch}',
        homeTeam: match.homeTeam,
        awayTeam: match.awayTeam,
        league: match.league,
        pick: pick,
        odds: actualOdds, // ✅ Use actual odds
        confidence: confidence,
        analysis: predictionData['analysis'] ?? 'No analysis available',
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('❌ Error generating AI prediction: $e');
      return null;
    }
  }

  // ✅ NEW HELPER FUNCTION
  static double _getActualOddsForPick(Match match, String pick) {
    if (match.odds == null) {
      return _calculateOddsFromConfidence(70); // Fallback
    }

    final odds = match.odds!;
    final pickLower = pick.toLowerCase();
    final homeLower = match.homeTeam.toLowerCase();
    final awayLower = match.awayTeam.toLowerCase();

    // Match the pick to actual odds
    if (pickLower.contains(homeLower) || pickLower.contains('home win')) {
      return odds.homeWin;
    } else if (pickLower.contains(awayLower) || pickLower.contains('away win')) {
      return odds.awayWin;
    } else if (pickLower.contains('draw')) {
      return odds.draw;
    } else if (pickLower.contains('over 2.5')) {
      return odds.over25 ?? 1.85;
    } else if (pickLower.contains('under 2.5')) {
      return odds.under25 ?? 1.85;
    } else if (pickLower.contains('btts') || pickLower.contains('both teams')) {
      return odds.btts ?? 1.80;
    }

    // Fallback to confidence-based calculation
    return _calculateOddsFromConfidence(70);
  }

  static String _buildAIPrompt(Match match) {
    final leagueContext = _getLeagueContext(match.league);
    final teamContext = _getTeamContext(match.homeTeam, match.awayTeam);

    return '''
Analyze this upcoming football match:

**Match Details:**
- Home: ${match.homeTeam}
- Away: ${match.awayTeam}
- League: ${match.league}
- Kickoff: ${_formatDateTime(match.dateTime)}
${match.odds != null ? '- Market Odds: H:${match.odds!.homeWin} D:${match.odds!.draw} A:${match.odds!.awayWin}' : ''}

**League Context:**
$leagueContext

**Team Insights:**
$teamContext

**Analysis Factors:**
Consider: Recent form (last 5 games), head-to-head history, home advantage, league standings, tactical styles, key players, injury impact, motivation levels, and goal-scoring patterns.

**Output Format (JSON only, no markdown):**
{
  "pick": "Home Win/Draw/Away Win/Over 2.5/Under 2.5",
  "confidence": 65-85,
  "analysis": "2-3 sentence analysis with specific reasoning based on the factors above",
  "key_factors": ["factor1", "factor2", "factor3"]
}
''';
  }

  static String _getLeagueContext(String league) {
    final contexts = {
      'Premier League':
          'Most competitive league. Strong home advantage. Mid-table teams upset favorites regularly. Avg 2.8 goals/game.',
      'La Liga':
          'Technical, possession-based. Top 3 teams dominate. Home advantage crucial for big clubs. Avg 2.6 goals/game.',
      'Bundesliga':
          'High-pressing, attacking style. Most goals in top 5 leagues. Bayern dominates but competitive below. Avg 3.1 goals/game.',
      'Serie A':
          'Tactical, defensive-minded. Lower scoring. Home advantage significant. Traditional powers strong. Avg 2.5 goals/game.',
      'Ligue 1':
          'PSG dominance but competitive elsewhere. Technical play. Moderate scoring. Avg 2.7 goals/game.',
      'Champions League':
          'Elite competition. Tactics and form critical. Away goals matter. Home advantage amplified.',
      'Europa League':
          'Competitive. Squad rotation common. Home advantage significant.',
      'Championship':
          'Highly competitive, unpredictable. Home advantage strong. High-intensity matches.',
    };

    return contexts[league] ??
        'Competitive league. Form and home advantage matter.';
  }

  static String _getTeamContext(String home, String away) {
    final teamProfiles = {
      'Manchester City':
          'Possession masters (70%+), high press, clinical finishing. Fortress at home.',
      'Liverpool':
          'Gegenpressing, high intensity, Anfield atmosphere advantage.',
      'Real Madrid':
          'Champions mentality, clinical in big games, Bernabeu fortress.',
      'Barcelona':
          'Tiki-taka possession, Camp Nou dominance, creative midfield.',
      'Bayern Munich':
          'Bundesliga dominance, high-scoring, Allianz Arena power.',
      'PSG':
          'Star-studded attack, Ligue 1 dominance, Parc des Princes advantage.',
      'Arsenal':
          'Possession-based, Emirates form improving, young attacking talent.',
      'Chelsea':
          'Tactical flexibility, solid defense, Stamford Bridge fortress.',
      'Manchester United':
          'Counter-attacking, inconsistent but dangerous, Old Trafford history.',
      'Inter': 'Defensive solidity, tactical discipline, San Siro advantage.',
      'Milan': 'Balanced approach, San Siro passion.',
      'Juventus': 'Defensive masters, experienced squad.',
      'Atletico': 'Defensive specialists, set-piece threat.',
      'Dortmund': 'High-press, attacking football, Yellow Wall support.',
      'Tottenham': 'Counter-attacking pace, home advantage matters.',
    };

    String homeProfile = 'Solid home team';
    String awayProfile = 'Competitive visitors';

    for (var entry in teamProfiles.entries) {
      if (home.contains(entry.key)) homeProfile = entry.value;
      if (away.contains(entry.key)) awayProfile = entry.value;
    }

    return 'Home: $homeProfile | Away: $awayProfile';
  }

  static Map<String, dynamic>? _parseAIResponse(String content) {
    try {
      // Clean the response
      String cleaned = content.trim();

      // Remove markdown code blocks if present
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      final data = json.decode(cleaned);

      // Validate required fields
      if (data['pick'] != null &&
          data['confidence'] != null &&
          data['analysis'] != null) {
        return data;
      }

      return null;
    } catch (e) {
      print('❌ Failed to parse AI response: $e');
      return null;
    }
  }

  static double _calculateOddsFromConfidence(int confidence) {
    // More granular mapping
    if (confidence >= 90) return 1.25;
    if (confidence >= 88) return 1.30;
    if (confidence >= 86) return 1.35;
    if (confidence >= 84) return 1.40;
    if (confidence >= 82) return 1.45;
    if (confidence >= 80) return 1.50;
    if (confidence >= 78) return 1.60;
    if (confidence >= 76) return 1.70;
    if (confidence >= 74) return 1.80;
    if (confidence >= 72) return 1.90;
    if (confidence >= 70) return 2.00;
    if (confidence >= 68) return 2.10;
    if (confidence >= 66) return 2.20;
    if (confidence >= 64) return 2.35;
    if (confidence >= 62) return 2.50;
    if (confidence >= 60) return 2.70;
    return 3.00;
  }

  static Future<void> _storeAIPredictions(List<Prediction> predictions) async {
    try {
      final batch = _firestore.batch();

      for (final prediction in predictions) {
        final docRef = _firestore.collection('ai_predictions').doc(prediction.id);

        // ✅ Use consistent field names with Timestamp
        batch.set(docRef, {
          'id': prediction.id,
          'home_team': prediction.homeTeam,
          'away_team': prediction.awayTeam,
          'league': prediction.league,
          'pick': prediction.pick,
          'odds': prediction.odds,
          'confidence': prediction.confidence,
          'analysis': prediction.analysis,
          'created_at': Timestamp.fromDate(prediction.createdAt), // ✅ Use Timestamp
          'ai_generated': true,
          'stored_at': FieldValue.serverTimestamp(),
          'status': 'pending',
          'source': 'openai_gpt35',
        });
      }

      await batch.commit();
      print('💾 Stored ${predictions.length} AI predictions in Firestore');
    } catch (e) {
      print('❌ Error storing predictions: $e');
    }
  }

  // ==================== BASIC PREDICTIONS (Fallback) ====================

  static Future<List<Prediction>> _getBasicPredictions() async {
    try {
      // Check cache first
      final cached = await _getCachedBasicPredictions();
      if (cached.isNotEmpty) {
        print('✅ Using ${cached.length} cached basic predictions');
        return cached;
      }

      // Generate from matches
      final matches = await ApiService.getTodayMatches();
      final predictions =
          matches
              .where((m) => m.odds != null && m.status == 'upcoming')
              .map(_createBasicPrediction)
              .toList()
            ..sort((a, b) => b.confidence.compareTo(a.confidence));

      if (predictions.isNotEmpty) {
        await _cacheBasicPredictions(predictions);
      }

      return predictions.isNotEmpty ? predictions : _getFallbackPredictions();
    } catch (e) {
      return _getFallbackPredictions();
    }
  }

  static Prediction _createBasicPrediction(Match m) {
    final odds = m.odds!;
    String pick;
    double pickOdds;
    String analysis;

    if (odds.homeWin < odds.draw && odds.homeWin < odds.awayWin) {
      pick = '${m.homeTeam} Win';
      pickOdds = odds.homeWin;
      analysis =
          '${m.homeTeam} are favorites with strong home advantage in ${m.league}.';
    } else if (odds.awayWin < odds.draw && odds.awayWin < odds.homeWin) {
      pick = '${m.awayTeam} Win';
      pickOdds = odds.awayWin;
      analysis = '${m.awayTeam} showing strong form as favorites to win.';
    } else if (odds.over25 != null && odds.over25! < 2.0) {
      pick = 'Over 2.5 Goals';
      pickOdds = odds.over25!;
      analysis =
          'Both teams have attacking potential. Expect goals in this match.';
    } else {
      pick = 'Draw';
      pickOdds = odds.draw;
      analysis = 'Evenly matched teams suggest a tight, competitive contest.';
    }

    return Prediction(
      id: 'pred_${m.id}',
      homeTeam: m.homeTeam,
      awayTeam: m.awayTeam,
      league: m.league,
      pick: pick,
      odds: pickOdds,
      confidence: _calculateBasicConfidence(pickOdds),
      analysis: analysis,
      createdAt: DateTime.now(),
    );
  }

  static int _calculateBasicConfidence(double odds) {
    if (odds <= 1.5) return 85;
    if (odds <= 1.8) return 78;
    if (odds <= 2.0) return 72;
    if (odds <= 2.5) return 68;
    if (odds <= 3.0) return 63;
    return 58;
  }

  // ==================== CACHE ====================

  static Future<List<Prediction>> _getCachedBasicPredictions() async {
    try {
      final doc = await _firestore
          .collection('predictions_cache')
          .doc(_getDateKey())
          .get();

      if (!doc.exists) return [];

      final data = doc.data()!;
      final cached = (data['cached_at'] as Timestamp).toDate();
      if (DateTime.now().difference(cached) > _cacheExpiry) return [];

      return (data['predictions'] as List)
          .map((p) => Prediction.fromJson(p))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> _cacheBasicPredictions(
    List<Prediction> predictions,
  ) async {
    try {
      await _firestore.collection('predictions_cache').doc(_getDateKey()).set({
        'predictions': predictions.map((p) => p.toJson()).toList(),
        'cached_at': FieldValue.serverTimestamp(),
        'count': predictions.length,
      });
    } catch (e) {}
  }

  // ==================== PREDICTION TRACKING ====================

  static Future<void> updatePredictionResult({
    required String predictionId,
    required String actualResult,
    required String? finalScore,
    required bool isCorrect,
  }) async {
    try {
      await _firestore.collection('ai_predictions').doc(predictionId).update({
        'status': isCorrect ? 'correct' : 'incorrect',
        'actual_result': actualResult,
        'final_score': finalScore,
        'result_recorded_at': FieldValue.serverTimestamp(),
        'is_correct': isCorrect,
      });

      // Update statistics
      await _updateOverallStats(isCorrect);

      print('✅ Updated result for prediction $predictionId');
    } catch (e) {
      print('❌ Error updating prediction result: $e');
    }
  }

  static Future<void> _updateOverallStats(bool isCorrect) async {
    try {
      final statsRef = _firestore.collection('prediction_stats').doc('overall');

      await statsRef.set({
        'total_predictions': FieldValue.increment(1),
        'correct_predictions': FieldValue.increment(isCorrect ? 1 : 0),
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {}
  }

  static Future<Map<String, dynamic>> getPredictionStats() async {
    try {
      final doc = await _firestore
          .collection('prediction_stats')
          .doc('overall')
          .get();

      if (!doc.exists) {
        return {'total': 0, 'correct': 0, 'accuracy': 0.0};
      }

      final data = doc.data()!;
      final total = data['total_predictions'] ?? 0;
      final correct = data['correct_predictions'] ?? 0;

      return {
        'total': total,
        'correct': correct,
        'accuracy': total > 0 ? (correct / total * 100) : 0.0,
      };
    } catch (e) {
      return {'total': 0, 'correct': 0, 'accuracy': 0.0};
    }
  }

  // ==================== HELPERS ====================

  static String _formatDateTime(DateTime dt) {
    final weekday = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ][dt.weekday - 1];
    final month = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][dt.month - 1];
    return '$weekday, $month ${dt.day} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static String _getDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static List<Prediction> _getFallbackPredictions() {
    return [
      Prediction(
        id: 'pred_fallback_1',
        homeTeam: 'Manchester City',
        awayTeam: 'Liverpool',
        league: 'Premier League',
        pick: 'Over 2.5 Goals',
        odds: 1.65,
        confidence: 78,
        analysis:
            'Both teams have strong attacking records with quality forwards.',
        createdAt: DateTime.now(),
      ),
      Prediction(
        id: 'pred_fallback_2',
        homeTeam: 'Bayern Munich',
        awayTeam: 'Borussia Dortmund',
        league: 'Bundesliga',
        pick: 'Bayern Munich Win',
        odds: 1.85,
        confidence: 80,
        analysis: 'Bayern dominant at home with excellent recent form.',
        createdAt: DateTime.now(),
      ),
    ];
  }
}