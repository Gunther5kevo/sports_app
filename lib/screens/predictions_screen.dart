// lib/screens/predictions_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({super.key});

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> {
  final List<Prediction> predictions = [
    Prediction(
      homeTeam: 'Manchester City',
      awayTeam: 'Liverpool',
      league: 'Premier League',
      prediction: 'Over 2.5 Goals',
      confidence: 85,
      reasoning: 'Both teams in excellent form, averaging 3+ goals in recent matches',
    ),
    Prediction(
      homeTeam: 'Bayern Munich',
      awayTeam: 'Dortmund',
      league: 'Bundesliga',
      prediction: 'Bayern Win',
      confidence: 72,
      reasoning: 'Bayern unbeaten at home, strong head-to-head record',
    ),
    Prediction(
      homeTeam: 'Real Madrid',
      awayTeam: 'Barcelona',
      league: 'La Liga',
      prediction: 'Both Teams to Score',
      confidence: 68,
      reasoning: 'Both teams have strong attacking records in recent matches',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Expert Predictions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(theme),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              itemCount: predictions.length,
              itemBuilder: (context, index) {
                return _buildPredictionCard(predictions[index], theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      color: theme.colorScheme.primaryContainer,
      child: Row(
        children: [
          Icon(
            Icons.lightbulb,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Top Picks',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  '${predictions.length} predictions available',
                  style: AppTheme.bodySmall.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(Prediction prediction, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // League badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing8,
                vertical: AppTheme.spacing4,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                prediction.league,
                style: AppTheme.caption.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            
            // Teams
            Text(
              '${prediction.homeTeam} vs ${prediction.awayTeam}',
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            
            // Prediction
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppTheme.successColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.successColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Text(
                    prediction.prediction,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            
            // Confidence
            Row(
              children: [
                Text(
                  'Confidence:',
                  style: AppTheme.bodySmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: prediction.confidence / 100,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: _getConfidenceColor(prediction.confidence),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                Text(
                  '${prediction.confidence}%',
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getConfidenceColor(prediction.confidence),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            
            // Reasoning
            Text(
              'Analysis:',
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              prediction.reasoning,
              style: AppTheme.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(int confidence) {
    if (confidence >= 75) return AppTheme.successColor;
    if (confidence >= 60) return AppTheme.warningColor;
    return AppTheme.dangerColor;
  }
}

class Prediction {
  final String homeTeam;
  final String awayTeam;
  final String league;
  final String prediction;
  final int confidence;
  final String reasoning;

  Prediction({
    required this.homeTeam,
    required this.awayTeam,
    required this.league,
    required this.prediction,
    required this.confidence,
    required this.reasoning,
  });
}