import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme.dart';
import 'association_nearby_donations.dart';
import 'association_tasks.dart';
import 'association_volunteers.dart';
import 'association_profile.dart';
import 'association_notifications.dart';
import 'association_activation_codes.dart';
import 'association_reports.dart';
import 'association_inventory.dart';
import 'association_donation_details.dart';
import '../main.dart';


class AssociationHome extends StatefulWidget {
  const AssociationHome({super.key});

  @override
  State<AssociationHome> createState() => _AssociationHomeState();
}

class _AssociationHomeState extends State<AssociationHome>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final userProfile = await supabase
        .from('users')
        .select('full_name')
        .eq('id', user.id)
        .single();
    final associationName = userProfile['full_name'] ?? 'اسم الجمعية';

    final tasksFuture = supabase
        .from('donations')
        .select('donation_id')
        .eq('association_id', user.id);
    final pendingDonationsFuture = supabase
        .from('donations')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .limit(5);
    final volunteersFuture = supabase
        .from('users')
        .select('id')
        .eq('role', 'volunteer')
        .eq('is_active', true);
    final mealsFuture = supabase
        .from('inventory')
        .select('quantity')
        .eq('association_id', user.id)
        .eq('item_name', 'وجبة');
    final completedDonationsFuture = supabase
        .from('donations')
        .select('donation_id')
        .eq('association_id', user.id)
        .eq('status', 'completed');
    final cancelledDonationsFuture = supabase
        .from('donations')
        .select('donation_id')
        .eq('association_id', user.id)
        .eq('status', 'cancelled');
    final donationsWithLocationFuture = supabase
        .from('donations_with_coordinates')
        .select('title, latitude, longitude')
        .not('latitude', 'is', null)
        .not('longitude', 'is', null);
    final topVolunteersFuture =
        supabase.rpc('get_top_volunteers', params: {'limit_count': 5});

    final results = await Future.wait([
      tasksFuture,
      pendingDonationsFuture,
      volunteersFuture,
      mealsFuture,
      completedDonationsFuture,
      cancelledDonationsFuture,
      donationsWithLocationFuture,
      topVolunteersFuture
    ]);

    _animationController.forward();

    return {
      'association_name': associationName,
      'tasks_count': (results[0] as List).length,
      'pending_donations':
          (results[1] as List).map((e) => e as Map<String, dynamic>).toList(),
      'volunteers_count': (results[2] as List).length,
      'meals_count': (results[3] as List)
          .fold(0, (prev, element) => prev + (element['quantity'] as int)),
      'completed_donations_count': (results[4] as List).length,
      'cancelled_donations_count': (results[5] as List).length,
      'donations_with_location':
          (results[6] as List).map((e) => e as Map<String, dynamic>).toList(),
      'top_volunteers':
          (results[7] as List).map((e) => e as Map<String, dynamic>).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchDashboardData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('خطأ في تحميل البيانات: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد بيانات لعرضها'));
          }
          final data = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(context, data['association_name']),
                SliverPadding(
                  padding: const EdgeInsets.all(SPACING_UNIT * 2),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed([
                      const SizedBox(height: SPACING_UNIT),
                      _buildStatsGrid(context, data),
                      const SizedBox(height: SPACING_UNIT * 4),
                      _buildSectionTitle(context, 'الطلبات العاجلة'),
                      const SizedBox(height: SPACING_UNIT),
                      _buildUrgentRequests(context, data['pending_donations']),
                      const SizedBox(height: SPACING_UNIT * 4),
                      _buildSectionTitle(context, 'أداء الجمعية'),
                      const SizedBox(height: SPACING_UNIT),
                      _buildChart(context, data),
                      const SizedBox(height: SPACING_UNIT * 4),

                      _buildSectionTitle(context, 'المتطوعون المتصدرون'),
                      const SizedBox(height: SPACING_UNIT),
                      _buildLeaderboard(context, data['top_volunteers']),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      drawer: _buildDrawer(context),
    );
  }

  SliverAppBar _buildSliverAppBar(
      BuildContext context, String associationName) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      expandedHeight: 120.0,
      backgroundColor: COLOR_BACKGROUND,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 72, bottom: 16),
        title: Text(
          'مرحباً، $associationName',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
        ),
        background: Container(
          color: COLOR_BACKGROUND,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: COLOR_PRIMARY),
          tooltip: 'الإشعارات',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => const AssociationNotificationsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .headlineSmall
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> data) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: SPACING_UNIT,
          mainAxisSpacing: SPACING_UNIT,
          childAspectRatio: 1.5,
          children: [
            _StatCard(
              title: 'تبرعات اليوم',
              value: (data['tasks_count'] ?? 0).toString(),
              icon: Icons.favorite_border,
              color: COLOR_PRIMARY,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AssociationTasksScreen())),
            ),
            _StatCard(
              title: 'المتطوعين النشطين',
              value: (data['volunteers_count'] ?? 0).toString(),
              icon: Icons.people_alt_outlined,
              color: COLOR_ACCENT,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AssociationVolunteersScreen())),
            ),
            _StatCard(
              title: 'المهام المفتوحة',
              value: (data['pending_donations'] as List).length.toString(),
              icon: Icons.assignment_late_outlined,
              color: Colors.orange,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AssociationNearbyDonationsScreen())),
            ),
            _StatCard(
              title: 'الوجبات الموزعة',
              value: (data['meals_count'] ?? 0).toString(),
              icon: Icons.restaurant_menu,
              color: Colors.blue,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AssociationInventoryScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptDonation(String donationId) async {
    try {
      await Supabase.instance.client.from('donations').update({
        'status': 'accepted',
        'association_id': Supabase.instance.client.auth.currentUser!.id,
      }).eq('donation_id', donationId);
      setState(() {}); // Refresh the dashboard
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم قبول التبرع بنجاح!'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('حدث خطأ أثناء قبول التبرع: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildUrgentRequests(
      BuildContext context, List<Map<String, dynamic>> donations) {
    if (donations.isEmpty) {
      return const Text('لا توجد طلبات عاجلة حالياً.');
    }
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: donations.length,
        itemBuilder: (context, index) {
          final donation = donations[index];
          return _UrgentRequestCard(
              donation: donation, onAccept: _acceptDonation);
        },
      ),
    );
  }

  Widget _buildChart(BuildContext context, Map<String, dynamic> data) {
    final int completed = data['completed_donations_count'] ?? 0;
    final int pending = (data['pending_donations'] as List).length;
    final int cancelled = data['cancelled_donations_count'] ?? 0;
    final total = completed + pending + cancelled;

    List<PieChartSectionData> generateSections() {
      if (total == 0) {
        return [
          PieChartSectionData(
              value: 1,
              color: Colors.grey,
              title: 'لا توجد بيانات',
              radius: 50),
        ];
      }

      final sections = <PieChartSectionData>[
        if (completed > 0)
          PieChartSectionData(
            value: completed.toDouble(),
            color: COLOR_PRIMARY,
            title: '${(completed / total * 100).toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        if (pending > 0)
          PieChartSectionData(
            value: pending.toDouble(),
            color: Colors.orange,
            title: '${(pending / total * 100).toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        if (cancelled > 0)
          PieChartSectionData(
            value: cancelled.toDouble(),
            color: COLOR_ACCENT,
            title: '${(cancelled / total * 100).toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
      ];

      return sections;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(SPACING_UNIT * 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: PieChart(
          PieChartData(
            sections: generateSections(),
            sectionsSpace: 2,
            centerSpaceRadius: 40,
          ),
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text('اسم الجمعية',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.white)),
            accountEmail: Text(user?.email ?? '',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white70)),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Text('ج',
                  style: TextStyle(color: COLOR_PRIMARY, fontSize: 24)),
            ),
            decoration: const BoxDecoration(color: COLOR_PRIMARY),
          ),
          _buildDrawerItem(context,
              icon: Icons.home_outlined,
              text: 'الرئيسية',
              onTap: () => Navigator.pop(context)),
          _buildDrawerItem(context,
              icon: Icons.location_on_outlined,
              text: 'عرض التبرعات القريبة',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AssociationNearbyDonationsScreen()))),
          _buildDrawerItem(context,
              icon: Icons.assignment_outlined,
              text: 'مهامي',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AssociationTasksScreen()))),
          _buildDrawerItem(context,
              icon: Icons.group_outlined,
              text: 'إدارة المتطوعين',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AssociationVolunteersScreen()))),
          _buildDrawerItem(context,
              icon: Icons.person_outline,
              text: 'الملف الشخصي',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AssociationProfileScreen()))),
          _buildDrawerItem(context,
              icon: Icons.vpn_key_outlined,
              text: 'أكواد تفعيل المتطوعين',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AssociationActivationCodesScreen()))),
          _buildDrawerItem(context,
              icon: Icons.bar_chart_outlined,
              text: 'التقارير والإحصائيات',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AssociationReportsScreen()))),
          _buildDrawerItem(context,
              icon: Icons.inventory_2_outlined,
              text: 'إدارة المخزون',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AssociationInventoryScreen()))),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('الوضع الليلي'),
            trailing: Switch(
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (value) {
                WisaalApp.of(context)
                    .changeTheme(value ? ThemeMode.dark : ThemeMode.light);
              },
            ),
          ),
          const Divider(),
          _buildDrawerItem(context, icon: Icons.logout, text: 'تسجيل الخروج',
              onTap: () async {
            await Supabase.instance.client.auth.signOut();
            if (context.mounted) {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/auth', (route) => false);
            }
          }),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem(BuildContext context,
      {required IconData icon,
      required String text,
      required VoidCallback onTap}) {
    return ListTile(
      leading:
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(text),
      onTap: onTap,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM)),
      style: ListTileStyle.drawer,
    );
  }



  Widget _buildLeaderboard(
      BuildContext context, List<Map<String, dynamic>> volunteers) {
    if (volunteers.isEmpty) {
      return const Text('لا يوجد متطوعون لعرضهم.');
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: volunteers.length,
      itemBuilder: (context, index) {
        final volunteer = volunteers[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: SPACING_UNIT / 2),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: COLOR_PRIMARY.withAlpha((255 * 0.2).round()),
              child: Text('${index + 1}',
                  style: const TextStyle(
                      color: COLOR_PRIMARY, fontWeight: FontWeight.bold)),
            ),
            title: Text(volunteer['full_name'],
                style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text('${volunteer['completed_donations_count']} تبرعات',
                style: const TextStyle(
                    color: COLOR_ACCENT, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(SPACING_UNIT * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 32, color: color),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              color: color, fontWeight: FontWeight.bold)),
                  Text(title,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UrgentRequestCard extends StatelessWidget {
  final Map<String, dynamic> donation;
  final Future<void> Function(String) onAccept;

  const _UrgentRequestCard({required this.donation, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Card(
        margin: const EdgeInsetsDirectional.only(end: SPACING_UNIT),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  AssociationDonationDetailsScreen(donation: donation),
            ));
          },
          child: Padding(
            padding: const EdgeInsets.all(SPACING_UNIT * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donation['title'] ?? 'بلا عنوان',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: SPACING_UNIT / 2),
                Text(
                  donation['pickup_address'] ?? 'عنوان غير محدد',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Align(
                  alignment: AlignmentDirectional.bottomEnd,
                  child: ElevatedButton(
                    onPressed: () => onAccept(donation['donation_id']),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: SPACING_UNIT * 2),
                    ),
                    child: const Text('قبول'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
