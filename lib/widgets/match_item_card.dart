// lib/widgets/match_item_card.dart

import 'package:flutter/material.dart';
import '../models/match.dart';
import '../theme/app_theme.dart';

class MatchItemCard extends StatelessWidget {
  final Match match;
  final VoidCallback? onTap;

  const MatchItemCard({
    super.key,
    required this.match,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      elevation: 0,
      color: AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        side: BorderSide(color: AppTheme.borderColor(context)),
      ),
      child: InkWell(
        onTap: onTap ?? () => _showMatchDetails(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: AppTheme.spacing12),
              _buildTeamsSection(context),
              if (match.odds != null) ...[
                const SizedBox(height: AppTheme.spacing16),
                _buildOddsSection(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // League badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing8,
            vertical: AppTheme.spacing4,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Text(
            match.league,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        // Status badge
        _buildStatusBadge(context),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (match.isLive) {
      statusColor = AppTheme.dangerColor;
      statusText = 'LIVE';
      statusIcon = Icons.circle;
    } else if (match.isFinished) {
      statusColor = AppTheme.textSecondary(context);
      statusText = 'FT';
      statusIcon = Icons.check_circle;
    } else {
      statusColor = AppTheme.textSecondary(context);
      statusText = match.formattedTime;
      statusIcon = Icons.access_time;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing8,
        vertical: AppTheme.spacing4,
      ),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 12, color: statusColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsSection(BuildContext context) {
    return Row(
      children: [
        // Home Team
        Expanded(
          child: Column(
            children: [
              _buildTeamAvatar(
                context,
                match.homeTeam,
                match.homeTeamLogo,
                AppTheme.primaryColor,
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                match.homeTeam,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary(context),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (match.homeScore != null)
                Text(
                  '${match.homeScore}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
            ],
          ),
        ),
        // VS / Score
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
          child: Column(
            children: [
              Text(
                match.scoreDisplay,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              if (match.isUpcoming)
                Text(
                  match.formattedDate,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
            ],
          ),
        ),
        // Away Team
        Expanded(
          child: Column(
            children: [
              _buildTeamAvatar(
                context,
                match.awayTeam,
                match.awayTeamLogo,
                AppTheme.secondaryColor,
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                match.awayTeam,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary(context),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (match.awayScore != null)
                Text(
                  '${match.awayScore}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamAvatar(
    BuildContext context,
    String teamName,
    String? logoUrl,
    Color fallbackColor,
  ) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: fallbackColor.withOpacity(0.1),
        backgroundImage: NetworkImage(logoUrl),
        onBackgroundImageError: (_, __) {},
        child: const SizedBox(), // Empty child for error state
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: fallbackColor.withOpacity(0.1),
      child: Text(
        teamName.isNotEmpty ? teamName.substring(0, 1).toUpperCase() : '?',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: fallbackColor,
        ),
      ),
    );
  }

  Widget _buildOddsSection(BuildContext context) {
    if (match.odds == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.borderColor(context).withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildOddButton(
            context,
            '1',
            match.odds!.homeWin.toStringAsFixed(2),
            'Home',
          ),
          _buildOddButton(
            context,
            'X',
            match.odds!.draw.toStringAsFixed(2),
            'Draw',
          ),
          _buildOddButton(
            context,
            '2',
            match.odds!.awayWin.toStringAsFixed(2),
            'Away',
          ),
        ],
      ),
    );
  }

  Widget _buildOddButton(
    BuildContext context,
    String label,
    String odd,
    String tooltip,
  ) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.spacing8,
            horizontal: AppTheme.spacing4,
          ),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: AppTheme.borderColor(context),
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                odd,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMatchDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MatchDetailsSheet(match: match),
    );
  }
}

// Match Details Bottom Sheet
class _MatchDetailsSheet extends StatelessWidget {
  final Match match;

  const _MatchDetailsSheet({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderColor(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // League
                  Text(
                    match.league,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Match Title
                  Text(
                    '${match.homeTeam} vs ${match.awayTeam}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Date/Time
                  _buildInfoRow(
                    context,
                    Icons.calendar_today,
                    'Date & Time',
                    match.formattedDate,
                  ),
                  const SizedBox(height: 12),
                  // Status
                  _buildInfoRow(
                    context,
                    Icons.info_outline,
                    'Status',
                    match.status.toUpperCase(),
                  ),
                  if (match.odds != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Betting Odds',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildOddsGrid(context),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOddsGrid(BuildContext context) {
    final odds = match.odds!;
    
    return Column(
      children: [
        _buildOddsRow(context, 'Home Win', odds.homeWin),
        const SizedBox(height: 8),
        _buildOddsRow(context, 'Draw', odds.draw),
        const SizedBox(height: 8),
        _buildOddsRow(context, 'Away Win', odds.awayWin),
        if (odds.over25 != null) ...[
          const SizedBox(height: 8),
          _buildOddsRow(context, 'Over 2.5 Goals', odds.over25!),
        ],
        if (odds.under25 != null) ...[
          const SizedBox(height: 8),
          _buildOddsRow(context, 'Under 2.5 Goals', odds.under25!),
        ],
      ],
    );
  }

  Widget _buildOddsRow(BuildContext context, String label, double odd) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.borderColor(context).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            odd.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}