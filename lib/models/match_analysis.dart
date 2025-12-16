// lib/models/match_analysis.dart

class MatchAnalysis {
  final String match;
  final String league;
  final String recommendedBet;
  final String marketType;
  final String odds;
  final String estimatedProbability;
  final String confidenceLevel;
  final List<String> reasoning;
  final DateTime dateAnalyzed;

  MatchAnalysis({
    required this.match,
    required this.league,
    required this.recommendedBet,
    this.marketType = '',
    this.odds = '',
    this.estimatedProbability = '',
    this.confidenceLevel = '',
    required this.reasoning,
    DateTime? dateAnalyzed,
  }) : dateAnalyzed = dateAnalyzed ?? DateTime.now();

  // Check if this analysis has a betting recommendation
  bool get hasRecommendation => recommendedBet != 'No bet recommended';

  // Convert to JSON (for storing/sending data)
  Map<String, dynamic> toJson() {
    return {
      'match': match,
      'league': league,
      'recommendedBet': recommendedBet,
      'marketType': marketType,
      'odds': odds,
      'estimatedProbability': estimatedProbability,
      'confidenceLevel': confidenceLevel,
      'reasoning': reasoning,
      'dateAnalyzed': dateAnalyzed.toIso8601String(),
    };
  }

  // Create from JSON (for receiving data)
  factory MatchAnalysis.fromJson(Map<String, dynamic> json) {
    return MatchAnalysis(
      match: json['match'] ?? '',
      league: json['league'] ?? '',
      recommendedBet: json['recommendedBet'] ?? '',
      marketType: json['marketType'] ?? '',
      odds: json['odds'] ?? '',
      estimatedProbability: json['estimatedProbability'] ?? '',
      confidenceLevel: json['confidenceLevel'] ?? '',
      reasoning: List<String>.from(json['reasoning'] ?? []),
      dateAnalyzed: json['dateAnalyzed'] != null 
          ? DateTime.parse(json['dateAnalyzed'])
          : DateTime.now(),
    );
  }
}