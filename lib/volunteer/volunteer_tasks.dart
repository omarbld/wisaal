import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wisaal/core/theme.dart';
import 'package:wisaal/volunteer/volunteer_task_details.dart';

class VolunteerTasksScreen extends StatefulWidget {
  const VolunteerTasksScreen({super.key});

  @override
  State<VolunteerTasksScreen> createState() => _VolunteerTasksScreenState();
}

class _VolunteerTasksScreenState extends State<VolunteerTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchTasks(String status) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      List<String> statusList;
      switch (status) {
        case 'assigned':
          statusList = ['assigned'];
          break;
        case 'in_progress':
          statusList = ['in_progress'];
          break;
        case 'completed':
          statusList = ['completed'];
          break;
        default:
          statusList = [];
      }

      final response = await _supabase
          .from('donations')
          .select('*, donor:donor_id(full_name), association:association_id(full_name)')
          .eq('volunteer_id', user.id)
          .in_('status', statusList)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل المهام: $e')),
        );
      }
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مهامي'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'مُعيَّنة'),
            Tab(text: 'قيد التنفيذ'),
            Tab(text: 'مكتملة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTasksList('assigned'),
          _buildTasksList('in_progress'),
          _buildTasksList('completed'),
        ],
      ),
    );
  }

  Widget _buildTasksList(String status) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchTasks(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyMessage(status),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        final tasks = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(SPACING_UNIT * 2),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _buildTaskCard(context, task);
            },
          ),
        );
      },
    );
  }

  String _getEmptyMessage(String status) {
    switch (status) {
      case 'assigned':
        return 'لا توجد مهام مُعيَّنة';
      case 'in_progress':
        return 'لا توجد مهام قيد التنفيذ';
      case 'completed':
        return 'لا توجد مهام مكتملة';
      default:
        return 'لا توجد مهام';
    }
  }

  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> task) {
    final status = task['status'];
    Color statusColor;
    String statusText;

    switch (status) {
      case 'assigned':
        statusColor = COLOR_WARNING;
        statusText = 'مُعيَّنة';
        break;
      case 'in_progress':
        statusColor = COLOR_INFO;
        statusText = 'قيد التنفيذ';
        break;
      case 'completed':
        statusColor = COLOR_SUCCESS;
        statusText = 'مكتملة';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'غير معروف';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: SPACING_UNIT * 2),
      child: ListTile(
        title: Text(
          task['title'] ?? 'مهمة',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task['donor'] != null)
              Text('من: ${task['donor']['full_name']}'),
            if (task['association'] != null)
              Text('إلى: ${task['association']['full_name']}'),
            if (task['pickup_address'] != null)
              Text('العنوان: ${task['pickup_address']}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(25),
            borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
          ),
          child: Text(
            statusText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VolunteerTaskDetailsScreen(donation: task),
            ),
          );
        },
      ),
    );
  }
}