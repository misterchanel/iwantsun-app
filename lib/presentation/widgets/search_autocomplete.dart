import 'package:flutter/material.dart';
import 'package:iwantsun/core/services/search_history_service.dart';
import 'package:iwantsun/core/theme/app_colors.dart';

/// Widget d'autocomplétion pour les recherches avec historique
class SearchAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(SearchHistoryEntry) onHistorySelected;
  final String hintText;
  final Function(String)? onChanged;
  final bool isLoading;

  const SearchAutocomplete({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onHistorySelected,
    this.hintText = 'Rechercher une ville...',
    this.onChanged,
    this.isLoading = false,
  });

  @override
  State<SearchAutocomplete> createState() => _SearchAutocompleteState();
}

class _SearchAutocompleteState extends State<SearchAutocomplete> {
  final SearchHistoryService _historyService = SearchHistoryService();
  List<SearchHistoryEntry> _filteredHistory = [];
  bool _showSuggestions = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onTextChanged() {
    _updateSuggestions();
  }

  void _onFocusChanged() {
    if (widget.focusNode.hasFocus) {
      _updateSuggestions();
    } else {
      // Délai pour permettre le clic sur les suggestions
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _removeOverlay();
        }
      });
    }
  }

  Future<void> _updateSuggestions() async {
    final text = widget.controller.text.toLowerCase().trim();
    final history = await _historyService.getRecentSearches(limit: 10);

    setState(() {
      if (text.isEmpty) {
        // Afficher les 5 recherches les plus récentes
        _filteredHistory = history.take(5).toList();
      } else {
        // Filtrer par nom de localisation
        _filteredHistory = history
            .where((entry) =>
                entry.locationName?.toLowerCase().contains(text) ?? false)
            .take(5)
            .toList();
      }
      _showSuggestions = _filteredHistory.isNotEmpty && widget.focusNode.hasFocus;
    });

    if (_showSuggestions) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _getTextFieldWidth(),
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, _getTextFieldHeight() + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightGray),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _filteredHistory.length + 1,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildHeader();
                  }

                  final entry = _filteredHistory[index - 1];
                  return _buildSuggestionItem(entry);
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  double _getTextFieldWidth() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 300;
  }

  double _getTextFieldHeight() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.height ?? 56;
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.history, size: 18, color: AppColors.darkGray),
          const SizedBox(width: 8),
          Text(
            'Recherches récentes',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray.withOpacity(0.7),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () async {
              await _historyService.clearHistory();
              _updateSuggestions();
            },
            child: Text(
              'Effacer',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primaryOrange.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(SearchHistoryEntry entry) {
    return InkWell(
      onTap: () {
        widget.controller.text = entry.locationName ?? '';
        _removeOverlay();
        widget.onHistorySelected(entry);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.location_on,
                size: 20,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.locationName ?? 'Localisation',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatSearchDetails(entry),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.darkGray.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.north_west,
              size: 16,
              color: AppColors.darkGray,
            ),
          ],
        ),
      ),
    );
  }

  String _formatSearchDetails(SearchHistoryEntry entry) {
    final parts = <String>[];

    // Température
    final minTemp = entry.params.desiredMinTemperature?.toInt() ?? 20;
    final maxTemp = entry.params.desiredMaxTemperature?.toInt() ?? 30;
    parts.add('$minTemp-$maxTemp°C');

    // Dates
    final startDate = entry.params.startDate;
    final endDate = entry.params.endDate;
    final diff = endDate.difference(startDate).inDays;
    parts.add('$diff jours');

    // Résultats
    parts.add('${entry.resultsCount} résultats');

    return parts.join(' • ');
  }

  Widget? _buildSuffixIcon() {
    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryOrange,
          ),
        ),
      );
    }
    if (widget.controller.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.clear, color: AppColors.darkGray),
        onPressed: () {
          widget.controller.clear();
          _updateSuggestions();
          widget.onChanged?.call('');
        },
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.textDark,
        ),
        onChanged: (value) {
          widget.onChanged?.call(value);
        },
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: AppColors.darkGray.withOpacity(0.5),
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.darkGray,
          ),
          suffixIcon: _buildSuffixIcon(),
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightGray),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryOrange, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
