import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/eintrag.dart';
import '../models/profil.dart';
import '../utils/lehrjahr.dart';

const _pageWidth = 595.28;
const _pageHeight = 841.89;
const _margin = 36.0;

// ── Shared styles & constants ─────────────────────────────────────────────────

const _cellPadding = pw.EdgeInsets.all(4);
final _bold = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9);
const _normal = pw.TextStyle(fontSize: 9);
const _small = pw.TextStyle(fontSize: 8);

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

pw.Widget _signatureBlock(String role) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Container(
        width: 180,
        height: 30,
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(width: 0.75, color: PdfColors.black),
          ),
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text('Datum, Unterschrift', style: const pw.TextStyle(fontSize: 8)),
      pw.Text(role, style: const pw.TextStyle(fontSize: 8)),
    ],
  );
}

// ── Private page builder ──────────────────────────────────────────────────────

pw.Page _buildEintragPage(Eintrag eintrag, Profil profil) {
  final dateFormat = DateFormat('dd.MM.yyyy');

  // Compute Lehrjahr dynamically based on training start date
  final lehrjahr = berechneLehrjahr(eintrag.vonDatum, profil.ausbildungsbeginn);

  // ── Grid cell helper ──────────────────────────────────────────────────────
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

  // ── 1. Header block ───────────────────────────────────────────────────────
  final headerBlock = pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(width: 0.75, color: PdfColors.black),
    ),
    child: pw.Column(
      children: [
        // Row 1: Name (spans full width)
        pw.Row(children: [
          pw.Expanded(
            flex: 25,
            child: gridCell(pw.Text('Name, Vorname:', style: _bold)),
          ),
          pw.Expanded(
            flex: 75,
            child: gridCell(
              pw.Text(profil.name, style: _normal),
              borderRight: false,
            ),
          ),
        ]),
        // Row 2: Lehrjahr + Ausbildungsbereich
        pw.Row(children: [
          pw.Expanded(
            flex: 25,
            child: gridCell(pw.Text('Lehrjahr:', style: _bold)),
          ),
          pw.Expanded(
            flex: 12,
            child: gridCell(
              pw.Text(lehrjahr?.toString() ?? '', style: _normal),
            ),
          ),
          pw.Expanded(
            flex: 28,
            child: gridCell(pw.Text('Ausbildungsbereich:', style: _bold)),
          ),
          pw.Expanded(
            flex: 35,
            child: gridCell(
              pw.Text(profil.ausbildungsbereich, style: _normal),
              borderRight: false,
            ),
          ),
        ]),
        // Row 3: Ausbildungswoche + Bis (no bottom border — last row)
        pw.Row(children: [
          pw.Expanded(
            flex: 25,
            child: gridCell(
              pw.Text('Ausbildungswoche:', style: _bold),
              borderBottom: false,
            ),
          ),
          pw.Expanded(
            flex: 20,
            child: gridCell(
              pw.Text(dateFormat.format(eintrag.vonDatum), style: _normal),
              borderBottom: false,
            ),
          ),
          pw.Expanded(
            flex: 8,
            child: gridCell(
              pw.Text('Bis:', style: _bold),
              borderBottom: false,
            ),
          ),
          pw.Expanded(
            flex: 47,
            child: gridCell(
              pw.Text(dateFormat.format(eintrag.bisDatum), style: _normal),
              borderRight: false,
              borderBottom: false,
            ),
          ),
        ]),
      ],
    ),
  );

  // ── 2. Content block ──────────────────────────────────────────────────────

  const contentBlockHeight = 460.0;

  final leftColumn = pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Container(
        padding: _cellPadding,
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(width: 0.75, color: PdfColors.black),
          ),
        ),
        child: pw.Text('Betriebliche Tätigkeiten', style: _bold),
      ),
      pw.Expanded(
        child: pw.Container(
          padding: _cellPadding,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(width: 0.75, color: PdfColors.black),
            ),
          ),
          alignment: pw.Alignment.topLeft,
          child: _itemList(eintrag.betriebliches),
        ),
      ),
      pw.Container(
        padding: _cellPadding,
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(width: 0.75, color: PdfColors.black),
          ),
        ),
        child: pw.Text('Schulische Tätigkeiten', style: _bold),
      ),
      pw.Expanded(
        child: pw.Container(
          padding: _cellPadding,
          alignment: pw.Alignment.topLeft,
          child: _itemList(eintrag.schulisches),
        ),
      ),
    ],
  );

  final rightColumn = pw.Container(
    padding: _cellPadding,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Zusatz', style: _bold),
        pw.SizedBox(height: 6),
        pw.Text('Pause: ${eintrag.pauseMinuten} Min', style: _small),
        pw.SizedBox(height: 2),
        pw.Text('Krank: ${eintrag.krankheitstage} Tg', style: _small),
        pw.SizedBox(height: 2),
        pw.Text('Urlaub: ${eintrag.urlaubstage} Tg', style: _small),
        if (eintrag.notizen.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            'Notizen:',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(eintrag.notizen, style: _small),
        ],
      ],
    ),
  );

  final contentBlock = pw.Container(
    height: contentBlockHeight,
    decoration: pw.BoxDecoration(
      border: pw.Border.all(width: 0.75, color: PdfColors.black),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                right: pw.BorderSide(width: 0.75, color: PdfColors.black),
              ),
            ),
            child: leftColumn,
          ),
        ),
        pw.Expanded(flex: 1, child: rightColumn),
      ],
    ),
  );

  // ── 3. Signature row ──────────────────────────────────────────────────────
  final signatureRow = pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
    children: [
      _signatureBlock('Auszubildender'),
      _signatureBlock('Ausbilderin'),
    ],
  );

  return pw.Page(
    pageFormat: const PdfPageFormat(_pageWidth, _pageHeight),
    margin: const pw.EdgeInsets.all(_margin),
    build: (pw.Context context) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          headerBlock,
          pw.SizedBox(height: 15),
          contentBlock,
          pw.SizedBox(height: 100),
          signatureRow,
        ],
      );
    },
  );
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

/// Generates a single-page PDF for one [Eintrag].
Future<Uint8List> generateEintragPdf(Eintrag eintrag, Profil profil) async {
  final doc = pw.Document();
  doc.addPage(_buildEintragPage(eintrag, profil));
  return doc.save();
}

/// Generates a multi-page PDF with one page per entry in [eintraege].
///
/// If [eintraege] is empty, returns a single-page PDF with a placeholder message.
///
/// If [includeDeckblatt] is true and [eintraege] is non-empty, entries are grouped
/// by their computed Lehrjahr number (via [berechneLehrjahr]). Groups are ordered
/// descending (highest/most-recent Lehrjahr first). For each group a dedicated
/// cover page is prepended, followed by that group's entries in ascending date order.
/// Entries with an undetermined Lehrjahr (null) are placed last without a cover page.
///
/// If [includeDeckblatt] is false, all entry pages are added in ascending date order.
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
  } else if (!includeDeckblatt) {
    // No cover pages — just emit all entry pages in ascending date order.
    final sorted = List<Eintrag>.from(eintraege)
      ..sort((a, b) => a.vonDatum.compareTo(b.vonDatum));
    for (final eintrag in sorted) {
      doc.addPage(_buildEintragPage(eintrag, profil));
    }
  } else {
    // Group entries by Lehrjahr number.
    final Map<int?, List<Eintrag>> groups = {};
    for (final eintrag in eintraege) {
      final lj = berechneLehrjahr(eintrag.vonDatum, profil.ausbildungsbeginn);
      groups.putIfAbsent(lj, () => []).add(eintrag);
    }

    // Sort each group's entries in ascending date order.
    for (final list in groups.values) {
      list.sort((a, b) => a.vonDatum.compareTo(b.vonDatum));
    }

    // Collect non-null group keys, sorted descending (most recent first).
    final sortedKeys = groups.keys.whereType<int>().toList()
      ..sort((a, b) => b.compareTo(a));

    // Emit cover page + entries for each identified Lehrjahr group.
    for (final lj in sortedKeys) {
      doc.addPage(_buildDeckblattPage(lehrjahr: lj, profil: profil));
      for (final eintrag in groups[lj]!) {
        doc.addPage(_buildEintragPage(eintrag, profil));
      }
    }

    // Entries with null Lehrjahr (ausbildungsbeginn not set) go last, no cover.
    if (groups.containsKey(null)) {
      for (final eintrag in groups[null]!) {
        doc.addPage(_buildEintragPage(eintrag, profil));
      }
    }
  }

  return doc.save();
}
