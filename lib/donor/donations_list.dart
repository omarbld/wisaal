
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'donation_details.dart';
import 'donor_rate_screen.dart';

class DonationsListScreen extends StatefulWidget {
  const DonationsListScreen({super.key});

  @override
  State<DonationsListScreen> createState() => _DonationsListScreenState();
}

class _DonationsListScreenState extends State<DonationsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchDonations(String status) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      print('User is null in _fetchDonations');
      return [];
    }
    
    print('Fetching donations for user: ${user.id}, status: $status');
    
    try {
      var query = supabase
          .from('donations')
          .select('*, volunteer:volunteer_id(full_name, avatar_url), association:association_id(full_name, avatar_url)')
          .eq('donor_id', user.id);
      
      if (status != 'all') {
        query = query.eq('status', status);
      }
      
      final res = await query.order('created_at', ascending: false);
      
      print('Fetched ${res.length} donations for status: $status');
      
      // طباعة تفاصيل التبرعات لفهم الحالات الفعلية
      if (res.isNotEmpty) {
        print('Sample donation statuses:');
        for (int i = 0; i < res.length && i < 5; i++) {
          print('Donation ${i + 1}: status = "${res[i]['status']}", title = "${res[i]['title']}"');
        }
      }
      
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('Error fetching donations: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل التبرعات'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'قيد الانتظار'),
            Tab(text: 'مقبولة'),
            Tab(text: 'قيد التنفيذ'),
            Tab(text: 'مكتملة'),
            Tab(text: 'ملغاة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDonationsList('all'),
          _buildDonationsList('pending'),
          _buildDonationsList('assigned'),
          _buildDonationsList('in_progress'),
          _buildDonationsList('completed'),
          _buildDonationsList('cancelled'),
        ],
      ),
    );
  }

  Widget _buildDonationsList(String status) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchDonations(status),
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
                  'لا توجد تبرعات هنا',
                  style: textTheme.titleLarge
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }
        final donations = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: donations.length,
            itemBuilder: (context, i) {
              final d = donations[i];
              final currentStatusColor =
                  _statusColor(d['status'] ?? '', colorScheme);
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) => DonationDetailsScreen(donation: d),
                          ),
                        )
                        .then((_) => setState(() {}));
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: currentStatusColor.withAlpha(26),
                          child: Icon(_statusIcon(d['status'] ?? ''),
                              color: currentStatusColor),
                        ),
                        title: Text(d['title'] ?? 'بلا عنوان',
                            style: textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تاريخ الإنشاء: ${DateFormat('yyyy/MM/dd - HH:mm', 'ar').format(DateTime.parse(d['created_at']))}',
                              style: textTheme.bodySmall,
                            ),
                            if (d['description'] != null && d['description'].toString().isNotEmpty)
                              Text(
                                d['description'],
                                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          children: [
                            Chip(
                            label: Text(_statusText(d['status'] ?? '')),
                            backgroundColor:
                            currentStatusColor.withAlpha(38),
                              labelStyle: textTheme.labelLarge
                                  ?.copyWith(color: currentStatusColor),
                              side: BorderSide.none,
                            ),
                            const Spacer(),
                            if (status == 'completed' && d['rating'] == null)
                              TextButton(
                                onPressed: () {
                                  final entityType = d['volunteer_id'] != null
                                      ? 'volunteer'
                                      : 'association';
                                  final ratedEntityId =
                                      d['volunteer_id'] ?? d['association_id'];
                                  if (ratedEntityId != null) {
                                    Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (_) => DonorRateScreen(
                                              taskId: d['donation_id'],
                                              ratedEntityId: ratedEntityId,
                                              entityType: entityType,
                                            ),
                                          ),
                                        )
                                        .then((_) => setState(() {}));
                                  }
                                },
                                child: const Text('تقييم التجربة'),
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

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'بانتظار القبول';
      case 'assigned':
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
        return Icons.pending_actions_outlined;
      case 'assigned':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.delivery_dining_outlined;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Color _statusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'pending':
        return colorScheme.secondary;
      case 'assigned':
        return colorScheme.primary;
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
}
