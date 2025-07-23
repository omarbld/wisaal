import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class PdfReportHelper {
  static Future<Uint8List> generateReport(
      Map<String, dynamic> data, String reportType) async {
    final pdf = pw.Document();

    // Load fonts and logo
    final fontData = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
    final boldFontData = await rootBundle.load("assets/fonts/Cairo-Bold.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldTtf = pw.Font.ttf(boldFontData);
    final logoImageBytes = await rootBundle.load('assets/logo.png');
    final logoImage = pw.MemoryImage(logoImageBytes.buffer.asUint8List());

    final reportTheme = pw.ThemeData.withFont(
      base: ttf,
      bold: boldTtf,
    );

    pdf.addPage(pw.MultiPage(
      pageTheme: _buildPdfPageTheme(reportTheme, logoImage),
      footer: (context) => _buildPdfFooter(context),
      build: (pw.Context context) => [
        _buildReportHeader(context, data, reportType, logoImage),
        _buildSectionTitle('ملخص الأداء', context),
        _buildOverviewTable(context, data),
        _buildSectionTitle('قائمة التبرعات', context),
        _buildDonationsTable(context, data),
        _buildSectionTitle('أفضل المتطوعين', context),
        _buildVolunteersTable(context, data),
        _buildSectionTitle('ملاحظات وتوصيات', context),
        _buildNotesAndRecommendations(context),
        _buildSectionTitle('توزيع أنواع الطعام', context),
        _buildFoodTypeDistributionChart(context, data),
        _buildSectionTitle('حالة التبرعات', context),
        _buildDonationStatusChart(context, data),
      ],
    ));

    return pdf.save();
  }

  static pw.PageTheme _buildPdfPageTheme(
      pw.ThemeData theme, pw.MemoryImage logo) {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      textDirection: pw.TextDirection.rtl,
      buildBackground: (context) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Watermark(
            angle: 20,
            child: pw.Opacity(
                opacity: 0.05,
                child: pw.Image(logo, alignment: pw.Alignment.center))),
      ),
    );
  }

  static pw.Widget _buildReportHeader(pw.Context context, Map<String, dynamic> data,
      String reportType, pw.MemoryImage logo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('تقرير أداء الجمعية - ${data['association_name'] ?? ''}',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Image(logo, height: 60),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text('نوع التقرير: $reportType'),
        pw.Text(
            'التاريخ: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}'),
        pw.Divider(height: 30),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title, pw.Context context) {
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: pw.Text(title,
          style: pw.Theme.of(context).defaultTextStyle.copyWith(
              fontWeight: pw.FontWeight.bold,
              fontSize: 16,
              color: PdfColor.fromHex('#388E3C'))),
    );
  }

  static pw.Widget _buildOverviewTable(
      pw.Context context, Map<String, dynamic> data) {
    final headers = ['القيمة', 'المؤشر'];
    final tableData = _buildOverviewData(data);

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: tableData,
      border: pw.TableBorder.all(color: PdfColors.grey400),
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
      cellStyle: const pw.TextStyle(),
      cellAlignments: {
        0: pw.Alignment.centerRight,
        1: pw.Alignment.centerLeft,
      },
    );
  }

  static pw.Widget _buildDonationsTable(
      pw.Context context, Map<String, dynamic> data) {
    final donations = (data['donations'] as List<dynamic>? ?? [])
        .map((d) => d as Map<String, dynamic>)
        .toList();
    final headers = [
      'اسم المتطوع',
      'الحالة',
      'التاريخ',
      'عنوان التبرع',
      'رقم التبرع'
    ];
    final tableData = _buildDonationsData(donations);

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: tableData,
      border: pw.TableBorder.all(color: PdfColors.grey400),
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
      cellStyle: const pw.TextStyle(),
      cellAlignments: {
        0: pw.Alignment.centerRight,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.center,
      },
    );
  }

  static pw.Widget _buildVolunteersTable(
      pw.Context context, Map<String, dynamic> data) {
    final volunteers = (data['top_volunteers'] as List<dynamic>? ?? []);
    final headers = ['التعليق', 'التقييم', 'اسم المتطوع'];
    final tableData = _buildVolunteersData(volunteers);

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: tableData,
      border: pw.TableBorder.all(color: PdfColors.grey400),
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
      cellStyle: const pw.TextStyle(),
      cellAlignments: {
        0: pw.Alignment.centerRight,
        1: pw.Alignment.center,
        2: pw.Alignment.centerLeft,
      },
    );
  }

  static pw.Widget _buildNotesAndRecommendations(pw.Context context) {
    // This can be populated with dynamic data later
    return pw.Container(
      height: 100,
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(8.0),
        child: pw.Text('لا توجد ملاحظات أو توصيات حاليًا.'),
      ),
    );
  }

  static pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
          border:
              pw.Border(top: pw.BorderSide(color: PdfColors.grey, width: 2))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
              'تاريخ التوليد: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text('صفحة ${context.pageNumber} من ${context.pagesCount}',
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  static List<List<String>> _buildOverviewData(Map<String, dynamic> data) {
    final overviewData = <List<String>>[];
    if (data.containsKey('total_donations')) {
      overviewData
          .add([data['total_donations'].toString(), 'عدد التبرعات المستلمة']);
    }
    if (data.containsKey('active_volunteers')) {
      overviewData.add(
          [data['active_volunteers'].toString(), 'عدد المتطوعين المشاركين']);
    }
    // Add more data points as needed
    return overviewData;
  }

  static List<List<String>> _buildDonationsData(
      List<Map<String, dynamic>> donations) {
    return donations
        .map((d) => <String>[
              d['volunteer_name'] ?? '',
              d['status'] ?? '',
              d['created_at'] != null
                  ? DateFormat('yyyy-MM-dd')
                      .format(DateTime.parse(d['created_at']))
                  : '',
              d['title'] ?? '',
              d['id'].toString(),
            ])
        .toList();
  }

  static List<List<String>> _buildVolunteersData(List<dynamic> volunteers) {
    return volunteers
        .map((v) => <String>[
              v['comment'] ?? '',
              v['rating'].toString(),
              v['name'] ?? '',
            ])
        .toList();
  }

  static pw.Widget _buildFoodTypeDistributionChart(
      pw.Context context, Map<String, dynamic> data) {
    final foodTypeDist = (data['food_type_dist'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, v as int));

    if (foodTypeDist.isEmpty) {
      return pw.Text('لا توجد بيانات لعرضها');
    }

    final chartData = foodTypeDist.entries.map((e) {
      return pw.PieDataSet(
        legend: e.key,
        value: e.value.toDouble(),
        color: PdfColors.primaries[foodTypeDist.keys.toList().indexOf(e.key) % PdfColors.primaries.length],
      );
    }).toList();

    return pw.Chart(
      datasets: chartData,
      title: pw.Text('توزيع أنواع الطعام'),
      grid: pw.PieGrid(),
    );
  }

  static pw.Widget _buildDonationStatusChart(
      pw.Context context, Map<String, dynamic> data) {
    final monthlyDonations = (data['monthly_donations'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, v as int));

    if (monthlyDonations.isEmpty) {
      return pw.Text('لا توجد بيانات لعرضها');
    }

    final chartData = monthlyDonations.entries.map((e) {
      return pw.BarDataSet<pw.PointChartValue>(
        legend: e.key,
        data: [pw.PointChartValue(monthlyDonations.keys.toList().indexOf(e.key).toDouble(), e.value.toDouble())],
        color: PdfColors.primaries[monthlyDonations.keys.toList().indexOf(e.key) % PdfColors.primaries.length],
      );
    }).toList();

    return pw.Chart(
      datasets: chartData,
      title: pw.Text('حالة التبرعات'),
      grid: pw.CartesianGrid(
        xAxis: pw.FixedAxis([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]),
        yAxis: pw.FixedAxis([0, 10, 20, 30, 40, 50]),
      ),
    );
  }
}
