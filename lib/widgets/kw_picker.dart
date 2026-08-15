import 'package:flutter/material.dart';

import '../utils/monats_kws.dart';

// ── German month names (1-indexed) ──────────────────────────────────────────

const _monthNames = [
  '',
  'Januar',
  'Februar',
  'März',
  'April',
  'Mai',
  'Juni',
  'Juli',
  'August',
  'September',
  'Oktober',
  'November',
  'Dezember',
];

const _monthNamesShort = [
  '',
  'Jan',
  'Feb',
  'Mär',
  'Apr',
  'Mai',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Okt',
  'Nov',
  'Dez',
];

const _weekdayHeaders = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

// ── Public entry point ────────────────────────────────────────────────────────

/// Shows a calendar-week picker dialog.
///
/// Returns `({DateTime start, DateTime end})` where [start] is always a
/// Monday and [end] is always the following Sunday (start + 6 days).
///
/// Returns `null` if the user cancels.
Future<({DateTime start, DateTime end})?> showKwPicker(
  BuildContext context, {
  DateTime? firstMonth,
  DateTime? lastMonth,
}) {
  return showDialog<({DateTime start, DateTime end})>(
    context: context,
    builder: (context) => _KwPickerDialog(
      firstMonth: firstMonth,
      lastMonth: lastMonth,
    ),
  );
}

// ── Internal date helpers ─────────────────────────────────────────────────────

DateTime _mondayOf(DateTime d) =>
    d.subtract(Duration(days: d.weekday - 1));

String _fmt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

String _fmtFull(DateTime d) => '${_fmt(d)}.${d.year}';

// Month identity helpers (ignore day/time).
bool _monthBefore(DateTime a, DateTime b) =>
    a.year < b.year || (a.year == b.year && a.month < b.month);

bool _monthAfter(DateTime a, DateTime b) =>
    a.year > b.year || (a.year == b.year && a.month > b.month);

// ── Dialog widget ─────────────────────────────────────────────────────────────

class _KwPickerDialog extends StatefulWidget {
  final DateTime? firstMonth;
  final DateTime? lastMonth;

  const _KwPickerDialog({this.firstMonth, this.lastMonth});

  @override
  State<_KwPickerDialog> createState() => _KwPickerDialogState();
}

class _KwPickerDialogState extends State<_KwPickerDialog> {
  late DateTime _displayed; // which month is shown (day is always 1)

  // Selection: null = nothing, one entry = anchor, two entries = range
  DateTime? _anchorMonday; // always a Monday
  DateTime? _endMonday;    // always a Monday; null when only anchor selected

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Start on the lastMonth if provided, else today's month.
    final initial = widget.lastMonth ?? now;
    _displayed = DateTime(initial.year, initial.month, 1);
    _clampDisplayed();
  }

  // ── Boundary helpers ───────────────────────────────────────────────────────

  void _clampDisplayed() {
    if (widget.firstMonth != null && _monthBefore(_displayed, widget.firstMonth!)) {
      _displayed = DateTime(widget.firstMonth!.year, widget.firstMonth!.month, 1);
    }
    if (widget.lastMonth != null && _monthAfter(_displayed, widget.lastMonth!)) {
      _displayed = DateTime(widget.lastMonth!.year, widget.lastMonth!.month, 1);
    }
  }

  bool get _canGoBack {
    if (widget.firstMonth == null) return true;
    final prev = DateTime(_displayed.year, _displayed.month - 1, 1);
    return !_monthBefore(prev, widget.firstMonth!);
  }

  bool get _canGoForward {
    if (widget.lastMonth == null) return true;
    final next = DateTime(_displayed.year, _displayed.month + 1, 1);
    return !_monthAfter(next, widget.lastMonth!);
  }

  // ── Week row computation ───────────────────────────────────────────────────

  /// All weeks overlapping the displayed month (kwSlotsOverlappingMonth).
  List<KwSlot> get _weeks =>
      kwSlotsOverlappingMonth(_displayed.year, _displayed.month);

  // ── Selection logic ────────────────────────────────────────────────────────

  void _tapWeek(DateTime monday) {
    setState(() {
      if (_anchorMonday == null) {
        // No selection yet → set anchor.
        _anchorMonday = monday;
        _endMonday = null;
      } else if (_endMonday == null) {
        // Anchor set, no end yet.
        if (monday == _anchorMonday) {
          // Tapped same week → keep single selection.
          _endMonday = null;
        } else {
          // Set range.
          if (monday.isBefore(_anchorMonday!)) {
            _endMonday = _anchorMonday;
            _anchorMonday = monday;
          } else {
            _endMonday = monday;
          }
        }
      } else {
        // Range already set → start fresh.
        _anchorMonday = monday;
        _endMonday = null;
      }
    });
  }

  // Normalised start/end (Mondays).
  DateTime? get _startMonday => _anchorMonday;
  DateTime? get _endMondayNorm => _endMonday ?? _anchorMonday;

  bool _isSelected(DateTime monday) {
    if (_startMonday == null) return false;
    return !monday.isBefore(_startMonday!) &&
        !monday.isAfter(_endMondayNorm!);
  }

  bool _isEdge(DateTime monday) =>
      monday == _startMonday || monday == _endMondayNorm;

  // ── Summary line ───────────────────────────────────────────────────────────

  String get _summary {
    if (_startMonday == null) return '';
    final start = _startMonday!;
    final endMon = _endMondayNorm!;
    final endSun = endMon.add(const Duration(days: 6));
    final kwStart = isoWeekNumber(start);
    final kwEnd = isoWeekNumber(endMon);

    if (_endMonday == null || _endMonday == _anchorMonday) {
      // Single week
      final monthLabel = _monthSpanLabel(start, endSun);
      return 'KW $kwStart  (${_fmt(start)}–${_fmtFull(endSun)}) · $monthLabel';
    } else {
      return 'KW $kwStart – KW $kwEnd  (${_fmtFull(start)} – ${_fmtFull(endSun)})';
    }
  }

  String _monthSpanLabel(DateTime mon, DateTime sun) {
    if (mon.month == sun.month) {
      return _monthNames[mon.month];
    }
    return '${_monthNamesShort[mon.month]}/${_monthNamesShort[sun.month]}';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final weeks = _weeks;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                'Kalenderwoche wählen',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Month navigation header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _canGoBack
                        ? () => setState(() {
                              _displayed = DateTime(
                                  _displayed.year, _displayed.month - 1, 1);
                            })
                        : null,
                    color: _canGoBack ? cs.primary : cs.onSurface.withOpacity(0.3),
                  ),
                  Expanded(
                    child: Text(
                      '${_monthNames[_displayed.month]} ${_displayed.year}',
                      textAlign: TextAlign.center,
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _canGoForward
                        ? () => setState(() {
                              _displayed = DateTime(
                                  _displayed.year, _displayed.month + 1, 1);
                            })
                        : null,
                    color: _canGoForward
                        ? cs.primary
                        : cs.onSurface.withOpacity(0.3),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Weekday header row
              _WeekdayHeader(),
              const SizedBox(height: 4),

              // Week rows
              ...weeks.map((slot) => _WeekRow(
                    slot: slot,
                    displayedMonth: _displayed.month,
                    selected: _isSelected(slot.montag),
                    isEdge: _isEdge(slot.montag),
                    onTap: () => _tapWeek(slot.montag),
                    colorScheme: cs,
                  )),

              const SizedBox(height: 16),

              // Summary
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _startMonday != null
                    ? Container(
                        key: ValueKey(_summary),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _summary,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : SizedBox(
                        key: const ValueKey('empty'),
                        height: 38,
                      ),
              ),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Abbrechen'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _startMonday != null
                        ? () {
                            final start = _startMonday!;
                            final end = _endMondayNorm!
                                .add(const Duration(days: 6));
                            Navigator.of(context).pop((start: start, end: end));
                          }
                        : null,
                    child: const Text('Auswählen'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Weekday header row ────────────────────────────────────────────────────────

class _WeekdayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final muted =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.45);
    return Row(
      children: [
        // KW badge placeholder
        SizedBox(
          width: 44,
          child: Text(
            'KW',
            style: TextStyle(
                fontSize: 10, color: muted, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
        ...List.generate(
          7,
          (i) => Expanded(
            child: Text(
              _weekdayHeaders[i],
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  color: i >= 5 ? muted.withOpacity(0.7) : muted,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Single week row ───────────────────────────────────────────────────────────

class _WeekRow extends StatelessWidget {
  final KwSlot slot;
  final int displayedMonth;
  final bool selected;
  final bool isEdge;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _WeekRow({
    required this.slot,
    required this.displayedMonth,
    required this.selected,
    required this.isEdge,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme;
    final bgColor = isEdge
        ? cs.primary.withOpacity(0.85)
        : selected
            ? cs.primary.withOpacity(0.18)
            : Colors.transparent;
    final textColor = isEdge ? cs.onPrimary : cs.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              // KW badge
              SizedBox(
                width: 44,
                child: Text(
                  '${slot.kwNummer}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isEdge
                        ? cs.onPrimary.withOpacity(0.85)
                        : cs.primary.withOpacity(0.75),
                  ),
                ),
              ),
              // 7 day cells
              ...List.generate(7, (i) {
                final day = slot.montag.add(Duration(days: i));
                final inMonth = day.month == displayedMonth;
                final isWeekend = i >= 5;
                return Expanded(
                  child: Text(
                    '${day.day}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isEdge ? FontWeight.w600 : FontWeight.normal,
                      color: isEdge
                          ? cs.onPrimary
                              .withOpacity(inMonth ? 1.0 : 0.55)
                          : inMonth
                              ? (isWeekend
                                  ? textColor.withOpacity(0.55)
                                  : textColor)
                              : textColor.withOpacity(0.28),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
