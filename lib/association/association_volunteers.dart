
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssociationVolunteersScreen extends StatefulWidget {
  const AssociationVolunteersScreen({super.key});

  @override
  State<AssociationVolunteersScreen> createState() =>
      _AssociationVolunteersScreenState();
}

class _AssociationVolunteersScreenState
    extends State<AssociationVolunteersScreen> {
  final _supabase = Supabase.instance.client;
  String _sortOrder = 'name';
  bool? _activeFilter;

  Future<List<Map<String, dynamic>>> _fetchVolunteers() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final res = await _supabase.rpc(
        'get_volunteers_for_association',
        params: {'p_association_id': user.id},
      );
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch volunteers: ${e.toString()}')),
        );
      }
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المتطوعين'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterSortControls(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchVolunteers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('لا يوجد متطوعون حالياً'));
                }

                List<Map<String, dynamic>> volunteers = snapshot.data!;

                // Apply filtering and sorting
                if (_activeFilter != null) {
                  volunteers = volunteers
                      .where((v) => v['is_active'] == _activeFilter)
                      .toList();
                }
                volunteers.sort((a, b) {
                  if (_sortOrder == 'rating') {
                    return (b['average_rating'] ?? 0.0)
                        .compareTo(a['average_rating'] ?? 0.0);
                  } else {
                    return (a['full_name'] ?? '')
                        .compareTo(b['full_name'] ?? '');
                  }
                });

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: volunteers.length,
                    itemBuilder: (context, index) {
                      return _VolunteerCard(volunteer: volunteers[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSortControls() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          const Text('ترتيب حسب:'),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _sortOrder,
            items: const [
              DropdownMenuItem(value: 'name', child: Text('الاسم')),
              DropdownMenuItem(value: 'rating', child: Text('التقييم')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _sortOrder = value);
            },
          ),
          const Spacer(),
          const Text('الحالة:'),
          const SizedBox(width: 8),
          DropdownButton<bool?>(
            value: _activeFilter,
            items: const [
              DropdownMenuItem(value: null, child: Text('الكل')),
              DropdownMenuItem(value: true, child: Text('نشط')),
              DropdownMenuItem(value: false, child: Text('غير نشط')),
            ],
            onChanged: (value) => setState(() => _activeFilter = value),
          ),
        ],
      ),
    );
  }
}

class _VolunteerCard extends StatelessWidget {
  final Map<String, dynamic> volunteer;

  const _VolunteerCard({required this.volunteer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isActive = volunteer['is_active'] ?? false;
    final avgRating = volunteer['average_rating'] as double? ?? 0.0;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: volunteer['avatar_url'] != null
              ? NetworkImage(volunteer['avatar_url'])
              : null,
          child: volunteer['avatar_url'] == null
              ? const Icon(Icons.person_outline)
              : null,
        ),
        title: Text(volunteer['full_name'] ?? 'اسم غير معروف',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Icon(Icons.star, color: Colors.amber.shade700, size: 16),
            const SizedBox(width: 4),
            Text(avgRating.toStringAsFixed(1)),
          ],
        ),
        trailing: Chip(
          label: Text(isActive ? 'نشط' : 'غير نشط'),
          backgroundColor:
              (isActive ? Colors.green : Colors.grey).withAlpha(51),
          labelStyle: TextStyle(
              color: isActive ? Colors.green.shade800 : Colors.grey.shade800),
        ),
      ),
    );
  }
}
