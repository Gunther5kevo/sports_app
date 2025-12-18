// lib/models/match.dart

class Match {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final String league;
  final DateTime dateTime;
  final String? homeTeamLogo;
  final String? awayTeamLogo;
  final MatchOdds? odds;
  final String status; // 'upcoming', 'live', 'finished'
  final int? homeScore;
  final int? awayScore;

  Match({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.league,
    required this.dateTime,
    this.homeTeamLogo,
    this.awayTeamLogo,
    this.odds,
    this.status = 'upcoming',
    this.homeScore,
    this.awayScore,
  });

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'league': league,
      'dateTime': dateTime.toIso8601String(),
      'homeTeamLogo': homeTeamLogo,
      'awayTeamLogo': awayTeamLogo,
      'odds': odds?.toJson(),
      'status': status,
      'homeScore': homeScore,
      'awayScore': awayScore,
    };
  }

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as String,
      homeTeam: json['homeTeam'] as String,
      awayTeam: json['awayTeam'] as String,
      league: json['league'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      homeTeamLogo: json['homeTeamLogo'] as String?,
      awayTeamLogo: json['awayTeamLogo'] as String?,
      odds: json['odds'] != null 
          ? MatchOdds.fromJson(json['odds'] as Map<String, dynamic>) 
          : null,
      status: json['status'] as String? ?? 'upcoming',
      homeScore: json['homeScore'] as int?,
      awayScore: json['awayScore'] as int?,
    );
  }

  Match copyWith({
    String? id,
    String? homeTeam,
    String? awayTeam,
    String? league,
    DateTime? dateTime,
    String? homeTeamLogo,
    String? awayTeamLogo,
    MatchOdds? odds,
    String? status,
    int? homeScore,
    int? awayScore,
  }) {
    return Match(
      id: id ?? this.id,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      league: league ?? this.league,
      dateTime: dateTime ?? this.dateTime,
      homeTeamLogo: homeTeamLogo ?? this.homeTeamLogo,
      awayTeamLogo: awayTeamLogo ?? this.awayTeamLogo,
      odds: odds ?? this.odds,
      status: status ?? this.status,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
    );
  }

  // Helper getters
  String get formattedTime {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else if (status == 'live') {
      return 'LIVE';
    } else if (status == 'finished') {
      return 'FT';
    }
    return 'Soon';
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final matchDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (matchDay == today) {
      return 'Today, ${_formatTime(dateTime)}';
    } else if (matchDay == today.add(const Duration(days: 1))) {
      return 'Tomorrow, ${_formatTime(dateTime)}';
    } else {
      return '${_formatDate(dateTime)}, ${_formatTime(dateTime)}';
    }
  }

  String get scoreDisplay {
    if (homeScore != null && awayScore != null) {
      return '$homeScore - $awayScore';
    }
    return 'vs';
  }

  bool get isLive => status == 'live';
  bool get isFinished => status == 'finished';
  bool get isUpcoming => status == 'upcoming';

  static String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}

class MatchOdds {
  final double homeWin;
  final double draw;
  final double awayWin;
  final double? over25;
  final double? under25;
  final double? btts;

  MatchOdds({
    required this.homeWin,
    required this.draw,
    required this.awayWin,
    this.over25,
    this.under25,
    this.btts,
  });

  Map<String, dynamic> toJson() {
    return {
      'homeWin': homeWin,
      'draw': draw,
      'awayWin': awayWin,
      'over25': over25,
      'under25': under25,
      'btts': btts,
    };
  }

  factory MatchOdds.fromJson(Map<String, dynamic> json) {
    return MatchOdds(
      homeWin: (json['homeWin'] as num).toDouble(),
      draw: (json['draw'] as num).toDouble(),
      awayWin: (json['awayWin'] as num).toDouble(),
      over25: json['over25'] != null ? (json['over25'] as num).toDouble() : null,
      under25: json['under25'] != null ? (json['under25'] as num).toDouble() : null,
      btts: json['btts'] != null ? (json['btts'] as num).toDouble() : null,
    );
  }
}