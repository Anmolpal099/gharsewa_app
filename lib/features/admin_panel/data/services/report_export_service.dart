import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Export admin reports as CSV (clipboard) or PDF (share/print).
class ReportExportService {
  Future<void> exportCsv({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln(headers.map(_escapeCsv).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(_escapeCsv).join(','));
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
  }

  Future<void> exportPdf({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    String? subtitle,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(title, style: pw.TextStyle(fontSize: 22)),
          ),
          if (subtitle != null) pw.Text(subtitle),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: '${title.replaceAll(' ', '_').toLowerCase()}.pdf',
    );
  }

  List<List<String>> rowsFromReportData(Map<String, dynamic> report) {
    final rawRows = report['rows'];
    if (rawRows is! List || rawRows.isEmpty) return [];

    final first = rawRows.first;
    if (first is! Map) return [];

    final keys = first.keys.map((k) => k.toString()).toList();
    final data = <List<String>>[
      for (final item in rawRows)
        if (item is Map)
          keys.map((k) => '${item[k]}').toList(),
    ];
    return data;
  }

  List<String> headersFromReportData(Map<String, dynamic> report) {
    final rawRows = report['rows'];
    if (rawRows is! List || rawRows.isEmpty) return const [];
    final first = rawRows.first;
    if (first is! Map) return const [];
    return first.keys.map((k) => k.toString()).toList();
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
