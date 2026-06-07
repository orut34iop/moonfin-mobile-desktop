import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../data/models/aggregated_item.dart';
import '../../../data/repositories/advanced_filter_catalog_repository.dart';
import '../../../data/services/advanced_filter_perf_logger.dart';
import '../../../data/services/advanced_filter_catalog_sync_service.dart';
import '../../../data/viewmodels/advanced_filter_view_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../preference/user_preferences.dart';
import '../../../util/platform_detection.dart';
import '../../navigation/destinations.dart';
import '../../widgets/media_card.dart';
import '../../widgets/navigation_layout.dart';
import '../../widgets/focus/request_initial_focus.dart';

class AdvancedFilterScreen extends StatefulWidget {
  final List<String> initialGenres;
  final List<String> initialYears;

  const AdvancedFilterScreen({
    super.key,
    this.initialGenres = const [],
    this.initialYears = const [],
  });

  @override
  State<AdvancedFilterScreen> createState() => _AdvancedFilterScreenState();
}

class _AdvancedFilterScreenState extends State<AdvancedFilterScreen> {
  late final AdvancedFilterViewModel _vm;
  late final UserPreferences _prefs;
  final Set<_FilterRowKey> _expandedRows = <_FilterRowKey>{};

  @override
  void initState() {
    super.initState();
    final getIt = GetIt.instance;
    _prefs = getIt<UserPreferences>();
    _vm = AdvancedFilterViewModel(
      client: getIt<MediaServerClient>(),
      prefs: _prefs,
      catalogRepository: getIt<AdvancedFilterCatalogRepository>(),
      catalogSyncService: getIt<AdvancedFilterCatalogSyncService>(),
    )..addListener(_onVmChanged);
    _vm.load(
      initialSelection: AdvancedFilterInitialSelection(
        genres: widget.initialGenres,
        years: widget.initialYears,
      ),
    );
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    _vm.dispose();
    super.dispose();
  }

  void _onVmChanged() {
    if (!mounted) return;
    final traceId = _vm.lastPerfTraceId;
    final frameStart = DateTime.now();
    AdvancedFilterPerfLogger.write(
      '[AdvancedFilterPerf][trace=${traceId ?? 'ui'}] '
      'screen:onVmChanged results=${_vm.results.length} '
      'state=${_vm.state.name}',
    );
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final frameMs = DateTime.now().difference(frameStart).inMilliseconds;
      AdvancedFilterPerfLogger.write(
        '[AdvancedFilterPerf][trace=${traceId ?? 'ui'}] '
        'screen:postFrame ms=$frameMs results=${_vm.results.length} '
        'state=${_vm.state.name}',
      );
    });
  }

  void _toggleExpandedRow(_FilterRowKey rowKey) {
    setState(() {
      if (!_expandedRows.add(rowKey)) {
        _expandedRows.remove(rowKey);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RequestInitialFocus(
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7F9),
        body: NavigationLayout(
          activeRoute: Destinations.advancedFilter,
          showBackButton: true,
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: PlatformDetection.useMobileUi ? 72 : 88,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _FilterPanel(
                    vm: _vm,
                    expandedRows: _expandedRows,
                    onToggleExpandedRow: _toggleExpandedRow,
                    onClearAll: _vm.clearAll,
                    onRefreshCatalog: _vm.refreshCatalog,
                  ),
                ),
                ..._buildBodySlivers(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBodySlivers() {
    final l10n = AppLocalizations.of(context);
    return switch (_vm.state) {
      AdvancedFilterLoadState.loading => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _CenteredState(
            icon: Icons.tune_rounded,
            title: l10n.advancedFilterLoading,
            showProgress: true,
            progress: _vm.loadingProgress,
            progressLabel: _vm.totalItemCount == null
                ? null
                : '${_vm.loadedItemCount.clamp(0, _vm.totalItemCount!)} / ${_vm.totalItemCount}',
          ),
        ),
      ],
      AdvancedFilterLoadState.error => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _CenteredState(
            icon: Icons.error_outline_rounded,
            title: l10n.advancedFilterLoadFailed,
            actionLabel: l10n.retry,
            onAction: _vm.load,
          ),
        ),
      ],
      AdvancedFilterLoadState.ready => _buildReadyBodySlivers(l10n),
    };
  }

  List<Widget> _buildReadyBodySlivers(AppLocalizations l10n) {
    if (_vm.results.isEmpty) {
      return [
        _ResultsHeaderSliver(vm: _vm),
        SliverFillRemaining(
          hasScrollBody: false,
          child: _CenteredState(
            icon: Icons.search_off_rounded,
            title: l10n.noResults,
            actionLabel: l10n.clearFilters,
            onAction: _vm.clearAll,
          ),
        ),
      ];
    }

    return [
      _ResultsHeaderSliver(vm: _vm),
      _ResultsGridSliver(
        items: _vm.results,
        imageUrlFor: _vm.imageUrl,
        prefs: _prefs,
      ),
    ];
  }
}

enum _FilterRowKey { type, library, genre, region, year }

class _FilterPanel extends StatelessWidget {
  final AdvancedFilterViewModel vm;
  final Set<_FilterRowKey> expandedRows;
  final ValueChanged<_FilterRowKey> onToggleExpandedRow;
  final Future<void> Function() onClearAll;
  final Future<void> Function() onRefreshCatalog;

  const _FilterPanel({
    required this.vm,
    required this.expandedRows,
    required this.onToggleExpandedRow,
    required this.onClearAll,
    required this.onRefreshCatalog,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isCompact =
        PlatformDetection.useMobileUi || MediaQuery.sizeOf(context).width < 720;
    final horizontalPadding = isCompact ? 16.0 : 48.0;
    final clearButton = TextButton.icon(
      onPressed: vm.state == AdvancedFilterLoadState.ready
          ? () => unawaited(onClearAll())
          : null,
      style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF5368)),
      icon: const Icon(Icons.clear_all_rounded),
      label: Text(l10n.clearFilters),
    );
    final refreshButton = _RefreshCatalogButton(
      vm: vm,
      onRefreshCatalog: onRefreshCatalog,
    );

    return Material(
      color: Colors.white,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black.withAlpha(18))),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            18,
            horizontalPadding,
            14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFFFF5368),
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.advancedFilter,
                      style: const TextStyle(
                        color: Color(0xFF2D3036),
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (!isCompact) ...[
                    refreshButton,
                    if (vm.hasActiveFilters) clearButton,
                  ],
                ],
              ),
              if (isCompact) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    refreshButton,
                    if (vm.hasActiveFilters) clearButton,
                  ],
                ),
              ],
              const SizedBox(height: 18),
              _FilterRow(
                rowKey: _FilterRowKey.type,
                label: l10n.advancedFilterByType,
                options: vm.types
                    .map(
                      (value) => _FilterOption(
                        value: value,
                        labelKey: switch (value) {
                          AdvancedFilterViewModel.movieType =>
                            _FilterOptionLabel.movie,
                          AdvancedFilterViewModel.seriesType =>
                            _FilterOptionLabel.series,
                          _ => null,
                        },
                        label: value,
                      ),
                    )
                    .toList(growable: false),
                selectedValues: vm.selectedTypes,
                onToggle: vm.toggleType,
                onClear: vm.clearTypes,
                expanded: expandedRows.contains(_FilterRowKey.type),
                onToggleExpanded: () => onToggleExpandedRow(_FilterRowKey.type),
              ),
              if (vm.showLibraryFilter && vm.libraries.isNotEmpty)
                _FilterRow(
                  rowKey: _FilterRowKey.library,
                  label: l10n.advancedFilterByLibrary,
                  options: vm.libraries
                      .map(
                        (library) => _FilterOption(
                          value: library.id,
                          label: library.name,
                        ),
                      )
                      .toList(growable: false),
                  selectedValues: vm.selectedLibraries,
                  onToggle: vm.toggleLibrary,
                  onClear: vm.clearLibraries,
                  expanded: expandedRows.contains(_FilterRowKey.library),
                  onToggleExpanded: () =>
                      onToggleExpandedRow(_FilterRowKey.library),
                ),
              _FilterRow(
                rowKey: _FilterRowKey.genre,
                label: l10n.advancedFilterByGenre,
                options: vm.genres
                    .map((value) => _FilterOption(value: value, label: value))
                    .toList(growable: false),
                selectedValues: vm.selectedGenres,
                onToggle: vm.toggleGenre,
                onClear: vm.clearGenres,
                expanded: expandedRows.contains(_FilterRowKey.genre),
                onToggleExpanded: () =>
                    onToggleExpandedRow(_FilterRowKey.genre),
              ),
              _FilterRow(
                rowKey: _FilterRowKey.region,
                label: l10n.advancedFilterByRegion,
                options: vm.regions
                    .map((value) => _FilterOption(value: value, label: value))
                    .toList(growable: false),
                selectedValues: vm.selectedRegions,
                onToggle: vm.toggleRegion,
                onClear: vm.clearRegions,
                expanded: expandedRows.contains(_FilterRowKey.region),
                onToggleExpanded: () =>
                    onToggleExpandedRow(_FilterRowKey.region),
              ),
              _FilterRow(
                rowKey: _FilterRowKey.year,
                label: l10n.advancedFilterByYear,
                options: vm.years
                    .map((value) => _FilterOption(value: value, label: value))
                    .toList(growable: false),
                selectedValues: vm.selectedYears,
                onToggle: vm.toggleYear,
                onClear: vm.clearYears,
                expanded: expandedRows.contains(_FilterRowKey.year),
                onToggleExpanded: () => onToggleExpandedRow(_FilterRowKey.year),
                isLast: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _FilterOptionLabel { movie, series }

class _RefreshCatalogButton extends StatelessWidget {
  final AdvancedFilterViewModel vm;
  final Future<void> Function() onRefreshCatalog;

  const _RefreshCatalogButton({
    required this.vm,
    required this.onRefreshCatalog,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final enabled =
        vm.state == AdvancedFilterLoadState.ready && !vm.isRefreshingCatalog;

    return TextButton.icon(
      onPressed: enabled ? () => unawaited(onRefreshCatalog()) : null,
      style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF5368)),
      icon: SizedBox(
        width: 20,
        height: 20,
        child: vm.isRefreshingCatalog
            ? const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Color(0xFFFF5368)),
              )
            : const Icon(Icons.refresh_rounded),
      ),
      label: Text(l10n.refresh),
    );
  }
}

class _FilterOption {
  final String value;
  final String? label;
  final _FilterOptionLabel? labelKey;

  const _FilterOption({required this.value, this.label, this.labelKey});

  String resolveLabel(AppLocalizations l10n) {
    return switch (labelKey) {
      _FilterOptionLabel.movie => l10n.advancedFilterMovie,
      _FilterOptionLabel.series => l10n.advancedFilterSeries,
      null => label ?? value,
    };
  }
}

class _FilterRow extends StatelessWidget {
  final _FilterRowKey rowKey;
  final String label;
  final List<_FilterOption> options;
  final Set<String> selectedValues;
  final Future<void> Function(String value) onToggle;
  final Future<void> Function() onClear;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final bool isLast;

  const _FilterRow({
    required this.rowKey,
    required this.label,
    required this.options,
    required this.selectedValues,
    required this.onToggle,
    required this.onClear,
    required this.expanded,
    required this.onToggleExpanded,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isCompact =
        PlatformDetection.useMobileUi || MediaQuery.sizeOf(context).width < 720;
    final labelWidth = isCompact ? 78.0 : 104.0;
    final chips = <Widget>[
      _FilterChip(
        debugLabel: '${rowKey.name}:all',
        label: l10n.all,
        selected: selectedValues.isEmpty,
        onTap: () => unawaited(onClear()),
      ),
      for (final option in options)
        _FilterChip(
          debugLabel: '${rowKey.name}:${option.value}',
          label: option.resolveLabel(l10n),
          selected: selectedValues.contains(option.value),
          onTap: () => unawaited(onToggle(option.value)),
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : Colors.black.withAlpha(12),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            height: 38,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: const TextStyle(color: Color(0xFF8B8F99), fontSize: 16),
              ),
            ),
          ),
          Expanded(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topLeft,
              child: expanded
                  ? Wrap(spacing: 10, runSpacing: 8, children: chips)
                  : SingleChildScrollView(
                      key: ValueKey<_FilterRowKey>(rowKey),
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (
                            var index = 0;
                            index < chips.length;
                            index++
                          ) ...[
                            if (index > 0) const SizedBox(width: 10),
                            chips[index],
                          ],
                        ],
                      ),
                    ),
            ),
          ),
          if (options.isNotEmpty) ...[
            const SizedBox(width: 8),
            _FilterExpandButton(
              tooltip: label,
              expanded: expanded,
              onPressed: onToggleExpanded,
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterExpandButton extends StatelessWidget {
  final String tooltip;
  final bool expanded;
  final VoidCallback onPressed;

  const _FilterExpandButton({
    required this.tooltip,
    required this.expanded,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        color: const Color(0xFF69707D),
        icon: Icon(
          expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String debugLabel;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.debugLabel,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(19),
      onTap: () {
        AdvancedFilterPerfLogger.write(
          '[AdvancedFilterPerf][trace=ui] chip:tap '
          'target="$debugLabel" label="$label" selectedBefore=$selected',
        );
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        constraints: const BoxConstraints(minHeight: 38, minWidth: 54),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFF5368) : Colors.transparent,
          borderRadius: BorderRadius.circular(19),
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF343840),
              fontSize: 16,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsHeaderSliver extends StatelessWidget {
  final AdvancedFilterViewModel vm;

  const _ResultsHeaderSliver({required this.vm});

  @override
  Widget build(BuildContext context) {
    final isCompact =
        PlatformDetection.useMobileUi || MediaQuery.sizeOf(context).width < 720;
    final horizontalPadding = isCompact ? 16.0 : 48.0;
    final controls = _SortControls(vm: vm);

    return SliverToBoxAdapter(
      child: Material(
        color: const Color(0xFFF6F7F9),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            18,
            horizontalPadding,
            0,
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResultsCount(count: vm.results.length),
                    const SizedBox(height: 12),
                    controls,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _ResultsCount(count: vm.results.length)),
                    controls,
                  ],
                ),
        ),
      ),
    );
  }
}

class _ResultsCount extends StatelessWidget {
  final int count;

  const _ResultsCount({required this.count});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Text(
      l10n.advancedFilterResultsCount(count),
      style: const TextStyle(
        color: Color(0xFF343840),
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SortControls extends StatelessWidget {
  final AdvancedFilterViewModel vm;

  const _SortControls({required this.vm});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SegmentedButton<AdvancedFilterSortField>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: const Color(0xFFFF5368),
            selectedForegroundColor: Colors.white,
            foregroundColor: const Color(0xFF343840),
            backgroundColor: Colors.white,
            side: BorderSide(color: Colors.black.withAlpha(22)),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          segments: [
            ButtonSegment(
              value: AdvancedFilterSortField.name,
              icon: const Icon(Icons.sort_by_alpha_rounded, size: 18),
              label: Text(l10n.advancedFilterSortByName),
            ),
            ButtonSegment(
              value: AdvancedFilterSortField.year,
              icon: const Icon(Icons.calendar_month_rounded, size: 18),
              label: Text(l10n.advancedFilterSortByYear),
            ),
          ],
          selected: {vm.sortField},
          onSelectionChanged: (selection) {
            unawaited(vm.setSortField(selection.single));
          },
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 42,
          height: 42,
          child: IconButton(
            tooltip: vm.sortAscending
                ? l10n.advancedFilterSortAscending
                : l10n.advancedFilterSortDescending,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF343840),
              side: BorderSide(color: Colors.black.withAlpha(22)),
            ),
            icon: Icon(
              vm.sortAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
            ),
            onPressed: () => unawaited(vm.toggleSortDirection()),
          ),
        ),
      ],
    );
  }
}

class _ResultsGridSliver extends StatelessWidget {
  final List<AggregatedItem> items;
  final String? Function(AggregatedItem item) imageUrlFor;
  final UserPreferences prefs;

  const _ResultsGridSliver({
    required this.items,
    required this.imageUrlFor,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact =
        PlatformDetection.useMobileUi || MediaQuery.sizeOf(context).width < 720;
    final padding = isCompact ? 16.0 : 48.0;
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        const spacing = 18.0;
        const aspectRatio = 2 / 3;
        final availableWidth = (constraints.crossAxisExtent - (padding * 2))
            .clamp(0.0, double.infinity)
            .toDouble();
        final targetWidth = isCompact ? 132.0 : 160.0;
        final rawColumns = (availableWidth / (targetWidth + spacing)).floor();
        final columns = rawColumns.clamp(2, 10).toInt();
        final itemWidth =
            (availableWidth - (spacing * (columns - 1))) / columns;
        final itemHeight = (itemWidth / aspectRatio) + 54;

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(padding, 24, padding, 36),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: 18,
              childAspectRatio: itemWidth / itemHeight,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = items[index];
              return MediaCard(
                title: item.name,
                subtitle: _subtitle(context, item),
                imageUrl: imageUrlFor(item),
                width: double.infinity,
                aspectRatio: aspectRatio,
                isFavorite: item.isFavorite,
                isPlayed: item.isPlayed,
                watchedBehavior: prefs.get(
                  UserPreferences.watchedIndicatorBehavior,
                ),
                cardFocusExpansion: prefs.get(
                  UserPreferences.cardFocusExpansion,
                ),
                itemType: item.type,
                titleColor: const Color(0xFF2D3036),
                subtitleColor: const Color(0xFF69707D),
                onTap: () => context.push(
                  Destinations.itemOrPhoto(
                    item.id,
                    serverId: item.serverId,
                    type: item.type,
                  ),
                ),
              );
            }, childCount: items.length),
          ),
        );
      },
    );
  }

  String? _subtitle(BuildContext context, AggregatedItem item) {
    final l10n = AppLocalizations.of(context);
    final parts = <String>[];
    final year = item.productionYear;
    if (year != null) parts.add(year.toString());
    switch (item.type) {
      case AdvancedFilterViewModel.movieType:
        parts.add(l10n.advancedFilterMovie);
      case AdvancedFilterViewModel.seriesType:
        parts.add(l10n.advancedFilterSeries);
    }
    return parts.isEmpty ? null : parts.join('  ');
  }
}

class _CenteredState extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool showProgress;
  final double? progress;
  final String? progressLabel;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CenteredState({
    required this.icon,
    required this.title,
    this.showProgress = false,
    this.progress,
    this.progressLabel,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF8B8F99)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF343840),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showProgress) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: 320,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  color: const Color(0xFFFF5368),
                  backgroundColor: const Color(0xFFFFD5DC),
                ),
              ),
              if (progressLabel != null) ...[
                const SizedBox(height: 10),
                Text(
                  progressLabel!,
                  style: const TextStyle(
                    color: Color(0xFF69707D),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5368),
                  foregroundColor: Colors.white,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
