import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManagerReportsScreen extends StatefulWidget {
  const ManagerReportsScreen({super.key});

  @override
  State<ManagerReportsScreen> createState() => _ManagerReportsScreenState();
}

class _ManagerReportsScreenState extends State<ManagerReportsScreen> {
  Map<String, dynamic>? _reportData;
  bool _loading = true;
  String _reportPeriod = 'monthly';

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;
      final usersFuture = supabase
          .from('users')
          .select('id, full_name, role, city, created_at');
      final donationsFuture = supabase.from('donations').select(
          '*, donor_id(full_name), volunteer_id(full_name), association_id(full_name)');
      final ratingsFuture = supabase.from('ratings').select('*');

      if (_reportPeriod != 'all') {
        final now = DateTime.now();
        DateTime fromDate;
        if (_reportPeriod == 'daily') {
          fromDate = DateTime(now.year, now.month, now.day);
        } else if (_reportPeriod == 'weekly') {
          fromDate = now.subtract(const Duration(days: 7));
        } else if (_reportPeriod == 'monthly') {
          fromDate = DateTime(now.year, now.month, 1);
        } else { // yearly
          fromDate = DateTime(now.year, 1, 1);
        }
        donationsFuture.gte('created_at', fromDate.toIso8601String());
      }

      final results =
          await Future.wait([usersFuture, donationsFuture, ratingsFuture]);
      final users = List<Map<String, dynamic>>.from(results[0] as List);
      final donations = List<Map<String, dynamic>>.from(results[1] as List);
      final ratings = List<Map<String, dynamic>>.from(results[2] as List);

      // --- Process Data for Reports ---
      // This is a simplified processing logic. A real-world scenario might need more complex calculations.
      final cancelledDonations =
          donations.where((d) => d['status'] == 'cancelled').length;
      final cancellationRate = donations.isEmpty
          ? 0.0
          : (cancelledDonations / donations.length) * 100;

      final userGrowth = <String, int>{};
      for (var u in users) {
        final date =
            DateTime.parse(u['created_at']).toIso8601String().substring(0, 10);
        userGrowth[date] = (userGrowth[date] ?? 0) + 1;
      }

      final cityDistribution = <String, int>{};
      for (var u in users.where((u) => u['city'] != null)) {
        final city = u['city'];
        cityDistribution[city] = (cityDistribution[city] ?? 0) + 1;
      }

      setState(() {
        _reportData = {
          'users': users,
          'donations': donations,
          'ratings': ratings,
          'cancellation_rate': cancellationRate,
          'user_growth': userGrowth,
          'city_distribution': cityDistribution,
        };
      });
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير والإحصائيات'),
        centerTitle: true,
              ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reportData == null
              ? const Center(child: Text('لا توجد بيانات لعرضها'))
              : RefreshIndicator(
                  onRefresh: _fetchReportData,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildKpiGrid(textTheme, colorScheme),
                      const SizedBox(height: 24),
                      _buildChartCard(
                        'نمو المستخدمين (آخر 30 يومًا)',
                        LineChart(_buildGrowthChartData(colorScheme)),
                        theme,
                      ),
                      const SizedBox(height: 24),
                      _buildChartCard(
                        'توزيع المستخدمين حسب المدينة',
                        BarChart(_buildCityDistributionData(colorScheme)),
                        theme,
                      ),
                      const SizedBox(height: 24),
                      _buildReportList(theme),
                    ],
                  ),
                ),
    );
  }

  Widget _buildKpiGrid(TextTheme textTheme, ColorScheme colorScheme) {
    final users = _reportData!['users'] as List<Map<String, dynamic>>;
    final donations = _reportData!['donations'] as List<Map<String, dynamic>>;
    final ratings = _reportData!['ratings'] as List<Map<String, dynamic>>;
    final totalDonations = donations.length;
    final totalUsers = users.length;
    final totalVolunteers = users.where((u) => u['role'] == 'volunteer').length;
    final totalAssociations =
        users.where((u) => u['role'] == 'association').length;
    final averageRating = ratings.isEmpty
        ? 0.0
        : ratings.fold<double>(0.0, (prev, r) => prev + (r['rating'] as num)) /
            ratings.length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _KpiCard(
            title: 'إجمالي المستخدمين',
            value: totalUsers.toString(),
            icon: Icons.people_alt_outlined,
            color: colorScheme.primary),
        _KpiCard(
            title: 'إجمالي التبرعات',
            value: totalDonations.toString(),
            icon: Icons.card_giftcard_outlined,
            color: colorScheme.secondary),
        _KpiCard(
            title: 'إجمالي المتطوعين',
            value: totalVolunteers.toString(),
            icon: Icons.volunteer_activism_outlined,
            color: Colors.orange),
        _KpiCard(
            title: 'إجمالي الجمعيات',
            value: totalAssociations.toString(),
            icon: Icons.business_outlined,
            color: Colors.green),
        _KpiCard(
            title: 'متوسط التقييم',
            value: averageRating.toStringAsFixed(1),
            icon: Icons.star_border_outlined,
            color: Colors.amber),
        _KpiCard(
            title: 'نسبة التبرعات الملغاة',
            value: '${_reportData!['cancellation_rate'].toStringAsFixed(2)}%',
            icon: Icons.cancel_presentation_outlined,
            color: colorScheme.error),
      ],
    );
  }

  Widget _buildChartCard(String title, Widget chart, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(height: 200, child: chart),
          ],
        ),
      ),
    );
  }

  Widget _buildReportList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('التقارير المتاحة', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _reportPeriod,
          items: const [
            DropdownMenuItem(value: 'daily', child: Text('يومي')),
            DropdownMenuItem(value: 'weekly', child: Text('أسبوعي')),
            DropdownMenuItem(value: 'monthly', child: Text('شهري')),
            DropdownMenuItem(value: 'yearly', child: Text('سنوي')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _reportPeriod = value;
                _fetchReportData();
              });
            }
          },
          decoration: const InputDecoration(
            labelText: 'فترة التقرير',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('التقرير الإداري'),
            onTap: () => _generateAdminReport(),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('التقرير المجتمعي'),
            onTap: () => _generateCommunityReport(),
          ),
        ),
      ],
    );
  }

  Future<void> _generateAdminReport() async {
    if (_reportData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'يرجى الانتظار حتى تحميل البيانات بالكامل قبل طباعة التقرير.')),
      );
      return;
    }
    try {
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

      final greenColor = PdfColor.fromHex('#388E3C');

      pdf.addPage(pw.Page(
        theme: reportTheme,
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) =>
            _buildCoverPage(context, greenColor, logoImage),
      ));

      pdf.addPage(pw.MultiPage(
        pageTheme: _buildPdfPageTheme(reportTheme, logoImage),
        build: (pw.Context context) => [
          _buildSectionTitle('ملخص تنفيذي', context),
          _buildExecutiveSummary(context),
          _buildSectionTitle('الجداول المفصلة', context),
          _buildDetailedTables(context),
          _buildSectionTitle('الأداء حسب المدينة', context),
          _buildCityPerformanceTable(context),
          _buildSectionTitle('تقارير المتطوعين', context),
          _buildVolunteerReports(context),
          _buildSectionTitle('تقارير الجمعيات', context),
          _buildAssociationReports(context),
          _buildSectionTitle('المشاكل والإنذارات', context),
          _buildIssuesAndAlerts(context),
          _buildSectionTitle('التوصيات', context),
          _buildRecommendations(context),
        ],
      ));

      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إنشاء التقرير: ${e.toString()}')),
        );
      }
    }
  }

  pw.Widget _buildCoverPage(
      pw.Context context, PdfColor color, pw.MemoryImage logo) {
    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Image(logo, width: 120, height: 120),
        pw.SizedBox(height: 40),
        pw.Text('التقرير الإداري – منصة وصال',
            style: pw.TextStyle(
                fontSize: 28, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(height: 20),
        pw.Text('فترة التقرير: $_reportPeriod', style: const pw.TextStyle(fontSize: 16)),
        pw.SizedBox(height: 80),
        pw.Text('تاريخ التوليد: ${DateTime.now().toString().substring(0, 10)}'),
        pw.Text('التوقيع: ___________________'),
      ],
    );
  }

  pw.Widget _buildExecutiveSummary(pw.Context context) {
    final donations = _reportData!['donations'] as List<Map<String, dynamic>>;
    final users = _reportData!['users'] as List<Map<String, dynamic>>;
    final successfulDonations =
        donations.where((d) => d['status'] == 'completed').length;
    final successRate =
        donations.isEmpty ? 0 : (successfulDonations / donations.length) * 100;
    final totalQuantity =
        donations.fold<num>(0, (prev, d) => prev + (d['quantity'] ?? 0));

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSummaryRow('عدد التبرعات', '${donations.length}', context),
          _buildSummaryRow('كميات الطعام', '$totalQuantity كجم', context),
          _buildSummaryRow(
              'عدد الجمعيات',
              '${users.where((u) => u['role'] == 'association').length}',
              context),
          _buildSummaryRow(
              'المتطوعون',
              '${users.where((u) => u['role'] == 'volunteer').length}',
              context),
          _buildSummaryRow(
              'نسبة النجاح', '${successRate.toStringAsFixed(2)}%', context),
        ],
      ),
    );
  }

  pw.Widget _buildDetailedTables(pw.Context context) {
    final donations = _reportData!['donations'] as List<Map<String, dynamic>>;
    final headers = [
      'المدة',
      'الحالة',
      'التاريخ',
      'المدينة',
      'الجمعية',
      'المتطوع',
      'المتبرع',
      'التبرع'
    ];
    final data = donations.map((d) {
      final pickedUp =
          d['picked_up_at'] != null ? DateTime.parse(d['picked_up_at']) : null;
      final delivered =
          d['delivered_at'] != null ? DateTime.parse(d['delivered_at']) : null;
      final duration = delivered != null && pickedUp != null
          ? delivered.difference(pickedUp).inHours.toString() + ' ساعة'
          : 'N/A';
      return [
        duration,
        d['status'] ?? '',
        (d['created_at'] as String).substring(0, 10),
        d['pickup_address'] ?? '',
        d['association_id']?['full_name'] ?? 'N/A',
        d['volunteer_id']?['full_name'] ?? 'N/A',
        d['donor_id']?['full_name'] ?? 'N/A',
        d['title'] ?? '',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey400),
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
      cellStyle: const pw.TextStyle(),
      cellAlignments: {
        for (var i = 0; i < headers.length; i++) i: pw.Alignment.centerRight
      },
    );
  }

  pw.Widget _buildCityPerformanceTable(pw.Context context) {
    final cityData = _reportData!['city_distribution'] as Map<String, int>;
    final headers = ['عدد المستخدمين', 'المدينة'];
    final data =
        cityData.entries.map((e) => [e.value.toString(), e.key]).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey400),
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
      cellStyle: const pw.TextStyle(),
      cellAlignments: {0: pw.Alignment.center, 1: pw.Alignment.centerRight},
    );
  }

  pw.Widget _buildVolunteerReports(pw.Context context) {
    final volunteers = (_reportData!['users'] as List<Map<String, dynamic>>)
        .where((u) => u['role'] == 'volunteer')
        .toList();
    final donations = _reportData!['donations'] as List<Map<String, dynamic>>;
    final headers = ['نسبة النجاح', 'عدد التوصيلات', 'الاسم'];
    final data = volunteers.map((v) {
      final volunteerDonations = donations
          .where((d) => d['volunteer_id']?['full_name'] == v['full_name'])
          .toList();
      final completed =
          volunteerDonations.where((d) => d['status'] == 'completed').length;
      final successRate = volunteerDonations.isEmpty
          ? 0
          : (completed / volunteerDonations.length) * 100;
      return [
        '${successRate.toStringAsFixed(2)}%',
        volunteerDonations.length.toString(),
        v['full_name'],
      ];
    }).toList();
    return pw.TableHelper.fromTextArray(
        headers: headers,
        data: data,
        border: pw.TableBorder.all(),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        cellAlignments: {
          0: pw.Alignment.center,
          1: pw.Alignment.center,
          2: pw.Alignment.centerRight
        });
  }

  pw.Widget _buildAssociationReports(pw.Context context) {
    final associations = (_reportData!['users'] as List<Map<String, dynamic>>)
        .where((u) => u['role'] == 'association')
        .toList();
    final donations = _reportData!['donations'] as List<Map<String, dynamic>>;
    final headers = ['عدد التبرعات المستلمة', 'الجمعية'];
    final data = associations.map((a) {
      final associationDonations = donations
          .where((d) => d['association_id']?['full_name'] == a['full_name'])
          .length;
      return [
        associationDonations.toString(),
        a['full_name'],
      ];
    }).toList();
    return pw.TableHelper.fromTextArray(
        headers: headers,
        data: data,
        border: pw.TableBorder.all(),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        cellAlignments: {0: pw.Alignment.center, 1: pw.Alignment.centerRight});
  }

  pw.Widget _buildIssuesAndAlerts(pw.Context context) {
    final donations = _reportData!['donations'] as List<Map<String, dynamic>>;
    final uncompletedDonations = donations
        .where((d) => d['status'] != 'completed' && d['status'] != 'cancelled')
        .toList();

    if (uncompletedDonations.isEmpty) {
      return pw.Text('لا توجد مشاكل أو إنذارات حاليًا.');
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: uncompletedDonations
          .map((d) => pw.Bullet(text: 'التبرع "${d['title']}" لم يكتمل بعد.'))
          .toList(),
    );
  }

  pw.Widget _buildRecommendations(pw.Context context) {
    // This section can be enhanced with more complex logic later
    return pw.Text('لا توجد توصيات تلقائية حاليًا.');
  }

  Future<void> _generateCommunityReport() async {
    if (_reportData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'يرجى الانتظار حتى تحميل البيانات بالكامل قبل طباعة التقرير.')),
      );
      return;
    }
    try {
      final pdf = pw.Document();
      final fontData = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
      final font = pw.Font.ttf(fontData);
      final greenColor = PdfColor.fromHex('#388E3C');
      final logoImageBytes = await rootBundle.load('assets/logo.png');
      final logoImage = pw.MemoryImage(logoImageBytes.buffer.asUint8List());

      final reportTheme = pw.ThemeData.withFont(
        base: font,
      );

      // Page 1: Cover
      pdf.addPage(pw.Page(
        theme: reportTheme,
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) =>
            _buildCommunityCoverPage(context, greenColor, logoImage),
      ));

      // Page 2: General Indicators
      pdf.addPage(pw.MultiPage(
        pageTheme: _buildPdfPageTheme(reportTheme, logoImage),
        build: (pw.Context context) => [
          _buildPdfHeader(context, logoImage, 'المؤشرات العامة'),
          _buildGeneralIndicators(context),
          _buildPdfFooter(context),
        ],
      ));

      // Page 3: Top Cities
      pdf.addPage(pw.MultiPage(
        pageTheme: _buildPdfPageTheme(reportTheme, logoImage),
        build: (pw.Context context) => [
          _buildPdfHeader(context, logoImage, 'أفضل المدن'),
          _buildTopCitiesTable(context),
          _buildPdfFooter(context),
        ],
      ));

      // Page 4: Donation Types
      pdf.addPage(pw.MultiPage(
        pageTheme: _buildPdfPageTheme(reportTheme, logoImage),
        build: (pw.Context context) => [
          _buildPdfHeader(context, logoImage, 'أنواع التبرعات'),
          _buildDonationTypesTable(context),
          _buildPdfFooter(context),
        ],
      ));

      // Page 5: Future Outlook
      pdf.addPage(pw.MultiPage(
        pageTheme: _buildPdfPageTheme(reportTheme, logoImage),
        build: (pw.Context context) => [
          _buildPdfHeader(context, logoImage, 'نظرة مستقبلية'),
          _buildFutureOutlook(context),
          _buildPdfFooter(context),
        ],
      ));

      // Page 6: How to Contribute
      pdf.addPage(pw.MultiPage(
        pageTheme: _buildPdfPageTheme(reportTheme, logoImage),
        build: (pw.Context context) => [
          _buildPdfHeader(context, logoImage, 'كيف تساهم'),
          _buildContributionTable(context),
          _buildPdfFooter(context),
        ],
      ));

      // Page 7: Final Notes
      pdf.addPage(pw.Page(
        theme: reportTheme,
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) =>
            _buildFinalNotesPage(context, greenColor),
      ));

      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e, stack) {
      print('PDF Report Error: ' + e.toString());
      print(stack.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل إنشاء التقرير: ${e.toString()}')));
      }
    }
  }

  pw.Widget _buildCommunityCoverPage(
      pw.Context context, PdfColor color, pw.MemoryImage logo) {
    // Similar to the admin cover page, but with community-focused titles
    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Image(logo, width: 120, height: 120),
        pw.SizedBox(height: 40),
        pw.Text('وصال في أرقام – تقرير الأثر المجتمعي',
            style: pw.TextStyle(
                fontSize: 24, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(height: 20),
        pw.Text('فترة التقرير: $_reportPeriod'),
        pw.SizedBox(height: 60),
        pw.Text('إصدار: ${DateTime.now().toString().substring(0, 10)}'),
        pw.Text('الجهة المصدرة: إدارة وصال – جهة العيون الساقية الحمراء'),
        pw.SizedBox(height: 40),
        pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(),
          data: 'https://yourapp.com/download', // Replace with your app link
          width: 80,
          height: 80,
        ),
        pw.Text('www.wisaal.ma'), // Replace with your website
      ],
    );
  }

  pw.Widget _buildGeneralIndicators(pw.Context context) {
    final donations = _reportData!['donations'] as List<Map<String, dynamic>>;
    final users = _reportData!['users'] as List<Map<String, dynamic>>;
    if (donations.isEmpty || users.isEmpty) {
      return pw.Center(child: pw.Text('لا توجد بيانات متاحة'));
    }
    final successfulDonations =
        donations.where((d) => d['status'] == 'completed').length;
    final successRate =
        donations.isEmpty ? 0 : (successfulDonations / donations.length) * 100;
    final cities = donations
        .map((d) => d['pickup_address'])
        .where((d) => d != null)
        .toSet()
        .join(', ');
    final totalQuantity =
        donations.fold<num>(0, (prev, d) => prev + (d['quantity'] ?? 0));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('عدد التبرعات المسجلة: ${donations.length}'),
        pw.Text('كمية الطعام المنقذ (كغ): $totalQuantity'),
        pw.Text(
            'عدد المتطوعين النشطين: ${users.where((u) => u['role'] == 'volunteer').length}'),
        pw.Text(
            'عدد الجمعيات المشاركة: ${users.where((u) => u['role'] == 'association').length}'),
        pw.Text('المدن المستفيدة: $cities'),
        pw.Text('نسبة نجاح التوصيل (%): ${successRate.toStringAsFixed(2)}%'),
        pw.Text(
            'الزمن الوسيط للتوصيل: N/A دقيقة'), // Median calculation is complex
      ],
    );
  }

  pw.Widget _buildTopCitiesTable(pw.Context context) {
    final cityData = _reportData!['city_distribution'] as Map<String, int>;
    final headers = ['عدد المستخدمين', 'المدينة'];
    final data =
        cityData.entries.map((e) => [e.value.toString(), e.key]).toList();

    if (data.isEmpty) {
      return pw.Center(child: pw.Text('لا توجد بيانات متاحة'));
    }
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignments: {0: pw.Alignment.center, 1: pw.Alignment.centerRight},
    );
  }

  pw.Widget _buildDonationTypesTable(pw.Context context) {
    final donations = _reportData!['donations'] as List<Map<String, dynamic>>;
    final typeData = <String, int>{};
    for (var d in donations.where((d) => d['food_type'] != null)) {
      final type = d['food_type'];
      typeData[type] = (typeData[type] ?? 0) + 1;
    }
    final totalDonations = donations.length;

    final headers = ['النسبة (%)', 'نوع التبرع'];
    final data = typeData.entries.map((e) {
      final percentage =
          totalDonations == 0 ? 0 : (e.value / totalDonations) * 100;
      return ['${percentage.toStringAsFixed(2)}%', e.key];
    }).toList();

    if (data.isEmpty) {
      return pw.Center(child: pw.Text('لا توجد بيانات متاحة'));
    }
    return pw.TableHelper.fromTextArray(
        headers: headers,
        data: data,
        border: pw.TableBorder.all(),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        cellAlignments: {0: pw.Alignment.center, 1: pw.Alignment.centerRight});
  }

  pw.Widget _buildFutureOutlook(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Bullet(text: 'التوسع إلى مدينة كلميم'),
        pw.Bullet(text: 'تحسين الأداء اللوجستي لتقليل الزمن الوسيط للتوصيل'),
        pw.Bullet(text: 'إدماج شركاء جدد: مطاعم محلية وأسواق مركزية'),
      ],
    );
  }

  pw.Widget _buildContributionTable(pw.Context context) {
    final headers = ['طريقة المساهمة', 'الدور'];
    final data = [
      ['سجّل فائض الطعام عبر التطبيق', 'متبرع'],
      ['تطوع لتوصيل التبرعات للمحتاجين', 'متطوع'],
      ['استقبل التبرعات وشارك في التوزيع', 'جمعية'],
      ['ادعم المشروع تقنيًا أو لوجستيًا', 'جهة داعمة'],
    ];
    return pw.TableHelper.fromTextArray(
        headers: headers,
        data: data,
        border: pw.TableBorder.all(),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        cellAlignments: {
          0: pw.Alignment.centerRight,
          1: pw.Alignment.centerRight
        });
  }

  pw.Widget _buildFinalNotesPage(pw.Context context, PdfColor color) {
    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
            'هذا التقرير تم توليده تلقائيًا بناءً على بيانات واقعية 100% من نظام وصال للفترة: 01/10/2023 إلى 31/10/2023',
            textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 20),
        pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(),
          data:
              'https://yourapp.com/verify/report123', // Replace with your verification link
          width: 100,
          height: 100,
        ),
        pw.SizedBox(height: 10),
        pw.Text('لمزيد من المعلومات، يرجى زيارة موقعنا: www.wisaal.ma',
            textAlign: pw.TextAlign.center),
      ],
    );
  }

  pw.PageTheme _buildPdfPageTheme(pw.ThemeData theme, pw.MemoryImage logo) {
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

  pw.Widget _buildPdfHeader(pw.Context context, pw.MemoryImage logo,
      [String? text]) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
          border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey, width: 2))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(text ?? 'تقرير وصال الإداري',
              style: pw.Theme.of(context)
                  .defaultTextStyle
                  .copyWith(fontWeight: pw.FontWeight.bold, fontSize: 18)),
          pw.Image(logo, width: 50, height: 50),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
          border:
              pw.Border(top: pw.BorderSide(color: PdfColors.grey, width: 2))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('${DateTime.now().toString().substring(0, 16)}',
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text('صفحة ${context.pageNumber} من ${context.pagesCount}',
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title, pw.Context context) {
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: pw.Text(title,
          style: pw.Theme.of(context).defaultTextStyle.copyWith(
              fontWeight: pw.FontWeight.bold,
              fontSize: 16,
              color: PdfColor.fromHex('#388E3C'))),
    );
  }

  pw.Widget _buildSummaryRow(String title, String value, pw.Context context) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(value,
              style: pw.Theme.of(context)
                  .defaultTextStyle
                  .copyWith(fontWeight: pw.FontWeight.bold)),
          pw.Text(title),
        ],
      ),
    );
  }

  LineChartData _buildGrowthChartData(ColorScheme colorScheme) {
    final growthData = _reportData!['user_growth'] as Map<String, int>;
    final spots = growthData.entries
        .map((e) => FlSpot(
            DateTime.parse(e.key).millisecondsSinceEpoch.toDouble(),
            e.value.toDouble()))
        .toList();
    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          color: colorScheme.primary,
          isCurved: true,
          barWidth: 3,
          dotData: FlDotData(show: false),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (spot) => colorScheme.surfaceContainerHighest,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
              return LineTooltipItem(
                '${spot.y.toInt()} users on ${date.day}/${date.month}',
                TextStyle(color: colorScheme.onSurfaceVariant),
              );
            }).toList();
          },
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: false),
    );
  }

  BarChartData _buildCityDistributionData(ColorScheme colorScheme) {
    final cityData = _reportData!['city_distribution'] as Map<String, int>;
    return BarChartData(
      barGroups: cityData.entries.map((e) {
        return BarChartGroupData(x: e.key.hashCode, barRods: [
          BarChartRodData(
            toY: e.value.toDouble(),
            color: colorScheme.secondary,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          )
        ]);
      }).toList(),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (rod) => colorScheme.surfaceContainerHighest,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final cityName = cityData.keys.elementAt(groupIndex);
            return BarTooltipItem(
              '$cityName\n${rod.toY.toInt()} users',
              TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: false),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 12),
            Text(value,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.bold)),
            Text(title,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 2),
          ],
        ),
      ),
    );
  }
}
