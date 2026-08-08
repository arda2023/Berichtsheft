import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/eintrag.dart';

/// A4 page dimensions in PDF points.
const _pageWidth = 595.28;
const _pageHeight = 841.89;

/// Convert a top-based Y coordinate (from page top) to PDF bottom-based Y.
double _y(double top) => _pageHeight - top;

Future<Uint8List> generateEintragPdf(Eintrag eintrag) async {
  final dateFormat = DateFormat('dd.MM.yyyy');

  // Load the template PDF from assets.
  final templateBytes = await rootBundle.load('assets/berichtsheft_template.pdf');

  // Rasterize the first page of the template at 2x resolution for a crisp background.
  final rasterImages = Printing.raster(
    templateBytes.buffer.asUint8List(),
    pages: [0],
    dpi: PdfPageFormat.inch * 2, // 144 DPI (2 × 72)
  );

  final PdfRaster firstPageRaster = await rasterImages.first;
  final backgroundImageData = await firstPageRaster.toPng();
  final backgroundImage = pw.MemoryImage(backgroundImageData);

  final doc = pw.Document();

  // Helper: build a bullet list as a column of text widgets.
  List<pw.Widget> bulletLines(
    List<String> items, {
    double fontSize = 9,
    double lineHeight = 13,
    double maxWidth = 370,
  }) {
    if (items.isEmpty) return [];
    return items.map((item) {
      return pw.Container(
        width: maxWidth,
        child: pw.Text(
          '• $item',
          style: pw.TextStyle(fontSize: fontSize),
        ),
      );
    }).toList();
  }

  doc.addPage(
    pw.Page(
      pageFormat: const PdfPageFormat(_pageWidth, _pageHeight),
      margin: pw.EdgeInsets.zero,
      build: (pw.Context context) {
        return pw.Stack(
          children: [
            // Background: template as full-page raster image.
            pw.Positioned(
              left: 0,
              top: 0,
              child: pw.Image(
                backgroundImage,
                width: _pageWidth,
                height: _pageHeight,
                fit: pw.BoxFit.fill,
              ),
            ),

            // Von-Datum
            pw.Positioned(
              left: 194,
              top: _pageHeight - _y(104), // top=104 → bottom-left origin: y = 841.89 - 104
              child: pw.Text(
                dateFormat.format(eintrag.vonDatum),
                style: pw.TextStyle(fontSize: 9),
              ),
            ),

            // Bis-Datum
            pw.Positioned(
              left: 293,
              top: _pageHeight - _y(104),
              child: pw.Text(
                dateFormat.format(eintrag.bisDatum),
                style: pw.TextStyle(fontSize: 9),
              ),
            ),

            // Betriebliche Tätigkeiten block
            pw.Positioned(
              left: 76,
              top: _pageHeight - _y(155),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: bulletLines(
                  eintrag.betriebliches,
                  fontSize: 9,
                  lineHeight: 13,
                  maxWidth: 370,
                ),
              ),
            ),

            // Schulische Tätigkeiten block
            pw.Positioned(
              left: 76,
              top: _pageHeight - _y(389),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: bulletLines(
                  eintrag.schulisches,
                  fontSize: 9,
                  lineHeight: 13,
                  maxWidth: 370,
                ),
              ),
            ),

            // Zusatz block: Pause, Krank, Urlaub
            pw.Positioned(
              left: 458,
              top: _pageHeight - _y(155),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 100,
                    child: pw.Text(
                      'Pause: ${eintrag.pauseMinuten} Min',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ),
                  pw.Container(
                    width: 100,
                    child: pw.Text(
                      'Krank: ${eintrag.krankheitstage} Tg',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ),
                  pw.Container(
                    width: 100,
                    child: pw.Text(
                      'Urlaub: ${eintrag.urlaubstage} Tg',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  return doc.save();
}
