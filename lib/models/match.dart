// lib/models/match.dart

class Match {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final String league;
  final DateTime dateTime;
  final String? homeTeamLogo;
  final String? awayTeamLogo;
  final MatchOdds odds;
  final String? status; // 'upcoming', 'live', 'finished'

  Match({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.league,
    required this.dateTime,
    this.homeTeamLogo,
    this.awayTeamLogo,
    required this.odds,
    this.status = 'upcoming',
  });

  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  String get formattedTime {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] ?? '',
      homeTeam: json['homeTeam'] ?? '',
      awayTeam: json['awayTeam'] ?? '',
      league: json['league'] ?? '',
      dateTime: DateTime.parse(json['dateTime']),
      homeTeamLogo: json['homeTeamLogo'],
      awayTeamLogo: json['awayTeamLogo'],
      odds: MatchOdds.fromJson(json['odds'] ?? {}),
      status: json['status'] ?? 'upcoming',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'league': league,
      'dateTime': dateTime.toIso8601String(),
      'homeTeamLogo': homeTeamLogo,
      'awayTeamLogo': awayTeamLogo,
      'odds': odds.toJson(),
      'status': status,
    };
  }
}

class MatchOdds {
  final double homeWin;
  final double draw;
  final double awayWin;
  final double? over25;
  final double? under25;
  final double? bothTeamsScore;

  MatchOdds({
    required this.homeWin,
    required this.draw,
    required this.awayWin,
    this.over25,
    this.under25,
    this.bothTeamsScore,
  });

  factory MatchOdds.fromJson(Map<String, dynamic> json) {
    return MatchOdds(
      homeWin: (json['homeWin'] ?? 0.0).toDouble(),
      draw: (json['draw'] ?? 0.0).toDouble(),
      awayWin: (json['awayWin'] ?? 0.0).toDouble(),
      over25: json['over25']?.toDouble(),
      under25: json['under25']?.toDouble(),
      bothTeamsScore: json['bothTeamsScore']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'homeWin': homeWin,
      'draw': draw,
      'awayWin': awayWin,
      'over25': over25,
      'under25': under25,
      'bothTeamsScore': bothTeamsScore,
    };
  }
}