// lib/widgets/summary_card.dart

import 'package:flutter/material.dart';
import '../models/match_analysis.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';

class SummaryCard extends StatelessWidget {
  final List<MatchAnalysis> analyses;

  const SummaryCard({
    super.key,
    required this.analyses,
  });

  int get totalMatches => analyses.length;
  
  int get totalBets => analyses
      .where((a) => a.recommendedBet != AppConstants.noBetRecommended)
      .length;

  String get riskLevel {
    if (analyses.isEmpty) return AppConstants.riskLow;
    
    final highConfidenceCount = analyses
        .where((a) => a.confidenceLevel == AppConstants.confidenceHigh)
        .length;
    final mediumConfidenceCount = analyses
        .where((a) => a.confidenceLevel == AppConstants.confidenceMedium)
        .length;

    if (highConfidenceCount >= 2) return AppConstants.riskLow;
    if (mediumConfidenceCount >= 2) return AppConstants.riskMedium;
    return AppConstants.riskHigh;
  }

  Color _getRiskColor() {
    switch (riskLevel) {
      case AppConstants.riskLow:
        return AppTheme.successColor;
      case AppConstants.riskMedium:
        return AppTheme.warningColor;
      case AppConstants.riskHigh:
        return AppTheme.dangerColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (analyses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Summary',
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  AppConstants.totalMatchesAnalyzed,
                  totalMatches.toString(),
                  Icons.sports_soccer,
                  theme,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: _buildSummaryItem(
                  AppConstants.totalBetsRecommended,
                  totalBets.toString(),
                  Icons.recommend,
                  theme,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: _buildRiskItem(theme),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildResponsibleGamblingNotice(theme),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            value,
            style: AppTheme.heading2.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.caption.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskItem(ThemeData theme) {
    final color = _getRiskColor();
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 24,
            color: color,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            riskLevel,
            style: AppTheme.heading2.copyWith(
              color: color,
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            AppConstants.overallRiskLevel,
            textAlign: TextAlign.center,
            style: AppTheme.caption.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsibleGamblingNotice(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              AppConstants.responsibleGamblingNotice,
              style: AppTheme.caption.copyWith(
                color: theme.colorScheme.onErrorContainer,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}