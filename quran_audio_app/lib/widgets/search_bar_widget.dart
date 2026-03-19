import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/quran_provider.dart';

/// Search bar widget for searching surahs
class SearchBarWidget extends StatefulWidget {
  /// Callback when search query changes
  final ValueChanged<String>? onSearchChanged;

  /// Callback when search is submitted
  final ValueChanged<String>? onSearchSubmitted;

  /// Callback when search is cleared
  final VoidCallback? onCleared;

  /// Hint text for the search field
  final String hintText;

  /// Whether to show the search icon
  final bool showSearchIcon;

  /// Whether to auto focus the search field
  final bool autoFocus;

  /// Whether to show clear button
  final bool showClearButton;

  /// Custom prefix icon
  final Widget? prefixIcon;

  /// Custom suffix icon
  final Widget? suffixIcon;

  /// Background color
  final Color? backgroundColor;

  /// Text style
  final TextStyle? textStyle;

  /// Hint text style
  final TextStyle? hintStyle;

  /// Border radius
  final double borderRadius;

  /// Whether the search bar is expanded
  final bool isExpanded;

  /// Animation duration for expand/collapse
  final Duration animationDuration;

  const SearchBarWidget({
    super.key,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onCleared,
    this.hintText = 'ابحث عن سورة...',
    this.showSearchIcon = true,
    this.autoFocus = false,
    this.showClearButton = true,
    this.prefixIcon,
    this.suffixIcon,
    this.backgroundColor,
    this.textStyle,
    this.hintStyle,
    this.borderRadius = 16,
    this.isExpanded = true,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget>
    with SingleTickerProviderStateMixin {
  /// Text editing controller
  late TextEditingController _controller;

  /// Focus node for the text field
  late FocusNode _focusNode;

  /// Whether the search field has focus
  bool _hasFocus = false;

  /// Animation controller for expand/collapse
  AnimationController? _animationController;

  /// Animation for expand/collapse
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    _focusNode.addListener(_onFocusChange);

    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
      value: widget.isExpanded ? 1.0 : 0.0,
    );

    _animation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  void _onClear() {
    _controller.clear();
    context.read<QuranProvider>().clearSearch();
    widget.onSearchChanged?.call('');
    widget.onCleared?.call();
  }

  void _onSubmit(String query) {
    widget.onSearchSubmitted?.call(query);
    _focusNode.unfocus();
  }

  void _onChanged(String query) {
    context.read<QuranProvider>().setSearchQuery(query);
    widget.onSearchChanged?.call(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _animation!,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 56),
          decoration: BoxDecoration(
            color: widget.backgroundColor ??
                colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: _hasFocus
                ? Border.all(
                    color: colorScheme.primary,
                    width: 2,
                  )
                : null,
            boxShadow: _hasFocus
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Prefix icon (search icon)
              if (widget.showSearchIcon) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 16, left: 8),
                  child: Icon(
                    Icons.search,
                    color: _hasFocus
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ],

              // Custom prefix icon
              if (widget.prefixIcon != null) widget.prefixIcon!,

              // Text field
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: widget.autoFocus,
                  textAlign: TextAlign.right,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _onSubmit,
                  onChanged: _onChanged,
                  style: widget.textStyle ??
                      theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: widget.hintStyle ??
                        theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),

              // Clear button
              if (widget.showClearButton && _controller.text.isNotEmpty) ...[
                AnimatedOpacity(
                  opacity: _controller.text.isNotEmpty ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: _onClear,
                    tooltip: 'مسح البحث',
                  ),
                ),
              ] else ...[
                const SizedBox(width: 8),
              ],

              // Custom suffix icon
              if (widget.suffixIcon != null) widget.suffixIcon!,
            ],
          ),
        );
      },
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }
}

/// Animated search bar that expands on tap
class ExpandableSearchBar extends StatefulWidget {
  /// Callback when search query changes
  final ValueChanged<String>? onSearchChanged;

  /// Hint text
  final String hintText;

  /// Initial expanded state
  final bool initiallyExpanded;

  const ExpandableSearchBar({
    super.key,
    this.onSearchChanged,
    this.hintText = 'ابحث عن سورة...',
    this.initiallyExpanded = false,
  });

  @override
  State<ExpandableSearchBar> createState() => _ExpandableSearchBarState();
}

class _ExpandableSearchBarState extends State<ExpandableSearchBar>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
        _focusNode.requestFocus();
      } else {
        _animationController.reverse();
        _controller.clear();
        context.read<QuranProvider>().clearSearch();
        _focusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search icon button
              IconButton(
                icon: AnimatedRotation(
                  turns: _isExpanded ? 0.125 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.search,
                    color: _isExpanded
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                onPressed: _toggleExpanded,
                tooltip: _isExpanded ? 'إغلاق البحث' : 'فتح البحث',
              ),

              // Expandable text field
              SizeTransition(
                sizeFactor: _animation,
                axis: Axis.horizontal,
                axisAlignment: 1.0,
                child: SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textAlign: TextAlign.right,
                    textInputAction: TextInputAction.search,
                    onChanged: widget.onSearchChanged,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),

              // Clear button (when expanded and has text)
              if (_isExpanded && _controller.text.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: () {
                    _controller.clear();
                    context.read<QuranProvider>().clearSearch();
                  },
                  tooltip: 'مسح',
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Search bar with suggestions dropdown
class SearchBarWithSuggestions extends StatefulWidget {
  /// Callback when a suggestion is tapped
  final ValueChanged<String>? onSuggestionTap;

  /// Maximum number of suggestions to show
  final int maxSuggestions;

  /// Hint text
  final String hintText;

  const SearchBarWithSuggestions({
    super.key,
    this.onSuggestionTap,
    this.maxSuggestions = 5,
    this.hintText = 'ابحث عن سورة...',
  });

  @override
  State<SearchBarWithSuggestions> createState() =>
      _SearchBarWithSuggestionsState();
}

class _SearchBarWithSuggestionsState extends State<SearchBarWithSuggestions> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<QuranProvider>().setSearchQuery(query);

    // Generate suggestions based on query
    if (query.isNotEmpty) {
      _suggestions = _generateSuggestions(query)
          .take(widget.maxSuggestions)
          .toList();
    } else {
      _suggestions = [];
    }

    setState(() {});
  }

  List<String> _generateSuggestions(String query) {
    final provider = context.read<QuranProvider>();
    final filteredSurahs = provider.filteredSurahs;

    return filteredSurahs
        .where((surah) =>
            surah.nameArabic.contains(query) ||
            surah.nameEnglish.toLowerCase().contains(query.toLowerCase()))
        .map((surah) => surah.nameArabic)
        .toList();
  }

  void _onSuggestionTap(String suggestion) {
    _controller.text = suggestion;
    context.read<QuranProvider>().setSearchQuery(suggestion);
    widget.onSuggestionTap?.call(suggestion);
    _focusNode.unfocus();
    setState(() {
      _suggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SearchBarWidget(
          onSearchChanged: _onSearchChanged,
          hintText: widget.hintText,
        ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...List.generate(_suggestions.length, (index) {
            return ListTile(
              title: Text(_suggestions[index]),
              onTap: () => _onSuggestionTap(_suggestions[index]),
            );
          }),
        ],
      ],
    );
  }
}

/// Minimal search icon button that expands into search bar
class MinimalSearchButton extends StatelessWidget {
  /// Callback when search is tapped
  final VoidCallback? onTap;

  /// Color of the icon
  final Color? iconColor;

  /// Background color
  final Color? backgroundColor;

  /// Size of the button
  final double size;

  const MinimalSearchButton({
    super.key,
    this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        icon: Icon(
          Icons.search,
          color: iconColor ?? colorScheme.onSurfaceVariant,
        ),
        onPressed: onTap,
        tooltip: 'بحث',
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
