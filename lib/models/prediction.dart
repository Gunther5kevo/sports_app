// lib/models/prediction.dart

class Prediction {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final String league;
  final String pick;
  final double odds;
  final int confidence;
  final String analysis;
  final DateTime createdAt;

  Prediction({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.league,
    required this.pick,
    required this.odds,
    required this.confidence,
    required this.analysis,
    required this.createdAt,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      id: json['id'] ?? '',
      homeTeam: json['home_team'] ?? json['homeTeam'] ?? '',
      awayTeam: json['away_team'] ?? json['awayTeam'] ?? '',
      league: json['league'] ?? '',
      pick: json['pick'] ?? json['prediction'] ?? '',
      odds: (json['odds'] ?? 0).toDouble(),
      confidence: json['confidence'] ?? 0,
      analysis: json['analysis'] ?? json['description'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'home_team': homeTeam,
      'away_team': awayTeam,
      'league': league,
      'pick': pick,
      'odds': odds,
      'confidence': confidence,
      'analysis': analysis,
      'created_at': createdAt.toIso8601String(),
    };
  }
}