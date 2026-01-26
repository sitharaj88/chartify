import 'dart:math' as math;

import 'package:chartify/chartify.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ChartifyExampleApp());
}

class ChartifyExampleApp extends StatefulWidget {
  const ChartifyExampleApp({super.key});

  @override
  State<ChartifyExampleApp> createState() => _ChartifyExampleAppState();
}

class _ChartifyExampleAppState extends State<ChartifyExampleApp> {
  bool _isDarkMode = true;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chartify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
        extensions: [ChartThemeData.fromSeed(const Color(0xFF6366F1))],
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        extensions: [
          ChartThemeData.fromSeed(const Color(0xFF6366F1), brightness: Brightness.dark),
        ],
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: ChartGallery(
        isDarkMode: _isDarkMode,
        onThemeToggle: _toggleTheme,
      ),
    );
  }
}

// Chart categories for filtering
enum ChartCategory { all, basic, advanced, statistical, hierarchical, specialty }

class ChartGallery extends StatefulWidget {
  const ChartGallery({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  @override
  State<ChartGallery> createState() => _ChartGalleryState();
}

class _ChartGalleryState extends State<ChartGallery> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  ChartCategory _selectedCategory = ChartCategory.all;
  late PageController _pageController;
  late AnimationController _fabAnimationController;

  final List<ChartExample> _examples = [
    // Basic Charts
    ChartExample(
      name: 'Interactive',
      description: 'Touch to explore data points',
      icon: Icons.touch_app_rounded,
      color: const Color(0xFF6366F1),
      category: ChartCategory.basic,
      builder: (context) => const InteractiveChartExample(),
    ),
    ChartExample(
      name: 'Line Chart',
      description: 'Track trends over time',
      icon: Icons.show_chart_rounded,
      color: const Color(0xFF10B981),
      category: ChartCategory.basic,
      builder: (context) => const SimpleLineChartExample(),
    ),
    ChartExample(
      name: 'Multi-Series',
      description: 'Compare multiple datasets',
      icon: Icons.stacked_line_chart_rounded,
      color: const Color(0xFF3B82F6),
      category: ChartCategory.basic,
      builder: (context) => const MultiSeriesLineChartExample(),
    ),
    ChartExample(
      name: 'Area Chart',
      description: 'Visualize volume over time',
      icon: Icons.area_chart_rounded,
      color: const Color(0xFF8B5CF6),
      category: ChartCategory.basic,
      builder: (context) => const AreaChartExample(),
    ),
    ChartExample(
      name: 'Animated',
      description: 'Dynamic live data',
      icon: Icons.animation_rounded,
      color: const Color(0xFFF59E0B),
      category: ChartCategory.basic,
      builder: (context) => const AnimatedLineChartExample(),
    ),
    ChartExample(
      name: 'Bar Chart',
      description: 'Compare categories',
      icon: Icons.bar_chart_rounded,
      color: const Color(0xFFEF4444),
      category: ChartCategory.basic,
      builder: (context) => const BarChartExample(),
    ),
    ChartExample(
      name: 'Pie Chart',
      description: 'Show proportions',
      icon: Icons.pie_chart_rounded,
      color: const Color(0xFFEC4899),
      category: ChartCategory.basic,
      builder: (context) => const PieChartExample(),
    ),
    // Advanced Charts
    ChartExample(
      name: 'Scatter',
      description: 'Plot data distribution',
      icon: Icons.scatter_plot_rounded,
      color: const Color(0xFF14B8A6),
      category: ChartCategory.advanced,
      builder: (context) => const ScatterChartExample(),
    ),
    ChartExample(
      name: 'Radar',
      description: 'Multi-dimensional comparison',
      icon: Icons.radar_rounded,
      color: const Color(0xFF8B5CF6),
      category: ChartCategory.advanced,
      builder: (context) => const RadarChartExample(),
    ),
    ChartExample(
      name: 'Gauge',
      description: 'Display single metrics',
      icon: Icons.speed_rounded,
      color: const Color(0xFF22C55E),
      category: ChartCategory.advanced,
      builder: (context) => const GaugeChartExample(),
    ),
    ChartExample(
      name: 'Sparkline',
      description: 'Compact inline charts',
      icon: Icons.insights_rounded,
      color: const Color(0xFF06B6D4),
      category: ChartCategory.advanced,
      builder: (context) => const SparklineChartExample(),
    ),
    ChartExample(
      name: 'Bubble',
      description: '3D data visualization',
      icon: Icons.bubble_chart_rounded,
      color: const Color(0xFFA855F7),
      category: ChartCategory.advanced,
      builder: (context) => const BubbleChartExample(),
    ),
    ChartExample(
      name: 'Radial Bar',
      description: 'Circular progress display',
      icon: Icons.donut_large_rounded,
      color: const Color(0xFFD946EF),
      category: ChartCategory.advanced,
      builder: (context) => const RadialBarChartExample(),
    ),
    // Statistical Charts
    ChartExample(
      name: 'Candlestick',
      description: 'Financial OHLC data',
      icon: Icons.candlestick_chart_rounded,
      color: const Color(0xFF22C55E),
      category: ChartCategory.statistical,
      builder: (context) => const CandlestickChartExample(),
    ),
    ChartExample(
      name: 'Histogram',
      description: 'Data distribution',
      icon: Icons.equalizer_rounded,
      color: const Color(0xFF6366F1),
      category: ChartCategory.statistical,
      builder: (context) => const HistogramChartExample(),
    ),
    ChartExample(
      name: 'Waterfall',
      description: 'Cumulative effect',
      icon: Icons.waterfall_chart_rounded,
      color: const Color(0xFF0EA5E9),
      category: ChartCategory.statistical,
      builder: (context) => const WaterfallChartExample(),
    ),
    ChartExample(
      name: 'Box Plot',
      description: 'Statistical summary',
      icon: Icons.candlestick_chart_rounded,
      color: const Color(0xFFF97316),
      category: ChartCategory.statistical,
      builder: (context) => const BoxPlotChartExample(),
    ),
    // Hierarchical Charts
    ChartExample(
      name: 'Funnel',
      description: 'Conversion pipeline',
      icon: Icons.filter_alt_rounded,
      color: const Color(0xFF8B5CF6),
      category: ChartCategory.hierarchical,
      builder: (context) => const FunnelChartExample(),
    ),
    ChartExample(
      name: 'Pyramid',
      description: 'Hierarchical layers',
      icon: Icons.change_history_rounded,
      color: const Color(0xFFF59E0B),
      category: ChartCategory.hierarchical,
      builder: (context) => const PyramidChartExample(),
    ),
    ChartExample(
      name: 'Heatmap',
      description: 'Intensity matrix',
      icon: Icons.grid_on_rounded,
      color: const Color(0xFFEF4444),
      category: ChartCategory.hierarchical,
      builder: (context) => const HeatmapChartExample(),
    ),
    ChartExample(
      name: 'Treemap',
      description: 'Nested rectangles',
      icon: Icons.dashboard_rounded,
      color: const Color(0xFF22C55E),
      category: ChartCategory.hierarchical,
      builder: (context) => const TreemapChartExample(),
    ),
    ChartExample(
      name: 'Sunburst',
      description: 'Radial hierarchy',
      icon: Icons.wb_sunny_rounded,
      color: const Color(0xFFFBBF24),
      category: ChartCategory.hierarchical,
      builder: (context) => const SunburstChartExample(),
    ),
    // Specialty Charts
    ChartExample(
      name: 'Bullet',
      description: 'KPI indicators',
      icon: Icons.linear_scale_rounded,
      color: const Color(0xFF64748B),
      category: ChartCategory.specialty,
      builder: (context) => const BulletChartExample(),
    ),
    ChartExample(
      name: 'Step',
      description: 'Discrete changes',
      icon: Icons.stairs_rounded,
      color: const Color(0xFF0891B2),
      category: ChartCategory.specialty,
      builder: (context) => const StepChartExample(),
    ),
    ChartExample(
      name: 'Range',
      description: 'Min/max values',
      icon: Icons.swap_vert_rounded,
      color: const Color(0xFF7C3AED),
      category: ChartCategory.specialty,
      builder: (context) => const RangeChartExample(),
    ),
    ChartExample(
      name: 'Lollipop',
      description: 'Values with markers',
      icon: Icons.radio_button_checked_rounded,
      color: const Color(0xFFDB2777),
      category: ChartCategory.specialty,
      builder: (context) => const LollipopChartExample(),
    ),
    ChartExample(
      name: 'Dumbbell',
      description: 'Before & after',
      icon: Icons.compare_arrows_rounded,
      color: const Color(0xFF059669),
      category: ChartCategory.specialty,
      builder: (context) => const DumbbellChartExample(),
    ),
    ChartExample(
      name: 'Slope',
      description: 'Trend changes',
      icon: Icons.trending_up_rounded,
      color: const Color(0xFF2563EB),
      category: ChartCategory.specialty,
      builder: (context) => const SlopeChartExample(),
    ),
    ChartExample(
      name: 'Rose',
      description: 'Polar bar chart',
      icon: Icons.donut_small_rounded,
      color: const Color(0xFFE11D48),
      category: ChartCategory.specialty,
      builder: (context) => const RoseChartExample(),
    ),
    ChartExample(
      name: 'Bump',
      description: 'Ranking over time',
      icon: Icons.leaderboard_rounded,
      color: const Color(0xFF9333EA),
      category: ChartCategory.specialty,
      builder: (context) => const BumpChartExample(),
    ),
    ChartExample(
      name: 'Calendar',
      description: 'GitHub-style heatmap',
      icon: Icons.calendar_month_rounded,
      color: const Color(0xFF16A34A),
      category: ChartCategory.specialty,
      builder: (context) => const CalendarHeatmapExample(),
    ),
    ChartExample(
      name: 'Gantt',
      description: 'Project timeline',
      icon: Icons.view_timeline_rounded,
      color: const Color(0xFF0284C7),
      category: ChartCategory.specialty,
      builder: (context) => const GanttChartExample(),
    ),
    ChartExample(
      name: 'Sankey',
      description: 'Flow visualization',
      icon: Icons.account_tree_rounded,
      color: const Color(0xFFC026D3),
      category: ChartCategory.specialty,
      builder: (context) => const SankeyChartExample(),
    ),
  ];

  List<ChartExample> get _filteredExamples {
    if (_selectedCategory == ChartCategory.all) return _examples;
    return _examples.where((e) => e.category == _selectedCategory).toList();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isWideScreen) {
      return _buildDesktopLayout(theme, isDark);
    }
    return _buildMobileLayout(theme, isDark);
  }

  Widget _buildMobileLayout(ThemeData theme, bool isDark) {
    final filteredExamples = _filteredExamples;
    final safeSelectedIndex = _selectedIndex.clamp(0, filteredExamples.length - 1);
    final currentExample = filteredExamples[safeSelectedIndex];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header with gradient
            _buildMobileHeader(theme, isDark, currentExample),
            // Category chips
            _buildCategoryChips(theme, isDark),
            // Chart area
            Expanded(
              child: _buildMobileChartArea(theme, isDark, filteredExamples, safeSelectedIndex),
            ),
            // Bottom navigation dots
            _buildPageIndicator(theme, isDark, filteredExamples, safeSelectedIndex),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHeader(ThemeData theme, bool isDark, ChartExample currentExample) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [theme.colorScheme.primaryContainer, theme.colorScheme.secondaryContainer],
        ),
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
                    colors: [currentExample.color, currentExample.color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: currentExample.color.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  currentExample.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chartify',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '${_examples.length} Chart Types',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onThemeToggle,
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                ),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return RotationTransition(
                      turns: Tween(begin: 0.75, end: 1.0).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    key: ValueKey(isDark),
                    color: isDark ? Colors.amber : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _showChartPicker(context),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                ),
                icon: Icon(
                  Icons.apps_rounded,
                  color: isDark ? Colors.white70 : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(ThemeData theme, bool isDark) {
    final categories = [
      (ChartCategory.all, 'All', Icons.grid_view_rounded),
      (ChartCategory.basic, 'Basic', Icons.show_chart_rounded),
      (ChartCategory.advanced, 'Advanced', Icons.auto_graph_rounded),
      (ChartCategory.statistical, 'Stats', Icons.analytics_rounded),
      (ChartCategory.hierarchical, 'Hierarchy', Icons.account_tree_rounded),
      (ChartCategory.specialty, 'Specialty', Icons.star_rounded),
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final (category, label, icon) = categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              avatar: Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white60 : theme.colorScheme.onSurfaceVariant),
              ),
              label: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : theme.colorScheme.onSurface),
                ),
              ),
              backgroundColor: isDark ? const Color(0xFF1E1E2D) : theme.colorScheme.surfaceContainerHighest,
              selectedColor: theme.colorScheme.primary,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onSelected: (_) {
                setState(() {
                  _selectedCategory = category;
                  _selectedIndex = 0;
                  _pageController.jumpToPage(0);
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileChartArea(ThemeData theme, bool isDark, List<ChartExample> examples, int selectedIndex) {
    return PageView.builder(
      controller: _pageController,
      itemCount: examples.length,
      onPageChanged: (index) {
        setState(() => _selectedIndex = index);
      },
      itemBuilder: (context, index) {
        final example = examples[index];
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              // Chart title card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2D) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: example.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(example.icon, color: example.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            example.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            example.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: example.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${index + 1}/${examples.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: example.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Chart container
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E2D) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: example.color.withValues(alpha: isDark ? 0.1 : 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: example.builder(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator(ThemeData theme, bool isDark, List<ChartExample> examples, int selectedIndex) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          IconButton(
            onPressed: selectedIndex > 0
                ? () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    )
                : null,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: selectedIndex > 0
                  ? (isDark ? Colors.white70 : theme.colorScheme.primary)
                  : (isDark ? Colors.white24 : theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            ),
          ),
          // Dots
          SizedBox(
            height: 8,
            child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: math.min(examples.length, 7),
              itemBuilder: (context, index) {
                final dotIndex = _getDotIndex(index, selectedIndex, examples.length);
                final isSelected = dotIndex == selectedIndex;
                final distance = (dotIndex - selectedIndex).abs();
                final scale = distance == 0 ? 1.0 : (distance == 1 ? 0.7 : 0.5);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isSelected ? 24 : 8 * scale,
                  height: 8 * scale,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? examples[selectedIndex].color
                        : (isDark ? Colors.white24 : theme.colorScheme.outline.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
          ),
          // Next button
          IconButton(
            onPressed: selectedIndex < examples.length - 1
                ? () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    )
                : null,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: selectedIndex < examples.length - 1
                  ? (isDark ? Colors.white70 : theme.colorScheme.primary)
                  : (isDark ? Colors.white24 : theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            ),
          ),
        ],
      ),
    );
  }

  int _getDotIndex(int displayIndex, int selectedIndex, int total) {
    if (total <= 7) return displayIndex;
    final start = (selectedIndex - 3).clamp(0, total - 7);
    return start + displayIndex;
  }

  void _showChartPicker(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2D) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'All Charts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              // Grid
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _examples.length,
                  itemBuilder: (context, index) {
                    final example = _examples[index];
                    final isSelected = index == _selectedIndex && _selectedCategory == ChartCategory.all;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = ChartCategory.all;
                          _selectedIndex = index;
                          _pageController.jumpToPage(index);
                        });
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? example.color.withValues(alpha: 0.2)
                              : (isDark ? const Color(0xFF252538) : theme.colorScheme.surfaceContainerHighest),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? example.color : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: example.color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(example.icon, color: example.color, size: 24),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              example.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : theme.colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(ThemeData theme, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : theme.colorScheme.surface,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : theme.colorScheme.surfaceContainerLow,
              border: Border(
                right: BorderSide(
                  color: isDark ? Colors.white10 : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Column(
              children: [
                // Logo and theme toggle
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.bar_chart_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Chartify',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onThemeToggle,
                        tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        ),
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return RotationTransition(
                              turns: Tween(begin: 0.75, end: 1.0).animate(animation),
                              child: FadeTransition(opacity: animation, child: child),
                            );
                          },
                          child: Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            key: ValueKey(isDark),
                            color: isDark ? Colors.amber : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _examples.length,
                    itemBuilder: (context, index) {
                      final example = _examples[index];
                      final isSelected = index == _selectedIndex;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? example.color : example.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              example.icon,
                              size: 18,
                              color: isSelected ? Colors.white : example.color,
                            ),
                          ),
                          title: Text(
                            example.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected
                                  ? (isDark ? Colors.white : theme.colorScheme.primary)
                                  : (isDark ? Colors.white70 : null),
                            ),
                          ),
                          subtitle: Text(
                            example.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onTap: () => setState(() => _selectedIndex = index),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A2E) : theme.colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? Colors.white10 : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _examples[_selectedIndex].color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _examples[_selectedIndex].icon,
                          color: _examples[_selectedIndex].color,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _examples[_selectedIndex].name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            _examples[_selectedIndex].description,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Chart
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E2D) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white10 : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: _examples[_selectedIndex].builder(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChartExample {
  const ChartExample({
    required this.name,
    required this.description,
    required this.icon,
    required this.builder,
    required this.color,
    this.category = ChartCategory.basic,
  });

  final String name;
  final String description;
  final IconData icon;
  final Widget Function(BuildContext context) builder;
  final Color color;
  final ChartCategory category;
}

// ============== Chart Examples ==============

class InteractiveChartExample extends StatefulWidget {
  const InteractiveChartExample({super.key});

  @override
  State<InteractiveChartExample> createState() => _InteractiveChartExampleState();
}

class _InteractiveChartExampleState extends State<InteractiveChartExample> {
  String _lastTapped = 'Tap or hover over data points';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _lastTapped,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LineChart(
            data: LineChartData(
              series: [
                LineSeries<int, double>(
                  name: 'Revenue',
                  data: const [
                    DataPoint(x: 0, y: 4200),
                    DataPoint(x: 1, y: 5800),
                    DataPoint(x: 2, y: 4900),
                    DataPoint(x: 3, y: 7200),
                    DataPoint(x: 4, y: 6100),
                    DataPoint(x: 5, y: 8500),
                    DataPoint(x: 6, y: 7800),
                  ],
                  color: const Color(0xFF6366F1),
                  strokeWidth: 3,
                  curved: true,
                  showMarkers: true,
                  markerSize: 8,
                  fillArea: true,
                  areaOpacity: 0.15,
                ),
              ],
              xAxis: AxisConfig(
                label: 'Month',
                labelFormatter: (value) {
                  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];
                  final index = value.toInt();
                  if (index >= 0 && index < months.length) {
                    return months[index];
                  }
                  return '';
                },
              ),
              yAxis: AxisConfig(
                label: 'Revenue',
                min: 0,
                labelFormatter: (value) => '\$${(value / 1000).toStringAsFixed(1)}K',
              ),
            ),
            tooltip: const TooltipConfig(
              enabled: true,
              showIndicatorLine: true,
              showIndicatorDot: true,
            ),
            showCrosshair: true,
            animation: const ChartAnimation(
              duration: Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
            ),
            onDataPointTap: (info) {
              setState(() {
                _lastTapped = 'Tapped: \$${info.yValue} at month ${info.xValue}';
              });
            },
          ),
        ),
      ],
    );
  }
}

class SimpleLineChartExample extends StatelessWidget {
  const SimpleLineChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      data: LineChartData(
        series: [
          LineSeries<int, double>(
            name: 'Sales',
            data: const [
              DataPoint(x: 0, y: 10),
              DataPoint(x: 1, y: 25),
              DataPoint(x: 2, y: 15),
              DataPoint(x: 3, y: 30),
              DataPoint(x: 4, y: 22),
              DataPoint(x: 5, y: 35),
              DataPoint(x: 6, y: 28),
            ],
            color: const Color(0xFF10B981),
            strokeWidth: 3,
            showMarkers: true,
            markerSize: 8,
          ),
        ],
        xAxis: const AxisConfig(label: 'Month'),
        yAxis: const AxisConfig(label: 'Sales (\$K)', min: 0),
      ),
      tooltip: const TooltipConfig(enabled: true),
      showCrosshair: true,
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}

class MultiSeriesLineChartExample extends StatelessWidget {
  const MultiSeriesLineChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      data: LineChartData(
        series: [
          LineSeries<int, double>(
            name: 'Revenue',
            data: const [
              DataPoint(x: 0, y: 50),
              DataPoint(x: 1, y: 75),
              DataPoint(x: 2, y: 65),
              DataPoint(x: 3, y: 90),
              DataPoint(x: 4, y: 85),
              DataPoint(x: 5, y: 100),
            ],
            color: const Color(0xFF3B82F6),
            strokeWidth: 2.5,
            curved: true,
          ),
          LineSeries<int, double>(
            name: 'Costs',
            data: const [
              DataPoint(x: 0, y: 40),
              DataPoint(x: 1, y: 55),
              DataPoint(x: 2, y: 50),
              DataPoint(x: 3, y: 60),
              DataPoint(x: 4, y: 65),
              DataPoint(x: 5, y: 70),
            ],
            color: const Color(0xFFEF4444),
            strokeWidth: 2.5,
            curved: true,
          ),
          LineSeries<int, double>(
            name: 'Profit',
            data: const [
              DataPoint(x: 0, y: 10),
              DataPoint(x: 1, y: 20),
              DataPoint(x: 2, y: 15),
              DataPoint(x: 3, y: 30),
              DataPoint(x: 4, y: 20),
              DataPoint(x: 5, y: 30),
            ],
            color: const Color(0xFF22C55E),
            strokeWidth: 2.5,
            curved: true,
            dashPattern: const [8, 4],
          ),
        ],
        xAxis: const AxisConfig(label: 'Quarter'),
        yAxis: const AxisConfig(label: 'Amount (\$K)', min: 0),
        showLegend: true,
      ),
      tooltip: const TooltipConfig(enabled: true),
      showCrosshair: true,
      animation: const ChartAnimation.staggered(),
    );
  }
}

class AreaChartExample extends StatelessWidget {
  const AreaChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      data: LineChartData(
        series: [
          LineSeries<int, double>(
            name: 'Active Users',
            data: const [
              DataPoint(x: 0, y: 1200),
              DataPoint(x: 1, y: 2800),
              DataPoint(x: 2, y: 2100),
              DataPoint(x: 3, y: 3900),
              DataPoint(x: 4, y: 3200),
              DataPoint(x: 5, y: 4800),
              DataPoint(x: 6, y: 4200),
            ],
            color: const Color(0xFF8B5CF6),
            strokeWidth: 3,
            curved: true,
            fillArea: true,
            areaOpacity: 0.25,
            showMarkers: false,
          ),
        ],
        xAxis: AxisConfig(
          label: 'Day',
          labelFormatter: (value) {
            const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            final index = value.toInt();
            if (index >= 0 && index < days.length) {
              return days[index];
            }
            return '';
          },
        ),
        yAxis: AxisConfig(
          label: 'Users',
          min: 0,
          labelFormatter: (value) => '${(value / 1000).toStringAsFixed(1)}K',
        ),
      ),
      tooltip: const TooltipConfig(enabled: true),
      showCrosshair: true,
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 1000),
        type: AnimationType.draw,
      ),
    );
  }
}

class AnimatedLineChartExample extends StatefulWidget {
  const AnimatedLineChartExample({super.key});

  @override
  State<AnimatedLineChartExample> createState() =>
      _AnimatedLineChartExampleState();
}

class _AnimatedLineChartExampleState extends State<AnimatedLineChartExample> {
  late List<DataPoint<int, double>> _data;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _generateData();
  }

  void _generateData() {
    _data = List.generate(
      10,
      (i) => DataPoint<int, double>(
        x: i,
        y: 20 + _random.nextDouble() * 80,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LineChart(
            key: ValueKey(_data.hashCode),
            data: LineChartData(
              series: [
                LineSeries<int, double>(
                  name: 'Random Data',
                  data: _data,
                  color: const Color(0xFFF59E0B),
                  strokeWidth: 3,
                  curved: true,
                  showMarkers: true,
                  markerSize: 10,
                  markerShape: MarkerShape.diamond,
                  fillArea: true,
                  areaOpacity: 0.1,
                ),
              ],
              yAxis: const AxisConfig(min: 0, max: 100),
            ),
            tooltip: const TooltipConfig(enabled: true),
            showCrosshair: true,
            animation: const ChartAnimation(
              duration: Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () {
            setState(() {
              _generateData();
            });
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Generate New Data'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ],
    );
  }
}

class BarChartExample extends StatelessWidget {
  const BarChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      data: BarChartData(
        series: [
          BarSeries.fromValues<double>(
            name: 'Sales',
            values: const [45, 72, 53, 85, 61, 78],
            color: const Color(0xFF3B82F6),
          ),
          BarSeries.fromValues<double>(
            name: 'Expenses',
            values: const [32, 48, 41, 52, 38, 55],
            color: const Color(0xFFEF4444),
          ),
        ],
        xAxis: BarXAxisConfig(
          categories: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
        ),
        yAxis: const BarYAxisConfig(min: 0),
        grouping: BarGrouping.grouped,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class PieChartExample extends StatelessWidget {
  const PieChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return PieChart(
      data: PieChartData(
        sections: [
          PieSection(
            value: 35,
            label: 'Mobile',
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shadowElevation: 6,
          ),
          const PieSection(
            value: 30,
            label: 'Desktop',
            color: Color(0xFF10B981),
            shadowElevation: 4,
          ),
          PieSection(
            value: 20,
            label: 'Tablet',
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            shadowElevation: 4,
          ),
          const PieSection(
            value: 15,
            label: 'Other',
            color: Color(0xFF8B5CF6),
            shadowElevation: 4,
          ),
        ],
        holeRadius: 0.5,
        showLabels: true,
        labelPosition: PieLabelPosition.outside,
        labelConnector: PieLabelConnector.elbow,
        segmentGap: 3,
        enableShadows: true,
        hoverDuration: const Duration(milliseconds: 200),
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
      ),
      centerWidget: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Total',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            '100',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ScatterChartExample extends StatelessWidget {
  const ScatterChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ScatterChart(
      data: ScatterChartData(
        series: [
          ScatterSeries<double, double>(
            name: 'Group A',
            data: const [
              ScatterDataPoint(x: 10, y: 20, size: 12),
              ScatterDataPoint(x: 25, y: 35, size: 18),
              ScatterDataPoint(x: 40, y: 28, size: 10),
              ScatterDataPoint(x: 55, y: 45, size: 15),
              ScatterDataPoint(x: 70, y: 38, size: 22),
            ],
            color: const Color(0xFF6366F1),
            pointSize: 12,
          ),
          ScatterSeries<double, double>(
            name: 'Group B',
            data: const [
              ScatterDataPoint(x: 15, y: 50, size: 14),
              ScatterDataPoint(x: 30, y: 65, size: 10),
              ScatterDataPoint(x: 45, y: 55, size: 16),
              ScatterDataPoint(x: 60, y: 72, size: 12),
              ScatterDataPoint(x: 80, y: 60, size: 20),
            ],
            color: const Color(0xFFEC4899),
            pointSize: 12,
          ),
        ],
        xAxis: const AxisConfig(label: 'X Value', min: 0, max: 100),
        yAxis: const AxisConfig(label: 'Y Value', min: 0, max: 100),
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}

class RadarChartExample extends StatelessWidget {
  const RadarChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return RadarChart(
      data: const RadarChartData(
        axes: ['Speed', 'Power', 'Defense', 'Range', 'Accuracy', 'Mobility'],
        series: [
          RadarSeries(
            name: 'Player A',
            values: [85, 70, 60, 90, 75, 80],
            color: Color(0xFF3B82F6),
          ),
          RadarSeries(
            name: 'Player B',
            values: [70, 85, 75, 65, 90, 70],
            color: Color(0xFFEF4444),
          ),
        ],
        tickCount: 5,
        gridType: RadarGridType.polygon,
      ),
      tooltipConfig: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class GaugeChartExample extends StatefulWidget {
  const GaugeChartExample({super.key});

  @override
  State<GaugeChartExample> createState() => _GaugeChartExampleState();
}

class _GaugeChartExampleState extends State<GaugeChartExample> {
  double _value = 72;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GaugeChart(
            data: GaugeChartData(
              value: _value,
              minValue: 0,
              maxValue: 100,
              ranges: const [
                GaugeRange(start: 0, end: 30, color: Color(0xFFEF4444)),
                GaugeRange(start: 30, end: 70, color: Color(0xFFF59E0B)),
                GaugeRange(start: 70, end: 100, color: Color(0xFF22C55E)),
              ],
              label: 'Performance',
              showTicks: true,
              majorTickCount: 5,
            ),
            animation: const ChartAnimation(
              duration: Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Slider(
          value: _value,
          min: 0,
          max: 100,
          divisions: 100,
          label: _value.toStringAsFixed(0),
          onChanged: (value) => setState(() => _value = value),
        ),
      ],
    );
  }
}

// ============== New Chart Examples ==============

class SparklineChartExample extends StatelessWidget {
  const SparklineChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Line Sparkline', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: SparklineChart(
            data: const SparklineChartData(
              values: [10, 25, 15, 30, 22, 35, 28, 40, 32, 45],
              type: SparklineType.line,
              color: Color(0xFF6366F1),
              showLastMarker: true,
              showMinMarker: true,
              showMaxMarker: true,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Area Sparkline', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: SparklineChart(
            data: const SparklineChartData(
              values: [5, 20, 12, 28, 18, 35, 25, 42, 30, 48],
              type: SparklineType.area,
              color: Color(0xFF10B981),
              areaOpacity: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Bar Sparkline', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: SparklineChart(
            data: const SparklineChartData(
              values: [15, -10, 25, -5, 30, 20, -15, 35, 10, 40],
              type: SparklineType.bar,
              color: Color(0xFF3B82F6),
              negativeColor: Color(0xFFEF4444),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Win/Loss Sparkline', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: SparklineChart(
            data: const SparklineChartData(
              values: [1, -1, 1, 1, -1, 1, -1, -1, 1, 1],
              type: SparklineType.winLoss,
              color: Color(0xFF22C55E),
              negativeColor: Color(0xFFEF4444),
            ),
          ),
        ),
      ],
    );
  }
}

class BubbleChartExample extends StatelessWidget {
  const BubbleChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return BubbleChart(
      data: BubbleChartData(
        series: [
          BubbleSeries<double, double>(
            name: 'Products',
            data: const [
              BubbleDataPoint(x: 10, y: 20, size: 100),
              BubbleDataPoint(x: 25, y: 45, size: 200),
              BubbleDataPoint(x: 40, y: 30, size: 150),
              BubbleDataPoint(x: 55, y: 60, size: 300),
              BubbleDataPoint(x: 70, y: 40, size: 180),
              BubbleDataPoint(x: 85, y: 70, size: 250),
            ],
            color: const Color(0xFF6366F1),
            opacity: 0.7,
          ),
          BubbleSeries<double, double>(
            name: 'Services',
            data: const [
              BubbleDataPoint(x: 15, y: 55, size: 120),
              BubbleDataPoint(x: 35, y: 25, size: 180),
              BubbleDataPoint(x: 50, y: 50, size: 220),
              BubbleDataPoint(x: 65, y: 35, size: 140),
              BubbleDataPoint(x: 80, y: 55, size: 200),
            ],
            color: const Color(0xFFEC4899),
            opacity: 0.7,
          ),
        ],
        xAxis: const AxisConfig(label: 'Revenue', min: 0, max: 100),
        yAxis: const AxisConfig(label: 'Growth', min: 0, max: 100),
        sizeConfig: const BubbleSizeConfig(
          minSize: 10,
          maxSize: 50,
          scaling: BubbleSizeScaling.sqrt,
        ),
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}

class RadialBarChartExample extends StatelessWidget {
  const RadialBarChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return RadialBarChart(
      data: const RadialBarChartData(
        bars: [
          RadialBarItem(
            label: 'Sales',
            value: 85,
            maxValue: 100,
            color: Color(0xFF6366F1),
          ),
          RadialBarItem(
            label: 'Marketing',
            value: 72,
            maxValue: 100,
            color: Color(0xFF10B981),
          ),
          RadialBarItem(
            label: 'Support',
            value: 60,
            maxValue: 100,
            color: Color(0xFFF59E0B),
          ),
          RadialBarItem(
            label: 'Development',
            value: 90,
            maxValue: 100,
            color: Color(0xFFEC4899),
          ),
        ],
        innerRadius: 0.3,
        trackGap: 8,
        strokeCap: StrokeCap.round,
        showLabels: true,
      ),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class CandlestickChartExample extends StatelessWidget {
  const CandlestickChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return CandlestickChart(
      data: CandlestickChartData(
        data: [
          CandlestickDataPoint(date: now.subtract(const Duration(days: 9)), open: 100, high: 110, low: 95, close: 105),
          CandlestickDataPoint(date: now.subtract(const Duration(days: 8)), open: 105, high: 115, low: 100, close: 98),
          CandlestickDataPoint(date: now.subtract(const Duration(days: 7)), open: 98, high: 108, low: 92, close: 106),
          CandlestickDataPoint(date: now.subtract(const Duration(days: 6)), open: 106, high: 120, low: 104, close: 118),
          CandlestickDataPoint(date: now.subtract(const Duration(days: 5)), open: 118, high: 125, low: 115, close: 112),
          CandlestickDataPoint(date: now.subtract(const Duration(days: 4)), open: 112, high: 118, low: 105, close: 108),
          CandlestickDataPoint(date: now.subtract(const Duration(days: 3)), open: 108, high: 122, low: 106, close: 120),
          CandlestickDataPoint(date: now.subtract(const Duration(days: 2)), open: 120, high: 128, low: 118, close: 125),
          CandlestickDataPoint(date: now.subtract(const Duration(days: 1)), open: 125, high: 130, low: 120, close: 118),
          CandlestickDataPoint(date: now, open: 118, high: 126, low: 115, close: 124),
        ],
        bullishColor: const Color(0xFF22C55E),
        bearishColor: const Color(0xFFEF4444),
        style: CandlestickStyle.filled,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}

class HistogramChartExample extends StatelessWidget {
  const HistogramChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Generate sample data (normal distribution)
    final random = math.Random(42);
    final values = List.generate(200, (_) {
      // Box-Muller transform for normal distribution
      final u1 = random.nextDouble();
      final u2 = random.nextDouble();
      return 50 + 15 * math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
    });

    return HistogramChart(
      data: HistogramChartData(
        values: values,
        binCount: 15,
        color: const Color(0xFF6366F1),
        showDistributionCurve: true,
        distributionCurveColor: const Color(0xFFEC4899),
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}

class WaterfallChartExample extends StatelessWidget {
  const WaterfallChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return WaterfallChart(
      data: const WaterfallChartData(
        items: [
          WaterfallItem(label: 'Start', value: 100, type: WaterfallItemType.total),
          WaterfallItem(label: 'Sales', value: 50, type: WaterfallItemType.increase),
          WaterfallItem(label: 'Services', value: 30, type: WaterfallItemType.increase),
          WaterfallItem(label: 'Costs', value: -40, type: WaterfallItemType.decrease),
          WaterfallItem(label: 'Tax', value: -20, type: WaterfallItemType.decrease),
          WaterfallItem(label: 'Subtotal', value: 120, type: WaterfallItemType.subtotal),
          WaterfallItem(label: 'Investment', value: 25, type: WaterfallItemType.increase),
          WaterfallItem(label: 'Expenses', value: -15, type: WaterfallItemType.decrease),
          WaterfallItem(label: 'Final', value: 130, type: WaterfallItemType.total),
        ],
        increaseColor: Color(0xFF22C55E),
        decreaseColor: Color(0xFFEF4444),
        totalColor: Color(0xFF3B82F6),
        showConnectors: true,
        showValues: true,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 1000),
      ),
    );
  }
}

class BoxPlotChartExample extends StatelessWidget {
  const BoxPlotChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return BoxPlotChart(
      data: const BoxPlotChartData(
        items: [
          BoxPlotItem(
            label: 'Q1',
            min: 10,
            q1: 25,
            median: 35,
            q3: 50,
            max: 70,
            outliers: [5, 80],
            mean: 38,
          ),
          BoxPlotItem(
            label: 'Q2',
            min: 15,
            q1: 30,
            median: 45,
            q3: 60,
            max: 75,
            outliers: [8],
            mean: 44,
          ),
          BoxPlotItem(
            label: 'Q3',
            min: 20,
            q1: 35,
            median: 50,
            q3: 65,
            max: 80,
            mean: 50,
          ),
          BoxPlotItem(
            label: 'Q4',
            min: 25,
            q1: 40,
            median: 55,
            q3: 70,
            max: 85,
            outliers: [15, 95],
            mean: 54,
          ),
        ],
        showOutliers: true,
        showMean: true,
        boxWidth: 0.6,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}

class FunnelChartExample extends StatelessWidget {
  const FunnelChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FunnelChart(
      data: const FunnelChartData(
        sections: [
          FunnelSection(label: 'Visitors', value: 10000, color: Color(0xFF6366F1)),
          FunnelSection(label: 'Leads', value: 6500, color: Color(0xFF8B5CF6)),
          FunnelSection(label: 'Prospects', value: 4200, color: Color(0xFFA855F7)),
          FunnelSection(label: 'Negotiations', value: 2100, color: Color(0xFFC084FC)),
          FunnelSection(label: 'Sales', value: 1200, color: Color(0xFFD8B4FE)),
        ],
        mode: FunnelMode.proportional,
        neckWidth: 0.3,
        gap: 4,
        showLabels: true,
        showValues: true,
        showConversionRate: true,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class PyramidChartExample extends StatelessWidget {
  const PyramidChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return PyramidChart(
      data: const PyramidChartData(
        sections: [
          PyramidSection(label: 'Basic', value: 50, color: Color(0xFF22C55E)),
          PyramidSection(label: 'Standard', value: 35, color: Color(0xFF3B82F6)),
          PyramidSection(label: 'Premium', value: 25, color: Color(0xFF8B5CF6)),
          PyramidSection(label: 'Enterprise', value: 15, color: Color(0xFFF59E0B)),
          PyramidSection(label: 'Ultimate', value: 8, color: Color(0xFFEF4444)),
        ],
        mode: PyramidMode.proportional,
        gap: 3,
        showLabels: true,
        labelPosition: PyramidLabelPosition.right,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 1000),
      ),
    );
  }
}

class HeatmapChartExample extends StatelessWidget {
  const HeatmapChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return HeatmapChart(
      data: HeatmapChartData(
        data: const [
          [1.0, 2.5, 3.2, 4.1, 2.8],
          [2.3, 4.5, 5.1, 3.8, 4.2],
          [3.1, 3.8, 6.2, 5.5, 3.9],
          [4.2, 5.1, 4.8, 7.2, 5.8],
          [2.9, 3.5, 5.2, 6.1, 8.0],
        ],
        rowLabels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        columnLabels: const ['9AM', '11AM', '1PM', '3PM', '5PM'],
        colorScale: HeatmapColorScale.viridis,
        showValues: true,
        cellPadding: 2,
        cellBorderRadius: 4,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}

class TreemapChartExample extends StatelessWidget {
  const TreemapChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return TreemapChart(
      data: TreemapChartData(
        root: TreemapNode(
          label: 'Portfolio',
          children: [
            TreemapNode(
              label: 'Technology',
              children: [
                const TreemapNode(label: 'Apple', value: 35, color: Color(0xFF6366F1)),
                const TreemapNode(label: 'Google', value: 28, color: Color(0xFF8B5CF6)),
                const TreemapNode(label: 'Microsoft', value: 22, color: Color(0xFFA855F7)),
              ],
            ),
            TreemapNode(
              label: 'Finance',
              children: [
                const TreemapNode(label: 'JPMorgan', value: 18, color: Color(0xFF22C55E)),
                const TreemapNode(label: 'Goldman', value: 12, color: Color(0xFF10B981)),
              ],
            ),
            TreemapNode(
              label: 'Healthcare',
              children: [
                const TreemapNode(label: 'Johnson', value: 15, color: Color(0xFF3B82F6)),
                const TreemapNode(label: 'Pfizer', value: 10, color: Color(0xFF0EA5E9)),
              ],
            ),
            const TreemapNode(label: 'Energy', value: 20, color: Color(0xFFF59E0B)),
          ],
        ),
        algorithm: TreemapLayoutAlgorithm.squarified,
        padding: 3,
        showLabels: true,
        labelPosition: TreemapLabelPosition.topLeft,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}

class SunburstChartExample extends StatelessWidget {
  const SunburstChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SunburstChart(
      data: SunburstChartData(
        root: SunburstNode(
          label: 'Total',
          children: [
            SunburstNode(
              label: 'Americas',
              color: const Color(0xFF6366F1),
              children: [
                const SunburstNode(label: 'USA', value: 40, color: Color(0xFF818CF8)),
                const SunburstNode(label: 'Canada', value: 15, color: Color(0xFFA5B4FC)),
                const SunburstNode(label: 'Brazil', value: 12, color: Color(0xFFC7D2FE)),
              ],
            ),
            SunburstNode(
              label: 'Europe',
              color: const Color(0xFF22C55E),
              children: [
                const SunburstNode(label: 'UK', value: 18, color: Color(0xFF4ADE80)),
                const SunburstNode(label: 'Germany', value: 16, color: Color(0xFF86EFAC)),
                const SunburstNode(label: 'France', value: 14, color: Color(0xFFBBF7D0)),
              ],
            ),
            SunburstNode(
              label: 'Asia',
              color: const Color(0xFFF59E0B),
              children: [
                const SunburstNode(label: 'China', value: 25, color: Color(0xFFFBBF24)),
                const SunburstNode(label: 'Japan', value: 18, color: Color(0xFFFCD34D)),
                const SunburstNode(label: 'India', value: 12, color: Color(0xFFFDE68A)),
              ],
            ),
          ],
        ),
        innerRadius: 40,
        ringWidth: 50,
        gap: 1,
        showLabels: true,
        showCenterLabel: true,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

// ============== Phase 6 Chart Examples ==============

class BulletChartExample extends StatelessWidget {
  const BulletChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return BulletChart(
      data: const BulletChartData(
        items: [
          BulletItem(
            label: 'Revenue',
            value: 275,
            target: 250,
            ranges: [150, 225, 300],
            max: 300,
          ),
          BulletItem(
            label: 'Profit',
            value: 22,
            target: 25,
            ranges: [10, 18, 30],
            max: 30,
          ),
          BulletItem(
            label: 'Orders',
            value: 1500,
            target: 1200,
            ranges: [800, 1100, 1600],
            max: 1600,
          ),
          BulletItem(
            label: 'Satisfaction',
            value: 4.5,
            target: 4.2,
            ranges: [3.0, 3.8, 5.0],
            max: 5.0,
          ),
        ],
        orientation: BulletOrientation.horizontal,
        rangeColors: [
          Color(0xFFE5E7EB),
          Color(0xFFD1D5DB),
          Color(0xFF9CA3AF),
        ],
        valueColor: Color(0xFF1F2937),
        targetColor: Color(0xFFEF4444),
        showLabels: true,
        showValues: true,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}

class StepChartExample extends StatelessWidget {
  const StepChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return StepChart(
      data: StepChartData(
        series: [
          StepSeries<int, double>(
            name: 'Temperature',
            data: const [
              DataPoint(x: 0, y: 20),
              DataPoint(x: 1, y: 22),
              DataPoint(x: 2, y: 22),
              DataPoint(x: 3, y: 25),
              DataPoint(x: 4, y: 23),
              DataPoint(x: 5, y: 28),
              DataPoint(x: 6, y: 26),
            ],
            color: const Color(0xFF6366F1),
            lineWidth: 2.5,
            showMarkers: true,
            fillArea: true,
            fillOpacity: 0.2,
          ),
        ],
        xAxisLabel: 'Hour',
        yAxisLabel: 'Temperature (°C)',
        minY: 15,
        maxY: 35,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}

class RangeChartExample extends StatelessWidget {
  const RangeChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return RangeChart(
      data: const RangeChartData(
        items: [
          RangeItem(label: 'Jan', min: 5, max: 15, mid: 10, color: Color(0xFF6366F1)),
          RangeItem(label: 'Feb', min: 8, max: 18, mid: 12, color: Color(0xFF8B5CF6)),
          RangeItem(label: 'Mar', min: 12, max: 22, mid: 16, color: Color(0xFFA855F7)),
          RangeItem(label: 'Apr', min: 15, max: 25, mid: 20, color: Color(0xFFC084FC)),
          RangeItem(label: 'May', min: 18, max: 28, mid: 23, color: Color(0xFFD8B4FE)),
          RangeItem(label: 'Jun', min: 22, max: 32, mid: 27, color: Color(0xFFE9D5FF)),
        ],
        orientation: RangeOrientation.vertical,
        barWidth: 0.6,
        showMidMarker: true,
        showValues: true,
        cornerRadius: 4,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}

class LollipopChartExample extends StatelessWidget {
  const LollipopChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return LollipopChart(
      data: const LollipopChartData(
        items: [
          LollipopItem(label: 'Product A', value: 85, color: Color(0xFF6366F1)),
          LollipopItem(label: 'Product B', value: 65, color: Color(0xFF8B5CF6)),
          LollipopItem(label: 'Product C', value: 92, color: Color(0xFFA855F7)),
          LollipopItem(label: 'Product D', value: 48, color: Color(0xFFC084FC)),
          LollipopItem(label: 'Product E', value: 73, color: Color(0xFFD8B4FE)),
        ],
        orientation: LollipopOrientation.horizontal,
        markerShape: LollipopMarkerShape.circle,
        markerSize: 14,
        stemWidth: 2,
        showLabels: true,
        showValues: true,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}

class DumbbellChartExample extends StatelessWidget {
  const DumbbellChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return DumbbellChart(
      data: const DumbbellChartData(
        items: [
          DumbbellItem(label: '2020', startValue: 45, endValue: 72),
          DumbbellItem(label: '2021', startValue: 52, endValue: 68),
          DumbbellItem(label: '2022', startValue: 38, endValue: 85),
          DumbbellItem(label: '2023', startValue: 60, endValue: 78),
          DumbbellItem(label: '2024', startValue: 55, endValue: 92),
        ],
        orientation: DumbbellOrientation.horizontal,
        markerSize: 12,
        connectorWidth: 3,
        showLabels: true,
        showValues: true,
        startColor: Color(0xFF6366F1),
        endColor: Color(0xFF22C55E),
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}

class SlopeChartExample extends StatelessWidget {
  const SlopeChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SlopeChart(
      data: const SlopeChartData(
        items: [
          SlopeItem(label: 'Product A', startValue: 45, endValue: 72, color: Color(0xFF6366F1)),
          SlopeItem(label: 'Product B', startValue: 68, endValue: 52, color: Color(0xFFEF4444)),
          SlopeItem(label: 'Product C', startValue: 55, endValue: 85, color: Color(0xFF22C55E)),
          SlopeItem(label: 'Product D', startValue: 40, endValue: 65, color: Color(0xFFF59E0B)),
          SlopeItem(label: 'Product E', startValue: 75, endValue: 58, color: Color(0xFF8B5CF6)),
        ],
        startLabel: '2023',
        endLabel: '2024',
        lineWidth: 2.5,
        markerSize: 10,
        showLabels: true,
        showValues: true,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class RoseChartExample extends StatelessWidget {
  const RoseChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return RoseChart(
      data: const RoseChartData(
        segments: [
          RoseSegment(label: 'N', value: 12, color: Color(0xFF6366F1)),
          RoseSegment(label: 'NE', value: 8, color: Color(0xFF8B5CF6)),
          RoseSegment(label: 'E', value: 15, color: Color(0xFFA855F7)),
          RoseSegment(label: 'SE', value: 22, color: Color(0xFFC084FC)),
          RoseSegment(label: 'S', value: 18, color: Color(0xFFD8B4FE)),
          RoseSegment(label: 'SW', value: 10, color: Color(0xFFE9D5FF)),
          RoseSegment(label: 'W', value: 25, color: Color(0xFFF3E8FF)),
          RoseSegment(label: 'NW', value: 14, color: Color(0xFFEDE9FE)),
        ],
        innerRadius: 0.2,
        gap: 2,
        showLabels: true,
        showValues: true,
        startAngle: -90,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class BumpChartExample extends StatelessWidget {
  const BumpChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return BumpChart(
      data: const BumpChartData(
        series: [
          BumpSeries(label: 'Team A', rankings: [1, 2, 1, 3, 2, 1], color: Color(0xFF6366F1)),
          BumpSeries(label: 'Team B', rankings: [2, 1, 3, 1, 1, 2], color: Color(0xFF22C55E)),
          BumpSeries(label: 'Team C', rankings: [3, 3, 2, 2, 3, 3], color: Color(0xFFF59E0B)),
          BumpSeries(label: 'Team D', rankings: [4, 4, 4, 4, 4, 4], color: Color(0xFFEF4444)),
        ],
        timeLabels: ['Week 1', 'Week 2', 'Week 3', 'Week 4', 'Week 5', 'Week 6'],
        lineWidth: 3,
        markerSize: 10,
        showLabels: true,
        showRankings: true,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class CalendarHeatmapExample extends StatelessWidget {
  const CalendarHeatmapExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Generate sample data for the past year
    final now = DateTime.now();
    final random = math.Random(42);
    final data = <CalendarDataPoint>[];

    for (var i = 0; i < 365; i++) {
      final date = now.subtract(Duration(days: i));
      // Generate random values with some patterns
      final dayOfWeek = date.weekday;
      final baseValue = dayOfWeek <= 5 ? 3 : 1; // Lower on weekends
      final value = random.nextInt(5) + baseValue;
      if (random.nextDouble() > 0.3) {
        // 70% chance of having data
        data.add(CalendarDataPoint(date: date, value: value.toDouble()));
      }
    }

    return CalendarHeatmapChart(
      data: CalendarHeatmapData(
        data: data,
        colorStops: const [
          Color(0xFFEBEDF0),
          Color(0xFF9BE9A8),
          Color(0xFF40C463),
          Color(0xFF30A14E),
          Color(0xFF216E39),
        ],
        cellSize: 12,
        cellSpacing: 3,
        cellRadius: 2,
        showDayLabels: true,
        showMonthLabels: true,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 1000),
      ),
    );
  }
}

class GanttChartExample extends StatelessWidget {
  const GanttChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return GanttChart(
      data: GanttChartData(
        tasks: [
          GanttTask(
            id: '1',
            label: 'Planning',
            start: now,
            end: now.add(const Duration(days: 7)),
            progress: 1.0,
            color: const Color(0xFF6366F1),
          ),
          GanttTask(
            id: '2',
            label: 'Design',
            start: now.add(const Duration(days: 5)),
            end: now.add(const Duration(days: 15)),
            progress: 0.8,
            color: const Color(0xFF8B5CF6),
          ),
          GanttTask(
            id: '3',
            label: 'Development',
            start: now.add(const Duration(days: 12)),
            end: now.add(const Duration(days: 35)),
            progress: 0.4,
            color: const Color(0xFFA855F7),
          ),
          GanttTask(
            id: '4',
            label: 'Testing',
            start: now.add(const Duration(days: 30)),
            end: now.add(const Duration(days: 42)),
            progress: 0.1,
            color: const Color(0xFFC084FC),
          ),
          GanttTask(
            id: '5',
            label: 'Deployment',
            start: now.add(const Duration(days: 40)),
            end: now.add(const Duration(days: 45)),
            progress: 0.0,
            color: const Color(0xFFD8B4FE),
            isMilestone: false,
          ),
          GanttTask(
            id: '6',
            label: 'Launch',
            start: now.add(const Duration(days: 45)),
            end: now.add(const Duration(days: 45)),
            progress: 0.0,
            color: const Color(0xFF22C55E),
            isMilestone: true,
          ),
        ],
        showProgress: true,
        showLabels: true,
        showDates: true,
        barHeight: 24,
        barRadius: 4,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}

class SankeyChartExample extends StatelessWidget {
  const SankeyChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SankeyChart(
      data: const SankeyChartData(
        nodes: [
          SankeyNode(id: 'salary', label: 'Salary', color: Color(0xFF22C55E)),
          SankeyNode(id: 'freelance', label: 'Freelance', color: Color(0xFF3B82F6)),
          SankeyNode(id: 'investments', label: 'Investments', color: Color(0xFF8B5CF6)),
          SankeyNode(id: 'housing', label: 'Housing', color: Color(0xFFEF4444)),
          SankeyNode(id: 'food', label: 'Food', color: Color(0xFFF59E0B)),
          SankeyNode(id: 'transport', label: 'Transport', color: Color(0xFF06B6D4)),
          SankeyNode(id: 'savings', label: 'Savings', color: Color(0xFF10B981)),
          SankeyNode(id: 'entertainment', label: 'Entertainment', color: Color(0xFFEC4899)),
        ],
        links: [
          SankeyLink(sourceId: 'salary', targetId: 'housing', value: 1500),
          SankeyLink(sourceId: 'salary', targetId: 'food', value: 800),
          SankeyLink(sourceId: 'salary', targetId: 'transport', value: 400),
          SankeyLink(sourceId: 'salary', targetId: 'savings', value: 1200),
          SankeyLink(sourceId: 'salary', targetId: 'entertainment', value: 300),
          SankeyLink(sourceId: 'freelance', targetId: 'savings', value: 800),
          SankeyLink(sourceId: 'freelance', targetId: 'entertainment', value: 200),
          SankeyLink(sourceId: 'investments', targetId: 'savings', value: 500),
        ],
        nodeWidth: 20,
        nodePadding: 15,
        linkOpacity: 0.5,
        showLabels: true,
        showValues: true,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}
