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
    if (analyses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'Daily Summary',
                style: AppTheme.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  AppConstants.totalMatchesAnalyzed,
                  totalMatches.toString(),
                  Icons.sports_soccer,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: _buildSummaryItem(
                  AppConstants.totalBetsRecommended,
                  totalBets.toString(),
                  Icons.recommend,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: _buildRiskItem(),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildResponsibleGamblingNotice(),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            value,
            style: AppTheme.heading2.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.caption.copyWith(
              color: Colors.grey.shade600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRiskItem() {
    final color = _getRiskColor();
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: color.withOpacity(0.3),
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
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            AppConstants.overallRiskLevel,
            textAlign: TextAlign.center,
            style: AppTheme.caption.copyWith(
              color: color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildResponsibleGamblingNotice() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: AppTheme.warningColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: AppTheme.warningColor,
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              AppConstants.responsibleGamblingNotice,
              style: AppTheme.caption.copyWith(
                color: Colors.grey.shade800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}