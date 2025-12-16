// lib/screens/daily_analysis_screen.dart

import 'package:flutter/material.dart';
import '../models/match_analysis.dart';
import '../widgets/match_card.dart';
import '../widgets/summary_card.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';

class DailyAnalysisScreen extends StatefulWidget {
  const DailyAnalysisScreen({super.key});

  @override
  State<DailyAnalysisScreen> createState() => _DailyAnalysisScreenState();
}

class _DailyAnalysisScreenState extends State<DailyAnalysisScreen> {
  List<MatchAnalysis> analyses = [];
  bool isLoading = false;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAnalyses();
  }

  void _loadAnalyses() {
    setState(() {
      isLoading = true;
    });

    // Simulate API call delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        analyses = _getSampleData();
        isLoading = false;
      });
    });
  }

  List<MatchAnalysis> _getSampleData() {
    return [
      MatchAnalysis(
        match: 'Manchester City vs Liverpool',
        league: 'Premier League',
        recommendedBet: 'Over 2.5 Goals',
        marketType: 'Goals',
        odds: '1.85',
        estimatedProbability: '58%',
        confidenceLevel: AppConstants.confidenceHigh,
        reasoning: [
          'Both teams averaging 3.2 goals per game in last 5 matches',
          'Historical head-to-head shows 7 of last 8 meetings had 3+ goals',
          'Both teams strong in attack, City scored in 15 consecutive games',
        ],
      ),
      MatchAnalysis(
        match: 'Real Madrid vs Barcelona',
        league: 'La Liga',
        recommendedBet: AppConstants.noBetRecommended,
        reasoning: [
          'Odds do not present sufficient value based on available data',
          'Both teams inconsistent form in recent weeks',
          'Too many variables in El Clásico to predict reliably',
        ],
      ),
      MatchAnalysis(
        match: 'Bayern Munich vs Dortmund',
        league: 'Bundesliga',
        recommendedBet: 'Bayern Munich to Win',
        marketType: 'Match Winner',
        odds: '1.70',
        estimatedProbability: '65%',
        confidenceLevel: AppConstants.confidenceMedium,
        reasoning: [
          'Bayern unbeaten at home this season (12 wins, 2 draws)',
          'Dortmund lost 3 of last 4 away matches',
          'Bayern won 4 of last 5 head-to-head meetings',
        ],
      ),
    ];
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2025, 12, 31),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _loadAnalyses();
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(theme),
          Expanded(
            child: isLoading
                ? _buildLoadingState()
                : analyses.isEmpty
                ? _buildEmptyState(theme)
                : _buildAnalysisList(),
          ),
          SummaryCard(analyses: analyses),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        AppConstants.dailyAnalysisTitle,
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _selectDate(context),
          tooltip: AppConstants.selectDateTooltip,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadAnalyses,
          tooltip: AppConstants.refreshTooltip,
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.radiusXLarge),
          bottomRight: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(selectedDate),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: AppTheme.spacing4),
          const Text(
            AppConstants.appTagline,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildAnalysisList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: analyses.length,
      itemBuilder: (context, index) {
        return MatchCard(analysis: analyses[index]);
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_soccer,
            size: 80,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            AppConstants.noMatchesAvailable,
            style: AppTheme.heading3.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            AppConstants.checkBackLater,
            style: AppTheme.bodyMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
