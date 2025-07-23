import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class EnhancedManagerDashboard extends StatefulWidget {
  const EnhancedManagerDashboard({super.key});

  @override
  State<EnhancedManagerDashboard> createState() =>
      _EnhancedManagerDashboardState();
}

class _EnhancedManagerDashboardState extends State<EnhancedManagerDashboard> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final result =
          await _supabase.rpc('get_manager_dashboard_comprehensive').select();
      setState(() {
        dashboardData = result.isNotEmpty ? result.first : null;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم المحسنة'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : dashboardData == null
              ? const Center(child: Text('خطأ في تحميل البيانات'))
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildOverviewCards(),
                      const SizedBox(height: 16),
                      _buildRecentActivity(),
                      const SizedBox(height: 16),
                      _buildTrends(),
                      const SizedBox(height: 16),
                      _buildCharts(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOverviewCards() {
    final overview = dashboardData!['overview'] ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نظرة عامة',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildStatCard(
                  'إجمالي المستخدمين',
                  (overview['total_users'] ?? 0).toString(),
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatCard(
                  'إجمالي التبرعات',
                  (overview['total_donations'] ?? 0).toString(),
                  Icons.volunteer_activism,
                  Colors.green,
                ),
                _buildStatCard(
                  'التبرعات المكتملة',
                  (overview['completed_donations'] ?? 0).toString(),
                  Icons.check_circle,
                  Colors.orange,
                ),
                _buildStatCard(
                  'المتطوعين النشطين',
                  (overview['active_volunteers'] ?? 0).toString(),
                  Icons.person_pin,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final activity = dashboardData!['recent_activity'] ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'النشاط اليوم',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildActivityTile(
              'مستخدمين جدد',
              (activity['new_users_today'] ?? 0).toString(),
              Icons.person_add,
              Colors.blue,
            ),
            _buildActivityTile(
              'تبرعات جديدة',
              (activity['donations_today'] ?? 0).toString(),
              Icons.add_circle,
              Colors.green,
            ),
            _buildActivityTile(
              'تبرعات مكتملة',
              (activity['completed_today'] ?? 0).toString(),
              Icons.done_all,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTile(
      String title, String value, IconData icon, Color color) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withAlpha(26),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildTrends() {
    final trends = dashboardData!['trends'] ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الاتجاهات',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('التبرعات هذا الأسبوع'),
              trailing: Text(
                (trends['donations_this_week'] ?? 0).toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              title: const Text('التبرعات الأسبوع الماضي'),
              trailing: Text(
                (trends['donations_last_week'] ?? 0).toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              title: const Text('معدل الإكمال'),
              trailing: Text(
                '${trends['completion_rate'] ?? 0}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts() {
    final chartData = dashboardData!['chart_data'] ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الرسوم البيانية',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildDonationsChart(chartData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationsChart(Map<String, dynamic> chartData) {
    final donations = chartData['weekly_donations'] as List? ?? [];

    if (donations.isEmpty) {
      return const Center(child: Text('لا توجد بيانات للعرض'));
    }

    final spots = donations.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), (entry.value as num).toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: const FlTitlesData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}
