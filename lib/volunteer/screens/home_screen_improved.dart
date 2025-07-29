import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wisaal/core/theme.dart';
import 'package:wisaal/volunteer/volunteer_task_details.dart';
import 'package:wisaal/common/utils/phone_utils.dart';
import 'package:wisaal/common/widgets/error_handler.dart';
import 'package:wisaal/volunteer/screens/advanced_search_screen.dart';
import 'package:wisaal/volunteer/screens/all_volunteer_tasks_screen.dart';

class HomeScreenImproved extends StatefulWidget {
  const HomeScreenImproved({super.key});

  @override
  State<HomeScreenImproved> createState() => _HomeScreenImprovedState();
}

class _HomeScreenImprovedState extends State<HomeScreenImproved> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _availableDonations = [];
  List<Map<String, dynamic>> _myTasks = [];
  List<Map<String, dynamic>> _notifications = [];
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _associationInfo;
  bool _loading = true;
  int _selectedFilter = 0; // 0: الكل، 1: عاجل، 2: قريب
  int _unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDashboardData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _loading = true);
    
    try {
      await Future.wait([
        _fetchDashboardStats(),
        _fetchAssociationInfo(),
        _fetchAvailableDonations(),
        _fetchMyActiveTasks(),
        _fetchNotifications(),
      ]);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'خطأ في تحميل البيانات: $e');
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase.rpc(
        'get_volunteer_dashboard_data',
        params: {'p_user_id': user.id},
      );

      setState(() {
        _dashboardData = response;
      });
    } catch (e) {
      print('خطأ في جلب إحصائيات اللوحة: $e');
    }
  }

  Future<void> _fetchAssociationInfo() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final volunteerData = await _supabase
          .from('users')
          .select('associated_with_association_id')
          .eq('id', user.id)
          .single();

      final associationId = volunteerData['associated_with_association_id'];
      if (associationId == null) return;

      final associationData = await _supabase
          .from('users')
          .select('full_name, phone, city, avatar_url')
          .eq('id', associationId)
          .single();

      setState(() {
        _associationInfo = associationData;
      });
    } catch (e) {
      print('خطأ في جلب معلومات الجمعية: $e');
    }
  }

  Future<void> _fetchAvailableDonations() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final volunteerData = await _supabase
          .from('users')
          .select('associated_with_association_id')
          .eq('id', user.id)
          .single();

      final associationId = volunteerData['associated_with_association_id'];
      if (associationId == null) return;

      final response = await _supabase
          .from('donations')
          .select('''
            *, 
            donor:donor_id(full_name, phone, city),
            association:association_id(full_name)
          ''')
          .eq('status', 'pending')
          .eq('association_id', associationId)
          .order('created_at', ascending: false)
          .limit(10);

      setState(() {
        _availableDonations = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('خطأ في جلب التبرعات المتاحة: $e');
    }
  }

  Future<void> _fetchMyActiveTasks() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('donations')
          .select('''
            *, 
            donor:donor_id(full_name, phone),
            association:association_id(full_name)
          ''')
          .eq('volunteer_id', user.id)
          .in_('status', ['assigned', 'in_progress'])
          .order('created_at', ascending: false)
          .limit(5);

      setState(() {
        _myTasks = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('خطأ في جلب مهامي النشطة: $e');
    }
  }

  Future<void> _acceptDonation(String donationId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('donations')
          .update({
            'volunteer_id': user.id,
            'status': 'assigned',
          })
          .eq('donation_id', donationId);

      if (mounted) {
        ErrorHandler.showSuccess(context, 'تم قبول التبرع بنجاح! 🎉');
        _loadDashboardData();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'خطأ في قبول التبرع: $e');
      }
    }
  }

  List<Map<String, dynamic>> get _filteredDonations {
    switch (_selectedFilter) {
      case 1: // عاجل
        return _availableDonations.where((d) => d['is_urgent'] == true).toList();
      case 2: // قريب (يمكن تطبيق منطق المسافة هنا)
        return _availableDonations;
      default: // الكل
        return _availableDonations;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverToBoxAdapter(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            _buildWelcomeSection(),
                            _buildStatsSection(),
                            _buildMyTasksSection(),
                            _buildAvailableDonationsSection(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: COLOR_VOLUNTEER_ACCENT,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'مرحباً ${_dashboardData?['userName'] ?? 'متطوع'}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                COLOR_VOLUNTEER_ACCENT,
                COLOR_VOLUNTEER_ACCENT.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: _showNotificationsDialog,
            ),
            if (_unreadNotificationsCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    _unreadNotificationsCount > 9 ? '9+' : '$_unreadNotificationsCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadDashboardData,
        ),
      ],
    );
  }

  Future<void> _fetchNotifications() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(20);

      setState(() {
        _notifications = List<Map<String, dynamic>>.from(response);
        _unreadNotificationsCount = _notifications.where((n) => n['is_read'] == false).length;
      });
    } catch (e) {
      print('خطأ في جلب الإشعارات: $e');
    }
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      
      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['is_read'] = true;
          _unreadNotificationsCount = _notifications.where((n) => n['is_read'] == false).length;
        }
      });
    } catch (e) {
      print('خطأ في تحديث حالة الإشعار: $e');
    }
  }

  Future<void> _markAllNotificationsAsRead() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);
      
      setState(() {
        for (var notification in _notifications) {
          notification['is_read'] = true;
        }
        _unreadNotificationsCount = 0;
      });
    } catch (e) {
      print('خطأ في تحديث جميع الإشعارات: $e');
    }
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('الإشعارات'),
          content: _notifications.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('لا توجد إشعارات جديدة'),
                  ),
                )
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isRead = notification['is_read'] == true;
                      
                      return Card(
                        color: isRead ? Colors.grey[100] : Colors.blue[50],
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(
                            notification['title'] ?? '',
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(notification['message'] ?? ''),
                          trailing: Text(
                            _formatNotificationDate(notification['created_at']),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          onTap: () {
                            _markNotificationAsRead(notification['id']);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () {
                _markAllNotificationsAsRead();
                Navigator.pop(context);
              },
              child: const Text('تحديد الكل كمقروء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNotificationDate(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return 'الآن';
      if (difference.inHours < 1) return 'منذ ${difference.inMinutes} دقيقة';
      if (difference.inDays < 1) return 'منذ ${difference.inHours} ساعة';
      if (difference.inDays == 1) return 'بالأمس';
      if (difference.inDays < 7) return 'منذ ${difference.inDays} أيام';
      
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildWelcomeSection() {
    if (_associationInfo == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(SPACING_MD),
      padding: const EdgeInsets.all(SPACING_LG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            COLOR_VOLUNTEER_ACCENT.withValues(alpha: 0.1),
            COLOR_VOLUNTEER_ACCENT.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(BORDER_RADIUS_LARGE),
        border: Border.all(
          color: COLOR_VOLUNTEER_ACCENT.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: COLOR_VOLUNTEER_ACCENT.withValues(alpha: 0.2),
            backgroundImage: _associationInfo!['avatar_url'] != null
                ? NetworkImage(_associationInfo!['avatar_url'])
                : null,
            child: _associationInfo!['avatar_url'] == null
                ? Icon(Icons.business, color: COLOR_VOLUNTEER_ACCENT, size: 30)
                : null,
          ),
          const SizedBox(width: SPACING_MD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تعمل مع',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  _associationInfo!['full_name'] ?? 'جمعية',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: COLOR_VOLUNTEER_ACCENT,
                  ),
                ),
                if (_associationInfo!['city'] != null)
                  Text(
                    _associationInfo!['city'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          if (_associationInfo!['phone'] != null)
            IconButton(
              icon: Icon(Icons.phone, color: COLOR_VOLUNTEER_ACCENT),
              onPressed: () async {
                try {
                  await PhoneUtils.makePhoneCall(_associationInfo!['phone']);
                } catch (e) {
                  if (mounted) {
                    ErrorHandler.showError(context, 'تعذر فتح تطبيق الهاتف: $e');
                  }
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_dashboardData == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SPACING_MD),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'المهام المكتملة',
              (_dashboardData!['completed_tasks'] ?? 0).toString(),
              Icons.check_circle,
              COLOR_SUCCESS,
            ),
          ),
          const SizedBox(width: SPACING_SM),
          Expanded(
            child: _buildStatCard(
              'قيد التنفيذ',
              (_dashboardData!['in_progress_tasks'] ?? 0).toString(),
              Icons.pending_actions,
              COLOR_WARNING,
            ),
          ),
          const SizedBox(width: SPACING_SM),
          Expanded(
            child: _buildStatCard(
              'التقييم',
              (_dashboardData!['avg_rating'] ?? 0.0).toStringAsFixed(1),
              Icons.star,
              COLOR_INFO,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(SPACING_MD),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: SPACING_XS),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMyTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(SPACING_MD),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'مهامي النشطة',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AllVolunteerTasksScreen(),
                    ),
                  );
                },
                child: const Text('عرض الكل'),
              ),
            ],
          ),
        ),
        if (_myTasks.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: SPACING_MD),
            padding: const EdgeInsets.all(SPACING_LG),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.assignment_outlined, color: Colors.grey[400], size: 40),
                const SizedBox(width: SPACING_MD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'لا توجد مهام نشطة',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'ابحث عن تبر��ات جديدة لتبدأ العمل',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: SPACING_MD),
              itemCount: _myTasks.length,
              itemBuilder: (context, index) {
                return _buildTaskCard(_myTasks[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final status = task['status'];
    Color statusColor = status == 'assigned' ? COLOR_WARNING : COLOR_INFO;
    String statusText = status == 'assigned' ? 'مُعيَّنة' : 'قيد التنفيذ';

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: SPACING_SM),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => VolunteerTaskDetailsScreen(donation: task),
              ),
            );
          },
          borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
          child: Padding(
            padding: const EdgeInsets.all(SPACING_MD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task['title'] ?? 'مهمة',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SPACING_XS),
                if (task['donor'] != null)
                  Text(
                    'من: ${task['donor']['full_name']}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (task['pickup_address'] != null)
                  Text(
                    task['pickup_address'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableDonationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(SPACING_MD),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'التبرعات المتاحة',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_filteredDonations.length} تبرع',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        _buildFilterChips(),
        const SizedBox(height: SPACING_SM),
        if (_filteredDonations.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: SPACING_MD),
            padding: const EdgeInsets.all(SPACING_LG),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.inbox_outlined, color: Colors.grey[400], size: 40),
                const SizedBox(width: SPACING_MD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'لا توجد تبرعات متاحة',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'تحقق مرة أخرى لاحقاً أو غير الفلتر',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: SPACING_MD),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: SPACING_SM,
              mainAxisSpacing: SPACING_SM,
              childAspectRatio: 0.8,
            ),
            itemCount: _filteredDonations.length,
            itemBuilder: (context, index) {
              return _buildDonationCard(_filteredDonations[index]);
            },
          ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'الكل', 'icon': Icons.all_inclusive},
      {'label': 'عاجل', 'icon': Icons.priority_high},
      {'label': 'قريب', 'icon': Icons.location_on},
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: SPACING_MD),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedFilter == index;
          return Container(
            margin: const EdgeInsets.only(right: SPACING_SM),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filters[index]['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : COLOR_VOLUNTEER_ACCENT,
                  ),
                  const SizedBox(width: 4),
                  Text(filters[index]['label'] as String),
                ],
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = index;
                });
              },
              selectedColor: COLOR_VOLUNTEER_ACCENT,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : COLOR_VOLUNTEER_ACCENT,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> donation) {
    final isUrgent = donation['is_urgent'] == true;
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showDonationDetails(donation),
        borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: isUrgent ? Colors.red[50] : Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(BORDER_RADIUS_MEDIUM),
                  topRight: Radius.circular(BORDER_RADIUS_MEDIUM),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.fastfood_outlined,
                      color: isUrgent ? Colors.red[300] : Colors.grey[400],
                      size: 40,
                    ),
                  ),
                  if (isUrgent)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'عاجل',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(SPACING_SM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation['title'] ?? 'تبرع',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'الكمية: ${donation['quantity'] ?? 'غير محدد'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      donation['donor']?['full_name'] ?? 'متبرع',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _acceptDonation(donation['donation_id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: COLOR_VOLUNTEER_ACCENT,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text(
                          'قبول',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AdvancedSearchScreen(),
          ),
        );
        if (result != null) {
          // يمكن تطبيق فلاتر البحث المتقدم هنا
          _loadDashboardData();
        }
      },
      backgroundColor: COLOR_VOLUNTEER_ACCENT,
      icon: const Icon(Icons.search, color: Colors.white),
      label: const Text(
        'بحث متقدم',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showDonationDetails(Map<String, dynamic> donation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(SPACING_LG),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          donation['title'] ?? 'تبرع',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: SPACING_MD),
                        _buildDetailRow(
                          'الوصف',
                          donation['description'] ?? 'لا يوجد وصف',
                          Icons.description,
                        ),
                        _buildDetailRow(
                          'الكمية',
                          donation['quantity']?.toString() ?? 'غير محدد',
                          Icons.scale,
                        ),
                        _buildDetailRow(
                          'المتبرع',
                          donation['donor']?['full_name'] ?? 'غير معروف',
                          Icons.person,
                        ),
                        if (donation['donor']?['phone'] != null)
                          _buildDetailRow(
                            'هاتف المتبرع',
                            donation['donor']['phone'],
                            Icons.phone,
                          ),
                        _buildDetailRow(
                          'عنوان الاستلام',
                          donation['pickup_address'] ?? 'غير محدد',
                          Icons.location_on,
                        ),
                        if (donation['expiry_date'] != null)
                          _buildDetailRow(
                            'تاريخ الانتهاء',
                            donation['expiry_date'],
                            Icons.schedule,
                          ),
                        const SizedBox(height: SPACING_LG),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _acceptDonation(donation['donation_id']);
                            },
                            icon: const Icon(Icons.volunteer_activism),
                            label: const Text('قبول هذا التبرع'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: COLOR_VOLUNTEER_ACCENT,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: COLOR_VOLUNTEER_ACCENT, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}