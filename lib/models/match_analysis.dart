// lib/models/match_analysis.dart

import '../constants/app_constants.dart';

class MatchAnalysis {
  final String match;
  final String league;
  final String recommendedBet;
  final String odds;
  final String estimatedProbability;
  final String confidenceLevel;
  final List<String> reasoning;

  MatchAnalysis({
    required this.match,
    required this.league,
    required this.recommendedBet,
    required this.odds,
    required this.estimatedProbability,
    required this.confidenceLevel,
    required this.reasoning,
  });

  bool get hasRecommendation => recommendedBet != AppConstants.noBetRecommended;

  factory MatchAnalysis.fromJson(Map<String, dynamic> json) {
    return MatchAnalysis(
      match: json['match'] as String,
      league: json['league'] as String,
      recommendedBet: json['recommended_bet'] as String,
      odds: json['odds'] as String,
      estimatedProbability: json['estimated_probability'] as String,
      confidenceLevel: json['confidence_level'] as String,
      reasoning: (json['reasoning'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'match': match,
      'league': league,
      'recommended_bet': recommendedBet,
      'odds': odds,
      'estimated_probability': estimatedProbability,
      'confidence_level': confidenceLevel,
      'reasoning': reasoning,
    };
  }

  @override
  String toString() {
    return 'MatchAnalysis(match: $match, league: $league, recommendedBet: $recommendedBet)';
  }
}