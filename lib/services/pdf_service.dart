import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/eintrag.dart';

const _pageWidth = 595.28;
const _pageHeight = 841.89;
const _margin = 36.0;

// ── Shared styles & constants ─────────────────────────────────────────────────

final _borderAll = pw.TableBorder.all(width: 0.75, color: PdfColors.black);
const _cellPadding = pw.EdgeInsets.all(4);
final _bold = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9);
final _normal = pw.TextStyle(fontSize: 9);
final _small = pw.TextStyle(fontSize: 8);

// ── Shared helper widgets ─────────────────────────────────────────────────────

pw.Widget _labelCell(String text, {pw.TextStyle? style}) => pw.Padding(
      padding: _cellPadding,
      child: pw.Text(text, style: style ?? _bold),
    );

pw.Widget _valueCell(String text, {pw.TextStyle? style}) => pw.Padding(
      padding: _cellPadding,
      child: pw.Text(text, style: style ?? _normal),
    );

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

  // 1. Header table
  final headerTable = pw.Table(
    border: _borderAll,
    columnWidths: {
      0: const pw.FixedColumnWidth(120),
      1: const pw.FlexColumnWidth(2),
      2: const pw.FixedColumnWidth(110),
      3: const pw.FlexColumnWidth(2),
    },
    children: [
      // Row 1: Name
      pw.TableRow(children: [
        _labelCell('Name, Vorname:'),
        _valueCell('Sayar, Arda Mehmet'),
        pw.SizedBox(),
        pw.SizedBox(),
      ]),
      // Row 2: Ausbildungsjahr + Ausbildungsbereich
      pw.TableRow(children: [
        _labelCell('Ausbildungsjahr:'),
        _valueCell(eintrag.ausbildungsjahr.toString()),
        _labelCell('Ausbildungsbereich:'),
        _valueCell('Büro / Sekretariat'),
      ]),
      // Row 3: Ausbildungswoche + Bis
      pw.TableRow(children: [
        _labelCell('Ausbildungswoche:'),
        _valueCell(dateFormat.format(eintrag.vonDatum)),
        _labelCell('Bis:'),
        _valueCell(dateFormat.format(eintrag.bisDatum)),
      ]),
    ],
  );

  // Zusatz content
  final zusatzContent = pw.Padding(
    padding: _cellPadding,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Pause: ${eintrag.pauseMinuten} Min', style: _small),
        pw.SizedBox(height: 4),
        pw.Text('Krank: ${eintrag.krankheitstage} Tg', style: _small),
        pw.SizedBox(height: 4),
        pw.Text('Urlaub: ${eintrag.urlaubstage} Tg', style: _small),
      ],
    ),
  );

  // 2. Main content table
  final contentTable = pw.Table(
    border: _borderAll,
    columnWidths: {
      0: const pw.FlexColumnWidth(5),
      1: const pw.FixedColumnWidth(90),
    },
    children: [
      // Header: Betriebliche Tätigkeiten | Zusatz
      pw.TableRow(children: [
        pw.Padding(
          padding: _cellPadding,
          child: pw.Text('Betriebliche Tätigkeiten', style: _bold),
        ),
        pw.Padding(
          padding: _cellPadding,
          child: pw.Text('Zusatz', style: _bold),
        ),
      ]),
      // Content: betriebliches list | zusatz values
      pw.TableRow(children: [
        pw.Container(
          constraints: const pw.BoxConstraints(minHeight: 220),
          padding: _cellPadding,
          child: _itemList(eintrag.betriebliches),
        ),
        pw.Container(
          constraints: const pw.BoxConstraints(minHeight: 220),
          child: zusatzContent,
        ),
      ]),
      // Header: Schulische Tätigkeiten
      pw.TableRow(children: [
        pw.Padding(
          padding: _cellPadding,
          child: pw.Text('Schulische Tätigkeiten', style: _bold),
        ),
        pw.SizedBox(),
      ]),
      // Content: schulisches list
      pw.TableRow(children: [
        pw.Container(
          constraints: const pw.BoxConstraints(minHeight: 200),
          padding: _cellPadding,
          child: _itemList(eintrag.schulisches),
        ),
        pw.SizedBox(),
      ]),
    ],
  );

  // 3. Signature row
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
          headerTable,
          pw.SizedBox(height: 15),
          contentTable,
          pw.SizedBox(height: 100),
          signatureRow,
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
Future<Uint8List> generateEintraegeRangePdf(List<Eintrag> eintraege) async {
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
    for (final eintrag in eintraege) {
      doc.addPage(_buildEintragPage(eintrag));
    }
  }

  return doc.save();
}
