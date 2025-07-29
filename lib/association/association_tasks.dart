import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'association_donation_details.dart';
import 'association_rate_volunteer.dart';

class AssociationTasksScreen extends StatefulWidget {
  const AssociationTasksScreen({super.key});

  @override
  State<AssociationTasksScreen> createState() => _AssociationTasksScreenState();
}

class _AssociationTasksScreenState extends State<AssociationTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    var query = supabase
        .from('donations')
        .select('*, volunteer:users!donations_volunteer_id_fkey(full_name)')
        .eq('association_id', user.id);

    if (status == 'accepted') {
      query = query.in_('status', ['accepted', 'assigned']);
    } else {
      query = query.eq('status', status);
    }

    final res = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مهام الجمعية'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'مقبولة'),
            Tab(text: 'قيد التنفيذ'),
            Tab(text: 'مكتملة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTasksList('accepted'),
          _buildTasksList('in_progress'),
          _buildTasksList('completed'),
        ],
      ),
    );
  }

  Widget _buildTasksList(String status) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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
                Icon(Icons.inbox_outlined,
                    size: 80,
                    color: colorScheme.onSurfaceVariant.withAlpha(128)),
                const SizedBox(height: 16),
                Text(
                  'لا توجد مهام هنا',
                  style: textTheme.titleLarge
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }
        final tasks = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, i) {
              final task = tasks[i];
              final volunteerName = task['volunteer']?['full_name'];

              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    final donationData = Map<String, dynamic>.from(task);
                    donationData['donation_id'] =
                        task['donation_id']?.toString();
                    donationData['volunteer_id'] =
                        task['volunteer_id']?.toString();
                    donationData['donor_id'] = task['donor_id']?.toString();

                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) => AssociationDonationDetailsScreen(
                                donation: donationData),
                          ),
                        )
                        .then((_) => setState(() {}));
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primary.withAlpha(26),
                          child: Icon(Icons.assignment_turned_in_outlined,
                              color: colorScheme.primary),
                        ),
                        title: Text(task['title'] ?? 'بلا عنوان',
                            style: textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'تاريخ القبول: ${DateFormat('yyyy-MM-dd', 'ar').format(DateTime.parse(task['created_at']))}',
                          style: textTheme.bodySmall,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          children: [
                            if (volunteerName != null)
                              Chip(
                                avatar: const Icon(Icons.person_outline),
                                label: Text(volunteerName),
                              ),
                            const Spacer(),
                            if (status == 'completed' &&
                                task['volunteer_id'] != null &&
                                task['rating'] == null)
                              TextButton(
                                onPressed: () {
                                  final donationId = task['donation_id'];
                                  if (donationId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('لم يتم العثور على معرف التبرع'),
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AssociationRateVolunteerScreen(
                                            volunteerName:
                                                task['volunteer']?['full_name'] ?? 'Unknown',
                                            donationId: donationId,
                                          ),
                                        ),
                                      )
                                      .then((_) => setState(() {}));
                                },
                                child: const Text('تقييم المتطوع'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
