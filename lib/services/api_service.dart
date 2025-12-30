// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match.dart';
import '../models/prediction.dart';

class ApiService {
  static String get _rapidApiKey => dotenv.env['RAPIDAPI_KEY'] ?? '';
  static const String _apiHost = 'free-api-live-football-data.p.rapidapi.com';
  static const String _baseUrl = 'https://$_apiHost';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const Duration _timeout = Duration(seconds: 20);
  static const Duration _cacheExpiry = Duration(hours: 3);
  static bool get isConfigured => _rapidApiKey.isNotEmpty;

  // ==================== FETCH MATCHES ====================

  static Future<List<Match>> getTodayMatches() async {
    try {
      print('🔄 Fetching matches...');

      if (!isConfigured) {
        print('⚠️ API key not configured');
        return _getFallbackMatches();
      }

      // Try fresh data FIRST
      print('🌐 Attempting fresh API fetch...');
      final matches = await _fetchMatches();
      
      if (matches.isNotEmpty) {
        print('✅ Fetched ${matches.length} fresh matches');
        await _cacheMatches(matches);
        return matches;
      }

      // Fallback to cache only if API fails
      print('⚠️ API returned no matches, checking cache...');
      final cached = await _getCachedMatches();
      if (cached.isNotEmpty) {
        print('✅ Using ${cached.length} cached matches');
        return cached;
      }

      print('⚠️ Using fallback matches');
      return _getFallbackMatches();
    } catch (e, stack) {
      print('❌ Error: $e');
      final cached = await _getCachedMatches();
      return cached.isNotEmpty ? cached : _getFallbackMatches();
    }
  }

  static Future<List<Match>> _fetchMatches() async {
    final List<Match> allMatches = [];
    final now = DateTime.now();

    // Fetch 7 days to get fixtures
    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      final dateStr = _formatDate(date);
      
      print('📅 Fetching: $dateStr');
      
      try {
        final matches = await _fetchMatchesByDate(dateStr);
        print('   Found ${matches.length} matches');
        allMatches.addAll(matches);

        if (allMatches.length >= 100) break;
      } catch (e) {
        print('   Error: $e');
        continue;
      }

      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (allMatches.isEmpty) return [];

    print('📊 Total: ${allMatches.length}');

    // Remove duplicates
    final unique = <String, Match>{};
    for (var m in allMatches) {
      unique[m.id] = m;
    }

    // Sort by priority then time
    final sorted = unique.values.toList()
      ..sort((a, b) {
        final pA = _getLeaguePriority(a.league);
        final pB = _getLeaguePriority(b.league);
        return pA == pB ? a.dateTime.compareTo(b.dateTime) : pA.compareTo(pB);
      });

    return sorted.take(80).toList();
  }

  static Future<List<Match>> _fetchMatchesByDate(String date) async {
    final url = Uri.parse('$_baseUrl/football-get-matches-by-date?date=$date');
    
    final response = await http.get(
      url,
      headers: {
        'x-rapidapi-key': _rapidApiKey,
        'x-rapidapi-host': _apiHost,
      },
    ).timeout(_timeout);

    print('   Status: ${response.statusCode}');
    
    if (response.statusCode != 200) {
      print('   Error: ${response.body.substring(0, 200)}');
      return [];
    }

    final data = json.decode(response.body);
    List matchesList = [];
    
    if (data is Map) {
      if (data['response'] is Map && data['response']['matches'] is List) {
        matchesList = data['response']['matches'];
      } else if (data['response'] is List) {
        matchesList = data['response'];
      } else if (data['data'] is Map && data['data']['matches'] is List) {
        matchesList = data['data']['matches'];
      } else if (data['data'] is List) {
        matchesList = data['data'];
      } else if (data['matches'] is List) {
        matchesList = data['matches'];
      } else {
        print('   Unknown structure: ${data.keys}');
        return [];
      }
    } else if (data is List) {
      matchesList = data;
    }

    if (matchesList.isEmpty) return [];

    final parsed = <Match>[];
    for (var fixture in matchesList) {
      try {
        final match = _parseMatch(fixture);
        if (match != null) parsed.add(match);
      } catch (e) {
        continue;
      }
    }

    print('   Parsed: ${parsed.length}/${matchesList.length}');
    return parsed;
  }

  static Match? _parseMatch(dynamic fixture) {
    try {
      if (fixture is! Map) return null;

      final id = fixture['id']?.toString() ?? 
                 fixture['fixture']?['id']?.toString() ??
                 DateTime.now().millisecondsSinceEpoch.toString();

      // Extract teams
      String homeTeam = fixture['home']?['name']?.toString() ?? 
                       fixture['home']?['longName']?.toString() ??
                       fixture['teams']?['home']?['name']?.toString() ??
                       'Home Team';
                       
      String awayTeam = fixture['away']?['name']?.toString() ?? 
                       fixture['away']?['longName']?.toString() ??
                       fixture['teams']?['away']?['name']?.toString() ??
                       'Away Team';

      // Extract league
      String league = 'Unknown League';
      final leagueId = fixture['leagueId']?.toString() ?? 
                       fixture['league']?['id']?.toString();
      
      if (leagueId != null) {
        league = _getLeagueName(leagueId) ?? 'League $leagueId';
      } else if (fixture['league']?['name'] != null) {
        league = fixture['league']['name'].toString();
      }

      // Parse time
      DateTime dateTime;
      final timeTS = fixture['timeTS'];
      
      if (timeTS is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timeTS);
      } else if (timeTS is String) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timeTS));
      } else {
        final timestamp = fixture['fixture']?['timestamp'] ?? fixture['timestamp'];
        if (timestamp is int) {
          dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        } else {
          final timeStr = fixture['status']?['utcTime']?.toString() ?? 
                          fixture['fixture']?['date']?.toString();
          dateTime = timeStr != null ? DateTime.parse(timeStr) : DateTime.now().add(Duration(hours: 2));
        }
      }

      // Status
      String status = 'upcoming';
      final statusObj = fixture['status'] ?? fixture['fixture']?['status'];
      
      if (statusObj is Map) {
        final started = statusObj['started'] ?? false;
        final finished = statusObj['finished'] ?? false;
        final cancelled = statusObj['cancelled'] ?? false;
        final short = statusObj['short']?.toString().toUpperCase();
        
        if (cancelled) status = 'cancelled';
        else if (finished || short == 'FT') status = 'finished';
        else if (started || ['1H', '2H', 'HT', 'LIVE'].contains(short)) status = 'live';
      }

      // Scores
      int? homeScore, awayScore;
      if (status != 'upcoming') {
        homeScore = fixture['home']?['score'] ?? fixture['goals']?['home'] ?? fixture['score']?['fulltime']?['home'];
        awayScore = fixture['away']?['score'] ?? fixture['goals']?['away'] ?? fixture['score']?['fulltime']?['away'];
      }

      final homeTeamLogo = fixture['home']?['logo'] ?? fixture['teams']?['home']?['logo'];
      final awayTeamLogo = fixture['away']?['logo'] ?? fixture['teams']?['away']?['logo'];

      return Match(
        id: id,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        league: league,
        dateTime: dateTime,
        homeTeamLogo: homeTeamLogo,
        awayTeamLogo: awayTeamLogo,
        odds: _generateOdds(homeTeam, awayTeam),
        status: status,
        homeScore: homeScore,
        awayScore: awayScore,
      );
    } catch (e) {
      return null;
    }
  }

  static String? _getLeagueName(String? leagueId) {
    if (leagueId == null) return null;
    
    return {
      // Top 5
      '47': 'Premier League', '53': 'La Liga', '54': 'Bundesliga',
      '55': 'Ligue 1', '135': 'Serie A',
      
      // Europe
      '2': 'Champions League', '3': 'Europa League', '848': 'Conference League',
      
      // England
      '900638': 'Championship', '900639': 'League One', '900640': 'League Two',
      '667': 'FA Cup', '528': 'EFL Cup',
      
      // Other major
      '61': 'Primeira Liga', '88': 'Eredivisie', '203': 'Süper Lig',
      '345': 'Pro League', '266': 'Premiership',
      
      // Americas
      '94': 'Liga MX', '262': 'MLS', '71': 'Serie A', '128': 'Primera',
      
      // Asia/Middle East
      '307': 'Saudi Pro League', '536': 'Pro League', '383': 'J-League',
      '127': 'Premier League', '523': 'Pro League',
      
      // International
      '960': 'World Cup', '4': 'Euro', '9': 'Copa America',
    }[leagueId];
  }

  static int _getLeaguePriority(String league) {
    return {
      'Premier League': 1, 'La Liga': 2, 'Bundesliga': 3, 'Serie A': 4, 'Ligue 1': 5,
      'Champions League': 6, 'Europa League': 7, 'Conference League': 8,
      'Primeira Liga': 10, 'Eredivisie': 11, 'Championship': 12,
      'Liga MX': 20, 'MLS': 21, 'Saudi Pro League': 22,
      'FA Cup': 30, 'League One': 40, 'League Two': 41,
    }[league] ?? 999;
  }

  static MatchOdds _generateOdds(String home, String away) {
    final big = ['Manchester City', 'Liverpool', 'Real Madrid', 'Barcelona',
      'Bayern Munich', 'PSG', 'Arsenal', 'Chelsea', 'Manchester United',
      'Inter', 'Milan', 'Juventus', 'Atletico', 'Dortmund', 'Tottenham'];

    final hBig = big.any((t) => home.contains(t));
    final aBig = big.any((t) => away.contains(t));
    final r = DateTime.now().millisecond % 50 / 100;

    double h, d, a;
    if (hBig && !aBig) {
      h = 1.50 + r; d = 3.80 + r; a = 5.50 + r;
    } else if (!hBig && aBig) {
      h = 4.50 + r; d = 3.60 + r; a = 1.70 + r;
    } else if (hBig && aBig) {
      h = 2.30 + r; d = 3.20 + r; a = 2.90 + r;
    } else {
      h = 2.10 + r; d = 3.30 + r; a = 3.00 + r;
    }

    return MatchOdds(homeWin: h, draw: d, awayWin: a, over25: 1.70 + r * 0.5, under25: 2.00 + r * 0.5);
  }

  // ==================== CACHE ====================

  static Future<List<Match>> _getCachedMatches() async {
    try {
      final doc = await _firestore.collection('matches_cache').doc(_getDateKey()).get();
      if (!doc.exists) return [];

      final data = doc.data()!;
      final cached = (data['cached_at'] as Timestamp).toDate();
      if (DateTime.now().difference(cached) > _cacheExpiry) return [];

      return (data['matches'] as List).map((m) => Match.fromJson(m)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> _cacheMatches(List<Match> matches) async {
    try {
      await _firestore.collection('matches_cache').doc(_getDateKey()).set({
        'matches': matches.map((m) => m.toJson()).toList(),
        'cached_at': FieldValue.serverTimestamp(),
        'count': matches.length,
      });
      print('💾 Cached ${matches.length} matches');
    } catch (e) {}
  }

  // ==================== USER STATS ====================

  static Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final doc = await _firestore.collection('user_stats').doc(userId).get();
      return doc.exists ? doc.data()! : _getDefaultStats();
    } catch (e) {
      return _getDefaultStats();
    }
  }

  static Future<void> updateUserStats(String userId, Map<String, dynamic> stats) async {
    try {
      await _firestore.collection('user_stats').doc(userId).set({
        ...stats,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {}
  }

  static Future<void> recordPredictionResult({
    required String userId,
    required bool isCorrect,
    required double odds,
    required double stake,
  }) async {
    try {
      final stats = await getUserStats(userId);
      final total = (stats['totalPredictions'] ?? 0) + 1;
      final correct = (stats['correctPredictions'] ?? 0) + (isCorrect ? 1 : 0);
      final profit = isCorrect ? (stake * odds - stake) : -stake;
      final currentStreak = isCorrect ? (stats['currentStreak'] ?? 0) + 1 : 0;

      await updateUserStats(userId, {
        'totalPredictions': total,
        'correctPredictions': correct,
        'winRate': (correct / total) * 100,
        'totalProfit': (stats['totalProfit'] ?? 0.0) + profit,
        'currentStreak': currentStreak,
        'bestStreak': currentStreak > (stats['bestStreak'] ?? 0) ? currentStreak : (stats['bestStreak'] ?? 0),
      });
    } catch (e) {}
  }

  // ==================== HELPERS ====================

  static String _formatDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  static String _getDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static Map<String, dynamic> _getDefaultStats() {
    return {
      'totalPredictions': 0,
      'correctPredictions': 0,
      'winRate': 0.0,
      'totalProfit': 0.0,
      'currentStreak': 0,
      'bestStreak': 0,
    };
  }

  static Future<List<Map<String, dynamic>>> getPopularLeagues() async {
    try {
      if (!isConfigured) return [];
      final url = Uri.parse('$_baseUrl/football-popular-leagues');
      final response = await http.get(url, headers: {
        'x-rapidapi-key': _rapidApiKey,
        'x-rapidapi-host': _apiHost,
      }).timeout(_timeout);
      if (response.statusCode != 200) return [];
      final data = json.decode(response.body);
      return data is List ? List<Map<String, dynamic>>.from(data) : [];
    } catch (e) {
      return [];
    }
  }

  static List<Match> _getFallbackMatches() {
    final now = DateTime.now();
    return [
      Match(
        id: '1',
        homeTeam: 'Manchester City',
        awayTeam: 'Liverpool',
        league: 'Premier League',
        dateTime: now.add(Duration(hours: 3)),
        odds: MatchOdds(homeWin: 2.10, draw: 3.40, awayWin: 3.20, over25: 1.65, under25: 2.10),
        status: 'upcoming',
      ),
      Match(
        id: '2',
        homeTeam: 'Arsenal',
        awayTeam: 'Chelsea',
        league: 'Premier League',
        dateTime: now.add(Duration(hours: 4)),
        odds: MatchOdds(homeWin: 2.30, draw: 3.20, awayWin: 2.90, over25: 1.75, under25: 2.05),
        status: 'upcoming',
      ),
      Match(
        id: '3',
        homeTeam: 'Real Madrid',
        awayTeam: 'Barcelona',
        league: 'La Liga',
        dateTime: now.add(Duration(hours: 6)),
        odds: MatchOdds(homeWin: 2.30, draw: 3.20, awayWin: 2.90, over25: 1.75, under25: 2.05),
        status: 'upcoming',
      ),
    ];
  }
}