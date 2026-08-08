import 'package:flutter/material.dart';

class ZusatzBereich extends StatefulWidget {
  final int pauseMinuten;
  final int krankheitstage;
  final int urlaubstage;
  final void Function({int? pauseMinuten, int? krankheitstage, int? urlaubstage}) onChanged;

  const ZusatzBereich({
    super.key,
    required this.pauseMinuten,
    required this.krankheitstage,
    required this.urlaubstage,
    required this.onChanged,
  });

  @override
  State<ZusatzBereich> createState() => _ZusatzBereichState();
}

class _ZusatzBereichState extends State<ZusatzBereich> {
  late TextEditingController _pauseController;
  late TextEditingController _krankheitController;
  late TextEditingController _urlaubController;

  @override
  void initState() {
    super.initState();
    _pauseController = TextEditingController(text: widget.pauseMinuten.toString());
    _krankheitController = TextEditingController(text: widget.krankheitstage.toString());
    _urlaubController = TextEditingController(text: widget.urlaubstage.toString());
  }

  @override
  void didUpdateWidget(covariant ZusatzBereich oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    _syncController(_pauseController, widget.pauseMinuten);
    _syncController(_krankheitController, widget.krankheitstage);
    _syncController(_urlaubController, widget.urlaubstage);
  }

  void _syncController(TextEditingController controller, int incomingValue) {
    final currentValue = int.tryParse(controller.text);
    if (incomingValue != currentValue) {
      final oldSelection = controller.selection;
      controller.text = incomingValue.toString();
      
      if (oldSelection.isValid && oldSelection.end <= controller.text.length) {
        controller.selection = oldSelection;
      } else {
        controller.selection = TextSelection.collapsed(offset: controller.text.length);
      }
    }
  }

  @override
  void dispose() {
    _pauseController.dispose();
    _krankheitController.dispose();
    _urlaubController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRow(
          'Pause pro Arbeitstag (Minuten)',
          _pauseController,
          (val) => widget.onChanged(pauseMinuten: val),
        ),
        const SizedBox(height: 12),
        _buildRow(
          'Krankheitstage',
          _krankheitController,
          (val) => widget.onChanged(krankheitstage: val),
        ),
        const SizedBox(height: 12),
        _buildRow(
          'Urlaubstage',
          _urlaubController,
          (val) => widget.onChanged(urlaubstage: val),
        ),
      ],
    );
  }

  Widget _buildRow(String label, TextEditingController controller, void Function(int) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        SizedBox(
          width: 80,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null) {
                onChanged(parsed);
              }
            },
          ),
        ),
      ],
    );
  }
}
