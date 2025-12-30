// lib/screens/matches_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/match.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> 
    with AutomaticKeepAliveClientMixin {
  List<Match> matches = [];
  bool isLoading = true;
  String selectedLeague = 'All Leagues';
  String selectedStatus = 'All';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => isLoading = true);
    
    try {
      final fetchedMatches = await ApiService.getTodayMatches();
      if (mounted) {
        setState(() {
          matches = fetchedMatches;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  List<Match> get filteredMatches {
    var filtered = matches;
    
    // Filter by league
    if (selectedLeague != 'All Leagues') {
      filtered = filtered.where((m) => m.league == selectedLeague).toList();
    }
    
    // Filter by status
    if (selectedStatus != 'All') {
      filtered = filtered.where((m) => m.status == selectedStatus.toLowerCase()).toList();
    }
    
    return filtered;
  }

  Set<String> get availableLeagues {
    // Get unique leagues and sort by priority
    final leagues = matches.map((m) => m.league).toSet().toList();
    leagues.sort((a, b) {
      final priorityA = _getLeaguePriority(a);
      final priorityB = _getLeaguePriority(b);
      return priorityA.compareTo(priorityB);
    });
    return {'All Leagues', ...leagues};
  }

  int _getLeaguePriority(String league) {
    final priorities = {
      'Premier League': 1, 'La Liga': 2, 'Bundesliga': 3,
      'Serie A': 4, 'Ligue 1': 5, 'Champions League': 6,
      'Europa League': 7, 'Conference League': 8,
    };
    return priorities[league] ?? 999;
  }

  Map<String, int> get statusCounts {
    return {
      'All': matches.length,
      'Upcoming': matches.where((m) => m.isUpcoming).length,
      'Live': matches.where((m) => m.isLive).length,
      'Finished': matches.where((m) => m.isFinished).length,
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        title: const Text(
          'Matches',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isLoading ? Icons.hourglass_empty : Icons.refresh,
              color: Colors.white,
            ),
            onPressed: isLoading ? null : _loadMatches,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(isDark),
          _buildStatusTabs(isDark),
          _buildLeagueFilter(isDark),
          Expanded(
            child: isLoading
                ? _buildLoadingState()
                : filteredMatches.isEmpty
                    ? _buildEmptyState(isDark)
                    : _buildMatchesList(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppTheme.darkSurface, AppTheme.darkCard]
              : [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppTheme.primaryColor).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isDark ? 0.1 : 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sports_soccer,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live Matches',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${matches.length} fixtures • ${availableLeagues.length - 1} leagues',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs(bool isDark) {
    final statuses = ['All', 'Upcoming', 'Live', 'Finished'];
    
    return Container(
      height: 45,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = statuses[index];
          final count = statusCounts[status] ?? 0;
          final isSelected = selectedStatus == status;
          
          return GestureDetector(
            onTap: () => setState(() => selectedStatus = status),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppTheme.accentColor : AppTheme.primaryColor)
                    : (isDark ? AppTheme.darkCard : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? AppTheme.accentColor : AppTheme.primaryColor)
                      : (isDark ? AppTheme.darkCard : Colors.grey.shade300),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.2)
                          : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeagueFilter(bool isDark) {
    final leagues = availableLeagues.toList();
    
    return Container(
      height: 45,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: leagues.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final league = leagues[index];
          final isSelected = selectedLeague == league;
          
          return GestureDetector(
            onTap: () => setState(() => selectedLeague = league),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppTheme.secondaryColor : AppTheme.primaryColor.withOpacity(0.1))
                    : (isDark ? AppTheme.darkCard : Colors.white),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? AppTheme.secondaryColor : AppTheme.primaryColor)
                      : (isDark ? AppTheme.darkCard : Colors.grey.shade300),
                  width: 1.5,
                ),
              ),
              child: Text(
                league,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : AppTheme.primaryColor)
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMatchesList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredMatches.length,
      itemBuilder: (context, index) {
        final match = filteredMatches[index];
        return _MatchCard(
          match: match,
          isDark: isDark,
          onTap: () => _showMatchDetails(match, isDark),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading matches...',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_soccer_outlined,
            size: 64,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Matches Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different filter',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                selectedLeague = 'All Leagues';
                selectedStatus = 'All';
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppTheme.accentColor : AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMatchDetails(Match match, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => _MatchDetailsDialog(match: match, isDark: isDark),
    );
  }
}

// ==================== MATCH CARD ====================

class _MatchCard extends StatelessWidget {
  final Match match;
  final bool isDark;
  final VoidCallback onTap;

  const _MatchCard({
    required this.match,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isDark ? AppTheme.darkCard : Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildTeams(),
            if (match.odds != null) ...[
              const SizedBox(height: 12),
              _buildOdds(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final statusColor = _getStatusColor();
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark 
                ? AppTheme.primaryColor.withOpacity(0.2)
                : AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark
                  ? AppTheme.primaryColor.withOpacity(0.4)
                  : AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Text(
            match.league,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.accentColor : AppTheme.primaryColor,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: statusColor, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getStatusIcon(), size: 12, color: statusColor),
              const SizedBox(width: 4),
              Text(
                match.status.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          DateFormat('HH:mm').format(match.dateTime),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTeams() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                match.homeTeam,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                match.awayTeam,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (match.homeScore != null && match.awayScore != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.accentColor.withOpacity(0.2)
                  : AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  '${match.homeScore}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${match.awayScore}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            'vs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
          ),
      ],
    );
  }

  Widget _buildOdds() {
    final odds = match.odds!;
    final isFinished = match.isFinished;
    
    // Determine winning outcome if finished
    String? winningOutcome;
    if (isFinished && match.homeScore != null && match.awayScore != null) {
      if (match.homeScore! > match.awayScore!) {
        winningOutcome = 'home';
      } else if (match.awayScore! > match.homeScore!) {
        winningOutcome = 'away';
      } else {
        winningOutcome = 'draw';
      }
    }
    
    return Row(
      children: [
        Expanded(
          child: _OddsChip(
            label: 'Home',
            odds: odds.homeWin,
            isDark: isDark,
            isWinner: winningOutcome == 'home',
            isFinished: isFinished,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _OddsChip(
            label: 'Draw',
            odds: odds.draw,
            isDark: isDark,
            isWinner: winningOutcome == 'draw',
            isFinished: isFinished,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _OddsChip(
            label: 'Away',
            odds: odds.awayWin,
            isDark: isDark,
            isWinner: winningOutcome == 'away',
            isFinished: isFinished,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (match.status) {
      case 'live':
        return AppTheme.successColor;
      case 'finished':
        return Colors.grey;
      case 'cancelled':
        return AppTheme.dangerColor;
      default:
        return isDark ? AppTheme.accentColor : AppTheme.primaryColor;
    }
  }

  IconData _getStatusIcon() {
    switch (match.status) {
      case 'live':
        return Icons.play_circle_filled;
      case 'finished':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }
}

// ==================== ODDS CHIP ====================

class _OddsChip extends StatelessWidget {
  final String label;
  final double odds;
  final bool isDark;
  final bool isWinner;
  final bool isFinished;

  const _OddsChip({
    required this.label,
    required this.odds,
    required this.isDark,
    required this.isWinner,
    required this.isFinished,
  });

  @override
  Widget build(BuildContext context) {
    final winnerColor = AppTheme.successColor;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isWinner
            ? winnerColor.withOpacity(0.2)
            : isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWinner
              ? winnerColor
              : isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.shade300,
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
              color: isWinner
                  ? winnerColor
                  : isDark
                      ? Colors.white70
                      : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isWinner)
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: winnerColor,
                ),
              if (isWinner) const SizedBox(width: 4),
              Text(
                odds.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isWinner
                      ? winnerColor
                      : isDark
                          ? Colors.white
                          : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== MATCH DETAILS DIALOG ====================

class _MatchDetailsDialog extends StatelessWidget {
  final Match match;
  final bool isDark;

  const _MatchDetailsDialog({
    required this.match,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Match Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'League', value: match.league),
            const Divider(height: 24),
            Text(
              '${match.homeTeam} vs ${match.awayTeam}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Date & Time',
              value: DateFormat('dd MMM yyyy, HH:mm').format(match.dateTime),
            ),
            const SizedBox(height: 8),
            _DetailRow(
              label: 'Status',
              value: match.status.toUpperCase(),
            ),
            if (match.homeScore != null && match.awayScore != null) ...[
              const SizedBox(height: 8),
              _DetailRow(
                label: 'Score',
                value: '${match.homeScore} - ${match.awayScore}',
              ),
            ],
            if (match.odds != null) ...[
              const Divider(height: 24),
              const Text(
                'Betting Odds',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Home Win',
                value: match.odds!.homeWin.toStringAsFixed(2),
              ),
              const SizedBox(height: 8),
              _DetailRow(
                label: 'Draw',
                value: match.odds!.draw.toStringAsFixed(2),
              ),
              const SizedBox(height: 8),
              _DetailRow(
                label: 'Away Win',
                value: match.odds!.awayWin.toStringAsFixed(2),
              ),
              if (match.odds!.over25 != null) ...[
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'Over 2.5',
                  value: match.odds!.over25!.toStringAsFixed(2),
                ),
              ],
              if (match.odds!.under25 != null) ...[
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'Under 2.5',
                  value: match.odds!.under25!.toStringAsFixed(2),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}