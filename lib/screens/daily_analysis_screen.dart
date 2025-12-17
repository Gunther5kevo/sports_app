// lib/screens/daily_analysis_screen.dart

import 'package:flutter/material.dart';
import '../models/match_analysis.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';
import '../widgets/match_card.dart';
import '../widgets/summary_card.dart';

class DailyAnalysisScreen extends StatefulWidget {
  const DailyAnalysisScreen({super.key});

  @override
  State<DailyAnalysisScreen> createState() => _DailyAnalysisScreenState();
}

class _DailyAnalysisScreenState extends State<DailyAnalysisScreen> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  bool isLoading = true;
  DateTime selectedDate = DateTime.now();
  List<MatchAnalysis> analyses = [];

  @override
  void initState() {
    super.initState();
    _loadAnalyses();
  }

  Future<void> _loadAnalyses() async {
    setState(() => isLoading = true);
    
    try {
      // TODO: Replace with actual API call
      // final fetchedAnalyses = await ApiService.getMatchAnalyses(selectedDate);
      
      // Simulated data for demonstration
      await Future.delayed(const Duration(seconds: 1));
      
      final mockAnalyses = [
        MatchAnalysis(
          match: 'Manchester City vs Liverpool',
          league: 'Premier League',
          recommendedBet: 'Over 2.5 Goals',
          odds: '1.85',
          estimatedProbability: '65%',
          confidenceLevel: AppConstants.confidenceHigh,
          reasoning: [
            'Both teams averaging 2.8+ goals per match',
            'Last 5 meetings had over 3 goals',
            'Man City\'s home attack is strong (90% scoring rate)',
            'Liverpool conceded in 7 of last 8 away games',
          ],
        ),
        MatchAnalysis(
          match: 'Bayern Munich vs Borussia Dortmund',
          league: 'Bundesliga',
          recommendedBet: 'Bayern Win',
          odds: '1.70',
          estimatedProbability: '72%',
          confidenceLevel: AppConstants.confidenceHigh,
          reasoning: [
            'Bayern unbeaten in last 10 home matches',
            'Dortmund missing 3 key defenders',
            'Bayern won 8 of last 10 Der Klassiker matches',
            'Home advantage: Bayern 85% win rate at Allianz Arena',
          ],
        ),
        MatchAnalysis(
          match: 'Real Madrid vs Barcelona',
          league: 'La Liga',
          recommendedBet: 'Both Teams To Score',
          odds: '1.65',
          estimatedProbability: '68%',
          confidenceLevel: AppConstants.confidenceMedium,
          reasoning: [
            'El Clasico historically high-scoring fixture',
            'Both teams scored in 9 of last 12 meetings',
            'Real Madrid: Strong home attack',
            'Barcelona: Scored in every away La Liga match this season',
          ],
        ),
        MatchAnalysis(
          match: 'PSG vs Olympique Marseille',
          league: 'Ligue 1',
          recommendedBet: AppConstants.noBetRecommended,
          odds: '-',
          estimatedProbability: '-',
          confidenceLevel: AppConstants.confidenceLow,
          reasoning: [
            'High-risk derby match with unpredictable outcomes',
            'Recent form inconsistent for both teams',
            'Key players injured on both sides',
            'Historical data shows volatile results',
          ],
        ),
        MatchAnalysis(
          match: 'Chelsea vs Arsenal',
          league: 'Premier League',
          recommendedBet: 'Draw',
          odds: '3.20',
          estimatedProbability: '32%',
          confidenceLevel: AppConstants.confidenceMedium,
          reasoning: [
            'Last 4 meetings ended in draws',
            'Both teams evenly matched this season',
            'Similar defensive records',
            'Derby atmosphere tends to neutralize home advantage',
          ],
        ),
      ];
      
      if (mounted) {
        setState(() {
          analyses = mockAnalyses;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load analyses: $e'),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _loadAnalyses();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (isLoading)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: AppTheme.spacing16),
                    Text(AppConstants.loadingMessage),
                  ],
                ),
              ),
            )
          else if (analyses.isEmpty)
            _buildEmptyState()
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: SummaryCard(analyses: analyses),
              ),
            ),
            _buildAnalysesList(),
          ],
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          AppConstants.dailyAnalysisTitle,
          style: AppTheme.heading3.copyWith(color: Colors.white),
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
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.white70, size: 16),
                      const SizedBox(width: AppTheme.spacing8),
                      Text(
                        AppConstants.appTagline,
                        style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    _getFormattedDate(),
                    style: AppTheme.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today),
          tooltip: AppConstants.selectDateTooltip,
          onPressed: _selectDate,
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: AppConstants.refreshTooltip,
          onPressed: isLoading ? null : _loadAnalyses,
        ),
        const SizedBox(width: AppTheme.spacing8),
      ],
    );
  }

  Widget _buildAnalysesList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => MatchCard(analysis: analyses[index]),
          childCount: analyses.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_soccer_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              AppConstants.noMatchesAvailable,
              style: AppTheme.heading3.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              AppConstants.checkBackLater,
              style: AppTheme.bodyMedium.copyWith(color: Colors.grey.shade500),
            ),
            const SizedBox(height: AppTheme.spacing24),
            ElevatedButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_today),
              label: const Text('Select Different Date'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing20,
                  vertical: AppTheme.spacing12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFormattedDate() {
    final now = selectedDate;
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final today = DateTime.now();
    if (now.year == today.year && 
        now.month == today.month && 
        now.day == today.day) {
      return 'Today, ${months[now.month - 1]} ${now.day}';
    }
    
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}