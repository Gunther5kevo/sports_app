// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match.dart';
import '../models/prediction.dart';

class ApiService {
  // ==================== ALLSPORTSAPI CONFIGURATION ====================
  // Register at: https://allsportsapi.com/
  // Free plan available with livescore, fixtures, standings
  static String get _allSportsApiKey => dotenv.env['ALLSPORTS_API_KEY'] ?? '';
  static const String _allSportsBaseUrl = 'https://apiv2.allsportsapi.com/football';
  
  // Odds API (Optional - for betting odds)
  static String get _rapidApiKey => dotenv.env['RAPIDAPI_KEY'] ?? '';
  static const String _oddsHost = 'odds.p.rapidapi.com';
  static const String _oddsBaseUrl = 'https://odds.p.rapidapi.com/v4';

  // Firebase
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static bool get isConfigured => _allSportsApiKey.isNotEmpty;
  static const Duration _timeout = Duration(seconds: 15);
  static const Duration _cacheExpiry = Duration(hours: 6);

  // ==================== FETCH MATCHES WITH ODDS ====================
  
  /// Fetch today's matches with odds
  static Future<List<Match>> getTodayMatches() async {
    try {
      print('🔄 Fetching today\'s matches...');
      
      if (!isConfigured) {
        print('⚠️ AllSportsAPI key not configured');
        return _getFallbackMatches();
      }
      
      // 1. Check Firebase cache
      final cachedMatches = await _getCachedMatches();
      if (cachedMatches.isNotEmpty) {
        print('✅ Loaded ${cachedMatches.length} matches from cache');
        return cachedMatches;
      }

      // 2. Fetch matches from AllSportsAPI
      print('📡 Fetching from AllSportsAPI...');
      final matches = await _fetchMatchesFromAllSportsAPI();
      
      if (matches.isEmpty) {
        print('⚠️ No matches found, using fallback');
        return _getFallbackMatches();
      }
      
      print('✅ Fetched ${matches.length} matches');

      // 3. Fetch odds for matches (if RapidAPI key available)
      if (_rapidApiKey.isNotEmpty) {
        print('📡 Fetching odds...');
        final matchesWithOdds = await _fetchOddsForMatches(matches);
        print('✅ Updated odds for ${matchesWithOdds.length} matches');
        
        // 4. Cache to Firebase
        await _cacheMatchesToFirebase(matchesWithOdds);
        return matchesWithOdds;
      }

      // 4. Cache to Firebase
      await _cacheMatchesToFirebase(matches);
      return matches;
      
    } catch (e) {
      print('❌ Error: $e');
      return _getFallbackMatches();
    }
  }

  /// Fetch matches from AllSportsAPI
  static Future<List<Match>> _fetchMatchesFromAllSportsAPI() async {
    try {
      final today = DateTime.now();
      
      // Try multiple date ranges to find matches
      List<Match> allMatches = [];
      
      // Try today
      print('📅 Trying today...');
      var matches = await _fetchFixturesByDate(today);
      allMatches.addAll(matches);
      
      // Try tomorrow if today has no matches
      if (allMatches.isEmpty) {
        print('📅 Trying tomorrow...');
        final tomorrow = today.add(const Duration(days: 1));
        matches = await _fetchFixturesByDate(tomorrow);
        allMatches.addAll(matches);
      }
      
      // Try yesterday (for finished matches)
      if (allMatches.isEmpty) {
        print('📅 Trying yesterday...');
        final yesterday = today.subtract(const Duration(days: 1));
        matches = await _fetchFixturesByDate(yesterday);
        allMatches.addAll(matches);
      }
      
      // Try next 7 days if still empty
      if (allMatches.isEmpty) {
        print('📅 Trying next 7 days...');
        for (int i = 2; i <= 7; i++) {
          final futureDate = today.add(Duration(days: i));
          matches = await _fetchFixturesByDate(futureDate);
          allMatches.addAll(matches);
          if (allMatches.length >= 20) break; // Stop if we have enough
        }
      }

      if (allMatches.isEmpty) {
        print('ℹ️ No fixtures found, trying livescore...');
        return await _fetchLiveScoresFromAllSportsAPI();
      }

      print('✅ Found ${allMatches.length} total matches');

      // Sort by time
      allMatches.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      
      // Limit to 50 matches
      return allMatches.take(50).toList();
      
    } catch (e) {
      print('❌ AllSportsAPI error: $e');
      return [];
    }
  }

  /// Fetch fixtures for a specific date
  static Future<List<Match>> _fetchFixturesByDate(DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final url = Uri.parse(
        '$_allSportsBaseUrl/?met=Fixtures&APIkey=$_allSportsApiKey&from=$dateStr&to=$dateStr'
      );

      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode != 200) {
        return [];
      }

      final data = json.decode(response.body);
      
      if (data['success'] != 1) {
        return [];
      }

      final fixtures = data['result'] as List? ?? [];

      if (fixtures.isEmpty) {
        return [];
      }

      // Parse matches
      final matches = fixtures
          .map((fixture) => _parseAllSportsAPIMatch(fixture))
          .where((match) => match != null)
          .cast<Match>()
          .toList();
      
      return matches;
      
    } catch (e) {
      return [];
    }
  }

  /// Fetch live scores as backup
  static Future<List<Match>> _fetchLiveScoresFromAllSportsAPI() async {
    try {
      final url = Uri.parse(
        '$_allSportsBaseUrl/?met=Livescore&APIkey=$_allSportsApiKey'
      );

      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode != 200) {
        return [];
      }

      final data = json.decode(response.body);
      
      if (data['success'] != 1) {
        return [];
      }

      final fixtures = data['result'] as List? ?? [];
      
      final matches = fixtures
          .map((fixture) => _parseAllSportsAPIMatch(fixture))
          .where((match) => match != null)
          .cast<Match>()
          .toList();
      
      matches.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      
      return matches.take(50).toList();
      
    } catch (e) {
      print('❌ Livescore error: $e');
      return [];
    }
  }

  /// Parse AllSportsAPI match data
  static Match? _parseAllSportsAPIMatch(dynamic fixture) {
    try {
      final homeTeam = fixture['event_home_team'] ?? 'Home Team';
      final awayTeam = fixture['event_away_team'] ?? 'Away Team';
      final league = fixture['league_name'] ?? 'Unknown League';
      
      // Parse date/time
      final dateStr = fixture['event_date'] ?? '';
      final timeStr = fixture['event_time'] ?? '';
      DateTime dateTime = DateTime.now();
      
      try {
        if (dateStr.isNotEmpty && timeStr.isNotEmpty) {
          dateTime = DateTime.parse('$dateStr $timeStr');
        }
      } catch (e) {
        dateTime = DateTime.now().add(const Duration(hours: 2));
      }
      
      // Parse status
      String status = 'upcoming';
      final statusValue = fixture['event_status']?.toString() ?? '';
      final eventLive = fixture['event_live']?.toString() ?? '0';
      
      if (statusValue == 'Finished' || fixture['event_final_result']?.toString().isNotEmpty == true) {
        status = 'finished';
      } else if (eventLive == '1' || statusValue.contains('Half') || statusValue.contains('Live')) {
        status = 'live';
      } else {
        status = 'upcoming';
      }
      
      // Parse scores
      int? homeScore;
      int? awayScore;
      
      final finalResult = fixture['event_final_result']?.toString() ?? '';
      if (finalResult.isNotEmpty && finalResult.contains(' - ')) {
        final scores = finalResult.split(' - ');
        homeScore = int.tryParse(scores[0].trim());
        awayScore = int.tryParse(scores[1].trim());
      }
      
      return Match(
        id: fixture['event_key']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        league: league,
        dateTime: dateTime,
        homeTeamLogo: fixture['home_team_logo'],
        awayTeamLogo: fixture['away_team_logo'],
        odds: _getDefaultOdds(),
        status: status,
        homeScore: homeScore,
        awayScore: awayScore,
      );
    } catch (e) {
      print('❌ Parse error: $e');
      return null;
    }
  }

  /// Fetch odds from Odds API
  static Future<List<Match>> _fetchOddsForMatches(List<Match> matches) async {
    try {
      if (matches.isEmpty || _rapidApiKey.isEmpty) return matches;

      // Try multiple sports
      final List<String> sports = [
        'soccer_epl',
        'soccer_spain_la_liga',
        'soccer_germany_bundesliga',
        'soccer_italy_serie_a',
        'soccer_france_ligue_one',
      ];

      Map<String, dynamic> allOddsData = {};

      for (var sport in sports) {
        try {
          final url = Uri.parse('$_oddsBaseUrl/sports/$sport/odds?regions=uk&markets=h2h');
          
          final response = await http.get(url, headers: {
            'X-RapidAPI-Key': _rapidApiKey,
            'X-RapidAPI-Host': _oddsHost,
          }).timeout(_timeout);

          if (response.statusCode == 200) {
            final oddsData = json.decode(response.body) as List? ?? [];
            for (var odds in oddsData) {
              final key = '${odds['home_team']}_${odds['away_team']}'.toLowerCase();
              allOddsData[key] = odds;
            }
          }
          
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          print('Error fetching odds for $sport: $e');
          continue;
        }
      }

      if (allOddsData.isEmpty) {
        print('ℹ️ No odds data');
        return matches;
      }

      int oddsMatched = 0;
      List<Match> updatedMatches = [];

      for (var match in matches) {
        dynamic oddsMatch;
        
        // Try to find matching odds
        for (var key in allOddsData.keys) {
          if (_matchTeamNames(
            allOddsData[key]['home_team']?.toString() ?? '',
            allOddsData[key]['away_team']?.toString() ?? '',
            match.homeTeam,
            match.awayTeam,
          )) {
            oddsMatch = allOddsData[key];
            break;
          }
        }

        if (oddsMatch != null) {
          updatedMatches.add(Match(
            id: match.id,
            homeTeam: match.homeTeam,
            awayTeam: match.awayTeam,
            league: match.league,
            dateTime: match.dateTime,
            homeTeamLogo: match.homeTeamLogo,
            awayTeamLogo: match.awayTeamLogo,
            odds: _parseOddsData(oddsMatch),
            status: match.status,
            homeScore: match.homeScore,
            awayScore: match.awayScore,
          ));
          oddsMatched++;
        } else {
          updatedMatches.add(match);
        }
      }

      print('✅ Matched odds for $oddsMatched matches');
      return updatedMatches;
      
    } catch (e) {
      print('❌ Odds error: $e');
      return matches;
    }
  }

  /// Parse odds data
  static MatchOdds _parseOddsData(dynamic odds) {
    try {
      final bookmakers = odds['bookmakers'] as List? ?? [];
      if (bookmakers.isEmpty) return _getDefaultOdds();
      
      final bookmaker = bookmakers.first;
      final markets = bookmaker['markets'] as List? ?? [];
      if (markets.isEmpty) return _getDefaultOdds();
      
      final market = markets.first;
      final outcomes = market['outcomes'] as List? ?? [];
      
      double homeOdds = 2.10;
      double drawOdds = 3.30;
      double awayOdds = 3.00;
      
      for (var outcome in outcomes) {
        final name = outcome['name'];
        final price = double.tryParse(outcome['price'].toString()) ?? 2.0;
        
        if (name.toString().toLowerCase().contains('home') || name == outcomes.first['name']) {
          homeOdds = price;
        } else if (name.toString().toLowerCase().contains('draw')) {
          drawOdds = price;
        } else if (name.toString().toLowerCase().contains('away')) {
          awayOdds = price;
        }
      }
      
      return MatchOdds(
        homeWin: homeOdds,
        draw: drawOdds,
        awayWin: awayOdds,
        over25: 1.80,
        under25: 2.00,
      );
    } catch (e) {
      return _getDefaultOdds();
    }
  }

  /// Fuzzy match team names
  static bool _matchTeamNames(String oddsHome, String oddsAway, String matchHome, String matchAway) {
    final normOddsHome = _normalizeTeamName(oddsHome);
    final normOddsAway = _normalizeTeamName(oddsAway);
    final normMatchHome = _normalizeTeamName(matchHome);
    final normMatchAway = _normalizeTeamName(matchAway);
    
    return (normOddsHome == normMatchHome && normOddsAway == normMatchAway) ||
           (normOddsHome.contains(normMatchHome) && normOddsAway.contains(normMatchAway)) ||
           (normMatchHome.contains(normOddsHome) && normMatchAway.contains(normOddsAway));
  }

  /// Normalize team name
  static String _normalizeTeamName(String name) {
    return name.toLowerCase()
        .replaceAll('fc', '')
        .replaceAll('afc', '')
        .replaceAll('united', 'utd')
        .replaceAll(' ', '')
        .trim();
  }

  // ==================== FIREBASE CACHE ====================

  static Future<List<Match>> _getCachedMatches() async {
    try {
      final today = _getTodayDateString();
      final doc = await _firestore.collection('matches_cache').doc(today).get();

      if (!doc.exists) return [];

      final data = doc.data()!;
      final cachedAt = (data['cached_at'] as Timestamp).toDate();
      
      if (DateTime.now().difference(cachedAt) > _cacheExpiry) {
        return [];
      }

      final matchesList = data['matches'] as List;
      return matchesList.map((m) => Match.fromJson(m)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> _cacheMatchesToFirebase(List<Match> matches) async {
    try {
      final today = _getTodayDateString();
      await _firestore.collection('matches_cache').doc(today).set({
        'matches': matches.map((m) => m.toJson()).toList(),
        'cached_at': FieldValue.serverTimestamp(),
        'count': matches.length,
      });
    } catch (e) {
      print('Cache error: $e');
    }
  }

  // ==================== PREDICTIONS ====================

  static Future<List<Prediction>> getPredictions() async {
    try {
      final cachedPredictions = await _getCachedPredictions();
      if (cachedPredictions.isNotEmpty) {
        return cachedPredictions;
      }

      final matches = await getTodayMatches();
      final predictions = matches
          .where((m) => m.odds != null && m.status == 'upcoming')
          .map(_generatePredictionFromMatch)
          .toList()
        ..sort((a, b) => b.confidence.compareTo(a.confidence));

      if (predictions.isNotEmpty) {
        await _cachePredictionsToFirebase(predictions);
      }

      return predictions.isNotEmpty ? predictions : _getFallbackPredictions();
      
    } catch (e) {
      return _getFallbackPredictions();
    }
  }

  static Future<List<Prediction>> _getCachedPredictions() async {
    try {
      final today = _getTodayDateString();
      final doc = await _firestore.collection('predictions_cache').doc(today).get();

      if (!doc.exists) return [];

      final data = doc.data()!;
      final cachedAt = (data['cached_at'] as Timestamp).toDate();
      
      if (DateTime.now().difference(cachedAt) > _cacheExpiry) return [];

      final predictionsList = data['predictions'] as List;
      return predictionsList.map((p) => Prediction.fromJson(p)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> _cachePredictionsToFirebase(List<Prediction> predictions) async {
    try {
      final today = _getTodayDateString();
      await _firestore.collection('predictions_cache').doc(today).set({
        'predictions': predictions.map((p) => p.toJson()).toList(),
        'cached_at': FieldValue.serverTimestamp(),
        'count': predictions.length,
      });
    } catch (e) {
      print('Cache error: $e');
    }
  }

  static Prediction _generatePredictionFromMatch(Match match) {
    final odds = match.odds!;
    final analysis = _analyzeMatch(match, odds);
    
    return Prediction(
      id: 'pred_${match.id}',
      homeTeam: match.homeTeam,
      awayTeam: match.awayTeam,
      league: match.league,
      pick: analysis['pick'],
      odds: analysis['odds'],
      confidence: analysis['confidence'],
      analysis: analysis['text'],
      createdAt: DateTime.now(),
    );
  }

  static Map<String, dynamic> _analyzeMatch(Match match, MatchOdds odds) {
    final homeOdd = odds.homeWin;
    final drawOdd = odds.draw;
    final awayOdd = odds.awayWin;
    
    if (homeOdd < drawOdd && homeOdd < awayOdd) {
      return {
        'pick': '${match.homeTeam} Win',
        'odds': homeOdd,
        'confidence': _calculateConfidence(homeOdd),
        'text': '${match.homeTeam} are favorites with strong home advantage.',
      };
    } else if (awayOdd < drawOdd && awayOdd < homeOdd) {
      return {
        'pick': '${match.awayTeam} Win',
        'odds': awayOdd,
        'confidence': _calculateConfidence(awayOdd),
        'text': '${match.awayTeam} show strong form as favorites.',
      };
    } else if (odds.over25 != null && odds.over25! < 2.0) {
      return {
        'pick': 'Over 2.5 Goals',
        'odds': odds.over25!,
        'confidence': _calculateConfidence(odds.over25!),
        'text': 'Both teams have attacking potential for a high-scoring match.',
      };
    }
    
    return {
      'pick': 'Draw',
      'odds': drawOdd,
      'confidence': _calculateConfidence(drawOdd),
      'text': 'Evenly matched teams suggest a tight contest.',
    };
  }

  static int _calculateConfidence(double odds) {
    if (odds <= 1.5) return 85;
    if (odds <= 1.8) return 78;
    if (odds <= 2.0) return 72;
    if (odds <= 2.5) return 68;
    if (odds <= 3.0) return 63;
    return 58;
  }

  // ==================== USER STATISTICS ====================

  static Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final doc = await _firestore.collection('user_stats').doc(userId).get();
      if (!doc.exists) return _getDefaultUserStats();
      return doc.data()!;
    } catch (e) {
      return _getDefaultUserStats();
    }
  }

  static Future<void> updateUserStats(String userId, Map<String, dynamic> stats) async {
    try {
      await _firestore.collection('user_stats').doc(userId).set(
        {...stats, 'lastUpdated': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Stats update error: $e');
    }
  }

  static Future<void> recordPredictionResult({
    required String userId,
    required bool isCorrect,
    required double odds,
    required double stake,
  }) async {
    try {
      final stats = await getUserStats(userId);
      
      final totalPredictions = (stats['totalPredictions'] ?? 0) + 1;
      final correctPredictions = (stats['correctPredictions'] ?? 0) + (isCorrect ? 1 : 0);
      final winRate = (correctPredictions / totalPredictions) * 100;
      
      final profit = isCorrect ? (stake * odds - stake) : -stake;
      final totalProfit = (stats['totalProfit'] ?? 0.0) + profit;
      
      final currentStreak = isCorrect ? (stats['currentStreak'] ?? 0) + 1 : 0;
      final bestStreak = currentStreak > (stats['bestStreak'] ?? 0) ? currentStreak : (stats['bestStreak'] ?? 0);
      
      await updateUserStats(userId, {
        'totalPredictions': totalPredictions,
        'correctPredictions': correctPredictions,
        'winRate': winRate,
        'totalProfit': totalProfit,
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
      });
    } catch (e) {
      print('Record error: $e');
    }
  }

  // ==================== HELPERS ====================

  static String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static MatchOdds _getDefaultOdds() {
    return MatchOdds(
      homeWin: 2.10,
      draw: 3.30,
      awayWin: 3.00,
      over25: 1.80,
      under25: 2.00,
    );
  }

  static Map<String, dynamic> _getDefaultUserStats() {
    return {
      'totalPredictions': 0,
      'correctPredictions': 0,
      'winRate': 0.0,
      'totalProfit': 0.0,
      'currentStreak': 0,
      'bestStreak': 0,
    };
  }

  static List<Match> _getFallbackMatches() {
    final now = DateTime.now();
    
    // Generate realistic upcoming matches
    return [
      // Premier League
      Match(
        id: '1',
        homeTeam: 'Manchester City',
        awayTeam: 'Liverpool',
        league: 'Premier League',
        dateTime: now.add(const Duration(hours: 3)),
        odds: MatchOdds(homeWin: 2.10, draw: 3.40, awayWin: 3.20, over25: 1.65, under25: 2.10),
        status: 'upcoming',
      ),
      Match(
        id: '2',
        homeTeam: 'Arsenal',
        awayTeam: 'Chelsea',
        league: 'Premier League',
        dateTime: now.add(const Duration(hours: 4)),
        odds: MatchOdds(homeWin: 2.30, draw: 3.20, awayWin: 2.90, over25: 1.75, under25: 2.05),
        status: 'upcoming',
      ),
      Match(
        id: '3',
        homeTeam: 'Manchester United',
        awayTeam: 'Tottenham',
        league: 'Premier League',
        dateTime: now.add(const Duration(hours: 5)),
        odds: MatchOdds(homeWin: 2.40, draw: 3.30, awayWin: 2.80, over25: 1.70, under25: 2.15),
        status: 'upcoming',
      ),
      
      // La Liga
      Match(
        id: '4',
        homeTeam: 'Real Madrid',
        awayTeam: 'Barcelona',
        league: 'La Liga',
        dateTime: now.add(const Duration(hours: 6)),
        odds: MatchOdds(homeWin: 2.30, draw: 3.20, awayWin: 2.90, over25: 1.75, under25: 2.05),
        status: 'upcoming',
      ),
      Match(
        id: '5',
        homeTeam: 'Atletico Madrid',
        awayTeam: 'Sevilla',
        league: 'La Liga',
        dateTime: now.add(const Duration(hours: 7)),
        odds: MatchOdds(homeWin: 1.95, draw: 3.40, awayWin: 3.50, over25: 1.80, under25: 2.00),
        status: 'upcoming',
      ),
      
      // Bundesliga
      Match(
        id: '6',
        homeTeam: 'Bayern Munich',
        awayTeam: 'Borussia Dortmund',
        league: 'Bundesliga',
        dateTime: now.add(const Duration(hours: 8)),
        odds: MatchOdds(homeWin: 1.85, draw: 3.60, awayWin: 3.80, over25: 1.55, under25: 2.20),
        status: 'upcoming',
      ),
      Match(
        id: '7',
        homeTeam: 'RB Leipzig',
        awayTeam: 'Bayer Leverkusen',
        league: 'Bundesliga',
        dateTime: now.add(const Duration(hours: 9)),
        odds: MatchOdds(homeWin: 2.20, draw: 3.30, awayWin: 3.00, over25: 1.70, under25: 2.10),
        status: 'upcoming',
      ),
      
      // Serie A
      Match(
        id: '8',
        homeTeam: 'Inter Milan',
        awayTeam: 'AC Milan',
        league: 'Serie A',
        dateTime: now.add(const Duration(hours: 10)),
        odds: MatchOdds(homeWin: 2.05, draw: 3.30, awayWin: 3.20, over25: 1.75, under25: 2.05),
        status: 'upcoming',
      ),
      Match(
        id: '9',
        homeTeam: 'Juventus',
        awayTeam: 'Napoli',
        league: 'Serie A',
        dateTime: now.add(const Duration(hours: 11)),
        odds: MatchOdds(homeWin: 2.15, draw: 3.25, awayWin: 3.10, over25: 1.80, under25: 2.00),
        status: 'upcoming',
      ),
      
      // Ligue 1
      Match(
        id: '10',
        homeTeam: 'Paris Saint-Germain',
        awayTeam: 'Marseille',
        league: 'Ligue 1',
        dateTime: now.add(const Duration(hours: 12)),
        odds: MatchOdds(homeWin: 1.60, draw: 3.80, awayWin: 4.50, over25: 1.60, under25: 2.25),
        status: 'upcoming',
      ),
      Match(
        id: '11',
        homeTeam: 'Lyon',
        awayTeam: 'Monaco',
        league: 'Ligue 1',
        dateTime: now.add(const Duration(hours: 13)),
        odds: MatchOdds(homeWin: 2.40, draw: 3.20, awayWin: 2.85, over25: 1.75, under25: 2.05),
        status: 'upcoming',
      ),
      
      // Champions League
      Match(
        id: '12',
        homeTeam: 'Manchester City',
        awayTeam: 'Real Madrid',
        league: 'Champions League',
        dateTime: now.add(const Duration(hours: 14)),
        odds: MatchOdds(homeWin: 2.00, draw: 3.40, awayWin: 3.30, over25: 1.70, under25: 2.10),
        status: 'upcoming',
      ),
      
      // Today's Live Match (Example)
      Match(
        id: '13',
        homeTeam: 'West Ham',
        awayTeam: 'Newcastle',
        league: 'Premier League',
        dateTime: now.subtract(const Duration(minutes: 30)),
        odds: MatchOdds(homeWin: 2.50, draw: 3.20, awayWin: 2.70, over25: 1.75, under25: 2.05),
        status: 'live',
        homeScore: 1,
        awayScore: 1,
      ),
      
      // Yesterday's Finished Match
      Match(
        id: '14',
        homeTeam: 'Aston Villa',
        awayTeam: 'Brighton',
        league: 'Premier League',
        dateTime: now.subtract(const Duration(hours: 20)),
        odds: MatchOdds(homeWin: 2.30, draw: 3.20, awayWin: 2.95, over25: 1.75, under25: 2.05),
        status: 'finished',
        homeScore: 2,
        awayScore: 1,
      ),
    ];
  }

  static List<Prediction> _getFallbackPredictions() {
    return [
      Prediction(
        id: 'pred_1',
        homeTeam: 'Manchester City',
        awayTeam: 'Liverpool',
        league: 'Premier League',
        pick: 'Over 2.5 Goals',
        odds: 1.65,
        confidence: 78,
        analysis: 'Both teams have strong attacking records and score frequently.',
        createdAt: DateTime.now(),
      ),
      Prediction(
        id: 'pred_2',
        homeTeam: 'Bayern Munich',
        awayTeam: 'Borussia Dortmund',
        league: 'Bundesliga',
        pick: 'Bayern Munich Win',
        odds: 1.85,
        confidence: 80,
        analysis: 'Bayern dominant at home with excellent form and strong squad.',
        createdAt: DateTime.now(),
      ),
      Prediction(
        id: 'pred_3',
        homeTeam: 'Real Madrid',
        awayTeam: 'Barcelona',
        league: 'La Liga',
        pick: 'Over 2.5 Goals',
        odds: 1.75,
        confidence: 75,
        analysis: 'El Clasico always delivers goals with both teams attacking.',
        createdAt: DateTime.now(),
      ),
      Prediction(
        id: 'pred_4',
        homeTeam: 'Paris Saint-Germain',
        awayTeam: 'Marseille',
        league: 'Ligue 1',
        pick: 'PSG Win',
        odds: 1.60,
        confidence: 85,
        analysis: 'PSG heavily favored with superior squad quality and home advantage.',
        createdAt: DateTime.now(),
      ),
      Prediction(
        id: 'pred_5',
        homeTeam: 'Arsenal',
        awayTeam: 'Chelsea',
        league: 'Premier League',
        pick: 'Arsenal Win',
        odds: 2.30,
        confidence: 72,
        analysis: 'Arsenal in good form at home, Chelsea struggling away.',
        createdAt: DateTime.now(),
      ),
      Prediction(
        id: 'pred_6',
        homeTeam: 'Inter Milan',
        awayTeam: 'AC Milan',
        league: 'Serie A',
        pick: 'Draw',
        odds: 3.30,
        confidence: 65,
        analysis: 'Derby della Madonnina is historically tight and competitive.',
        createdAt: DateTime.now(),
      ),
    ];
  }
}