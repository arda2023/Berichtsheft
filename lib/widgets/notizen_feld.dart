import 'dart:async';
import 'package:flutter/material.dart';

class NotizenFeld extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String label;

  const NotizenFeld({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Notizen',
  });

  @override
  State<NotizenFeld> createState() => _NotizenFeldState();
}

class _NotizenFeldState extends State<NotizenFeld> {
  late TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant NotizenFeld oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      final oldSelection = _controller.selection;
      _controller.text = widget.value;
      if (oldSelection.isValid && oldSelection.end <= widget.value.length) {
        _controller.selection = oldSelection;
      } else {
        _controller.selection = TextSelection.collapsed(
          offset: widget.value.length,
        );
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      widget.onChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          maxLines: 3,
          onChanged: _onTextChanged,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
