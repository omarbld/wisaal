
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssociationReportsScreen extends StatefulWidget {
  const AssociationReportsScreen({super.key});

  @override
  State<AssociationReportsScreen> createState() => _AssociationReportsScreenState();
}

class _AssociationReportsScreenState extends State<AssociationReportsScreen> {
  late Future<Map<String, dynamic>> _reportDataFuture;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _reportDataFuture = _fetchReportData();
  }

  Future<Map<String, dynamic>> _fetchReportData() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    final response = await supabase.rpc(
      'get_association_report_data',
      params: {'p_association_id': user.id, 'p_period': 'all'},
    );
    
    return response as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير والإحصائيات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // You can customize the shared content
              Share.share('تحقق من تقرير إنجازاتنا في تطبيق وصال! #وصال #مكافحة_هدر_الطعام');
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _reportDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          final reportData = snapshot.data!;
          final foodTypeDistribution = (reportData['food_type_dist'] as Map<String, dynamic>?) ?? {};
          final monthlyDonations = (reportData['monthly_donations'] as Map<String, dynamic>?) ?? {};
          final topDonors = (reportData['top_donors'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
          final topVolunteers = (reportData['top_volunteers'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsGrid(reportData),
                const SizedBox(height: 24),
                _buildSectionTitle('توزيع التبرعات حسب نوع الطعام'),
                _buildPieChart(foodTypeDistribution),
                const SizedBox(height: 24),
                _buildSectionTitle('التبرعات الشهرية'),
                _buildBarChart(monthlyDonations),
                const SizedBox(height: 24),
                _buildSectionTitle('أفضل المتبرعين'),
                _buildTopList(topDonors, 'full_name', 'count'),
                const SizedBox(height: 24),
                _buildSectionTitle('أفضل المتطوعين'),
                _buildTopList(topVolunteers, 'full_name', 'avg_rating'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> reportData) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard('إجمالي التبرعات', reportData['total_donations']?.toString() ?? '0', Icons.all_inbox),
        _buildStatCard('التبرعات المكتملة', reportData['completed_donations']?.toString() ?? '0', Icons.check_circle),
        _buildStatCard('المتطوعون النشطون', reportData['active_volunteers']?.toString() ?? '0', Icons.people),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPieChart(Map<String, dynamic> data) {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: data.entries.map((entry) {
            final index = data.keys.toList().indexOf(entry.key);
            return PieChartSectionData(
              color: Colors.primaries[index % Colors.primaries.length],
              value: (entry.value as num).toDouble(),
              title: '${entry.key}\n${entry.value}',
              radius: 80,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, dynamic> data) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: data.entries.map((entry) {
            final month = DateTime.parse('${entry.key}-01').month;
            return BarChartGroupData(
              x: month,
              barRods: [
                BarChartRodData(
                  toY: (entry.value as num).toDouble(),
                  color: Colors.blue,
                  width: 16,
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString());
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopList(List<Map<String, dynamic>> data, String titleKey, String valueKey) {
    return Card(
      elevation: 2,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text((index + 1).toString()),
            ),
            title: Text(item[titleKey]?.toString() ?? ''),
            trailing: Text(
              (item[valueKey] as num).toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}
