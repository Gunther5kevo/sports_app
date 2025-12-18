// lib/models/user_stats.dart

class UserStats {
  final String userId;
  final String period; // 'week', 'month', 'all'
  final int totalPredictions;
  final int won;
  final int lost;
  final double winRate;
  final double avgOdds;
  final String profit;
  final List<LeaguePerformance> leaguePerformance;
  final List<RecentResult> recentResults;
  final DateTime updatedAt;

  UserStats({
    required this.userId,
    required this.period,
    required this.totalPredictions,
    required this.won,
    required this.lost,
    required this.winRate,
    required this.avgOdds,
    required this.profit,
    required this.leaguePerformance,
    required this.recentResults,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'period': period,
      'total_predictions': totalPredictions,
      'won': won,
      'lost': lost,
      'win_rate': winRate,
      'avg_odds': avgOdds,
      'profit': profit,
      'league_performance': leaguePerformance.map((l) => l.toJson()).toList(),
      'recent_results': recentResults.map((r) => r.toJson()).toList(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      userId: json['userId'] as String? ?? '',
      period: json['period'] as String? ?? 'week',
      totalPredictions: json['total_predictions'] as int? ?? 0,
      won: json['won'] as int? ?? 0,
      lost: json['lost'] as int? ?? 0,
      winRate: (json['win_rate'] as num?)?.toDouble() ?? 0.0,
      avgOdds: (json['avg_odds'] as num?)?.toDouble() ?? 0.0,
      profit: json['profit'] as String? ?? '+0.0',
      leaguePerformance: (json['league_performance'] as List?)
              ?.map((l) => LeaguePerformance.fromJson(l as Map<String, dynamic>))
              .toList() ?? [],
      recentResults: (json['recent_results'] as List?)
              ?.map((r) => RecentResult.fromJson(r as Map<String, dynamic>))
              .toList() ?? [],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }
}

class LeaguePerformance {
  final String name;
  final int accuracy;
  final int count;

  LeaguePerformance({
    required this.name,
    required this.accuracy,
    required this.count,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'accuracy': accuracy,
      'count': count,
    };
  }

  factory LeaguePerformance.fromJson(Map<String, dynamic> json) {
    return LeaguePerformance(
      name: json['name'] as String,
      accuracy: json['accuracy'] as int,
      count: json['count'] as int,
    );
  }
}

class RecentResult {
  final String match;
  final String pick;
  final bool won;
  final double odds;
  final String date;

  RecentResult({
    required this.match,
    required this.pick,
    required this.won,
    required this.odds,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'match': match,
      'pick': pick,
      'won': won,
      'odds': odds,
      'date': date,
    };
  }

  factory RecentResult.fromJson(Map<String, dynamic> json) {
    return RecentResult(
      match: json['match'] as String,
      pick: json['pick'] as String,
      won: json['won'] as bool,
      odds: (json['odds'] as num).toDouble(),
      date: json['date'] as String,
    );
  }
}