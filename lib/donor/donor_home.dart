import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_donation.dart';
import 'donations_list.dart';
import 'donor_profile.dart';
import 'donor_notifications.dart';
import 'donation_details.dart';

import 'leaderboard_page.dart';

class DonorHome extends StatefulWidget {
  const DonorHome({super.key});

  @override
  State<DonorHome> createState() => _DonorHomeState();
}

class _DonorHomeState extends State<DonorHome> {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> _fetchStatsAndUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final donationsFuture = _supabase
        .from('donations')
        .select('title, status, created_at')
        .eq('donor_id', user.id)
        .order('created_at', ascending: false);

    final userProfileFuture =
        _supabase.from('users').select('full_name').eq('id', user.id).single();

    final results = await Future.wait([donationsFuture, userProfileFuture]);

    final donations = results[0] as List<dynamic>;
    final userProfile = results[1] as Map<String, dynamic>;

    final total = donations.length;
    final completed = donations.where((d) => d['status'] == 'completed').length;
    final pending = donations.where((d) => d['status'] == 'pending').length;
    final inProgress =
        donations.where((d) => d['status'] == 'in_progress').length;

    final recentDonations = donations.take(3).toList();

    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'in_progress': inProgress,
      'userName': userProfile['full_name'] ?? 'المتبرع الكريم',
      'recent_donations': recentDonations,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المتبرع'),
        centerTitle: true,
        automaticallyImplyLeading: false, // This removes the back button
      ),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _fetchStatsAndUser(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('لا توجد بيانات لعرضها'));
            }

            final data = snapshot.data!;
            final stats = data;
            final recentDonations = data['recent_donations'] as List<dynamic>;

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  'مرحباً بك، ${stats['userName']}!',
                  style: textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'شكراً لمساهمتك في حفض النعمة.',
                  style: textTheme.titleMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                _buildActionButton(
                  context: context,
                  icon: Icons.add_circle_outline,
                  label: 'إضافة تبرع جديد',
                  onTap: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (_) => const AddDonationScreen()))
                        .then((_) => setState(() {}));
                  },
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 24),
                _buildStatsGrid(stats, colorScheme, textTheme),
                const SizedBox(height: 24),
                _buildRecentDonations(context, recentDonations, textTheme, colorScheme),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats, ColorScheme colorScheme,
      TextTheme textTheme) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _StatCard(
          title: 'إجمالي التبرعات',
          value: stats['total'] ?? 0,
          icon: Icons.inventory_2_outlined,
          color: colorScheme.primary,
        ),
        _StatCard(
          title: 'تبرعات مكتملة',
          value: stats['completed'] ?? 0,
          icon: Icons.check_circle_outline,
          color: Colors.green.shade700,
        ),
        _StatCard(
          title: 'قيد الانتظار',
          value: stats['pending'] ?? 0,
          icon: Icons.pending_actions_outlined,
          color: colorScheme.secondary,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    bool isSecondary = false,
  }) {
    return isSecondary
        ? OutlinedButton.icon(
            icon: Icon(icon),
            label: Text(label),
            onPressed: onTap,
          )
        : ElevatedButton.icon(
            icon: Icon(icon),
            label: Text(label),
            onPressed: onTap,
          );
  }

  Widget _buildDrawer(BuildContext context) {
    final supabase = Supabase.instance.client;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.person_pin_circle_outlined, color: colorScheme.onPrimary, size: 40),
                const SizedBox(height: 8),
                Text(
                  'قائمة المتبرع',
                  style: textTheme.headlineSmall?.copyWith(color: colorScheme.onPrimary),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('إضافة تبرع جديد'),
            onTap: () {
              Navigator.of(context).pop(); // Close the drawer
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const AddDonationScreen()))
                  .then((_) => setState(() {}));
            },
          ),

          ListTile(
            leading: const Icon(Icons.leaderboard_outlined),
            title: const Text('المتصدرون'),
            onTap: () {
              Navigator.of(context).pop(); // Close the drawer
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const LeaderboardPage(),
              ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_outlined),
            title: const Text('عرض سجل التبرعات'),
            onTap: () {
              Navigator.of(context).pop(); // Close the drawer
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const DonationsListScreen(),
              ));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('الملف الشخصي'),
            onTap: () {
              Navigator.of(context).pop(); // Close the drawer
              Navigator.of(context)
                  .push(MaterialPageRoute(
                builder: (_) => const DonorProfileScreen(),
              ))
                  .then((_) => setState(() {}));
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('الإشعارات'),
            onTap: () {
              Navigator.of(context).pop(); // Close the drawer
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const DonorNotificationsScreen(),
              ));
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: colorScheme.error),
            title: Text('تسجيل الخروج', style: TextStyle(color: colorScheme.error)),
            onTap: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/auth', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withAlpha(77)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(26),
              radius: 20,
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              '$value',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildRecentDonations(BuildContext context,
    List<dynamic> donations, TextTheme textTheme, ColorScheme colorScheme) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'أحدث التبرعات',
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      if (donations.isEmpty)
        const Text('لا توجد تبرعات حديثة.')
      else
        ...donations.map((donation) {
          final status = donation['status'] ?? '';
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => DonationDetailsScreen(donation: donation),
                ));
              },
              child: ListTile(
                dense: true,
                leading: Icon(Icons.fastfood, color: colorScheme.primary, size: 28),
                title: Text(donation['title'] ?? 'بلا عنوان', style: textTheme.titleMedium),
                subtitle: Text('الحالة: ${_statusText(status)}', style: textTheme.bodySmall),
                trailing: Icon(_statusIcon(status),
                    color: _statusColor(status, colorScheme)),
              ),
            ),
          );
        }),
    ],
  );
}

String _statusText(String status) {
  switch (status) {
    case 'pending':
      return 'بانتظار القبول';
    case 'accepted':
      return 'مقبولة';
    case 'in_progress':
      return 'جاري الاستلام';
    case 'completed':
      return 'تم التسليم';
    case 'cancelled':
      return 'ملغاة';
    default:
      return status;
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'pending':
      return Icons.hourglass_empty;
    case 'accepted':
      return Icons.check;
    case 'in_progress':
      return Icons.delivery_dining;
    case 'completed':
      return Icons.check_circle;
    case 'cancelled':
      return Icons.cancel;
    default:
      return Icons.help_outline;
  }
}

Color _statusColor(String status, ColorScheme colorScheme) {
  switch (status) {
    case 'pending':
      return colorScheme.secondary;
    case 'accepted':
    case 'in_progress':
      return colorScheme.tertiary;
    case 'completed':
      return Colors.green.shade700;
    case 'cancelled':
      return colorScheme.error;
    default:
      return colorScheme.onSurface.withAlpha(179);
  }
}

