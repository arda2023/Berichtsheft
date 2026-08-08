import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/eintrag.dart';

const _pageWidth = 595.28;
const _pageHeight = 841.89;
const _margin = 36.0;

Future<Uint8List> generateEintragPdf(Eintrag eintrag) async {
  final dateFormat = DateFormat('dd.MM.yyyy');
  final doc = pw.Document();

  final borderAll = pw.TableBorder.all(width: 0.75, color: PdfColors.black);
  final cellPadding = const pw.EdgeInsets.all(4);

  final bold = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9);
  final normal = pw.TextStyle(fontSize: 9);
  final small = pw.TextStyle(fontSize: 8);

  // ── Helper: standard labelled cell ──────────────────────────────────────
  pw.Widget labelCell(String text, {pw.TextStyle? style}) => pw.Padding(
    padding: cellPadding,
    child: pw.Text(text, style: style ?? bold),
  );

  pw.Widget valueCell(String text, {pw.TextStyle? style}) => pw.Padding(
    padding: cellPadding,
    child: pw.Text(text, style: style ?? normal),
  );

  // ── 1. Header table ──────────────────────────────────────────────────────
  final headerTable = pw.Table(
    border: borderAll,
    columnWidths: {
      0: const pw.FixedColumnWidth(120),
      1: const pw.FlexColumnWidth(2),
      2: const pw.FixedColumnWidth(110),
      3: const pw.FlexColumnWidth(2),
    },
    children: [
      // Row 1: Name
      pw.TableRow(
        children: [
          labelCell('Name, Vorname:'),
          pw.TableCell(columnSpan: 3, child: valueCell('Sayar, Arda Mehmet')),
        ],
      ),
      // Row 2: Ausbildungsjahr + Ausbildungsbereich
      pw.TableRow(
        children: [
          labelCell('Ausbildungsjahr:'),
          valueCell(eintrag.ausbildungsjahr.toString()),
          labelCell('Ausbildungsbereich:'),
          valueCell('Büro / Sekretariat'),
        ],
      ),
      // Row 3: Ausbildungswoche + Bis
      pw.TableRow(
        children: [
          labelCell('Ausbildungswoche:'),
          valueCell(dateFormat.format(eintrag.vonDatum)),
          labelCell('Bis:'),
          valueCell(dateFormat.format(eintrag.bisDatum)),
        ],
      ),
    ],
  );

  // ── Helper: item list (hyphen prefix) ───────────────────────────────────
  pw.Widget itemList(List<String> items, {double fontSize = 9}) {
    if (items.isEmpty) {
      return pw.SizedBox();
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items
          .map(
            (item) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(
                '- $item',
                style: pw.TextStyle(fontSize: fontSize),
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Zusatz content ────────────────────────────────────────────────────────
  final zusatzContent = pw.Padding(
    padding: cellPadding,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Pause: ${eintrag.pauseMinuten} Min', style: small),
        pw.SizedBox(height: 4),
        pw.Text('Krank: ${eintrag.krankheitstage} Tg', style: small),
        pw.SizedBox(height: 4),
        pw.Text('Urlaub: ${eintrag.urlaubstage} Tg', style: small),
      ],
    ),
  );

  // ── 2. Main content table ────────────────────────────────────────────────
  final contentTable = pw.Table(
    border: borderAll,
    columnWidths: {
      0: const pw.FlexColumnWidth(5),
      1: const pw.FixedColumnWidth(90),
    },
    children: [
      // Header: Betriebliche Tätigkeiten | Zusatz
      pw.TableRow(
        children: [
          pw.Padding(
            padding: cellPadding,
            child: pw.Text('Betriebliche Tätigkeiten', style: bold),
          ),
          pw.Padding(
            padding: cellPadding,
            child: pw.Text('Zusatz', style: bold),
          ),
        ],
      ),
      // Content: betriebliches list | zusatz values
      pw.TableRow(
        children: [
          pw.Container(
            constraints: const pw.BoxConstraints(minHeight: 220),
            padding: cellPadding,
            child: itemList(eintrag.betriebliches),
          ),
          pw.Container(
            constraints: const pw.BoxConstraints(minHeight: 220),
            child: zusatzContent,
          ),
        ],
      ),
      // Header: Schulische Tätigkeiten
      pw.TableRow(
        children: [
          pw.Padding(
            padding: cellPadding,
            child: pw.Text('Schulische Tätigkeiten', style: bold),
          ),
          pw.SizedBox(), // empty right cell
        ],
      ),
      // Content: schulisches list
      pw.TableRow(
        children: [
          pw.Container(
            constraints: const pw.BoxConstraints(minHeight: 200),
            padding: cellPadding,
            child: itemList(eintrag.schulisches),
          ),
          pw.SizedBox(), // empty right cell
        ],
      ),
    ],
  );

  // ── 3. Signature row ─────────────────────────────────────────────────────
  pw.Widget signatureBlock(String role) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 180,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(width: 0.75, color: PdfColors.black),
            ),
          ),
          height: 30,
        ),
        pw.SizedBox(height: 4),
        pw.Text('Datum, Unterschrift', style: pw.TextStyle(fontSize: 8)),
        pw.Text(role, style: pw.TextStyle(fontSize: 8)),
      ],
    );
  }

  final signatureRow = pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
    children: [signatureBlock('Auszubildender'), signatureBlock('Ausbilderin')],
  );

  // ── Assemble page ────────────────────────────────────────────────────────
  doc.addPage(
    pw.Page(
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
    ),
  );

  return doc.save();
}
