// lib/screens/statistics_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Statistics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(theme),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsOverview(theme),
                  const SizedBox(height: AppTheme.spacing20),
                  _buildTopLeagues(theme),
                  const SizedBox(height: AppTheme.spacing20),
                  _buildRecentPerformance(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      color: theme.colorScheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'Performance Overview',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Track your prediction accuracy',
            style: AppTheme.bodySmall.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Week',
          style: AppTheme.heading3,
        ),
        const SizedBox(height: AppTheme.spacing12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Predictions',
                '24',
                Icons.lightbulb_outline,
                theme.colorScheme.primary,
                theme,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: _buildStatCard(
                'Success Rate',
                '68%',
                Icons.trending_up,
                AppTheme.successColor,
                theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Won',
                '16',
                Icons.check_circle,
                AppTheme.successColor,
                theme,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: _buildStatCard(
                'Lost',
                '8',
                Icons.cancel,
                AppTheme.dangerColor,
                theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            value,
            style: AppTheme.heading2.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopLeagues(ThemeData theme) {
    final leagues = [
      {'name': 'Premier League', 'accuracy': 72, 'predictions': 8},
      {'name': 'La Liga', 'accuracy': 65, 'predictions': 6},
      {'name': 'Bundesliga', 'accuracy': 70, 'predictions': 5},
      {'name': 'Ligue 1', 'accuracy': 60, 'predictions': 5},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'League Performance',
          style: AppTheme.heading3,
        ),
        const SizedBox(height: AppTheme.spacing12),
        ...leagues.map((league) => _buildLeagueRow(
          league['name'] as String,
          league['accuracy'] as int,
          league['predictions'] as int,
          theme,
        )),
      ],
    );
  }

  Widget _buildLeagueRow(String name, int accuracy, int predictions, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$predictions predictions',
                  style: AppTheme.caption.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing12,
              vertical: AppTheme.spacing4,
            ),
            decoration: BoxDecoration(
              color: _getAccuracyColor(accuracy).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              '$accuracy%',
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: _getAccuracyColor(accuracy),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPerformance(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Results',
          style: AppTheme.heading3,
        ),
        const SizedBox(height: AppTheme.spacing12),
        _buildResultRow('Man City vs Liverpool', 'Over 2.5', true, theme),
        _buildResultRow('Real Madrid vs Barcelona', 'Draw', false, theme),
        _buildResultRow('Bayern vs Dortmund', 'Bayern Win', true, theme),
        _buildResultRow('PSG vs Marseille', 'PSG Win', true, theme),
      ],
    );
  }

  Widget _buildResultRow(String match, String prediction, bool won, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(
            won ? Icons.check_circle : Icons.cancel,
            color: won ? AppTheme.successColor : AppTheme.dangerColor,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  prediction,
                  style: AppTheme.caption.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            won ? 'Won' : 'Lost',
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: won ? AppTheme.successColor : AppTheme.dangerColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAccuracyColor(int accuracy) {
    if (accuracy >= 70) return AppTheme.successColor;
    if (accuracy >= 60) return AppTheme.warningColor;
    return AppTheme.dangerColor;
  }
}