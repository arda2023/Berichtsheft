import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/eintrag.dart';

const _pageWidth = 595.28;
const _pageHeight = 841.89;
const _margin = 36.0;

// ── Shared styles & constants ─────────────────────────────────────────────────

const _cellPadding = pw.EdgeInsets.all(4);
final _bold = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9);
final _normal = pw.TextStyle(fontSize: 9);
final _small = pw.TextStyle(fontSize: 8);

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
      pw.Text('Datum, Unterschrift', style: pw.TextStyle(fontSize: 8)),
      pw.Text(role, style: pw.TextStyle(fontSize: 8)),
    ],
  );
}

// ── Private page builder ──────────────────────────────────────────────────────

pw.Page _buildEintragPage(Eintrag eintrag) {
  final dateFormat = DateFormat('dd.MM.yyyy');

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
              pw.Text('Sayar, Arda Mehmet', style: _normal),
              borderRight: false,
            ),
          ),
        ]),
        // Row 2: Ausbildungsjahr + Ausbildungsbereich
        pw.Row(children: [
          pw.Expanded(
            flex: 25,
            child: gridCell(pw.Text('Ausbildungsjahr:', style: _bold)),
          ),
          pw.Expanded(
            flex: 12,
            child: gridCell(
              pw.Text(eintrag.ausbildungsjahr.toString(), style: _normal),
            ),
          ),
          pw.Expanded(
            flex: 28,
            child: gridCell(pw.Text('Ausbildungsbereich:', style: _bold)),
          ),
          pw.Expanded(
            flex: 35,
            child: gridCell(
              pw.Text('Büro / Sekretariat', style: _normal),
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
    margin: pw.EdgeInsets.all(_margin),
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

pw.Page _buildDeckblattPage({int? ausbildungsjahr}) {
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
  final rows = [
    ('Ausbildungsjahr:', ausbildungsjahr?.toString() ?? ''),
    ('Name, Vorname:', 'Sayar, Arda Mehmet'),
    ('Adresse:', 'Hellgrund 4, 22880 Wedel'),
    ('Ausbildungsberuf:', 'Kaufmann für Büromanagement'),
    ('Fachrichtung/Schwerpunkt:', 'Auftragssteuerung / Assistenzaufgaben'),
    (
      'Ausbildungsbetrieb:',
      'WEKO Sicherheitsdienste GmbH, Sülldorfer Landstraße 199, 22589 Altona',
    ),
    ('Verantwortliche/r Ausbilder/in:', 'Ute Platzer'),
    ('Beginn der Ausbildung:', '01.08.2026'),
    ('Ende der Ausbildung:', '31.07.2029'),
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
    margin: pw.EdgeInsets.all(_margin),
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
Future<Uint8List> generateEintragPdf(Eintrag eintrag) async {
  final doc = pw.Document();
  doc.addPage(_buildEintragPage(eintrag));
  return doc.save();
}

/// Generates a multi-page PDF with one page per entry in [eintraege].
/// If [eintraege] is empty, returns a single-page PDF with a placeholder message.
/// If [includeDeckblatt] is true and [eintraege] is non-empty, prepends a cover page.
Future<Uint8List> generateEintraegeRangePdf(
  List<Eintrag> eintraege, {
  bool includeDeckblatt = false,
}) async {
  final doc = pw.Document();

  if (eintraege.isEmpty) {
    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(_pageWidth, _pageHeight),
        margin: pw.EdgeInsets.all(_margin),
        build: (pw.Context context) => pw.Center(
          child: pw.Text(
            'Keine Einträge im gewählten Zeitraum',
            style: pw.TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  } else {
    if (includeDeckblatt) {
      doc.addPage(
        _buildDeckblattPage(ausbildungsjahr: eintraege.first.ausbildungsjahr),
      );
    }
    for (final eintrag in eintraege) {
      doc.addPage(_buildEintragPage(eintrag));
    }
  }

  return doc.save();
}

