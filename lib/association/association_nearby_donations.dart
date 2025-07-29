
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class AssociationNearbyDonationsScreen extends StatefulWidget {
  const AssociationNearbyDonationsScreen({super.key});

  @override
  State<AssociationNearbyDonationsScreen> createState() =>
      _AssociationNearbyDonationsScreenState();
}

class _AssociationNearbyDonationsScreenState
    extends State<AssociationNearbyDonationsScreen> {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> _fetchNearbyDonations() async {
    // In a real app, this would use the association's location to find nearby donations.
    // For now, we fetch all pending donations.
    final res = await _supabase
        .from('donations')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> _acceptDonation(Map<String, dynamic> donation) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('donations').update({
      'status': 'accepted',
      'association_id': user.id,
    }).eq('donation_id', donation['donation_id']);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم قبول التبرع بنجاح!')),
      );
      setState(() {});
    }
  }

  void _showAcceptDialog(Map<String, dynamic> donation, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد قبول التبرع'),
        content: Text(
            'هل أنت متأكد من رغبتك في قبول هذا التبرع؟\n\nالعنوان: ${donation['pickup_address']}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptDonation(donation);
            },
            child: const Text('تأكيد القبول'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('التبرعات المتاحة'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchNearbyDonations(),
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
                    Icon(Icons.location_off_outlined, size: 80, color: colorScheme.onSurfaceVariant.withAlpha(128)),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد تبرعات متاحة حالياً',
                      style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }
            final donations = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: donations.length,
              itemBuilder: (context, index) {
                final donation = donations[index];
                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primary.withAlpha(26),
                          child: Icon(Icons.fastfood_outlined, color: colorScheme.primary),
                        ),
                        title: Text(donation['title'] ?? 'بلا عنوان', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        subtitle: Text(donation['pickup_address'] ?? 'بلا عنوان', maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('الكمية: ${donation['quantity']}', style: textTheme.bodyMedium),
                            Text(timeago.format(DateTime.parse(donation['created_at']), locale: 'ar'), style: textTheme.bodySmall),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () => _showAcceptDialog(donation, theme),
                          child: const Text('قبول هذا التبرع'),
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
