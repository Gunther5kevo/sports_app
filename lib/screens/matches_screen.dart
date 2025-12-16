// lib/screens/matches_screen.dart

import 'package:flutter/material.dart';
import '../models/match.dart';
import '../theme/app_theme.dart';
import '../widgets/match_item_card.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<Match> matches = [];
  bool isLoading = false;
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  void _loadMatches() {
    setState(() {
      isLoading = true;
    });

    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        matches = _getSampleMatches();
        isLoading = false;
      });
    });
  }

  List<Match> _getSampleMatches() {
    final now = DateTime.now();
    return [
      Match(
        id: '1',
        homeTeam: 'Manchester City',
        awayTeam: 'Liverpool',
        league: 'Premier League',
        dateTime: now.add(const Duration(hours: 3)),
        odds: MatchOdds(
          homeWin: 2.10,
          draw: 3.40,
          awayWin: 3.20,
          over25: 1.65,
          under25: 2.20,
        ),
      ),
      Match(
        id: '2',
        homeTeam: 'Real Madrid',
        awayTeam: 'Barcelona',
        league: 'La Liga',
        dateTime: now.add(const Duration(hours: 5)),
        odds: MatchOdds(
          homeWin: 2.30,
          draw: 3.20,
          awayWin: 2.90,
          over25: 1.75,
          under25: 2.05,
        ),
      ),
      Match(
        id: '3',
        homeTeam: 'Bayern Munich',
        awayTeam: 'Dortmund',
        league: 'Bundesliga',
        dateTime: now.add(const Duration(hours: 4)),
        odds: MatchOdds(
          homeWin: 1.85,
          draw: 3.60,
          awayWin: 3.80,
          over25: 1.55,
          under25: 2.35,
        ),
      ),
      Match(
        id: '4',
        homeTeam: 'PSG',
        awayTeam: 'Marseille',
        league: 'Ligue 1',
        dateTime: now.add(const Duration(hours: 6)),
        odds: MatchOdds(
          homeWin: 1.70,
          draw: 3.80,
          awayWin: 4.50,
          over25: 1.60,
          under25: 2.25,
        ),
      ),
    ];
  }

  List<Match> get filteredMatches {
    if (selectedFilter == 'All') return matches;
    return matches.where((m) => m.league == selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Today\'s Matches',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMatches,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateHeader(theme),
          _buildFilterChips(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredMatches.isEmpty
                    ? _buildEmptyState(theme)
                    : _buildMatchesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(ThemeData theme) {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      color: theme.colorScheme.primaryContainer,
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 20,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: AppTheme.spacing8),
          Text(
            'Today, ${now.day} ${months[now.month - 1]} ${now.year}',
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const Spacer(),
          Text(
            '${matches.length} matches',
            style: AppTheme.bodyMedium.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final leagues = ['All', 'Premier League', 'La Liga', 'Bundesliga', 'Ligue 1'];
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
        itemCount: leagues.length,
        itemBuilder: (context, index) {
          final league = leagues[index];
          final isSelected = selectedFilter == league;
          
          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacing8),
            child: FilterChip(
              label: Text(league),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedFilter = league;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMatchesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: filteredMatches.length,
      itemBuilder: (context, index) {
        return MatchItemCard(match: filteredMatches[index]);
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
            'No matches found',
            style: AppTheme.heading3.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    // TODO: Implement filter dialog
  }
}