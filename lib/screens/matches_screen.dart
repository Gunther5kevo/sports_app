// lib/screens/matches_screen.dart

import 'package:flutter/material.dart';
import '../models/match.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../constants/app_constants.dart';
import '../widgets/match_item_card.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> with AutomaticKeepAliveClientMixin {
  List<Match> matches = [];
  bool isLoading = true;
  String selectedLeague = 'All Leagues';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load matches: $e'),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<Match> get filteredMatches {
    if (selectedLeague == 'All Leagues') return matches;
    return matches.where((m) => m.league == selectedLeague).toList();
  }

  Set<String> get availableLeagues {
    return {'All Leagues', ...matches.map((m) => m.league)};
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (!isLoading && matches.isNotEmpty)
            SliverToBoxAdapter(child: _buildLeagueFilter()),
          isLoading
              ? const SliverFillRemaining(
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
              : filteredMatches.isEmpty
                  ? _buildEmptyState()
                  : _buildMatchesList(),
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
          'Today\'s Matches',
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
                      Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                      const SizedBox(width: AppTheme.spacing8),
                      Text(
                        _getFormattedDate(),
                        style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    '${matches.length} matches available',
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
          icon: const Icon(Icons.refresh_rounded),
          tooltip: AppConstants.refreshTooltip,
          onPressed: isLoading ? null : _loadMatches,
        ),
        const SizedBox(width: AppTheme.spacing8),
      ],
    );
  }

  Widget _buildLeagueFilter() {
    final leagues = availableLeagues.toList();
    
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
        itemCount: leagues.length,
        itemBuilder: (context, index) {
          final league = leagues[index];
          final selected = selectedLeague == league;
          
          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacing8),
            child: FilterChip(
              label: Text(league),
              selected: selected,
              onSelected: (_) => setState(() => selectedLeague = league),
              backgroundColor: Colors.white,
              selectedColor: AppTheme.primaryColor.withOpacity(0.15),
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? AppTheme.primaryColor : Colors.grey.shade700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                side: BorderSide(
                  color: selected ? AppTheme.primaryColor : Colors.grey.shade300,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMatchesList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => MatchItemCard(match: filteredMatches[index]),
          childCount: filteredMatches.length,
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
            Icon(Icons.sports_soccer_outlined, size: 64, color: Colors.grey.shade300),
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
          ],
        ),
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }
}