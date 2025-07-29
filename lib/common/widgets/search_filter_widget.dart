import 'package:flutter/material.dart';

class SearchFilterWidget extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final String? initialValue;
  final IconData? prefixIcon;
  final bool enabled;
  final TextInputType? keyboardType;
  final int? maxLength;

  const SearchFilterWidget({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.onClear,
    this.initialValue,
    this.prefixIcon,
    this.enabled = true,
    this.keyboardType,
    this.maxLength,
  });

  @override
  State<SearchFilterWidget> createState() => _SearchFilterWidgetState();
}

class _SearchFilterWidgetState extends State<SearchFilterWidget> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    widget.onChanged(_controller.text);
  }

  void _clearText() {
    _controller.clear();
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      maxLength: widget.maxLength,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: Icon(
          widget.prefixIcon ?? Icons.search,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        suffixIcon: _hasText
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearText,
                tooltip: 'مسح',
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withAlpha(128),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withAlpha(128),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        counterText: '', // Hide character counter
      ),
    );
  }
}

class FilterChipGroup extends StatelessWidget {
  final List<FilterChipData> chips;
  final int selectedIndex;
  final ValueChanged<int> onSelectionChanged;
  final EdgeInsetsGeometry? padding;
  final double spacing;

  const FilterChipGroup({
    super.key,
    required this.chips,
    required this.selectedIndex,
    required this.onSelectionChanged,
    this.padding,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: chips.asMap().entries.map((entry) {
          final index = entry.key;
          final chip = entry.value;
          final isSelected = selectedIndex == index;
          
          return Padding(
            padding: EdgeInsets.only(
              right: index < chips.length - 1 ? spacing : 0,
            ),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (chip.icon != null) ...[
                    Icon(
                      chip.icon,
                      size: 16,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(chip.label),
                ],
              ),
              onSelected: (selected) {
                if (selected) {
                  onSelectionChanged(index);
                }
              },
              selectedColor: Theme.of(context).colorScheme.primary,
              checkmarkColor: Theme.of(context).colorScheme.onPrimary,
              labelStyle: TextStyle(
                color: isSelected 
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary.withAlpha(128),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class FilterChipData {
  final String label;
  final IconData? icon;
  final dynamic value;

  const FilterChipData({
    required this.label,
    this.icon,
    this.value,
  });
}

class SortDropdown extends StatelessWidget {
  final String label;
  final List<SortOption> options;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const SortDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.sort),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(77),
      ),
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option.value,
          child: Row(
            children: [
              if (option.icon != null) ...[
                Icon(option.icon, size: 16),
                const SizedBox(width: 8),
              ],
              Text(option.label),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class SortOption {
  final String label;
  final String value;
  final IconData? icon;

  const SortOption({
    required this.label,
    required this.value,
    this.icon,
  });
}