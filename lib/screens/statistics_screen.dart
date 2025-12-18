// lib/screens/statistics_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  String selectedPeriod = 'week';
  Map<String, dynamic>? stats;
  bool isLoading = true;
  String? userId;

  static const periodLabels = {
    'week': 'This Week',
    'month': 'This Month',
    'all': 'All Time',
  };

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    // Get current user (or create anonymous user)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
    } else {
      // Sign in anonymously for demo purposes
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      userId = userCredential.user?.uid;
    }
    
    if (mounted) {
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    if (userId == null) {
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);
    
    try {
      final data = await ApiService.getUserStats(
        userId: userId!,
        period: selectedPeriod,
      );
      
      if (mounted) {
        setState(() {
          stats = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load stats: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            SliverToBoxAdapter(child: _buildPeriodSelector()),
            if (isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (userId == null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Please sign in to view statistics',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (stats != null) ...[
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStatsGrid(),
                    const SizedBox(height: 20),
                    _buildWinRateCard(),
                    const SizedBox(height: 20),
                    if ((stats!['league_performance'] as List).isNotEmpty)
                      _buildLeaguePerformance(),
                    if ((stats!['league_performance'] as List).isNotEmpty)
                      const SizedBox(height: 20),
                    if ((stats!['recent_results'] as List).isNotEmpty)
                      _buildRecentResults(),
                  ]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Performance', style: TextStyle(fontWeight: FontWeight.bold)),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: periodLabels.entries.map((entry) {
          final selected = selectedPeriod == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) {
                setState(() => selectedPeriod = entry.key);
                _loadStats();
              },
              backgroundColor: AppTheme.cardColor(context),
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? Colors.white : AppTheme.textPrimary(context),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (stats == null) return const SizedBox();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(
              icon: Icons.lightbulb_outline,
              value: '${stats!['total_predictions'] ?? 0}',
              label: 'Predictions',
              color: AppTheme.primaryColor,
              width: (constraints.maxWidth - 12) / 2,
            ),
            _StatCard(
              icon: Icons.trending_up,
              value: '${stats!['win_rate'] ?? 0}%',
              label: 'Win Rate',
              color: AppTheme.successColor,
              width: (constraints.maxWidth - 12) / 2,
            ),
            _StatCard(
              icon: Icons.check_circle_outline,
              value: '${stats!['won'] ?? 0}',
              label: 'Won',
              color: AppTheme.successColor,
              width: (constraints.maxWidth - 12) / 2,
            ),
            _StatCard(
              icon: Icons.cancel_outlined,
              value: '${stats!['lost'] ?? 0}',
              label: 'Lost',
              color: AppTheme.dangerColor,
              width: (constraints.maxWidth - 12) / 2,
            ),
            _StatCard(
              icon: Icons.show_chart,
              value: '${stats!['avg_odds'] ?? 0.0}',
              label: 'Avg Odds',
              color: AppTheme.warningColor,
              width: (constraints.maxWidth - 12) / 2,
            ),
            _StatCard(
              icon: Icons.account_balance_wallet_outlined,
              value: '${stats!['profit'] ?? '+0.0'}',
              label: 'Profit',
              color: (stats!['profit']?.toString() ?? '+0.0').startsWith('+')
                  ? AppTheme.successColor
                  : AppTheme.dangerColor,
              width: (constraints.maxWidth - 12) / 2,
            ),
          ],
        );
      },
    );
  }

  Widget _buildWinRateCard() {
    if (stats == null) return const SizedBox();
    
    final winRate = stats!['win_rate'] ?? 0;
    
    return Card(
      elevation: 0,
      color: AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.borderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Win Rate Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                Chip(
                  label: Text(
                    '$winRate%',
                    style: const TextStyle(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: AppTheme.successColor.withOpacity(0.1),
                  side: BorderSide.none,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (winRate / 100).clamp(0.0, 1.0),
                minHeight: 16,
                backgroundColor: AppTheme.borderColor(context),
                valueColor: const AlwaysStoppedAnimation(AppTheme.successColor),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _LegendItem(
                  color: AppTheme.successColor,
                  label: 'Won',
                  value: stats!['won'] ?? 0,
                ),
                const SizedBox(width: 20),
                _LegendItem(
                  color: AppTheme.dangerColor,
                  label: 'Lost',
                  value: stats!['lost'] ?? 0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaguePerformance() {
    final leagues = stats!['league_performance'] as List;
    if (leagues.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'League Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary(context),
            ),
          ),
        ),
        ...leagues.map((league) => _LeagueRow(league: league)),
      ],
    );
  }

  Widget _buildRecentResults() {
    final results = stats!['recent_results'] as List;
    if (results.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(context),
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.history, size: 16),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...results.map((result) => _ResultRow(result: result)),
      ],
    );
  }
}

// ==================== REUSABLE COMPONENTS ====================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final double width;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ($value)',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _LeagueRow extends StatelessWidget {
  final Map<String, dynamic> league;

  const _LeagueRow({required this.league});

  @override
  Widget build(BuildContext context) {
    final accuracy = league['accuracy'] ?? 0;
    final color = accuracy >= 70
        ? AppTheme.successColor
        : accuracy >= 60
            ? AppTheme.warningColor
            : AppTheme.dangerColor;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    league['name'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${league['count']} predictions',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$accuracy%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final Map<String, dynamic> result;

  const _ResultRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final won = result['won'] ?? false;
    final color = won ? AppTheme.successColor : AppTheme.dangerColor;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                won ? Icons.check_rounded : Icons.close_rounded,
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result['match'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${result['pick']} • @${result['odds']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Chip(
                  label: Text(
                    won ? 'Won' : 'Lost',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  backgroundColor: color.withOpacity(0.1),
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(height: 4),
                Text(
                  result['date'],
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}