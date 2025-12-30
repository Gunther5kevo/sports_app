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

  Map<String, dynamic>? stats;
  bool isLoading = true;
  String? userId;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        user = userCredential.user;
      }
      
      if (user != null) {
        setState(() {
          userId = user!.uid;
        });
        await _loadStats();
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to authenticate';
        });
      }
    } catch (e) {
      print('❌ Auth error: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Authentication failed';
      });
    }
  }

  Future<void> _loadStats() async {
    if (userId == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'User ID not available';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    try {
      final data = await ApiService.getUserStats(userId!);
      
      if (mounted) {
        setState(() {
          stats = data;
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading stats: $e');
      
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load statistics';
        });
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
            
            if (isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading statistics...'),
                    ],
                  ),
                ),
              )
            
            else if (errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadStats,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
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
                    _buildProfitCard(),
                    const SizedBox(height: 20),
                    _buildStreakCard(),
                    const SizedBox(height: 20),
                    _buildInsightsCard(),
                    const SizedBox(height: 20),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
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
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Performance',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            if (stats != null)
              Text(
                '${stats!['totalPredictions'] ?? 0} predictions tracked',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: 20,
                child: Icon(
                  Icons.analytics_outlined,
                  size: 120,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
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
              value: '${stats!['totalPredictions'] ?? 0}',
              label: 'Total Tips',
              color: AppTheme.primaryColor,
              width: (constraints.maxWidth - 12) / 2,
            ),
            _StatCard(
              icon: Icons.check_circle_outline,
              value: '${stats!['correctPredictions'] ?? 0}',
              label: 'Correct',
              color: AppTheme.successColor,
              width: (constraints.maxWidth - 12) / 2,
            ),
            _StatCard(
              icon: Icons.trending_up,
              value: '${(stats!['winRate'] ?? 0.0).toStringAsFixed(1)}%',
              label: 'Win Rate',
              color: _getWinRateColor(stats!['winRate'] ?? 0.0),
              width: (constraints.maxWidth - 12) / 2,
            ),
            _StatCard(
              icon: Icons.show_chart,
              value: (stats!['averageOdds'] ?? 0.0) > 0 
                  ? '${(stats!['averageOdds'] ?? 0.0).toStringAsFixed(2)}'
                  : 'N/A',
              label: 'Avg Odds',
              color: AppTheme.warningColor,
              width: (constraints.maxWidth - 12) / 2,
            ),
          ],
        );
      },
    );
  }

  Color _getWinRateColor(double winRate) {
    if (winRate >= 70) return AppTheme.successColor;
    if (winRate >= 50) return AppTheme.warningColor;
    return AppTheme.dangerColor;
  }

  Widget _buildWinRateCard() {
    if (stats == null) return const SizedBox();
    
    final totalPredictions = stats!['totalPredictions'] ?? 0;
    final correctPredictions = stats!['correctPredictions'] ?? 0;
    final winRate = stats!['winRate'] ?? 0.0;
    final lost = totalPredictions - correctPredictions;
    
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
                    '${winRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: _getWinRateColor(winRate),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _getWinRateColor(winRate).withOpacity(0.1),
                  side: BorderSide.none,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: totalPredictions > 0 ? (winRate / 100).clamp(0.0, 1.0) : 0.0,
                minHeight: 16,
                backgroundColor: AppTheme.borderColor(context),
                valueColor: AlwaysStoppedAnimation(_getWinRateColor(winRate)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _LegendItem(
                  color: AppTheme.successColor,
                  label: 'Won',
                  value: correctPredictions,
                ),
                const SizedBox(width: 20),
                _LegendItem(
                  color: AppTheme.dangerColor,
                  label: 'Lost',
                  value: lost,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitCard() {
    if (stats == null) return const SizedBox();
    
    final profit = (stats!['totalProfit'] ?? 0.0).toDouble();
    final isProfit = profit >= 0;
    
    return Card(
      elevation: 0,
      color: AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.borderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isProfit ? AppTheme.successColor : AppTheme.dangerColor)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isProfit ? Icons.trending_up : Icons.trending_down,
                color: isProfit ? AppTheme.successColor : AppTheme.dangerColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Profit/Loss',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isProfit ? '+' : ''}${profit.toStringAsFixed(2)} units',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isProfit ? AppTheme.successColor : AppTheme.dangerColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    if (stats == null) return const SizedBox();
    
    final currentStreak = stats!['currentStreak'] ?? 0;
    final bestStreak = stats!['bestStreak'] ?? 0;
    
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
            Text(
              'Winning Streaks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StreakItem(
                    icon: Icons.local_fire_department,
                    value: currentStreak,
                    label: 'Current',
                    color: currentStreak > 0 ? AppTheme.warningColor : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StreakItem(
                    icon: Icons.emoji_events,
                    value: bestStreak,
                    label: 'Best Ever',
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard() {
    if (stats == null) return const SizedBox();
    
    final totalPredictions = stats!['totalPredictions'] ?? 0;
    final winRate = stats!['winRate'] ?? 0.0;
    final profit = (stats!['totalProfit'] ?? 0.0).toDouble();
    
    String insight = _getInsight(totalPredictions, winRate, profit);
    IconData insightIcon = _getInsightIcon(winRate, profit);
    Color insightColor = _getInsightColor(winRate, profit);
    
    return Card(
      elevation: 0,
      color: insightColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: insightColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(insightIcon, color: insightColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Insight',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: insightColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInsight(int total, double winRate, double profit) {
    if (total == 0) {
      return 'Start tracking predictions to see your performance insights!';
    } else if (total < 10) {
      return 'Keep tracking! You need at least 10 predictions for reliable statistics.';
    } else if (winRate >= 70 && profit > 0) {
      return 'Excellent performance! You\'re consistently making profitable predictions.';
    } else if (winRate >= 60) {
      return 'Great win rate! Focus on higher odds to maximize your profits.';
    } else if (winRate >= 50) {
      return 'Good progress! Analyze your losing predictions to improve further.';
    } else {
      return 'Keep learning! Review your strategy and focus on quality over quantity.';
    }
  }

  IconData _getInsightIcon(double winRate, double profit) {
    if (winRate >= 70 && profit > 0) return Icons.star;
    if (winRate >= 60) return Icons.trending_up;
    if (winRate >= 50) return Icons.lightbulb_outline;
    return Icons.school;
  }

  Color _getInsightColor(double winRate, double profit) {
    if (winRate >= 70 && profit > 0) return AppTheme.successColor;
    if (winRate >= 60) return AppTheme.primaryColor;
    if (winRate >= 50) return AppTheme.warningColor;
    return Colors.blue;
  }

  Widget _buildQuickActions() {
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
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            _ActionButton(
              icon: Icons.refresh,
              label: 'Refresh Statistics',
              onTap: _loadStats,
            ),
            const SizedBox(height: 8),
            _ActionButton(
              icon: Icons.add_circle_outline,
              label: 'Record New Result',
              onTap: _showRecordResultDialog,
            ),
            const SizedBox(height: 8),
            _ActionButton(
              icon: Icons.delete_outline,
              label: 'Reset Statistics',
              onTap: _showResetConfirmation,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordResultDialog() {
    if (userId == null) return;
    
    showDialog(
      context: context,
      builder: (context) => _RecordResultDialog(userId: userId!),
    ).then((_) => _loadStats());
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Statistics?'),
        content: const Text(
          'This will permanently delete all your tracked predictions and statistics. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (userId != null) {
                await ApiService.updateUserStats(userId!, {
                  'totalPredictions': 0,
                  'correctPredictions': 0,
                  'winRate': 0.0,
                  'totalProfit': 0.0,
                  'currentStreak': 0,
                  'bestStreak': 0,
                  'averageOdds': 0.0,
                });
                _loadStats();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Statistics reset successfully')),
                  );
                }
              }
            },
            child: Text(
              'Reset',
              style: TextStyle(color: AppTheme.dangerColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== RECORD RESULT DIALOG ====================

class _RecordResultDialog extends StatefulWidget {
  final String userId;

  const _RecordResultDialog({required this.userId});

  @override
  State<_RecordResultDialog> createState() => _RecordResultDialogState();
}

class _RecordResultDialogState extends State<_RecordResultDialog> {
  final _oddsController = TextEditingController(text: '2.00');
  final _stakeController = TextEditingController(text: '10.0');
  bool isCorrect = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Prediction Result'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Won'),
                  selected: isCorrect,
                  onSelected: (selected) => setState(() => isCorrect = true),
                  selectedColor: AppTheme.successColor.withOpacity(0.2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Lost'),
                  selected: !isCorrect,
                  onSelected: (selected) => setState(() => isCorrect = false),
                  selectedColor: AppTheme.dangerColor.withOpacity(0.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _oddsController,
            decoration: const InputDecoration(
              labelText: 'Odds',
              border: OutlineInputBorder(),
              prefixText: '@',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stakeController,
            decoration: const InputDecoration(
              labelText: 'Stake (units)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final odds = double.tryParse(_oddsController.text) ?? 2.0;
            final stake = double.tryParse(_stakeController.text) ?? 10.0;
            
            await ApiService.recordPredictionResult(
              userId: widget.userId,
              isCorrect: isCorrect,
              odds: odds,
              stake: stake,
            );
            
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isCorrect ? 'Win recorded! 🎉' : 'Loss recorded'),
                  backgroundColor: isCorrect ? AppTheme.successColor : AppTheme.dangerColor,
                ),
              );
            }
          },
          child: const Text('Record'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _oddsController.dispose();
    _stakeController.dispose();
    super.dispose();
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

class _StreakItem extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _StreakItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppTheme.dangerColor : AppTheme.primaryColor;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderColor(context)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? color : AppTheme.textPrimary(context),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textSecondary(context),
            ),
          ],
        ),
      ),
    );
  }
}