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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        side: BorderSide(color: Colors.grey.shade200),
      ),
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
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        analysis.league,
        style: AppTheme.caption.copyWith(
          color: AppTheme.primaryColor,
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
            ? AppTheme.primaryColor.withOpacity(0.08)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: analysis.hasRecommendation
              ? AppTheme.primaryColor.withOpacity(0.3)
              : Colors.grey.shade300,
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
              ? AppTheme.primaryColor
              : Colors.grey.shade600,
        ),
        const SizedBox(width: AppTheme.spacing8),
        Expanded(
          child: Text(
            analysis.recommendedBet,
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: analysis.hasRecommendation
                  ? AppTheme.primaryColor
                  : Colors.grey.shade700,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.caption.copyWith(
                    color: Colors.grey.shade600,
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
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceChip(ThemeData theme) {
    final color = AppTheme.getConfidenceColor(int.parse(analysis.confidenceLevel));

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: color.withOpacity(0.3)),
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
            color: Colors.grey.shade700,
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
                  color: AppTheme.primaryColor,
                  fontSize: 16,
                ),
              ),
              Expanded(
                child: Text(
                  reason,
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.grey.shade700,
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