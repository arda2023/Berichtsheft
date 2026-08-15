import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/eintrag.dart';
import '../models/profil.dart';
import '../utils/lehrjahr.dart';
import '../utils/monats_kws.dart';

const _pageWidth = 595.28;
const _pageHeight = 841.89;
const _margin = 36.0;

// ── Shared styles & constants ─────────────────────────────────────────────────

const _cellPadding = pw.EdgeInsets.all(4);
final _bold = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12);
final _normal = pw.TextStyle(fontSize: 12);
final _small = pw.TextStyle(fontSize: 9);

// German month names, 1-indexed (index 0 unused).
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

// ── Shared helper widgets ─────────────────────────────────────────────────────

pw.Widget _itemList(List<String> items, {double fontSize = 9}) {
  if (items.isEmpty) return pw.SizedBox();
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: items
        .map(
          (item) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text('- $item', style: pw.TextStyle(fontSize: fontSize)),
          ),
        )
        .toList(),
  );
}

/// Estimates the largest font size (step 0.5, max→min) such that all
/// [items] rendered as '- item' lines fit within [availableHeight] at 1.35
/// line-height. Returns at least [minFont].
double _fitFontSize(
  List<String> items, {
  double availableHeight = 112,
  double maxFont = 12,
  double minFont = 6,
  double charsPerLine = 45,
}) {
  if (items.isEmpty) return maxFont;
  final totalLines = items.fold<int>(
    0,
    (sum, item) => sum + (item.length / charsPerLine).ceil().clamp(1, 999),
  );
  double f = maxFont;
  while (f > minFont) {
    if (totalLines * f * 1.35 <= availableHeight) return f;
    f -= 0.5;
  }
  return minFont;
}

/// A thin full-border box (0.75pt black).
pw.BoxDecoration _outerBorder() => pw.BoxDecoration(
      border: pw.Border.all(width: 0.75, color: PdfColors.black),
    );

/// Right border only.
pw.BoxDecoration _rightBorder() => const pw.BoxDecoration(
      border: pw.Border(
        right: pw.BorderSide(width: 0.75, color: PdfColors.black),
      ),
    );

/// Bottom border only.
pw.BoxDecoration _bottomBorder() => const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(width: 0.75, color: PdfColors.black),
      ),
    );

/// A grid cell with optional right / bottom borders.
pw.Widget _gridCell(
  pw.Widget child, {
  bool borderRight = true,
  bool borderBottom = true,
  pw.EdgeInsets padding = _cellPadding,
}) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border(
        right: borderRight
            ? const pw.BorderSide(width: 0.75, color: PdfColors.black)
            : pw.BorderSide.none,
        bottom: borderBottom
            ? const pw.BorderSide(width: 0.75, color: PdfColors.black)
            : pw.BorderSide.none,
      ),
    ),
    padding: padding,
    child: child,
  );
}

// ── Two-page-per-month builder ────────────────────────────────────────────────

/// Builds exactly 2 [pw.Page]s for the given [year]/[month]:
///   • Page 1 — betriebliche Tätigkeiten overview
///   • Page 2 — schulische Tätigkeiten + signature grid
///
/// [monthEntries] should contain all [Eintrag] objects whose [vonDatum] falls
/// in this month (caller is responsible for filtering). They will be sorted
/// chronologically internally.
List<pw.Page> _buildMonthPages(
  int year,
  int month,
  List<Eintrag> monthEntries,
  Profil profil,
) {
  final sorted = List<Eintrag>.from(monthEntries)
    ..sort((a, b) => a.vonDatum.compareTo(b.vonDatum));

  final slots = kwSlotsForMonth(year, month);

  // Pad to exactly 5 slots (empty nulls for missing rows).
  final List<KwSlot?> rows = List<KwSlot?>.from(slots.take(5));
  while (rows.length < 5) {
    rows.add(null);
  }

  // Reference date for Lehrjahr: first Monday of the month (first slot).
  final refDate = slots.isNotEmpty ? slots.first.montag : DateTime(year, month, 1);
  final lehrjahr = berechneLehrjahr(refDate, profil.ausbildungsbeginn);

  final titleStyle = pw.TextStyle(fontSize: 14);
  final headerBarStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11);
  final infoLabelStyle = pw.TextStyle(fontSize: 11);
  final infoValueStyle = pw.TextStyle(fontSize: 11);

  // ── Helper: format dd.MM ────────────────────────────────────────────────────
  String dd(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
  String ddyyyy(DateTime d) => '${dd(d)}.${d.year}';

  // ── Helper: find Eintrag matching a KwSlot ──────────────────────────────────
  Eintrag? entryForSlot(KwSlot slot) {
    for (final e in sorted) {
      if (isoWeekNumber(e.vonDatum) == slot.kwNummer &&
          e.vonDatum.year == slot.montag.year) {
        return e;
      }
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 1 — betriebliche Tätigkeiten
  // ══════════════════════════════════════════════════════════════════════════

  // ── 1. Title ───────────────────────────────────────────────────────────────
  final title = pw.Center(
    child: pw.Text(
      'Ausbildungsnachweis [${_monthNames[month]}; $year]',
      style: titleStyle,
    ),
  );

  // ── 2. Info table (4 rows, label ~48% | value ~52%) ────────────────────────
  final infoRows = [
    ('Name des Auszubildenden:', profil.name),
    ('Ausbildungsjahr:', lehrjahr?.toString() ?? ''),
    ('Ausbildungsberuf:', profil.ausbildungsberuf),
    ('Abteilung:', profil.ausbildungsbereich),
  ];

  final infoTable = pw.Container(
    decoration: _outerBorder(),
    child: pw.Column(
      children: List.generate(infoRows.length, (i) {
        final isLast = i == infoRows.length - 1;
        return pw.Row(children: [
          pw.Expanded(
            flex: 48,
            child: _gridCell(
              pw.Text(infoRows[i].$1, style: infoLabelStyle),
              borderRight: true,
              borderBottom: !isLast,
            ),
          ),
          pw.Expanded(
            flex: 52,
            child: _gridCell(
              pw.Text(infoRows[i].$2, style: infoValueStyle),
              borderRight: false,
              borderBottom: !isLast,
            ),
          ),
        ]);
      }),
    ),
  );

  // ── 3. Section header bar ──────────────────────────────────────────────────
  final betriebHeader = pw.Container(
    decoration: _outerBorder(),
    padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
    child: pw.Center(
      child: pw.Text('betriebliche Tätigkeiten', style: headerBarStyle),
    ),
  );

  // ── 4. Main table (LEFT 72% | RIGHT 28%), fixed height 600pt ───────────────
  const mainTableHeight = 600.0;
  const kwLabelWidth = 70.0;
  // Usable height per KW row for dynamic font sizing (600/5 minus ~8pt padding).
  const kwRowContentHeight = mainTableHeight / 5 - 8;

  // Build 5 KW rows for the LEFT panel.
  final List<pw.Widget> kwRowWidgets = [];
  for (int i = 0; i < 5; i++) {
    final slot = rows[i];
    final entry = slot != null ? entryForSlot(slot) : null;
    final isLast = i == 4;

    // KW label cell (rotated 90° CCW so text reads bottom-to-top).
    pw.Widget kwLabelCell;
    if (slot != null) {
      final labelWidget = pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'KW : ${slot.kwNummer}',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '${dd(slot.montag)}-${ddyyyy(slot.sonntag)}',
            style: pw.TextStyle(fontSize: 12),
          ),
        ],
      );
      kwLabelCell = pw.Container(
        width: kwLabelWidth,
        decoration: _rightBorder(),
        child: pw.Center(
          child: pw.Transform.rotateBox(
            angle: 1.5708, // 90° CCW (π/2)
            child: labelWidget,
          ),
        ),
      );
    } else {
      kwLabelCell = pw.Container(
        width: kwLabelWidth,
        decoration: _rightBorder(),
      );
    }

    // Content cell (betriebliche Tätigkeiten) — dynamic font to fit rows.
    final contentCell = pw.Expanded(
      child: pw.Container(
        padding: _cellPadding,
        alignment: pw.Alignment.topLeft,
        child: entry != null
            ? _itemList(
                entry.betriebliches,
                fontSize: _fitFontSize(
                  entry.betriebliches,
                  availableHeight: kwRowContentHeight,
                ),
              )
            : pw.SizedBox(),
      ),
    );

    kwRowWidgets.add(
      pw.Expanded(
        child: pw.Container(
          decoration: isLast ? null : _bottomBorder(),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              kwLabelCell,
              contentCell,
            ],
          ),
        ),
      ),
    );
  }

  final leftPanel = pw.Expanded(
    flex: 72,
    child: pw.Container(
      decoration: _rightBorder(),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: kwRowWidgets,
      ),
    ),
  );

  // RIGHT panel — Wochenstunden, Pause, Arbeitszeiten, Besonderheiten.
  final rightStyle = pw.TextStyle(fontSize: 12);
  final rightBoldStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);

  final List<pw.Widget> rightItems = [
    pw.Text('Wochenstunden:', style: rightBoldStyle),
    pw.Text(profil.wochenstunden, style: rightStyle),
    pw.SizedBox(height: 8),
    pw.Text('Pause:', style: rightBoldStyle),
    pw.Text(profil.pause, style: rightStyle),
    pw.SizedBox(height: 8),
    pw.Text('Arbeitszeiten:', style: rightBoldStyle),
    pw.Text(profil.arbeitszeiten, style: rightStyle),
    pw.SizedBox(height: 8),
    pw.Text('Besonderheiten:', style: rightBoldStyle),
  ];

  for (final e in sorted) {
    final b = e.besonderheiten.trim();
    if (b.isNotEmpty) {
      rightItems.add(pw.Text(
        '$b (KW ${isoWeekNumber(e.vonDatum)})',
        style: rightStyle,
      ));
    }
  }

  final rightPanel = pw.Expanded(
    flex: 28,
    child: pw.Container(
      padding: _cellPadding,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.start,
        children: rightItems,
      ),
    ),
  );

  final mainTable = pw.Container(
    height: mainTableHeight,
    decoration: _outerBorder(),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [leftPanel, rightPanel],
    ),
  );

  final page1 = pw.Page(
    pageFormat: const PdfPageFormat(_pageWidth, _pageHeight),
    margin: const pw.EdgeInsets.all(_margin),
    build: (pw.Context context) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          title,
          pw.SizedBox(height: 12),
          infoTable,
          pw.SizedBox(height: 15),
          betriebHeader,
          pw.SizedBox(height: 8),
          mainTable,
        ],
      );
    },
  );

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 2 — schulische Tätigkeiten + signature grid
  // ══════════════════════════════════════════════════════════════════════════

  // ── 1. Section header ──────────────────────────────────────────────────────
  final schulHeader = pw.Container(
    decoration: _outerBorder(),
    padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
    child: pw.Center(
      child: pw.Text('schulische Tätigkeiten', style: headerBarStyle),
    ),
  );

  // ── 2. Schulische content table (LEFT 68% | RIGHT 32%), 380pt ─────────────
  const schulTableHeight = 380.0;

  // LEFT panel: per-fach schulischesProFach items, merged chronologically.
  final schulLeftChildren = <pw.Widget>[];
  for (final fach in profil.faecher) {
    final items = <String>[];
    for (final e in sorted) {
      items.addAll(e.schulischesProFach[fach] ?? []);
    }
    schulLeftChildren.add(
      pw.Text('$fach:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
    );
    if (items.isNotEmpty) {
      schulLeftChildren.add(pw.SizedBox(height: 2));
      schulLeftChildren.add(_itemList(items, fontSize: 12));
    }
    schulLeftChildren.add(pw.SizedBox(height: 6));
  }

  final schulLeftPanel = pw.Expanded(
    flex: 68,
    child: pw.Container(
      decoration: _rightBorder(),
      padding: _cellPadding,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: schulLeftChildren,
      ),
    ),
  );

  // RIGHT panel: schultage as-is, then optional schulNotizen.
  final schulRightChildren = <pw.Widget>[
    pw.Text(profil.schultage, style: pw.TextStyle(fontSize: 12)),
  ];
  if (profil.schulNotizen.trim().isNotEmpty) {
    schulRightChildren.add(pw.SizedBox(height: 8));
    schulRightChildren.add(pw.Text(profil.schulNotizen.trim(), style: pw.TextStyle(fontSize: 12)));
  }

  final schulRightPanel = pw.Expanded(
    flex: 32,
    child: pw.Container(
      padding: _cellPadding,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: schulRightChildren,
      ),
    ),
  );

  final schulTable = pw.Container(
    height: schulTableHeight,
    decoration: _outerBorder(),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [schulLeftPanel, schulRightPanel],
    ),
  );

  // ── 3. Confirmation paragraph ─────────────────────────────────────────────
  final confirmationText = pw.Text(
    'Durch die nachfolgenden Unterschriften wird die Richtigkeit und Vollständigkeit der obigen Angaben bestätigt.',
    style: pw.TextStyle(fontSize: 11),
  );

  // ── 4. Signature grid (2 columns × 4 rows, each ~35pt tall) ───────────────
  // Row layout: empty | empty / label1 | label2 / empty | empty / label3 | label4
  pw.Widget sigCell(
    String text, {
    bool borderRight = true,
    bool borderBottom = true,
    double height = 35,
  }) {
    return pw.Container(
      height: height,
      decoration: pw.BoxDecoration(
        border: pw.Border(
          right: borderRight
              ? const pw.BorderSide(width: 0.75, color: PdfColors.black)
              : pw.BorderSide.none,
          bottom: borderBottom
              ? const pw.BorderSide(width: 0.75, color: PdfColors.black)
              : pw.BorderSide.none,
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: text.isNotEmpty
          ? pw.Align(
              alignment: pw.Alignment.bottomLeft,
              child: pw.Text(text, style: pw.TextStyle(fontSize: 9)),
            )
          : pw.SizedBox(),
    );
  }

  final signatureGrid = pw.Container(
    decoration: _outerBorder(),
    child: pw.Column(
      children: [
        // Row 1 — empty signature space
        pw.Row(children: [
          pw.Expanded(child: sigCell('', borderRight: true, borderBottom: true)),
          pw.Expanded(child: sigCell('', borderRight: false, borderBottom: true)),
        ]),
        // Row 2 — labels
        pw.Row(children: [
          pw.Expanded(
            child: sigCell(
              'Datum, Unterschrift der Auszubildenden',
              borderRight: true,
              borderBottom: true,
            ),
          ),
          pw.Expanded(
            child: sigCell(
              'Datum, Unterschrift der Ausbilderin',
              borderRight: false,
              borderBottom: true,
            ),
          ),
        ]),
        // Row 3 — empty signature space
        pw.Row(children: [
          pw.Expanded(child: sigCell('', borderRight: true, borderBottom: true)),
          pw.Expanded(child: sigCell('', borderRight: false, borderBottom: true)),
        ]),
        // Row 4 — further endorsements (no bottom border — last row)
        pw.Row(children: [
          pw.Expanded(
            child: sigCell(
              'Datum, ggf. weitere Sichtvermerke',
              borderRight: true,
              borderBottom: false,
            ),
          ),
          pw.Expanded(
            child: sigCell(
              'Datum, ggf. weitere Sichtvermerke',
              borderRight: false,
              borderBottom: false,
            ),
          ),
        ]),
      ],
    ),
  );

  final page2 = pw.Page(
    pageFormat: const PdfPageFormat(_pageWidth, _pageHeight),
    margin: const pw.EdgeInsets.all(_margin),
    build: (pw.Context context) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          schulHeader,
          pw.SizedBox(height: 8),
          schulTable,
          pw.SizedBox(height: 20),
          confirmationText,
          pw.SizedBox(height: 10),
          signatureGrid,
        ],
      );
    },
  );

  return [page1, page2];
}

// ── Cover page builder ────────────────────────────────────────────────────────

pw.Page _buildDeckblattPage({int? lehrjahr, required Profil profil}) {
  // ── Grid cell helper (same pattern as _buildEintragPage) ─────────────────
  pw.Widget gridCell(
    pw.Widget child, {
    bool borderRight = true,
    bool borderBottom = true,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          right: borderRight
              ? const pw.BorderSide(width: 0.75, color: PdfColors.black)
              : pw.BorderSide.none,
          bottom: borderBottom
              ? const pw.BorderSide(width: 0.75, color: PdfColors.black)
              : pw.BorderSide.none,
        ),
      ),
      padding: _cellPadding,
      child: child,
    );
  }

  // ── Info rows ─────────────────────────────────────────────────────────────
  final dateFormat = DateFormat('dd.MM.yyyy');
  final betriebFull = '${profil.betriebName}'
      '${profil.betriebName.isNotEmpty && profil.betriebAdresse.isNotEmpty ? ", " : ""}'
      '${profil.betriebAdresse}';

  final rows = [
    ('Lehrjahr:', lehrjahr?.toString() ?? ''),
    ('Name, Vorname:', profil.name),
    ('Adresse:', profil.adresse),
    ('Ausbildungsberuf:', profil.ausbildungsberuf),
    ('Fachrichtung/Schwerpunkt:', profil.fachrichtung),
    ('Ausbildungsbetrieb:', betriebFull),
    ('Verantwortliche/r Ausbilder/in:', profil.ausbilder),
    (
      'Beginn der Ausbildung:',
      profil.ausbildungsbeginn != null
          ? dateFormat.format(profil.ausbildungsbeginn!)
          : '',
    ),
    (
      'Ende der Ausbildung:',
      profil.ausbildungsende != null
          ? dateFormat.format(profil.ausbildungsende!)
          : '',
    ),
  ];

  final gridRows = <pw.Widget>[];
  for (int i = 0; i < rows.length; i++) {
    final isLast = i == rows.length - 1;
    gridRows.add(
      pw.Row(children: [
        pw.Expanded(
          flex: 30,
          child: gridCell(
            pw.Text(rows[i].$1, style: _bold),
            borderBottom: !isLast,
          ),
        ),
        pw.Expanded(
          flex: 70,
          child: gridCell(
            pw.Text(rows[i].$2, style: _normal),
            borderRight: false,
            borderBottom: !isLast,
          ),
        ),
      ]),
    );
  }

  final infoGrid = pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(width: 0.75, color: PdfColors.black),
    ),
    child: pw.Column(children: gridRows),
  );

  // ── Hinweise text ─────────────────────────────────────────────────────────
  final hinweiseText = [
    '1. Der ordnungsgemäß geführte Ausbildungsnachweis ist Zulassungsvoraussetzung zur Abschlussprüfung gemäß § 43 Abs. 1 Nr. 2 BBiG.',
    '2. Für das Anfertigen des Ausbildungsnachweises gelten folgende Anforderungen:',
    '- Der Ausbildungsnachweis ist in den gewerblich-technischen Ausbildungsberufen möglichst täglich, in den kaufmännischen Berufen möglichst wöchentlich zu führen.',
    '- Jedes Blatt des Ausbildungsnachweises ist mit dem Namen des/der Auszubildenden, dem Ausbildungsjahr und dem Berichtszeitraum zu versehen.',
    '- Der Ausbildungsnachweis muss mindestens stichwortartig den Inhalt der betrieblichen Ausbildung wiedergeben. Dabei sind betriebliche Tätigkeiten einerseits sowie Unterweisungen, betrieblicher Unterricht und sonstige Schulungen andererseits zu dokumentieren.',
    '- In den Ausbildungsnachweis müssen darüber hinaus die Themen des Berufsschulunterrichts aufgenommen werden.',
    '- Die ungefähre zeitliche Dauer der einzelnen Tätigkeiten sollte aus dem Ausbildungsnachweis hervorgehen.',
    '3. Ausbildende oder Ausbilder/innen müssen die Eintragungen im Ausbildungsnachweis mindestens monatlich (§ 14 Abs. 1 Nr. 4 BBiG) prüfen und die Richtigkeit und Vollständigkeit der Eintragungen mit Datum und Unterschrift bestätigen. Sie tragen dafür Sorge, dass auch ein/e gesetzliche/r Vertreter/in und die Berufsschule in angemessenen Zeitabständen stichprobenartig von den Ausbildungsnachweisen Kenntnis erhalten und sie unterschriftlich bestätigen können.',
  ];

  return pw.Page(
    pageFormat: const PdfPageFormat(_pageWidth, _pageHeight),
    margin: const pw.EdgeInsets.all(_margin),
    build: (pw.Context context) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Center(
            child: pw.Text(
              'Ausbildungsnachweis',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
          ),
          pw.SizedBox(height: 20),
          infoGrid,
          pw.SizedBox(height: 20),
          pw.Text('Hinweise:', style: _bold),
          pw.SizedBox(height: 6),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: hinweiseText
                .map(
                  (line) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(line, style: _small),
                  ),
                )
                .toList(),
          ),
        ],
      );
    },
  );
}

// ── Public API ────────────────────────────────────────────────────────────────

/// Generates a two-page PDF for the month of [eintrag.vonDatum].
///
/// [sameMonthEntries] should contain ALL entries for that calendar month
/// (including [eintrag] itself), so every KW row that has data is filled.
Future<Uint8List> generateEintragPdf(
  Eintrag eintrag,
  List<Eintrag> sameMonthEntries,
  Profil profil,
) async {
  final doc = pw.Document();
  final pages = _buildMonthPages(
    eintrag.vonDatum.year,
    eintrag.vonDatum.month,
    sameMonthEntries,
    profil,
  );
  for (final page in pages) {
    doc.addPage(page);
  }
  return doc.save();
}

/// Generates a multi-page PDF — 2 pages per calendar month — for all [eintraege].
///
/// Entries are grouped by year+month of [vonDatum]. Each group produces exactly
/// 2 pages (page 1: betriebliche Tätigkeiten; page 2: schulische Tätigkeiten +
/// signature grid).
///
/// If [eintraege] is empty, returns a single placeholder page.
///
/// If [includeDeckblatt] is true, entries are additionally grouped by Lehrjahr
/// (via [berechneLehrjahr]). Lehrjahr groups are ordered **descending**
/// (most-recent first). Before each Lehrjahr group's month-pages, one
/// [_buildDeckblattPage] cover page is prepended. Within a Lehrjahr group,
/// months are ordered **ascending**. Entries whose Lehrjahr cannot be
/// determined (null) are appended last, without a cover page.
Future<Uint8List> generateEintraegeRangePdf(
  List<Eintrag> eintraege,
  Profil profil, {
  bool includeDeckblatt = false,
}) async {
  final doc = pw.Document();

  if (eintraege.isEmpty) {
    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(_pageWidth, _pageHeight),
        margin: const pw.EdgeInsets.all(_margin),
        build: (pw.Context context) => pw.Center(
          child: pw.Text(
            'Keine Einträge im gewählten Zeitraum',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
    return doc.save();
  }

  // Helper: group a sorted list of entries by (year, month) and emit month pages.
  void addMonthPages(List<Eintrag> entries) {
    // Sort ascending.
    final sorted = List<Eintrag>.from(entries)
      ..sort((a, b) => a.vonDatum.compareTo(b.vonDatum));

    // Group by year+month key.
    final Map<String, List<Eintrag>> byMonth = {};
    for (final e in sorted) {
      final key = '${e.vonDatum.year}-${e.vonDatum.month.toString().padLeft(2, '0')}';
      byMonth.putIfAbsent(key, () => []).add(e);
    }

    // Emit in chronological order.
    final keys = byMonth.keys.toList()..sort();
    for (final key in keys) {
      final group = byMonth[key]!;
      final year = group.first.vonDatum.year;
      final month = group.first.vonDatum.month;
      for (final page in _buildMonthPages(year, month, group, profil)) {
        doc.addPage(page);
      }
    }
  }

  if (!includeDeckblatt) {
    addMonthPages(eintraege);
  } else {
    // Group by Lehrjahr.
    final Map<int?, List<Eintrag>> ljGroups = {};
    for (final e in eintraege) {
      final lj = berechneLehrjahr(e.vonDatum, profil.ausbildungsbeginn);
      ljGroups.putIfAbsent(lj, () => []).add(e);
    }

    // Sort non-null Lehrjahr keys descending.
    final sortedKeys = ljGroups.keys.whereType<int>().toList()
      ..sort((a, b) => b.compareTo(a));

    // Emit cover page + month pages for each Lehrjahr group.
    for (final lj in sortedKeys) {
      doc.addPage(_buildDeckblattPage(lehrjahr: lj, profil: profil));
      addMonthPages(ljGroups[lj]!);
    }

    // Null Lehrjahr entries go last, no cover page.
    if (ljGroups.containsKey(null)) {
      addMonthPages(ljGroups[null]!);
    }
  }

  return doc.save();
}
