import 'dart:async';
import 'package:flutter/material.dart';

class SearchFieldDebounced extends StatefulWidget {
  const SearchFieldDebounced({
    super.key,
    this.controller,
    this.onSearch,
    this.autoFocus = false,
    this.duration = const Duration(milliseconds: 350),
    this.hasPrefixIcon = true,
    this.textInputAction,
    this.onEditingComplete,
    this.onSubmitted,
    this.hintText,
    this.focusNode,
  });

  final Duration duration;
  final TextEditingController? controller;
  final void Function(String)? onSearch;
  final bool autoFocus;
  final bool hasPrefixIcon;
  final TextInputAction? textInputAction;
  final void Function()? onEditingComplete;
  final void Function(String)? onSubmitted;
  final String? hintText;
  final FocusNode? focusNode;

  @override
  State<SearchFieldDebounced> createState() => _SearchFieldDebouncedState();
}

class _SearchFieldDebouncedState extends State<SearchFieldDebounced> {
  Timer? _debounceTimer;
  late final TextEditingController _effectiveController;
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _effectiveController = widget.controller ?? TextEditingController();
    _showClear = _effectiveController.text.isNotEmpty;
    _effectiveController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _effectiveController.text.isNotEmpty;
    if (hasText != _showClear) {
      setState(() {
        _showClear = hasText;
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller == null) {
      _effectiveController.dispose();
    } else {
      _effectiveController.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      focusNode: widget.focusNode,
      controller: _effectiveController,
      autofocus: widget.autoFocus,
      textInputAction: widget.textInputAction,
      onEditingComplete: widget.onEditingComplete,
      onSubmitted: widget.onSubmitted,
      onChanged: (value) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(widget.duration, () {
          widget.onSearch?.call(value);
        });
      },
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hintText ?? 'Buscar...',
        prefixIcon: widget.hasPrefixIcon
            ? Icon(Icons.search, size: 20, color: theme.colorScheme.onSurfaceVariant)
            : null,
        suffixIcon: _showClear
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _effectiveController.clear();
                  _debounceTimer?.cancel();
                  widget.onSearch?.call('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}
