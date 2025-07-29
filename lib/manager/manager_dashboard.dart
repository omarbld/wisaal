
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'manager_users.dart';
import 'manager_ratings.dart';
import 'manager_activation_codes.dart';
import 'manager_reports.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _loading = true);
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final usersFuture = _supabase.from('users').select('role, is_active');
      final donationsFuture = _supabase.from('donations').select('status, created_at').gte('created_at', sevenDaysAgo.toIso8601String());
      final tasksFuture = _supabase.from('donations').select('status');

      final results = await Future.wait([usersFuture, donationsFuture, tasksFuture]);
      final users = results[0] as List<dynamic>;
      final donations = results[1] as List<dynamic>;
      final tasks = results[2] as List<dynamic>;

      // Process weekly donations
      final weeklyDonations = List<double>.filled(7, 0);
      for (var d in donations) {
        final day = DateTime.parse(d['created_at']).weekday % 7;
        weeklyDonations[day]++;
      }

      setState(() {
        _stats = {
          'total_users': users.length,
          'active_users': users.where((u) => u['is_active'] == true).length,
          'managers': users.where((u) => u['role'] == 'manager').length,
          'associations': users.where((u) => u['role'] == 'association').length,
          'volunteers': users.where((u) => u['role'] == 'volunteer').length,
          'donors': users.where((u) => u['role'] == 'donor').length,
          'total_donations': donations.length,
          'completed_donations': donations.where((d) => d['status'] == 'completed').length,
          'total_tasks': tasks.length,
          'completed_tasks': tasks.where((t) => t['status'] == 'completed').length,
          'weekly_donations': weeklyDonations,
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
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? const Center(child: Text('لا توجد بيانات لعرضها'))
              : RefreshIndicator(
                  onRefresh: _fetchStats,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildQuickActions(theme),
                      const SizedBox(height: 24),
                      _buildStatsGrid(theme),
                      const SizedBox(height: 24),
                      _buildCharts(theme),
                      const SizedBox(height: 24),
                      _buildUserStats(theme),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsGrid(ThemeData theme) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.8, // Adjusted for better layout
      children: [
        _StatCard(title: 'إجمالي التبرعات', value: _stats!['total_donations'].toString(), icon: Icons.card_giftcard_outlined, color: theme.colorScheme.secondary),
        _StatCard(title: 'التبرعات المكتملة', value: '${_stats!['completed_donations']}', icon: Icons.check_circle_outline, color: Colors.green.shade700),
        _StatCard(title: 'إجمالي المهام', value: _stats!['total_tasks'].toString(), icon: Icons.list_alt_outlined, color: theme.colorScheme.primary),
        _StatCard(title: 'المهام المكتملة', value: _stats!['completed_tasks'].toString(), icon: Icons.task_alt_outlined, color: Colors.orange.shade700),
      ],
    );
  }

  Widget _buildCharts(ThemeData theme) {
    return Column(
      children: [
        _buildPieChartCard('توزيع الأدوار', _buildRoleChartData(theme), theme),
        const SizedBox(height: 24),
        _buildBarChartCard('التبرعات خلال الأسبوع', _buildWeeklyDonationsData(theme, _stats!), theme),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('إجراءات سريعة', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            _QuickActionButton(icon: Icons.people_alt_outlined, label: 'إدارة المستخدمين', onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManagerUsersScreen()));
            }),
            _QuickActionButton(icon: Icons.star_border_outlined, label: 'مراجعة التقييمات', onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManagerRatingsScreen()));
            }),
            _QuickActionButton(icon: Icons.vpn_key_outlined, label: 'إنشاء رموز تفعيل', onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManagerActivationCodesScreen()));
            }),
            _QuickActionButton(icon: Icons.analytics_outlined, label: 'عرض التقارير', onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManagerReportsScreen()));
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildUserStats(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('إحصائيات المستخدمين', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: [
            _StatCard(title: 'إجمالي المستخدمين', value: _stats!['total_users'].toString(), icon: Icons.people_outline, color: theme.colorScheme.primary),
            _StatCard(title: 'المستخدمين النشطين', value: _stats!['active_users'].toString(), icon: Icons.person_outline, color: theme.colorScheme.secondary),
            _StatCard(title: 'المتطوعين', value: _stats!['volunteers'].toString(), icon: Icons.directions_run, color: theme.colorScheme.tertiary),
            _StatCard(title: 'الجمعيات', value: _stats!['associations'].toString(), icon: Icons.business_outlined, color: Colors.brown.shade700),
            _StatCard(title: 'المتبرعين', value: _stats!['donors'].toString(), icon: Icons.favorite_border_outlined, color: Colors.pink.shade700),
            _StatCard(title: 'المدراء', value: _stats!['managers'].toString(), icon: Icons.admin_panel_settings_outlined, color: Colors.blueGrey.shade700),
          ],
        ),
      ],
    );
  }

  Widget _buildPieChartCard(String title, List<PieChartSectionData> sections, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(PieChartData(sections: sections)),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildRoleChartData(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return [
      PieChartSectionData(value: _stats!['donors'].toDouble(), title: 'المتبرعين', color: colorScheme.primary, radius: 80),
      PieChartSectionData(value: _stats!['volunteers'].toDouble(), title: 'المتطوعين', color: colorScheme.secondary, radius: 80),
      PieChartSectionData(value: _stats!['associations'].toDouble(), title: 'الجمعيات', color: colorScheme.tertiary, radius: 80),
      PieChartSectionData(value: _stats!['managers'].toDouble(), title: 'المدراء', color: Colors.grey, radius: 80),
    ];
  }

  }

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: color.withAlpha(26),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(value, style: theme.textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
              Text(title, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildBarChartCard(String title, BarChartData data, ThemeData theme) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(data),
          ),
        ],
      ),
    ),
  );
}

BarChartData _buildWeeklyDonationsData(ThemeData theme, Map<String, dynamic> stats) {
  final weeklyData = stats['weekly_donations'] as List<double>;
  final days = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];

  return BarChartData(
    barGroups: List.generate(weeklyData.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [BarChartRodData(toY: weeklyData[index], color: theme.colorScheme.primary, width: 16)],
      );
    }),
    titlesData: FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) => Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(days[value.toInt() % 7], style: theme.textTheme.bodySmall),
          ),
          reservedSize: 30,
        ),
      ),
      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    ),
  );
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        foregroundColor: theme.colorScheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}
