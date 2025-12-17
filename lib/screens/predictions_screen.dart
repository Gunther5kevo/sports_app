// lib/screens/predictions_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../models/prediction.dart';

class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({super.key});

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  List<Prediction> predictions = [];
  bool isLoading = true;
  String selectedFilter = 'All';
  final filters = ['All', 'High Confidence', 'Medium Risk', 'Value Bets'];

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  Future<void> _loadPredictions() async {
    setState(() => isLoading = true);
    
    try {
      final fetchedPredictions = await ApiService.getPredictions();
      if (mounted) {
        setState(() {
          predictions = fetchedPredictions;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load predictions: $e'),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<Prediction> get filteredPredictions {
    if (selectedFilter == 'All') return predictions;
    
    return predictions.where((p) {
      switch (selectedFilter) {
        case 'High Confidence':
          return p.confidence >= 75;
        case 'Medium Risk':
          return p.confidence >= 65 && p.confidence < 75;
        case 'Value Bets':
          return p.odds >= 2.0;
        default:
          return true;
      }
    }).toList();
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
                    Text('Loading predictions...'),
                  ],
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(child: _buildSummaryCard()),
            SliverToBoxAdapter(child: _buildFilterChips()),
            SliverToBoxAdapter(child: _buildResponsibleGamblingNotice()),
            filteredPredictions.isEmpty
                ? _buildEmptyState()
                : _buildPredictionsList(),
          ],
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Match Insights',
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
              child: Row(
                children: [
                  Icon(Icons.analytics_outlined, color: Colors.white70, size: 20),
                  const SizedBox(width: AppTheme.spacing8),
                  Text(
                    'Data-driven predictions',
                    style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
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
          tooltip: 'Refresh',
          onPressed: isLoading ? null : _loadPredictions,
        ),
        const SizedBox(width: AppTheme.spacing8),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final highConfCount = predictions.where((p) => p.confidence >= 75).length;
    final avgConfidence = predictions.isEmpty 
        ? 0 
        : predictions.fold<int>(0, (sum, p) => sum + p.confidence) / predictions.length;
    
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacing16),
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Icon(Icons.lightbulb, color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Insights',
                      style: AppTheme.heading3,
                    ),
                    Text(
                      '${predictions.length} predictions available',
                      style: AppTheme.bodySmall.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing20),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '$highConfCount',
                    'High Confidence',
                    Icons.trending_up,
                    AppTheme.successColor,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                Expanded(
                  child: _buildStatItem(
                    '${avgConfidence.toStringAsFixed(0)}%',
                    'Avg. Confidence',
                    Icons.bar_chart,
                    AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTheme.heading3.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: AppTheme.caption.copyWith(color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacing8),
            child: FilterChip(
              label: Text(filter),
              selected: selected,
              onSelected: (_) => setState(() => selectedFilter = filter),
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

  Widget _buildResponsibleGamblingNotice() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing8,
      ),
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade700, size: 18),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Text(
              AppConstants.responsibleGamblingNotice,
              style: AppTheme.bodySmall.copyWith(
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionsList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildPredictionCard(filteredPredictions[index]),
          childCount: filteredPredictions.length,
        ),
      ),
    );
  }

  Widget _buildPredictionCard(Prediction pred) {
    final confLevel = pred.confidence >= 75 
        ? 'High' 
        : pred.confidence >= 65 
            ? 'Medium' 
            : 'Low';
    final confColor = AppTheme.getConfidenceColor(confLevel);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showPredictionDetails(pred),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text(
                        pred.league,
                        style: AppTheme.caption.copyWith(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          confColor.withOpacity(0.15),
                          confColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(color: confColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.speed, size: 12, color: confColor),
                        const SizedBox(width: 4),
                        Text(
                          '${pred.confidence}%',
                          style: AppTheme.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: confColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                '${pred.homeTeam} vs ${pred.awayTeam}',
                style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.successColor.withOpacity(0.08),
                      AppTheme.successColor.withOpacity(0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: AppTheme.successColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pred.pick,
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          Text(
                            '${AppConstants.oddsLabel}: ${pred.odds.toStringAsFixed(2)}',
                            style: AppTheme.bodySmall.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                pred.analysis,
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
              Icons.analytics_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'No predictions match your filter',
              style: AppTheme.heading3.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Try adjusting your filters',
              style: AppTheme.bodyMedium.copyWith(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  void _showPredictionDetails(Prediction pred) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPredictionDetailsSheet(pred),
    );
  }

  Widget _buildPredictionDetailsSheet(Prediction pred) {
    final confLevel = pred.confidence >= 75 
        ? 'High' 
        : pred.confidence >= 65 
            ? 'Medium' 
            : 'Low';
    final confColor = AppTheme.getConfidenceColor(confLevel);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: AppTheme.spacing12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${pred.homeTeam} vs ${pred.awayTeam}',
                    style: AppTheme.heading2,
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    pred.league,
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing24),
                  _buildDetailRow('Prediction', pred.pick, Icons.sports),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildDetailRow(
                    'Odds',
                    pred.odds.toStringAsFixed(2),
                    Icons.attach_money,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildDetailRow(
                    'Confidence',
                    '${pred.confidence}% ($confLevel)',
                    Icons.analytics,
                    color: confColor,
                  ),
                  const SizedBox(height: AppTheme.spacing24),
                  Text(
                    AppConstants.analysisLabel,
                    style: AppTheme.heading3,
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Text(
                    pred.analysis,
                    style: AppTheme.bodyMedium.copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? AppTheme.primaryColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(icon, color: color ?? AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.caption.copyWith(color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}