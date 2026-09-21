import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forfood/service/location/location_bloc.dart';
import 'package:forfood/service/location/location_event.dart';
import 'package:forfood/service/location/location_state.dart';
import '../../service/location/location_suggestion.dart';
import 'dart:async';

class LocationSearchPicker extends StatefulWidget {
  final String initialValue;
  final Function(String address, double latitude, double longitude)?
      onLocationSelected;

  const LocationSearchPicker({
    super.key,
    this.initialValue = '',
    this.onLocationSelected,
  });

  @override
  State<LocationSearchPicker> createState() => _LocationSearchPickerState();
}

class _LocationSearchPickerState extends State<LocationSearchPicker> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  OverlayEntry? _overlayEntry;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

 @override
void dispose() {
  _debounce?.cancel();  // ✅ ADD THIS
  _removeOverlay();
  _controller.dispose();
  _focusNode.dispose();
  super.dispose();
}

  void _showOverlay(List<LocationSuggestion> suggestions) {
    _removeOverlay();

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: position.dy + size.height + 4,
        left: position.dx,
        width: size.width,
        child: Material(
          elevation: 20,
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(13),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return ListTile(
                  dense: true,
                  onTap: () {
                    _removeOverlay();
                    _selectLocation(suggestion);
                  },
                  leading: const Icon(Icons.location_on_outlined, color: Color(0xFFE95322), size: 20),
                  title: Text(
                    suggestion.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
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

  void _onChanged(String value) {
  // Cancel previous timer
  _debounce?.cancel();

  // Set new timer
  _debounce = Timer(const Duration(milliseconds: 500), () {
    if (mounted && value.isNotEmpty) {
      context.read<LocationBloc>().add(LocationSearchChanged(value));
    }
  });

  setState(() {});
}

  void _selectLocation(LocationSuggestion suggestion) {
    _controller.text = suggestion.displayName;
    _focusNode.unfocus();
    context.read<LocationBloc>().add(LocationSuggestionSelected(suggestion));
    widget.onLocationSelected?.call(
      suggestion.displayName,
      suggestion.latitude,
      suggestion.longitude,
    );
    setState(() {});
  }

  void _openMap() {
    final state = context.read<LocationBloc>().state;
    final lat = state.mapLatitude ?? 36.7538;
    final lng = state.mapLongitude ?? 3.0588;
    final address = state.mapAddress.isEmpty ? 'Algiers, Algeria' : state.mapAddress;
    widget.onLocationSelected?.call(address, lat, lng);
  }

  void _clear() {
    _controller.clear();
    context.read<LocationBloc>().add(const LocationClearSearch());
    _focusNode.requestFocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, state) {
        final showSuggestions =
            state.suggestions.isNotEmpty && _focusNode.hasFocus;

        // ✅ Show Overlay when suggestions exist
        if (showSuggestions) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showOverlay(state.suggestions);
          });
        } else {
          _removeOverlay();
        }

        return Container(
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFFF3E9B5),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Search address...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                prefixIcon: IconButton(
                  icon: const Icon(Icons.location_on_outlined, color: Color(0xFFE95322)),
                  onPressed: _openMap,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _clear,
                      )
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}