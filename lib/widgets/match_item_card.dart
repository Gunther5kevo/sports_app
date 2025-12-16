// lib/widgets/match_item_card.dart

import 'package:flutter/material.dart';
import '../models/match.dart';
import '../theme/app_theme.dart';

class MatchItemCard extends StatelessWidget {
  final Match match;

  const MatchItemCard({
    super.key,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to match details
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            children: [
              _buildHeader(theme),
              const SizedBox(height: AppTheme.spacing12),
              _buildTeamsSection(theme),
              const SizedBox(height: AppTheme.spacing16),
              _buildOddsSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
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
            match.league,
            style: AppTheme.caption.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        Icon(
          Icons.access_time,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          match.formattedTime,
          style: AppTheme.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamsSection(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  match.homeTeam.substring(0, 1),
                  style: AppTheme.heading3.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                match.homeTeam,
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
          child: Text(
            'VS',
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Text(
                  match.awayTeam.substring(0, 1),
                  style: AppTheme.heading3.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                match.awayTeam,
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOddsSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildOddButton('1', match.odds.homeWin.toStringAsFixed(2), theme),
          _buildOddButton('X', match.odds.draw.toStringAsFixed(2), theme),
          _buildOddButton('2', match.odds.awayWin.toStringAsFixed(2), theme),
        ],
      ),
    );
  }

  Widget _buildOddButton(String label, String odd, ThemeData theme) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTheme.caption.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              odd,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}