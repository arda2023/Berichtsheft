import 'dart:async';
import 'package:flutter/material.dart';

class StichpunktListe extends StatefulWidget {
  final List<String> items;
  final ValueChanged<List<String>> onChanged;
  final String label;

  const StichpunktListe({
    super.key,
    required this.items,
    required this.onChanged,
    required this.label,
  });

  @override
  State<StichpunktListe> createState() => _StichpunktListeState();
}

class _StichpunktListeState extends State<StichpunktListe> {
  late List<TextEditingController> _controllers;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controllers = widget.items
        .map((item) => TextEditingController(text: item))
        .toList();
  }

  @override
  void didUpdateWidget(covariant StichpunktListe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != _controllers.length) {
      // Re-sync entirely if lengths don't match (e.g. external data change)
      for (var c in _controllers) {
        c.dispose();
      }
      _controllers = widget.items
          .map((item) => TextEditingController(text: item))
          .toList();
    } else {
      // Sync text if different, preserving cursor if possible
      for (int i = 0; i < widget.items.length; i++) {
        if (_controllers[i].text != widget.items[i]) {
          final oldSelection = _controllers[i].selection;
          _controllers[i].text = widget.items[i];
          if (oldSelection.isValid &&
              oldSelection.end <= widget.items[i].length) {
            _controllers[i].selection = oldSelection;
          } else {
            _controllers[i].selection = TextSelection.collapsed(
              offset: widget.items[i].length,
            );
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTextChanged(int index, String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      final newItems = List<String>.from(widget.items);
      newItems[index] = value;
      widget.onChanged(newItems);
    });
  }

  void _addItem() {
    final newItems = List<String>.from(widget.items)..add('');
    _controllers.add(TextEditingController(text: ''));
    setState(() {});
    widget.onChanged(newItems);
  }

  void _removeItem(int index) {
    final newItems = List<String>.from(widget.items)..removeAt(index);
    final c = _controllers.removeAt(index);
    c.dispose();
    setState(() {});
    widget.onChanged(newItems);
  }

  @override
  Widget build(BuildContext context) {
    // Compute weighted length: chars excluding spaces and hyphens.
    final weightedLength = widget.items.fold<int>(
      0,
      (sum, item) => sum + item.replaceAll(' ', '').replaceAll('-', '').length,
    );
    const _warningThreshold = 430;
    final showWarning = weightedLength > _warningThreshold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _controllers.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _controllers[index],
                      maxLines: null,
                      onChanged: (value) => _onTextChanged(index, value),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: () => _removeItem(index),
                    tooltip: 'Eintrag entfernen',
                    splashRadius: 20,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addItem,
          icon: const Icon(Icons.add),
          label: const Text('Hinzufügen'),
        ),
        if (showWarning) ...
          [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Achtung: Der Text ist sehr lang und passt evtl. nicht vollständig in die PDF (max. ca. 430 Zeichen empfohlen).',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
      ],
    );
  }
}
