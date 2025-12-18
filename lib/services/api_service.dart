// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match.dart';
import '../models/prediction.dart';

class ApiService {
  // API Credentials
  static String get _sportmonksKey => dotenv.env['SPORTMONKS_API_KEY'] ?? '';
  static String get _sportmonksUrl => dotenv.env['SPORTMONKS_BASE_URL'] ?? 'https://api.sportmonks.com/v3/football';
  
  static String get _sportsDataKey => dotenv.env['SPORTSDATA_API_KEY'] ?? '';
  static String get _sportsDataUrl => dotenv.env['SPORTSDATA_BASE_URL'] ?? 'https://api.sportsdata.io/v3/soccer';
  
  // Firebase Firestore
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static bool get isSportmonksConfigured => _sportmonksKey.isNotEmpty;
  static bool get isSportsDataConfigured => _sportsDataKey.isNotEmpty;
  
  static const Duration _timeout = Duration(seconds: 15);
  static const Duration _cacheExpiry = Duration(hours: 6);

  /// Test API connectivity
  static Future<void> testApiConnections() async {
    print('\n═══════════════════════════════════════');
    print('🧪 TESTING API CONNECTIONS');
    print('═══════════════════════════════════════\n');
    
    if (isSportsDataConfigured) {
      await _testSportsDataConnection();
    } else {
      print('⚠️ SportsData.io: Not configured');
    }
    
    print('');
    
    if (isSportmonksConfigured) {
      await _testSportmonksConnection();
    } else {
      print('⚠️ Sportmonks: Not configured');
    }
    
    print('\n═══════════════════════════════════════\n');
  }

  static Future<void> _testSportsDataConnection() async {
    try {
      print('🔍 Testing SportsData.io...');
      print('   Base URL: $_sportsDataUrl');
      print('   API Key: ${_sportsDataKey.substring(0, 8)}...');
      
      // Test competitions endpoint
      final url = Uri.parse('$_sportsDataUrl/scores/json/Competitions?key=$_sportsDataKey');
      
      final response = await http.get(url).timeout(_timeout);
      
      print('   Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final comps = json.decode(response.body) as List;
        print('   ✅ Connected! Available competitions: ${comps.length}');
        print('   Sample competitions:');
        comps.take(5).forEach((comp) {
          print('      - ${comp['Name']} (${comp['Key']})');
        });
      } else if (response.statusCode == 401) {
        print('   ❌ Authentication failed - Invalid API key');
      } else {
        print('   ⚠️ Unexpected status: ${response.body.substring(0, 100)}');
      }
    } catch (e) {
      print('   ❌ Connection failed: $e');
    }
  }

  static Future<void> _testSportmonksConnection() async {
    try {
      print('🔍 Testing Sportmonks...');
      print('   Base URL: $_sportmonksUrl');
      print('   API Key: ${_sportmonksKey.substring(0, 8)}...');
      
      final url = Uri.parse('$_sportmonksUrl/leagues?api_token=$_sportmonksKey');
      
      final response = await http.get(url).timeout(_timeout);
      
      print('   Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('   ✅ Connected!');
      } else if (response.statusCode == 401) {
        print('   ❌ Authentication failed - Invalid API key');
      } else {
        print('   ⚠️ Unexpected status: ${response.body.substring(0, 100)}');
      }
    } catch (e) {
      print('   ❌ Connection failed: $e');
    }
  }

  /// Fetch today's matches from multiple sources with Firebase caching
  static Future<List<Match>> getTodayMatches() async {
    try {
      print('\n🔄 Fetching today\'s matches...\n');
      
      // Try to get from Firebase cache first
      final cachedMatches = await _getCachedMatches();
      if (cachedMatches.isNotEmpty) {
        print('✅ Loaded ${cachedMatches.length} matches from Firebase cache');
        return cachedMatches;
      }

      // Fetch from APIs
      List<Match> matches = [];
      
      // Try SportsData.io first (better free tier)
      if (isSportsDataConfigured) {
        print('📡 Attempting SportsData.io...');
        matches = await _fetchFromSportsData();
        if (matches.isNotEmpty) {
          print('✅ Successfully fetched ${matches.length} matches from SportsData.io');
          await _cacheMatchesToFirebase(matches);
          return matches;
        } else {
          print('⚠️ No matches from SportsData.io');
        }
      }
      
      // Fallback to Sportmonks
      if (isSportmonksConfigured) {
        print('📡 Attempting Sportmonks...');
        matches = await _fetchFromSportmonks();
        if (matches.isNotEmpty) {
          print('✅ Successfully fetched ${matches.length} matches from Sportmonks');
          await _cacheMatchesToFirebase(matches);
          return matches;
        } else {
          print('⚠️ No matches from Sportmonks');
        }
      }
      
      // If both fail, return fallback data
      print('⚠️ All APIs unavailable. Using fallback data.');
      return _getFallbackMatches();
      
    } catch (e) {
      print('❌ Error in getTodayMatches: $e');
      print('Stack trace: ${StackTrace.current}');
      return _getFallbackMatches();
    }
  }

  /// Fetch from SportsData.io with improved error handling
  static Future<List<Match>> _fetchFromSportsData() async {
    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      print('📅 Date: $dateStr');
      
      // SportsData.io competition codes - verify these with your subscription
      final competitions = {
        'EPL': 'Premier League',
        'LIGA': 'La Liga', 
        'BUNDESLIGA': 'Bundesliga',
        'SERIEA': 'Serie A',
        'LIGUE1': 'Ligue 1',
      };
      
      List<Match> allMatches = [];
      int successCount = 0;
      int errorCount = 0;
      
      for (var entry in competitions.entries) {
        try {
          final compCode = entry.key;
          final compName = entry.value;
          
          // Primary endpoint format
          final url = '$_sportsDataUrl/scores/json/GamesByDate/$dateStr?key=$_sportsDataKey';
          
          print('   🔗 Fetching $compCode...');
          
          final response = await http.get(Uri.parse(url)).timeout(_timeout);
          
          if (response.statusCode == 200) {
            final responseBody = response.body;
            
            if (responseBody.isEmpty || responseBody == '[]' || responseBody == 'null') {
              print('      ℹ️ No games for $compCode');
              successCount++;
              continue;
            }
            
            try {
              final games = json.decode(responseBody);
              
              if (games is List) {
                if (games.isEmpty) {
                  print('      ℹ️ Empty list for $compCode');
                  successCount++;
                  continue;
                }
                
                // Filter games for the specific competition
                final compGames = games.where((g) => 
                  g['Competition'] == compCode || 
                  g['League'] == compCode ||
                  g['CompetitionId']?.toString() == compCode
                ).toList();
                
                if (compGames.isEmpty) {
                  // If no filter match, take all games and assign competition
                  final matches = games.map((game) => _parseSportsDataGame(game, compName)).toList();
                  allMatches.addAll(matches);
                  print('      ✅ Added ${matches.length} matches from $compCode');
                } else {
                  final matches = compGames.map((game) => _parseSportsDataGame(game, compName)).toList();
                  allMatches.addAll(matches);
                  print('      ✅ Added ${matches.length} matches from $compCode');
                }
                successCount++;
              } else {
                print('      ⚠️ Unexpected response format for $compCode');
                errorCount++;
              }
            } catch (parseError) {
              print('      ❌ Parse error for $compCode: $parseError');
              print('      Response preview: ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}');
              errorCount++;
            }
          } else if (response.statusCode == 401) {
            print('      🔐 Authentication failed - check API key');
            errorCount++;
            break; // No point continuing with other competitions
          } else if (response.statusCode == 404) {
            print('      ❌ Endpoint not found for $compCode');
            errorCount++;
          } else if (response.statusCode == 429) {
            print('      ⏰ Rate limit exceeded');
            errorCount++;
            break;
          } else {
            print('      ⚠️ HTTP ${response.statusCode}: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}');
            errorCount++;
          }
          
          // Small delay to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 300));
          
        } catch (e) {
          print('      ❌ Error: $e');
          errorCount++;
        }
      }
      
      print('   📊 Summary: $successCount successful, $errorCount errors');
      
      if (allMatches.isNotEmpty) {
        // Remove duplicates and sort by date
        final uniqueMatches = _removeDuplicateMatches(allMatches);
        uniqueMatches.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        return uniqueMatches;
      }
      
      return [];
    } catch (e) {
      print('❌ SportsData.io fatal error: $e');
      return [];
    }
  }

  /// Remove duplicate matches based on teams and date
  static List<Match> _removeDuplicateMatches(List<Match> matches) {
    final seen = <String>{};
    final unique = <Match>[];
    
    for (var match in matches) {
      final key = '${match.homeTeam}_${match.awayTeam}_${match.dateTime.day}';
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(match);
      }
    }
    
    return unique;
  }

  /// Parse SportsData.io game response
  static Match _parseSportsDataGame(dynamic game, String competition) {
    try {
      // Parse date/time - try multiple field names
      DateTime dateTime = DateTime.now();
      
      if (game['DateTime'] != null) {
        dateTime = DateTime.parse(game['DateTime']);
      } else if (game['Day'] != null) {
        final day = game['Day'].toString();
        final time = game['Time']?.toString() ?? '00:00:00';
        dateTime = DateTime.parse('${day}T$time');
      } else if (game['Date'] != null) {
        dateTime = DateTime.parse(game['Date']);
      }
      
      // Parse status
      final statusRaw = game['Status'] ?? game['GameStatus'] ?? game['MatchStatus'] ?? '';
      final status = _parseSportsDataStatus(statusRaw.toString());
      
      // Parse scores
      int? homeScore;
      int? awayScore;
      
      if (game['HomeTeamScore'] != null) {
        homeScore = int.tryParse(game['HomeTeamScore'].toString());
      } else if (game['HomeScore'] != null) {
        homeScore = int.tryParse(game['HomeScore'].toString());
      }
      
      if (game['AwayTeamScore'] != null) {
        awayScore = int.tryParse(game['AwayTeamScore'].toString());
      } else if (game['AwayScore'] != null) {
        awayScore = int.tryParse(game['AwayScore'].toString());
      }
      
      // Parse team names - try multiple field names
      final homeTeam = game['HomeTeamName'] ?? 
                       game['HomeTeam'] ?? 
                       game['Home'] ?? 
                       game['HomeTeamCountry'] ??
                       'Home Team';
                       
      final awayTeam = game['AwayTeamName'] ?? 
                       game['AwayTeam'] ?? 
                       game['Away'] ?? 
                       game['AwayTeamCountry'] ??
                       'Away Team';
      
      // Get match ID
      final matchId = game['GameId']?.toString() ?? 
                      game['Id']?.toString() ?? 
                      game['MatchId']?.toString() ??
                      DateTime.now().millisecondsSinceEpoch.toString();
      
      return Match(
        id: matchId,
        homeTeam: homeTeam.toString(),
        awayTeam: awayTeam.toString(),
        league: competition,
        dateTime: dateTime,
        homeTeamLogo: game['HomeTeamLogo'],
        awayTeamLogo: game['AwayTeamLogo'],
        odds: _generateEstimatedOdds(game),
        status: status,
        homeScore: homeScore,
        awayScore: awayScore,
      );
    } catch (e) {
      print('❌ Error parsing SportsData game: $e');
      return _getEmptyMatch();
    }
  }

  /// Parse SportsData status to our format
  static String _parseSportsDataStatus(String status) {
    final lowerStatus = status.toLowerCase();
    
    if (lowerStatus.contains('inprogress') || 
        lowerStatus.contains('in progress') ||
        lowerStatus.contains('halftime') ||
        lowerStatus.contains('live') ||
        lowerStatus.contains('playing')) {
      return 'live';
    } else if (lowerStatus.contains('final') || 
               lowerStatus.contains('complete') ||
               lowerStatus.contains('finished') ||
               lowerStatus.contains('fulltime') ||
               lowerStatus.contains('ft')) {
      return 'finished';
    } else if (lowerStatus.contains('scheduled') ||
               lowerStatus.contains('not started') ||
               lowerStatus.contains('upcoming')) {
      return 'upcoming';
    }
    
    // Default to upcoming for unknown statuses
    return 'upcoming';
  }

  /// Generate estimated odds based on team data
  static MatchOdds _generateEstimatedOdds(dynamic game) {
    // Try to get actual odds if available
    if (game['HomeTeamOdds'] != null && game['AwayTeamOdds'] != null) {
      final homeOdds = double.tryParse(game['HomeTeamOdds'].toString()) ?? 2.20;
      final drawOdds = double.tryParse(game['DrawOdds']?.toString() ?? '3.30') ?? 3.30;
      final awayOdds = double.tryParse(game['AwayTeamOdds'].toString()) ?? 3.00;
      
      return MatchOdds(
        homeWin: homeOdds,
        draw: drawOdds,
        awayWin: awayOdds,
        over25: 1.80,
        under25: 2.00,
      );
    }
    
    // Generate estimated odds based on available data
    return MatchOdds(
      homeWin: 2.20,
      draw: 3.30,
      awayWin: 3.00,
      over25: 1.80,
      under25: 2.00,
    );
  }

  /// Fetch from Sportmonks (fallback)
  static Future<List<Match>> _fetchFromSportmonks() async {
    try {
      final today = _getTodayDateString();
      final url = Uri.parse(
        '$_sportmonksUrl/fixtures/date/$today?api_token=$_sportmonksKey&include=participants;league;odds'
      );
      
      print('📅 Date: $today');
      
      final response = await http.get(url).timeout(_timeout);
      
      print('   Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fixtures = data['data'] as List? ?? [];
        
        if (fixtures.isEmpty) {
          print('   ℹ️ No fixtures for today');
          return [];
        }
        
        final matches = fixtures.map((f) => _parseSportmonksFixture(f)).toList();
        return matches;
      } else if (response.statusCode == 401) {
        print('   🔐 Authentication failed - check API key');
      } else {
        print('   ⚠️ HTTP ${response.statusCode}');
      }
      
      return [];
    } catch (e) {
      print('❌ Sportmonks error: $e');
      return [];
    }
  }

  /// Parse Sportmonks fixture
  static Match _parseSportmonksFixture(dynamic fixture) {
    try {
      final participants = fixture['participants'] as List? ?? [];
      final homeTeam = participants.firstWhere(
        (p) => p['meta']?['location'] == 'home',
        orElse: () => {'name': 'Home Team', 'image_path': null},
      );
      final awayTeam = participants.firstWhere(
        (p) => p['meta']?['location'] == 'away',
        orElse: () => {'name': 'Away Team', 'image_path': null},
      );

      final league = fixture['league'] ?? {};
      final startingAt = fixture['starting_at'] ?? DateTime.now().toIso8601String();
      final state = fixture['state']?['state'] ?? 'NS';

      return Match(
        id: fixture['id'].toString(),
        homeTeam: homeTeam['name'] ?? 'Home Team',
        awayTeam: awayTeam['name'] ?? 'Away Team',
        league: league['name'] ?? 'Unknown League',
        dateTime: DateTime.parse(startingAt),
        homeTeamLogo: homeTeam['image_path'],
        awayTeamLogo: awayTeam['image_path'],
        odds: _parseOddsFromFixture(fixture),
        status: _parseMatchStatus(state),
      );
    } catch (e) {
      print('Error parsing Sportmonks fixture: $e');
      return _getEmptyMatch();
    }
  }

  static String _parseMatchStatus(String state) {
    if (state == 'LIVE' || state == 'HT') return 'live';
    if (state == 'FT' || state == 'AET' || state == 'FT_PEN') return 'finished';
    return 'upcoming';
  }

  static MatchOdds _parseOddsFromFixture(dynamic fixture) {
    try {
      final odds = fixture['odds'] as List? ?? [];
      if (odds.isEmpty) return _getDefaultOdds();

      final fullTimeResult = odds.firstWhere(
        (odd) => odd['name'] == 'Fulltime Result' || odd['name'] == '3Way Result',
        orElse: () => null,
      );

      if (fullTimeResult != null) {
        final bookmaker = fullTimeResult['bookmaker'] ?? {};
        final oddsData = bookmaker['odds'] as List? ?? [];
        
        double homeWin = 2.0, draw = 3.2, awayWin = 3.5;

        for (var odd in oddsData) {
          final label = odd['label']?.toString().toLowerCase() ?? '';
          final value = double.tryParse(odd['value']?.toString() ?? '0') ?? 0.0;
          
          if (label.contains('1') || label.contains('home')) homeWin = value;
          else if (label.contains('x') || label.contains('draw')) draw = value;
          else if (label.contains('2') || label.contains('away')) awayWin = value;
        }

        return MatchOdds(homeWin: homeWin, draw: draw, awayWin: awayWin);
      }
    } catch (e) {
      print('Error parsing odds: $e');
    }
    return _getDefaultOdds();
  }

  // ==================== FIREBASE CACHE ====================

  /// Get cached matches from Firebase
  static Future<List<Match>> _getCachedMatches() async {
    try {
      final today = _getTodayDateString();
      final doc = await _firestore
          .collection('matches_cache')
          .doc(today)
          .get();

      if (!doc.exists) return [];

      final data = doc.data()!;
      final cachedAt = (data['cached_at'] as Timestamp).toDate();
      
      // Check if cache is still valid
      if (DateTime.now().difference(cachedAt) > _cacheExpiry) {
        print('⚠️ Cache expired, fetching fresh data');
        return [];
      }

      final matchesList = data['matches'] as List;
      return matchesList.map((m) => Match.fromJson(m)).toList();
    } catch (e) {
      print('Error reading cache: $e');
      return [];
    }
  }

  /// Cache matches to Firebase
  static Future<void> _cacheMatchesToFirebase(List<Match> matches) async {
    try {
      final today = _getTodayDateString();
      await _firestore.collection('matches_cache').doc(today).set({
        'matches': matches.map((m) => m.toJson()).toList(),
        'cached_at': FieldValue.serverTimestamp(),
        'count': matches.length,
      });
      print('✅ Cached ${matches.length} matches to Firebase');
    } catch (e) {
      print('Error caching to Firebase: $e');
    }
  }

  // ==================== PREDICTIONS ====================

  /// Generate predictions from matches and cache to Firebase
  static Future<List<Prediction>> getPredictions() async {
    try {
      // Try to get from Firebase cache first
      final cachedPredictions = await _getCachedPredictions();
      if (cachedPredictions.isNotEmpty) {
        print('✅ Loaded ${cachedPredictions.length} predictions from Firebase');
        return cachedPredictions;
      }

      // Generate fresh predictions
      final matches = await getTodayMatches();
      final predictions = matches
          .where((m) => m.odds != null && m.status == 'upcoming')
          .map(_generatePredictionFromMatch)
          .toList()
        ..sort((a, b) => b.confidence.compareTo(a.confidence));

      // Cache to Firebase
      if (predictions.isNotEmpty) {
        await _cachePredictionsToFirebase(predictions);
      }

      print('✅ Generated ${predictions.length} predictions');
      return predictions;
    } catch (e) {
      print('❌ Error generating predictions: $e');
      return _getFallbackPredictions();
    }
  }

  /// Get cached predictions from Firebase
  static Future<List<Prediction>> _getCachedPredictions() async {
    try {
      final today = _getTodayDateString();
      final doc = await _firestore
          .collection('predictions_cache')
          .doc(today)
          .get();

      if (!doc.exists) return [];

      final data = doc.data()!;
      final cachedAt = (data['cached_at'] as Timestamp).toDate();
      
      if (DateTime.now().difference(cachedAt) > _cacheExpiry) {
        return [];
      }

      final predictionsList = data['predictions'] as List;
      return predictionsList.map((p) => Prediction.fromJson(p)).toList();
    } catch (e) {
      print('Error reading predictions cache: $e');
      return [];
    }
  }

  /// Cache predictions to Firebase
  static Future<void> _cachePredictionsToFirebase(List<Prediction> predictions) async {
    try {
      final today = _getTodayDateString();
      await _firestore.collection('predictions_cache').doc(today).set({
        'predictions': predictions.map((p) => p.toJson()).toList(),
        'cached_at': FieldValue.serverTimestamp(),
        'count': predictions.length,
      });
      print('✅ Cached ${predictions.length} predictions to Firebase');
    } catch (e) {
      print('Error caching predictions: $e');
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
        'text': '${match.homeTeam} are favorites at ${homeOdd.toStringAsFixed(2)}. Home advantage and favorable odds suggest strong winning potential.',
      };
    } else if (awayOdd < drawOdd && awayOdd < homeOdd) {
      return {
        'pick': '${match.awayTeam} Win',
        'odds': awayOdd,
        'confidence': _calculateConfidence(awayOdd),
        'text': '${match.awayTeam} show strong form with odds of ${awayOdd.toStringAsFixed(2)}. Away teams with these odds typically have high success rates.',
      };
    } else if (_isCompetitiveMatch(homeOdd, awayOdd, drawOdd)) {
      if (odds.over25 != null && odds.over25! < 2.0) {
        return {
          'pick': 'Over 2.5 Goals',
          'odds': odds.over25!,
          'confidence': _calculateConfidence(odds.over25!),
          'text': 'Both teams have attacking potential. Odds suggest high-scoring match.',
        };
      }
      return {
        'pick': 'Both Teams To Score',
        'odds': 1.75,
        'confidence': 70,
        'text': 'Evenly matched teams. Both sides have attacking threat.',
      };
    }
    
    return {
      'pick': 'Draw',
      'odds': drawOdd,
      'confidence': _calculateConfidence(drawOdd),
      'text': 'Competitive fixture with balanced odds suggests tight contest.',
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

  static bool _isCompetitiveMatch(double home, double away, double draw) {
    final odds = [home, away, draw];
    final minOdd = odds.reduce((a, b) => a < b ? a : b);
    final maxOdd = odds.reduce((a, b) => a > b ? a : b);
    return (maxOdd - minOdd) < 0.8;
  }

  // ==================== USER STATISTICS (Firebase) ====================

  /// Get user statistics from Firebase
  static Future<Map<String, dynamic>> getUserStats({
    required String userId,
    String period = 'week',
  }) async {
    try {
      final doc = await _firestore
          .collection('user_stats')
          .doc(userId)
          .collection('periods')
          .doc(period)
          .get();

      if (doc.exists) {
        return doc.data()!;
      }

      // Return default stats if none exist
      return _getDefaultStats(period);
    } catch (e) {
      print('Error fetching user stats: $e');
      return _getDefaultStats(period);
    }
  }

  /// Update user statistics in Firebase
  static Future<void> updateUserStats({
    required String userId,
    required String period,
    required Map<String, dynamic> stats,
  }) async {
    try {
      await _firestore
          .collection('user_stats')
          .doc(userId)
          .collection('periods')
          .doc(period)
          .set(stats, SetOptions(merge: true));
      
      print('✅ Updated user stats for period: $period');
    } catch (e) {
      print('Error updating user stats: $e');
    }
  }

  /// Record prediction result
  static Future<void> recordPredictionResult({
    required String userId,
    required String predictionId,
    required bool won,
    required double odds,
  }) async {
    try {
      await _firestore.collection('prediction_results').add({
        'user_id': userId,
        'prediction_id': predictionId,
        'won': won,
        'odds': odds,
        'recorded_at': FieldValue.serverTimestamp(),
      });
      
      print('✅ Recorded prediction result');
    } catch (e) {
      print('Error recording prediction result: $e');
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
      draw: 3.20,
      awayWin: 3.50,
      over25: 1.75,
      under25: 2.05,
    );
  }

  static Match _getEmptyMatch() {
    return Match(
      id: '0',
      homeTeam: 'Unknown',
      awayTeam: 'Unknown',
      league: 'Unknown',
      dateTime: DateTime.now(),
      odds: _getDefaultOdds(),
    );
  }

  static List<Match> _getFallbackMatches() {
    final now = DateTime.now();
    return [
      Match(
        id: '1',
        homeTeam: 'Manchester City',
        awayTeam: 'Liverpool',
        league: 'Premier League',
        dateTime: now.add(const Duration(hours: 3)),
        odds: MatchOdds(homeWin: 2.10, draw: 3.40, awayWin: 3.20, over25: 1.65),
        status: 'upcoming',
      ),
      Match(
        id: '2',
        homeTeam: 'Real Madrid',
        awayTeam: 'Barcelona',
        league: 'La Liga',
        dateTime: now.add(const Duration(hours: 5)),
        odds: MatchOdds(homeWin: 2.30, draw: 3.20, awayWin: 2.90, over25: 1.75),
        status: 'upcoming',
      ),
      Match(
        id: '3',
        homeTeam: 'Bayern Munich',
        awayTeam: 'Borussia Dortmund',
        league: 'Bundesliga',
        dateTime: now.add(const Duration(hours: 4)),
        odds: MatchOdds(homeWin: 1.85, draw: 3.60, awayWin: 3.80, over25: 1.55),
        status: 'upcoming',
      ),
      Match(
        id: '4',
        homeTeam: 'Arsenal',
        awayTeam: 'Chelsea',
        league: 'Premier League',
        dateTime: now.add(const Duration(hours: 6)),
        odds: MatchOdds(homeWin: 2.00, draw: 3.30, awayWin: 3.40, over25: 1.70),
        status: 'upcoming',
      ),
      Match(
        id: '5',
        homeTeam: 'Inter Milan',
        awayTeam: 'AC Milan',
        league: 'Serie A',
        dateTime: now.add(const Duration(hours: 7)),
        odds: MatchOdds(homeWin: 2.20, draw: 3.10, awayWin: 3.20, over25: 1.80),
        status: 'upcoming',
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
        analysis: 'Both teams have strong attacking records. Expect high-scoring encounter.',
        createdAt: DateTime.now(),
      ),
      Prediction(
        id: 'pred_2',
        homeTeam: 'Bayern Munich',
        awayTeam: 'Borussia Dortmund',
        league: 'Bundesliga',
        pick: 'Bayern Munich Win',
        odds: 1.85,
        confidence: 75,
        analysis: 'Bayern unbeaten in last 5 home matches. Strong home advantage.',
        createdAt: DateTime.now(),
      ),
      Prediction(
        id: 'pred_3',
        homeTeam: 'Real Madrid',
        awayTeam: 'Barcelona',
        league: 'La Liga',
        pick: 'Both Teams To Score',
        odds: 1.70,
        confidence: 72,
        analysis: 'El Clasico tends to be high-scoring. Both teams have strong attacks.',
        createdAt: DateTime.now(),
      ),
    ];
  }

  static Map<String, dynamic> _getDefaultStats(String period) {
    return {
      'total_predictions': 0,
      'win_rate': 0,
      'won': 0,
      'lost': 0,
      'avg_odds': 0.0,
      'profit': '+0.0',
      'league_performance': [],
      'recent_results': [],
    };
  }
}