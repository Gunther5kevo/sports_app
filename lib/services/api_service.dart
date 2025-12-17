// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/match.dart';
import '../models/prediction.dart';

class ApiService {
  // Load API credentials from .env
  static String get _apiKey => dotenv.env['SPORTMONKS_API_KEY'] ?? '';
  static String get _baseUrl => dotenv.env['SPORTMONKS_BASE_URL'] ?? 'https://api.sportmonks.com/v3/football';
  
  // Check if API is configured
  static bool get isConfigured => _apiKey.isNotEmpty;
  
  /// Get today's fixtures with odds
  static Future<List<Match>> getTodayMatches() async {
    if (!isConfigured) {
      print('⚠️ Sportmonks API key not configured. Using fallback data.');
      return _getFallbackMatches();
    }

    try {
      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      print('🔄 Fetching matches for: $today');
      
      // Sportmonks API endpoint for fixtures by date
      final url = Uri.parse(
        '$_baseUrl/fixtures/date/$today?api_token=$_apiKey&include=participants;league;odds;statistics'
      );
      
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['errors'] != null) {
          print('❌ API Error: ${data['errors']}');
          return _getFallbackMatches();
        }
        
        final fixtures = data['data'] as List;
        
        print('✅ Fetched ${fixtures.length} matches from Sportmonks');
        
        if (fixtures.isEmpty) {
          print('ℹ️ No matches today. Using fallback data.');
          return _getFallbackMatches();
        }
        
        return fixtures.map((fixture) => _parseFixture(fixture)).toList();
      } else if (response.statusCode == 401) {
        print('❌ API Authentication failed. Check your Sportmonks API key.');
        return _getFallbackMatches();
      } else if (response.statusCode == 429) {
        print('❌ API Rate limit exceeded.');
        return _getFallbackMatches();
      } else {
        print('❌ API Error: ${response.statusCode}');
        return _getFallbackMatches();
      }
    } catch (e) {
      print('❌ Error fetching matches: $e');
      return _getFallbackMatches();
    }
  }

  /// Get predictions based on today's matches
  static Future<List<Prediction>> getPredictions() async {
    try {
      final matches = await getTodayMatches();
      
      // Generate predictions from matches with odds
      final predictions = matches
          .where((match) => match.odds != null && match.status == 'upcoming')
          .map((match) => _generatePredictionFromMatch(match))
          .toList();
      
      // Sort by confidence (highest first)
      predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
      
      print('✅ Generated ${predictions.length} predictions');
      
      return predictions;
    } catch (e) {
      print('❌ Error generating predictions: $e');
      return _getFallbackPredictions();
    }
  }

  /// Generate AI prediction from match data and odds
  static Prediction _generatePredictionFromMatch(Match match) {
    final odds = match.odds!;
    
    // Calculate confidence based on odds analysis
    String pick;
    int confidence;
    double selectedOdds;
    String analysis;
    
    // Find the most likely outcome based on odds
    final homeOdd = odds.homeWin;
    final drawOdd = odds.draw;
    final awayOdd = odds.awayWin;
    
    // Lower odds = higher probability
    if (homeOdd < drawOdd && homeOdd < awayOdd) {
      // Home win is most likely
      pick = '${match.homeTeam} Win';
      selectedOdds = homeOdd;
      confidence = _calculateConfidence(homeOdd);
      analysis = _generateHomeWinAnalysis(match, homeOdd, awayOdd);
    } else if (awayOdd < drawOdd && awayOdd < homeOdd) {
      // Away win is most likely
      pick = '${match.awayTeam} Win';
      selectedOdds = awayOdd;
      confidence = _calculateConfidence(awayOdd);
      analysis = _generateAwayWinAnalysis(match, homeOdd, awayOdd);
    } else if (_isCloseFavorite(homeOdd, awayOdd, drawOdd)) {
      // Close match - suggest Both Teams to Score or Over 2.5
      if (odds.over25 != null && odds.over25! < 2.0) {
        pick = 'Over 2.5 Goals';
        selectedOdds = odds.over25!;
        confidence = _calculateConfidence(odds.over25!);
        analysis = _generateOverGoalsAnalysis(match, odds.over25!);
      } else {
        pick = 'Both Teams To Score';
        selectedOdds = _estimateBTTSOdds(homeOdd, awayOdd);
        confidence = 70;
        analysis = _generateBTTSAnalysis(match, homeOdd, awayOdd);
      }
    } else {
      // Draw or close odds
      pick = 'Draw';
      selectedOdds = drawOdd;
      confidence = _calculateConfidence(drawOdd);
      analysis = _generateDrawAnalysis(match, homeOdd, awayOdd, drawOdd);
    }
    
    return Prediction(
      id: 'pred_${match.id}',
      homeTeam: match.homeTeam,
      awayTeam: match.awayTeam,
      league: match.league,
      pick: pick,
      odds: selectedOdds,
      confidence: confidence,
      analysis: analysis,
      createdAt: DateTime.now(),
    );
  }

  /// Calculate confidence percentage from odds
  static int _calculateConfidence(double odds) {
    // Convert odds to implied probability, then to confidence percentage
    // Lower odds = higher confidence
    if (odds <= 1.5) return 85;
    if (odds <= 1.8) return 78;
    if (odds <= 2.0) return 72;
    if (odds <= 2.5) return 68;
    if (odds <= 3.0) return 63;
    return 58;
  }

  /// Check if odds are close (competitive match)
  static bool _isCloseFavorite(double home, double away, double draw) {
    final minOdd = [home, away, draw].reduce((a, b) => a < b ? a : b);
    final maxOdd = [home, away, draw].reduce((a, b) => a > b ? a : b);
    return (maxOdd - minOdd) < 0.8;
  }

  /// Estimate Both Teams To Score odds
  static double _estimateBTTSOdds(double homeOdd, double awayOdd) {
    // Typically BTTS odds are between 1.6-1.9 for competitive matches
    return 1.75;
  }

  // Analysis generators
  static String _generateHomeWinAnalysis(Match match, double homeOdd, double awayOdd) {
    final oddsGap = (awayOdd - homeOdd).toStringAsFixed(2);
    return '${match.homeTeam} are strong favorites with odds of ${homeOdd.toStringAsFixed(2)}. '
        'The ${oddsGap} difference in odds suggests home advantage. '
        'Expect ${match.homeTeam} to control the match.';
  }

  static String _generateAwayWinAnalysis(Match match, double homeOdd, double awayOdd) {
    return '${match.awayTeam} show strong form with favorable odds of ${awayOdd.toStringAsFixed(2)}. '
        'Away teams with these odds typically have a strong chance. '
        'Look for ${match.awayTeam} to capitalize on scoring opportunities.';
  }

  static String _generateOverGoalsAnalysis(Match match, double over25Odds) {
    return 'Both teams have attacking potential. Odds of ${over25Odds.toStringAsFixed(2)} for Over 2.5 goals '
        'suggest high-scoring potential. ${match.homeTeam} vs ${match.awayTeam} matchups often produce goals.';
  }

  static String _generateBTTSAnalysis(Match match, double homeOdd, double awayOdd) {
    return 'Evenly matched teams with close odds (Home: ${homeOdd.toStringAsFixed(2)}, Away: ${awayOdd.toStringAsFixed(2)}). '
        'Both sides have attacking threat. Expect goals from both teams.';
  }

  static String _generateDrawAnalysis(Match match, double homeOdd, double awayOdd, double drawOdd) {
    return 'Competitive fixture with balanced odds. Draw priced at ${drawOdd.toStringAsFixed(2)} '
        'suggests a tight contest. Both teams evenly matched.';
  }

  /// Get user statistics (mock data - replace with backend API)
  static Future<Map<String, dynamic>> getUserStats({String period = 'week'}) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Mock statistics - replace with actual backend API
    final statsMap = {
      'week': {
        'total_predictions': 24,
        'win_rate': 68,
        'won': 16,
        'lost': 8,
        'avg_odds': 1.85,
        'profit': '+12.4',
        'league_performance': [
          {'name': 'Premier League', 'accuracy': 72, 'count': 8},
          {'name': 'La Liga', 'accuracy': 68, 'count': 6},
          {'name': 'Bundesliga', 'accuracy': 65, 'count': 5},
          {'name': 'Serie A', 'accuracy': 70, 'count': 5},
        ],
        'recent_results': [
          {'match': 'Man City vs Liverpool', 'pick': 'Over 2.5', 'won': true, 'odds': 1.85, 'date': '2 days ago'},
          {'match': 'Real Madrid vs Barcelona', 'pick': 'BTTS', 'won': false, 'odds': 1.65, 'date': '3 days ago'},
          {'match': 'Bayern vs Dortmund', 'pick': 'Bayern Win', 'won': true, 'odds': 1.70, 'date': '4 days ago'},
          {'match': 'PSG vs Marseille', 'pick': 'PSG Win', 'won': true, 'odds': 1.55, 'date': '5 days ago'},
        ],
      },
      'month': {
        'total_predictions': 96,
        'win_rate': 65,
        'won': 62,
        'lost': 34,
        'avg_odds': 1.92,
        'profit': '+28.7',
        'league_performance': [
          {'name': 'Premier League', 'accuracy': 70, 'count': 24},
          {'name': 'La Liga', 'accuracy': 66, 'count': 20},
          {'name': 'Bundesliga', 'accuracy': 68, 'count': 18},
          {'name': 'Serie A', 'accuracy': 62, 'count': 16},
          {'name': 'Ligue 1', 'accuracy': 63, 'count': 18},
        ],
        'recent_results': [
          {'match': 'Man City vs Liverpool', 'pick': 'Over 2.5', 'won': true, 'odds': 1.85, 'date': '2 days ago'},
          {'match': 'Real Madrid vs Barcelona', 'pick': 'BTTS', 'won': false, 'odds': 1.65, 'date': '3 days ago'},
          {'match': 'Bayern vs Dortmund', 'pick': 'Bayern Win', 'won': true, 'odds': 1.70, 'date': '4 days ago'},
          {'match': 'PSG vs Marseille', 'pick': 'PSG Win', 'won': true, 'odds': 1.55, 'date': '5 days ago'},
          {'match': 'Chelsea vs Arsenal', 'pick': 'Draw', 'won': false, 'odds': 3.20, 'date': '6 days ago'},
        ],
      },
      'all': {
        'total_predictions': 342,
        'win_rate': 67,
        'won': 229,
        'lost': 113,
        'avg_odds': 1.88,
        'profit': '+94.3',
        'league_performance': [
          {'name': 'Premier League', 'accuracy': 72, 'count': 85},
          {'name': 'La Liga', 'accuracy': 68, 'count': 72},
          {'name': 'Bundesliga', 'accuracy': 70, 'count': 68},
          {'name': 'Serie A', 'accuracy': 65, 'count': 62},
          {'name': 'Ligue 1', 'accuracy': 63, 'count': 55},
        ],
        'recent_results': [
          {'match': 'Man City vs Liverpool', 'pick': 'Over 2.5', 'won': true, 'odds': 1.85, 'date': '2 days ago'},
          {'match': 'Real Madrid vs Barcelona', 'pick': 'BTTS', 'won': false, 'odds': 1.65, 'date': '3 days ago'},
          {'match': 'Bayern vs Dortmund', 'pick': 'Bayern Win', 'won': true, 'odds': 1.70, 'date': '4 days ago'},
          {'match': 'PSG vs Marseille', 'pick': 'PSG Win', 'won': true, 'odds': 1.55, 'date': '5 days ago'},
          {'match': 'Chelsea vs Arsenal', 'pick': 'Draw', 'won': false, 'odds': 3.20, 'date': '6 days ago'},
        ],
      },
    };
    
    return statsMap[period] ?? statsMap['week']!;
  }

  /// Get fixtures by league
  static Future<List<Match>> getMatchesByLeague(int leagueId) async {
    if (!isConfigured) return _getFallbackMatches();

    try {
      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final url = Uri.parse(
        '$_baseUrl/fixtures/date/$today?api_token=$_apiKey&include=participants;league;odds&filters=leagueId:$leagueId'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fixtures = data['data'] as List;
        
        return fixtures.map((fixture) => _parseFixture(fixture)).toList();
      }
      throw Exception('Failed to load league matches');
    } catch (e) {
      print('Error fetching league matches: $e');
      return [];
    }
  }

  /// Get live matches
  static Future<List<Match>> getLiveMatches() async {
    if (!isConfigured) return [];

    try {
      final url = Uri.parse(
        '$_baseUrl/livescores/inplay?api_token=$_apiKey&include=participants;league;odds'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fixtures = data['data'] as List;
        
        return fixtures.map((fixture) => _parseFixture(fixture)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching live matches: $e');
      return [];
    }
  }

  /// Parse fixture from Sportmonks API response
  static Match _parseFixture(dynamic fixture) {
    try {
      // Parse participants (teams)
      final participants = fixture['participants'] as List? ?? [];
      final homeTeam = participants.firstWhere(
        (p) => p['meta']['location'] == 'home',
        orElse: () => {'name': 'Home Team', 'image_path': null},
      );
      final awayTeam = participants.firstWhere(
        (p) => p['meta']['location'] == 'away',
        orElse: () => {'name': 'Away Team', 'image_path': null},
      );

      // Parse league
      final league = fixture['league'] ?? {};
      
      // Parse date/time
      final startingAt = fixture['starting_at'] ?? DateTime.now().toIso8601String();
      
      // Parse odds
      final odds = _parseOddsFromFixture(fixture);
      
      // Parse status
      final state = fixture['state']?['state'] ?? 'NS';
      String status = 'upcoming';
      if (state == 'LIVE' || state == 'HT') {
        status = 'live';
      } else if (state == 'FT' || state == 'AET' || state == 'FT_PEN') {
        status = 'finished';
      }

      return Match(
        id: fixture['id'].toString(),
        homeTeam: homeTeam['name'] ?? 'Home Team',
        awayTeam: awayTeam['name'] ?? 'Away Team',
        league: league['name'] ?? 'Unknown League',
        dateTime: DateTime.parse(startingAt),
        homeTeamLogo: homeTeam['image_path'],
        awayTeamLogo: awayTeam['image_path'],
        odds: odds,
        status: status,
      );
    } catch (e) {
      print('Error parsing fixture: $e');
      return Match(
        id: '0',
        homeTeam: 'Unknown',
        awayTeam: 'Unknown',
        league: 'Unknown',
        dateTime: DateTime.now(),
        odds: MatchOdds(homeWin: 0.0, draw: 0.0, awayWin: 0.0),
      );
    }
  }

  /// Parse odds from fixture data
  static MatchOdds _parseOddsFromFixture(dynamic fixture) {
    try {
      final odds = fixture['odds'] as List? ?? [];
      
      if (odds.isEmpty) {
        return _getDefaultOdds();
      }

      // Find 1X2 market (Full Time Result)
      final fullTimeResult = odds.firstWhere(
        (odd) => odd['name'] == 'Fulltime Result' || odd['name'] == '3Way Result',
        orElse: () => null,
      );

      if (fullTimeResult != null) {
        final bookmaker = fullTimeResult['bookmaker'] ?? {};
        final oddsData = bookmaker['odds'] as List? ?? [];
        
        double homeWin = 2.0;
        double draw = 3.2;
        double awayWin = 3.5;
        double? over25;
        double? under25;

        // Parse 1X2 odds
        for (var odd in oddsData) {
          final label = odd['label']?.toString().toLowerCase() ?? '';
          final value = double.tryParse(odd['value']?.toString() ?? '0') ?? 0.0;
          
          if (label.contains('1') || label.contains('home')) {
            homeWin = value;
          } else if (label.contains('x') || label.contains('draw')) {
            draw = value;
          } else if (label.contains('2') || label.contains('away')) {
            awayWin = value;
          }
        }

        // Try to find Over/Under 2.5 goals
        final overUnder = odds.firstWhere(
          (odd) => odd['name']?.toString().contains('Over/Under') ?? false,
          orElse: () => null,
        );

        if (overUnder != null) {
          final ouBookmaker = overUnder['bookmaker'] ?? {};
          final ouOdds = ouBookmaker['odds'] as List? ?? [];
          
          for (var odd in ouOdds) {
            final label = odd['label']?.toString().toLowerCase() ?? '';
            final value = double.tryParse(odd['value']?.toString() ?? '0') ?? 0.0;
            
            if (label.contains('over') && label.contains('2.5')) {
              over25 = value;
            } else if (label.contains('under') && label.contains('2.5')) {
              under25 = value;
            }
          }
        }

        return MatchOdds(
          homeWin: homeWin,
          draw: draw,
          awayWin: awayWin,
          over25: over25,
          under25: under25,
        );
      }
    } catch (e) {
      print('Error parsing odds: $e');
    }
    
    return _getDefaultOdds();
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

  /// Fallback sample matches
  static List<Match> _getFallbackMatches() {
    final now = DateTime.now();
    return [
      Match(
        id: '1',
        homeTeam: 'Manchester City',
        awayTeam: 'Liverpool',
        league: 'Premier League',
        dateTime: now.add(const Duration(hours: 3)),
        odds: MatchOdds(homeWin: 2.10, draw: 3.40, awayWin: 3.20, over25: 1.65, under25: 2.20),
      ),
      Match(
        id: '2',
        homeTeam: 'Real Madrid',
        awayTeam: 'Barcelona',
        league: 'La Liga',
        dateTime: now.add(const Duration(hours: 5)),
        odds: MatchOdds(homeWin: 2.30, draw: 3.20, awayWin: 2.90, over25: 1.75, under25: 2.05),
      ),
      Match(
        id: '3',
        homeTeam: 'Bayern Munich',
        awayTeam: 'Borussia Dortmund',
        league: 'Bundesliga',
        dateTime: now.add(const Duration(hours: 4)),
        odds: MatchOdds(homeWin: 1.85, draw: 3.60, awayWin: 3.80, over25: 1.55, under25: 2.35),
      ),
      Match(
        id: '4',
        homeTeam: 'Paris Saint Germain',
        awayTeam: 'Olympique Marseille',
        league: 'Ligue 1',
        dateTime: now.add(const Duration(hours: 6)),
        odds: MatchOdds(homeWin: 1.70, draw: 3.80, awayWin: 4.50, over25: 1.60, under25: 2.25),
      ),
      Match(
        id: '5',
        homeTeam: 'Juventus',
        awayTeam: 'Inter Milan',
        league: 'Serie A',
        dateTime: now.add(const Duration(hours: 7)),
        odds: MatchOdds(homeWin: 2.40, draw: 3.10, awayWin: 2.80, over25: 1.80, under25: 1.95),
      ),
      Match(
        id: '6',
        homeTeam: 'Arsenal',
        awayTeam: 'Chelsea',
        league: 'Premier League',
        dateTime: now.add(const Duration(hours: 2)),
        odds: MatchOdds(homeWin: 2.25, draw: 3.30, awayWin: 3.10, over25: 1.70, under25: 2.10),
      ),
    ];
  }

  /// Fallback sample predictions
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
        analysis: 'Both teams have strong attacking records. Man City scored in 90% of home games. '
            'Liverpool\'s defense has been vulnerable away from home.',
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
        analysis: 'Bayern unbeaten in last 5 home matches. Dortmund missing key defenders. '
            'Home advantage significant in this fixture.',
        createdAt: DateTime.now(),
      ),
      Prediction(
        id: 'pred_3',
        homeTeam: 'Real Madrid',
        awayTeam: 'Barcelona',
        league: 'La Liga',
        pick: 'Both Teams To Score',
        odds: 1.75,
        confidence: 72,
        analysis: 'El Clasico historically high-scoring. Both teams strong in attack. '
            'Expect goals from both sides.',
        createdAt: DateTime.now(),
      ),
      Prediction(
        id: 'pred_4',
        homeTeam: 'Paris Saint Germain',
        awayTeam: 'Olympique Marseille',
        league: 'Ligue 1',
        pick: 'PSG Win',
        odds: 1.70,
        confidence: 80,
        analysis: 'PSG dominant at home. Marseille conceded 12 goals in last 4 away games. '
            'Clear favorite in this matchup.',
        createdAt: DateTime.now(),
      ),
    ];
  }
}