
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'manager_dashboard.dart';
import 'manager_users.dart';
import 'manager_associations.dart';
import 'manager_volunteers.dart';
import 'manager_donors.dart';
import 'manager_notifications.dart';

import 'leaderboard_page.dart';

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _notManager = false;

  final List<Widget> _pages = const [
    ManagerDashboardScreen(),
    ManagerUsersScreen(),
    ManagerAssociationsScreen(),
    ManagerVolunteersScreen(),
    ManagerDonorsScreen(),
    ManagerNotificationsScreen(),
  ];

  final List<String> _titles = [
    'لوحة التحكم',
    'إدارة المستخدمين',
    'إدارة الجمعيات',
    'إدارة المتطوعين',
    'إدارة المتبرعين',
    'إدارة الإشعارات',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    if (session == null) {
      setState(() {
        _loading = false;
        _notManager = true;
      });
      return;
    }
    final userId = session.user.id;
    try {
      final res = await supabase.from('users').select().eq('id', userId).single();
      if (res['role'] == 'manager') {
        setState(() {
          _user = res;
          _loading = false;
          _notManager = false;
        });
      } else {
        setState(() {
          _loading = false;
          _notManager = true;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _notManager = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_notManager) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.gpp_bad_outlined, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'غير مصرح لك بالدخول',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red),
              ),
              const SizedBox(height: 8),
              Text('هذه الصفحة مخصصة للمدراء فقط.'),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('العودة'))
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: true,
      ),
      drawer: _buildDrawer(context),
      body: _pages[_selectedIndex],
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            accountName: Text(_user?['full_name'] ?? 'المدير', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimary)),
            accountEmail: Text(_user?['email'] ?? '', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary.withAlpha(204))),
            currentAccountPicture: CircleAvatar(
              backgroundColor: theme.colorScheme.onPrimary,
              child: Text(
                _user?['full_name']?.substring(0, 1) ?? 'M',
                style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(context, 0, 'لوحة التحكم', Icons.dashboard_outlined),
                _buildDrawerItem(context, 1, 'إدارة المستخدمين', Icons.people_outline),
                _buildDrawerItem(context, 2, 'إدارة الجمعيات', Icons.business_outlined),
                _buildDrawerItem(context, 3, 'إدارة المتطوعين', Icons.volunteer_activism_outlined),
                _buildDrawerItem(context, 4, 'إدارة المتبرعين', Icons.card_giftcard_outlined),
                _buildDrawerItem(context, 5, 'إدارة الإشعارات', Icons.notifications_outlined),

                ListTile(
                  leading: const Icon(Icons.leaderboard_outlined),
                  title: const Text('المتصدرون'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const LeaderboardPage(),
                    ));
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('تسجيل الخروج'),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, int index, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }
}
