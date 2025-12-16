// lib/widgets/match_card.dart

import 'package:flutter/material.dart';
import '../models/match_analysis.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';

class MatchCard extends StatelessWidget {
  final MatchAnalysis analysis;

  const MatchCard({
    super.key,
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeagueBadge(theme),
            const SizedBox(height: AppTheme.spacing8),
            _buildMatchTitle(),
            const SizedBox(height: AppTheme.spacing16),
            _buildRecommendationSection(theme),
            const SizedBox(height: AppTheme.spacing16),
            _buildReasoningSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildLeagueBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing8,
        vertical: AppTheme.spacing4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        analysis.league,
        style: AppTheme.caption.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMatchTitle() {
    return Text(
      analysis.match,
      style: AppTheme.heading3,
    );
  }

  Widget _buildRecommendationSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: analysis.hasRecommendation
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: analysis.hasRecommendation
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecommendationHeader(theme),
          if (analysis.hasRecommendation) ...[
            const SizedBox(height: AppTheme.spacing12),
            _buildOddsAndProbability(theme),
            const SizedBox(height: AppTheme.spacing8),
            _buildConfidenceChip(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(
          analysis.hasRecommendation ? Icons.check_circle : Icons.block,
          size: 20,
          color: analysis.hasRecommendation
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppTheme.spacing8),
        Expanded(
          child: Text(
            analysis.recommendedBet,
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: analysis.hasRecommendation
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOddsAndProbability(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoChip(
            AppConstants.oddsLabel,
            analysis.odds,
            Icons.trending_up,
            theme,
          ),
        ),
        const SizedBox(width: AppTheme.spacing8),
        Expanded(
          child: _buildInfoChip(
            AppConstants.probabilityLabel,
            analysis.estimatedProbability,
            Icons.analytics,
            theme,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.caption.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceChip(ThemeData theme) {
    final color = AppTheme.getConfidenceColor(analysis.confidenceLevel);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '${AppConstants.confidenceLabel}: ${analysis.confidenceLevel}',
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasoningSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppConstants.analysisLabel,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        ...analysis.reasoning.map((reason) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 16,
                ),
              ),
              Expanded(
                child: Text(
                  reason,
                  style: AppTheme.bodySmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}