import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../data/seed_data.dart';
import '../state/app_state.dart';
import '../util.dart';
import '../l10n.dart';

/// Export ya PDF na Excel kwa rekodi moja au Ledger nzima.
class ExportService {
  // ---------- Kuhifadhi faili ----------
  /// Inarudisha njia ya faili, au null kama mtumiaji amegairi.
  static Future<String?> save(String fileName, List<int> bytes, String ext) async {
    final data = Uint8List.fromList(bytes);
    var path = await FilePicker.platform.saveFile(
      dialogTitle: tr('Hifadhi faili', 'Save file'),
      fileName: fileName,
      bytes: data,
      type: FileType.custom,
      allowedExtensions: [ext],
    );
    if (path == null) return null;
    if (!path.toLowerCase().endsWith('.$ext')) path = '$path.$ext';
    if (!Platform.isAndroid && !Platform.isIOS) {
      await File(path).writeAsBytes(data);
    }
    return path;
  }

  static String stamp() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  // ---------- PDF helpers ----------
  static Future<pw.MemoryImage> _logo() async =>
      pw.MemoryImage((await rootBundle.load('assets/logo.png')).buffer.asUint8List());

  static pw.TextStyle _b(double s) =>
      pw.TextStyle(fontSize: s, fontWeight: pw.FontWeight.bold);
  static pw.TextStyle _n(double s) => pw.TextStyle(fontSize: s);

  static pw.Widget _header(pw.MemoryImage logo) => pw.Row(children: [
        pw.Image(logo, width: 48, height: 48),
        pw.SizedBox(width: 10),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(tr('WANAWAKE WAKATOLIKI TANZANIA', 'CATHOLIC WOMEN OF TANZANIA'), style: _b(13)),
          pw.Text('WA-WA-TA', style: _n(10)),
        ]),
      ]);

  static pw.Widget _cellW(String s,
          {bool bold = false, bool right = false, PdfColor? bg}) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        color: bg,
        child: pw.Text(s, style: bold ? _b(10) : _n(10)),
      );

  static pw.Widget _table(
    List<String> head,
    List<List<String>> rows, {
    Set<int> right = const {},
    Map<int, pw.TableColumnWidth>? widths,
    int? boldRow,
  }) {
    const headBg = PdfColor.fromInt(0xFFF8E1E4);
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: .5),
      columnWidths: widths,
      children: [
        pw.TableRow(children: [
          for (var i = 0; i < head.length; i++)
            _cellW(head[i], bold: true, right: right.contains(i), bg: headBg),
        ]),
        for (var r = 0; r < rows.length; r++)
          pw.TableRow(children: [
            for (var i = 0; i < rows[r].length; i++)
              _cellW(rows[r][i], bold: boldRow == r, right: right.contains(i)),
          ]),
      ],
    );
  }

  static pw.Widget _kv(String title, List<List<String>> rows) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(title, style: _b(11)),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: .5),
          columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(3)},
          children: [
            for (final r in rows)
              pw.TableRow(children: [_cellW(r[0], bold: true), _cellW(r[1])]),
          ],
        ),
        pw.SizedBox(height: 12),
      ]);

  static String _tsh(int n) => 'TSh ${fmt(n)}';

  static List<List<String>> _recordRows(RecordInfo i) => [
        [tr('Aina ya rekodi', 'Record Type'), i.r.isKanda ? tr('Ada ya Kanda', 'Zone Fee') : tr('Ada ya Jumuiya', 'Community Fee')],
        [tr('Risiti No.', 'Receipt No.'), i.r.noText],
        [tr('Tarehe', 'Date'), dateText(i.r.date)],
        if (!i.r.isKanda) [tr('Jina la Jumuiya', 'Community Name'), i.r.jumuiya],
        [i.r.isKanda ? tr('Ada ya Kanda', 'Zone Fee') : tr('Ada ya Jumuiya', 'Community Fee'), _tsh(i.r.amount)],
      ];

  static List<List<String>> _kandaRows(RecordInfo i) => [
        [tr('Jina la Kanda', 'Zone Name'), i.kanda.name],
        [tr('Ada Kanda', 'Zone Fee'), i.kandaFee > 0 ? _tsh(i.kandaFee) : tr('Haijajazwa', 'Not entered')],
        [tr('Idadi ya Jumuiya', 'Community Count'), '${i.kanda.jumuiya.length}'],
        [tr('Jumuiya zilizolipa', 'Communities Paid'), '${i.paid} / ${i.kanda.jumuiya.length}'],
        [tr('Jumla ya ada za Jumuiya', 'Total Community Fees'), _tsh(i.jumuiyaTotal)],
        [tr('Jumla kuu ya Kanda', 'Zone Grand Total'), _tsh(i.total)],
      ];

  // ---------- Rekodi moja: PDF ----------
  static Future<Uint8List> recordPdf(AppState app, Receipt r) async {
    final i = app.infoFor(r);
    final logo = await _logo();
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        _header(logo),
        pw.SizedBox(height: 16),
        pw.Text(r.isKanda ? tr('TAARIFA YA ADA YA KANDA', 'ZONE FEE STATEMENT') : tr('RISITI YA JUMUIYA', 'COMMUNITY RECEIPT'),
            style: _b(15)),
        pw.SizedBox(height: 10),
        _kv(tr('Taarifa za Rekodi', 'Record Details'), _recordRows(i)),
        _kv(tr('Taarifa za Kanda', 'Zone Details'), _kandaRows(i)),
        pw.Text(tr('Jumuiya za Kanda hii', 'Communities in this Zone'), style: _b(11)),
        pw.SizedBox(height: 4),
        _table(
          [tr('Jumuiya', 'Community'), tr('Jumla ya ada (TSh)', 'Total Fees (TSh)'), tr('Taarifa', 'Records')],
          [
            for (final j in i.rows) [j.name, fmt(j.amount), '${j.count}'],
          ],
          right: {1},
          widths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1.4),
            2: const pw.FlexColumnWidth(1.2),
          },
        ),
        pw.SizedBox(height: 18),
        pw.Text('POWERED BY E-LAPS', style: _n(8)),
      ],
    ));
    return doc.save();
  }

  // ---------- Rekodi moja: Excel ----------
  static List<int> recordExcel(AppState app, Receipt r) {
    final i = app.infoFor(r);
    final ex = Excel.createExcel();
    final sh = ex['Sheet1'];
    sh.setColumnWidth(0, 30);
    sh.setColumnWidth(1, 30);
    sh.setColumnWidth(2, 16);
    void kv(String a, String b) => sh.appendRow([TextCellValue(a), TextCellValue(b)]);
    sh.appendRow([TextCellValue('WANAWAKE WAKATOLIKI TANZANIA (WA-WA-TA)')]);
    sh.appendRow([TextCellValue(r.isKanda ? tr('TAARIFA YA ADA YA KANDA', 'ZONE FEE STATEMENT') : tr('RISITI YA JUMUIYA', 'COMMUNITY RECEIPT'))]);
    sh.appendRow([TextCellValue('')]);
    sh.appendRow([TextCellValue(tr('TAARIFA ZA REKODI', 'RECORD DETAILS'))]);
    for (final row in _recordRows(i)) {
      kv(row[0], row[1]);
    }
    sh.appendRow([TextCellValue('')]);
    sh.appendRow([TextCellValue(tr('TAARIFA ZA KANDA', 'ZONE DETAILS'))]);
    for (final row in _kandaRows(i)) {
      kv(row[0], row[1]);
    }
    sh.appendRow([TextCellValue('')]);
    sh.appendRow([TextCellValue(tr('JUMUIYA ZA KANDA HII', 'COMMUNITIES IN THIS ZONE'))]);
    sh.appendRow([TextCellValue(tr('Jumuiya', 'Community')), TextCellValue(tr('Jumla ya ada (TSh)', 'Total Fees (TSh)')), TextCellValue(tr('Taarifa', 'Records'))]);
    for (final j in i.rows) {
      sh.appendRow([TextCellValue(j.name), IntCellValue(j.amount), IntCellValue(j.count)]);
    }
    return ex.save()!;
  }

  // ---------- Jumuiya moja (au Kanda): taarifa zote zilizoingizwa ----------
  static Future<Uint8List> entriesPdf(AppState app, Kanda k, String? j) async {
    final i = app.infoForKanda(k);
    final list = app.entriesFor(k.name, j).reversed.toList(); // za kwanza kwanza
    final sum = list.fold<int>(0, (s, r) => s + r.amount);
    final logo = await _logo();
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        _header(logo),
        pw.SizedBox(height: 16),
        pw.Text(j == null ? tr('TAARIFA ZA ADA YA KANDA', 'ZONE FEE RECORDS') : tr('TAARIFA ZA JUMUIYA', 'COMMUNITY RECORDS'), style: _b(15)),
        if (j != null) pw.Text(j, style: _b(12)),
        pw.SizedBox(height: 10),
        _kv(tr('Muhtasari', 'Summary'), [
          [tr('Idadi ya taarifa', 'Number of Records'), '${list.length}'],
          [tr('Jumla ya ada', 'Total Fees'), _tsh(sum)],
        ]),
        _kv(tr('Taarifa za Kanda', 'Zone Details'), _kandaRows(i)),
        pw.Text(tr('Orodha ya taarifa zilizoingizwa', 'Entered Records'), style: _b(11)),
        pw.SizedBox(height: 4),
        _table(
          [tr('Risiti No.', 'Receipt No.'), tr('Tarehe', 'Date'), tr('Ada (TSh)', 'Fee (TSh)')],
          [for (final r in list) [r.noText, dateText(r.date), fmt(r.amount)]],
          right: {2},
        ),
        pw.SizedBox(height: 18),
        pw.Text('POWERED BY E-LAPS', style: _n(8)),
      ],
    ));
    return doc.save();
  }

  static List<int> entriesExcel(AppState app, Kanda k, String? j) {
    final i = app.infoForKanda(k);
    final list = app.entriesFor(k.name, j).reversed.toList();
    final sum = list.fold<int>(0, (s, r) => s + r.amount);
    final ex = Excel.createExcel();
    final sh = ex['Sheet1'];
    sh.setColumnWidth(0, 30);
    sh.setColumnWidth(1, 30);
    sh.setColumnWidth(2, 16);
    void kv(String a, String b) => sh.appendRow([TextCellValue(a), TextCellValue(b)]);
    sh.appendRow([TextCellValue('WANAWAKE WAKATOLIKI TANZANIA (WA-WA-TA)')]);
    sh.appendRow([TextCellValue(j == null ? tr('TAARIFA ZA ADA YA KANDA', 'ZONE FEE RECORDS') : tr('TAARIFA ZA JUMUIYA: $j', 'COMMUNITY RECORDS: $j'))]);
    sh.appendRow([TextCellValue('')]);
    kv('Idadi ya taarifa', '${list.length}');
    kv('Jumla ya ada', _tsh(sum));
    sh.appendRow([TextCellValue('')]);
    sh.appendRow([TextCellValue(tr('TAARIFA ZA KANDA', 'ZONE DETAILS'))]);
    for (final row in _kandaRows(i)) {
      kv(row[0], row[1]);
    }
    sh.appendRow([TextCellValue('')]);
    sh.appendRow([TextCellValue(tr('TAARIFA ZILIZOINGIZWA', 'ENTERED RECORDS'))]);
    sh.appendRow([TextCellValue(tr('Risiti No.', 'Receipt No.')), TextCellValue(tr('Tarehe', 'Date')), TextCellValue(tr('Ada (TSh)', 'Fee (TSh)'))]);
    for (final r in list) {
      sh.appendRow([TextCellValue(r.noText), TextCellValue(dateText(r.date)), IntCellValue(r.amount)]);
    }
    return ex.save()!;
  }

  // ---------- Ledger nzima: PDF ----------
  static Future<Uint8List> ledgerPdf(AppState app, List<Receipt> list) async {
    final logo = await _logo();
    final doc = pw.Document();
    final sum = list.fold<int>(0, (s, r) => s + r.amount);
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      build: (ctx) => [
        _header(logo),
        pw.SizedBox(height: 12),
        pw.Text(tr('DAFTARI LA REKODI - ${DateTime.now().year}', 'RECORDS LEDGER - ${DateTime.now().year}'), style: _b(14)),
        pw.Text(tr('Imetolewa: ${dateText(DateTime.now())}   |   Rekodi: ${list.length}', 'Generated: ${dateText(DateTime.now())}   |   Records: ${list.length}'),
            style: _n(10)),
        pw.SizedBox(height: 10),
        _table(
          [tr('Risiti', 'Receipt'), tr('Aina', 'Type'), tr('Jina la Kanda', 'Zone Name'), tr('Jina la Jumuiya', 'Community Name'), tr('Ada (TSh)', 'Fee (TSh)'), tr('Ada Kanda', 'Zone Fee'), tr('Tarehe', 'Date')],
          [
            for (final r in list)
              [
                r.noText,
                r.aina,
                r.kanda,
                r.isKanda ? '-' : r.jumuiya,
                fmt(r.amount),
                fmt(app.kandaFee[r.kanda] ?? 0),
                dateText(r.date),
              ],
            ['', '', '', tr('JUMLA', 'TOTAL'), fmt(sum), '', ''],
          ],
          right: {4, 5},
          boldRow: list.length,
          widths: {
            0: const pw.FixedColumnWidth(135),
            1: const pw.FixedColumnWidth(58),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FixedColumnWidth(76),
            5: const pw.FixedColumnWidth(76),
            6: const pw.FixedColumnWidth(66),
          },
        ),
        pw.SizedBox(height: 14),
        pw.Text('POWERED BY E-LAPS', style: _n(8)),
      ],
    ));
    return doc.save();
  }

  // ---------- Ledger nzima: Excel ----------
  static List<int> ledgerExcel(AppState app, List<Receipt> list) {
    final ex = Excel.createExcel();
    final sh = ex['Sheet1'];
    const widths = [12.0, 12.0, 30.0, 30.0, 16.0, 16.0, 14.0];
    for (var c = 0; c < widths.length; c++) {
      sh.setColumnWidth(c, widths[c]);
    }
    sh.appendRow([TextCellValue('WANAWAKE WAKATOLIKI TANZANIA (WA-WA-TA) - RECORDS LEDGER ${DateTime.now().year}')]);
    sh.appendRow([TextCellValue('')]);
    sh.appendRow([
      for (final h in [tr('Risiti No.', 'Receipt No.'), tr('Aina', 'Type'), tr('Jina la Kanda', 'Zone Name'), tr('Jina la Jumuiya', 'Community Name'), tr('Ada (TSh)', 'Fee (TSh)'), tr('Ada Kanda (TSh)', 'Zone Fee (TSh)'), tr('Tarehe', 'Date')])
        TextCellValue(h),
    ]);
    var sum = 0;
    for (final r in list) {
      sum += r.amount;
      sh.appendRow([
        TextCellValue(r.noText),
        TextCellValue(r.aina),
        TextCellValue(r.kanda),
        TextCellValue(r.isKanda ? '-' : r.jumuiya),
        IntCellValue(r.amount),
        IntCellValue(app.kandaFee[r.kanda] ?? 0),
        TextCellValue(dateText(r.date)),
      ]);
    }
    sh.appendRow([
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(tr('JUMLA', 'TOTAL')),
      IntCellValue(sum),
    ]);
    return ex.save()!;
  }
}
