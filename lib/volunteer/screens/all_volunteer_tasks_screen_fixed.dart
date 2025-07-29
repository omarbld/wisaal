import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wisaal/core/theme.dart';
import 'package:wisaal/common/widgets/empty_state_widget.dart';
import 'package:wisaal/common/widgets/error_handler.dart';
import 'package:wisaal/common/widgets/search_filter_widget.dart';
import 'package:wisaal/volunteer/volunteer_task_details.dart';
import 'package:intl/intl.dart';

class AllVolunteerTasksScreen extends StatefulWidget {
  const AllVolunteerTasksScreen({super.key});

  @override
  State<AllVolunteerTasksScreen> createState() => _AllVolunteerTasksScreenState();
}

class _AllVolunteerTasksScreenState extends State<AllVolunteerTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;
  
  String _searchQuery = '';
  String _sortBy = 'created_at';
  bool _sortAscending = false;
  
  final List<String> _statusFilters = ['all', 'assigned', 'in_progress', 'completed'];
  final List<String> _statusLabels = ['الكل', 'مُعيَّنة', 'قيد التنفيذ', '��كتملة'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

      var query = _supabase
          .from('donations')
          .select('''
            *, 
            donor:donor_id(full_name, phone, city),
            association:association_id(full_name)
          ''')
          .eq('volunteer_id', user.id);

      // تطبيق فلتر الحالة
      if (status != 'all') {
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
        if (statusList.isNotEmpty) {
          query = query.in_('status', statusList);
        }
      }

      final response = await query;
      var results = List<Map<String, dynamic>>.from(response);

      // تطبيق البحث محل��اً
      if (_searchQuery.isNotEmpty) {
        results = results.where((task) {
          final searchLower = _searchQuery.toLowerCase();
          final title = (task['title'] ?? '').toString().toLowerCase();
          final description = (task['description'] ?? '').toString().toLowerCase();
          final address = (task['pickup_address'] ?? '').toString().toLowerCase();
          
          return title.contains(searchLower) || 
                 description.contains(searchLower) || 
                 address.contains(searchLower);
        }).toList();
      }

      // تطبيق الترتيب محلياً
      results.sort((a, b) {
        switch (_sortBy) {
          case 'title':
            final aTitle = (a['title'] ?? '').toString();
            final bTitle = (b['title'] ?? '').toString();
            return _sortAscending ? aTitle.compareTo(bTitle) : bTitle.compareTo(aTitle);
          case 'expiry_date':
            final aDate = DateTime.tryParse(a['expiry_date'] ?? '') ?? DateTime.now();
            final bDate = DateTime.tryParse(b['expiry_date'] ?? '') ?? DateTime.now();
            return _sortAscending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
          default: // created_at
            final aDate = DateTime.parse(a['created_at']);
            final bDate = DateTime.parse(b['created_at']);
            return _sortAscending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
        }
      });

      return results;
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'خطأ في تحميل المهام: ${e.toString()}');
      }
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جميع مهامي'),
        centerTitle: true,
        backgroundColor: COLOR_VOLUNTEER_ACCENT,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _statusLabels.map((label) => Tab(text: label)).toList(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                if (value == _sortBy) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortBy = value;
                  _sortAscending = false;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'created_at',
                child: Row(
                  children: [
                    Icon(Icons.access_time),
                    SizedBox(width: 8),
                    Text('تاريخ الإنشاء'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'title',
                child: Row(
                  children: [
                    Icon(Icons.title),
                    SizedBox(width: 8),
                    Text('العنوان'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'expiry_date',
                child: Row(
                  children: [
                    Icon(Icons.schedule),
                    SizedBox(width: 8),
                    Text('تاريخ الانتهاء'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            child: SearchFilterWidget(
              hintText: 'البحث في المهام...',
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onClear: () {
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
          ),
          
          // قائمة المهام
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _statusFilters.map((status) => _buildTasksList(status)).toList(),
            ),
          ),
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
          return ServerErrorWidget(
            onRetry: () => setState(() {}),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          if (_searchQuery.isNotEmpty) {
            return EmptySearchWidget(
              searchQuery: _searchQuery,
              onClearSearch: () {
                setState(() {
                  _searchQuery = '';
                });
              },
            );
          }
          
          return EmptyTasksWidget(
            customMessage: _getEmptyMessage(status),
          );
        }
        
        final tasks = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _buildTaskCard(task);
            },
          ),
        );
      },
    );
  }

  String _getEmptyMessage(String status) {
    switch (status) {
      case 'assigned':
        return 'لا توجد مهام مُعيَّنة حالياً';
      case 'in_progress':
        return 'لا توجد مهام قيد التنفيذ حالياً';
      case 'completed':
        return 'لم تكمل أي مهام بعد';
      default:
        return 'لا توجد مهام متاحة';
    }
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final status = task['status'];
    final isUrgent = task['is_urgent'] == true;
    
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'assigned':
        statusColor = COLOR_WARNING;
        statusText = 'مُعيَّنة';
        statusIcon = Icons.assignment_outlined;
        break;
      case 'in_progress':
        statusColor = COLOR_INFO;
        statusText = 'قيد التنفيذ';
        statusIcon = Icons.pending_actions;
        break;
      case 'completed':
        statusColor = COLOR_SUCCESS;
        statusText = 'مكتملة';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'غير معروف';
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VolunteerTaskDetailsScreen(donation: task),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان والحالة
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task['title'] ?? 'مهمة',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isUrgent)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'عاجل',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // الوصف
              if (task['description'] != null && task['description'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    task['description'],
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              
              // تفاصيل المهمة
              _buildDetailRow(
                Icons.person,
                'المتبرع',
                task['donor']?['full_name'] ?? 'غير معروف',
              ),
              
              if (task['association'] != null)
                _buildDetailRow(
                  Icons.business,
                  'الجمعية',
                  task['association']['full_name'],
                ),
              
              if (task['pickup_address'] != null)
                _buildDetailRow(
                  Icons.location_on,
                  'العنوان',
                  task['pickup_address'],
                ),
              
              _buildDetailRow(
                Icons.scale,
                'الكمية',
                task['quantity']?.toString() ?? 'غير محدد',
              ),
              
              if (task['food_type'] != null)
                _buildDetailRow(
                  Icons.category,
                  'النوع',
                  task['food_type'],
                ),
              
              // التواريخ
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDateInfo(
                      'تاريخ الإنشاء',
                      task['created_at'],
                      Icons.access_time,
                    ),
                  ),
                  if (task['expiry_date'] != null)
                    Expanded(
                      child: _buildDateInfo(
                        'تاريخ الانتهاء',
                        task['expiry_date'],
                        Icons.schedule,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(String label, String dateString, IconData icon) {
    try {
      final date = DateTime.parse(dateString);
      final formattedDate = DateFormat('dd/MM/yyyy', 'ar').format(date);
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Text(
            formattedDate,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}