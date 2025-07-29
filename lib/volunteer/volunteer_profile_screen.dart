import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wisaal/core/theme.dart';
import 'package:wisaal/volunteer/edit_volunteer_profile_screen.dart';

class VolunteerProfileScreen extends StatefulWidget {
  const VolunteerProfileScreen({super.key});

  @override
  State<VolunteerProfileScreen> createState() => _VolunteerProfileScreenState();
}

class _VolunteerProfileScreenState extends State<VolunteerProfileScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profileData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // جلب بيانات المستخدم مع معلومات الجمعية
      final userResponse = await _supabase
          .from('users')
          .select('*, association:associated_with_association_id(full_name, phone)')
          .eq('id', user.id)
          .single();

      // جلب إحصائي��ت المهام
      final tasksResponse = await _supabase
          .from('donations')
          .select()
          .eq('volunteer_id', user.id);

      final completedTasks = tasksResponse.where((task) => task['status'] == 'completed').length;
      final inProgressTasks = tasksResponse.where((task) => task['status'] == 'in_progress').length;
      final assignedTasks = tasksResponse.where((task) => task['status'] == 'assigned').length;

      // جلب التقييمات
      final ratingsResponse = await _supabase
          .from('ratings')
          .select()
          .eq('volunteer_id', user.id);

      double avgRating = 0.0;
      if (ratingsResponse.isNotEmpty) {
        final totalRating = ratingsResponse.fold<double>(
          0.0,
          (sum, rating) => sum + (rating['rating'] ?? 0).toDouble(),
        );
        avgRating = totalRating / ratingsResponse.length;
      }

      setState(() {
        _profileData = {
          ...userResponse,
          'completed_tasks': completedTasks,
          'in_progress_tasks': inProgressTasks,
          'assigned_tasks': assignedTasks,
          'total_tasks': tasksResponse.length,
          'avg_rating': avgRating,
          'total_ratings': ratingsResponse.length,
        };
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تسجيل الخروج: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EditVolunteerProfileScreen(),
                ),
              ).then((_) => _fetchProfile()); // Refresh after edit
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('تسجيل الخروج'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profileData == null
              ? const Center(child: Text('لا توجد بيانات'))
              : RefreshIndicator(
                  onRefresh: _fetchProfile,
                  child: ListView(
                    padding: const EdgeInsets.all(SPACING_UNIT * 2),
                    children: [
                      _buildProfileHeader(context, _profileData!),
                      const SizedBox(height: SPACING_UNIT * 4),
                      _buildStatsSection(context, _profileData!),
                      const SizedBox(height: SPACING_UNIT * 4),
                      _buildAssociationSection(context, _profileData!),
                      const SizedBox(height: SPACING_UNIT * 4),
                      _buildInfoSection(context, _profileData!),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Map<String, dynamic> profile) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: COLOR_VOLUNTEER_ACCENT.withAlpha(25),
          backgroundImage: profile['avatar_url'] != null
              ? NetworkImage(profile['avatar_url'])
              : null,
          child: profile['avatar_url'] == null
              ? Icon(
                  Icons.person,
                  size: 50,
                  color: COLOR_VOLUNTEER_ACCENT,
                )
              : null,
        ),
        const SizedBox(height: SPACING_UNIT * 2),
        Text(
          profile['full_name'] ?? 'متطوع',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (profile['email'] != null)
          Text(
            profile['email'],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, Map<String, dynamic> profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          context,
          'النقاط',
          (profile['points'] ?? 0).toString(),
          Icons.star,
          COLOR_WARNING,
        ),
        _buildStatItem(
          context,
          'المهام المكتملة',
          (profile['completed_tasks'] ?? 0).toString(),
          Icons.check_circle,
          COLOR_SUCCESS,
        ),
        _buildStatItem(
          context,
          'التقييم',
          profile['avg_rating'] != null
              ? profile['avg_rating'].toStringAsFixed(1)
              : '0.0',
          Icons.star_rate,
          COLOR_INFO,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildAssociationSection(BuildContext context, Map<String, dynamic> profile) {
    final association = profile['association'];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SPACING_UNIT * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.business,
                  color: COLOR_ASSOCIATION_ACCENT,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'الجمعية المرتبطة',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: COLOR_ASSOCIATION_ACCENT,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SPACING_UNIT * 2),
            if (association != null) ...[
              _buildInfoRow('اسم الجمعية', association['full_name'] ?? 'غير محدد'),
              if (association['phone'] != null)
                _buildInfoRow('هاتف الجمعية', association['phone']),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(25),
                  borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
                  border: Border.all(color: Colors.orange.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'لم يتم ربطك بأي جمعية. يرجى التواصل مع الإدارة.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, Map<String, dynamic> profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SPACING_UNIT * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'معلومات إضافية',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: SPACING_UNIT * 2),
            _buildInfoRow('المدينة', profile['city'] ?? 'غير محدد'),
            _buildInfoRow('رقم الهاتف', profile['phone'] ?? 'غير محدد'),
            _buildInfoRow('إجمالي المهام', (profile['total_tasks'] ?? 0).toString()),
            _buildInfoRow('المهام قيد التنفيذ', (profile['in_progress_tasks'] ?? 0).toString()),
            _buildInfoRow('المهام المُعيَّنة', (profile['assigned_tasks'] ?? 0).toString()),
            _buildInfoRow('عدد التقييمات', (profile['total_ratings'] ?? 0).toString()),
            _buildInfoRow(
              'الحالة',
              (profile['is_active'] ?? false) ? 'نشط' : 'غير نشط',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}