
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManagerVolunteersScreen extends StatefulWidget {
  const ManagerVolunteersScreen({super.key});

  @override
  State<ManagerVolunteersScreen> createState() =>
      _ManagerVolunteersScreenState();
}

class _ManagerVolunteersScreenState extends State<ManagerVolunteersScreen> {
  final _supabase = Supabase.instance.client;
  String _searchQuery = '';
  bool? _isActiveFilter;

  Future<List<Map<String, dynamic>>> _fetchVolunteers() async {
    var query = _supabase.from('users').select().eq('role', 'volunteer');

    if (_searchQuery.isNotEmpty) {
      query = query.ilike('full_name', '%$_searchQuery%');
    }
    if (_isActiveFilter != null) {
      query = query.eq('is_active', _isActiveFilter!);
    }

    final res = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> _updateVolunteer(String id, Map<String, dynamic> data) async {
    await _supabase.from('users').update(data).eq('id', id);
    setState(() {}); // Refresh the list
  }

  Future<void> _deleteVolunteer(String id) async {
    await _supabase.from('users').delete().eq('id', id);
    setState(() {}); // Refresh the list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchVolunteers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('لا توجد متطوعون بهذه المواصفات'));
                }
                final volunteers = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: volunteers.length,
                    itemBuilder: (context, index) {
                      return _VolunteerCard(
                        volunteer: volunteers[index],
                        onUpdate: _updateVolunteer,
                        onDelete: _deleteVolunteer,
                      );
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

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'بحث باسم المتطوع...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<bool>(
            value: _isActiveFilter,
            hint: const Text('الحالة'),
            onChanged: (value) => setState(() => _isActiveFilter = value),
            items: const [
              DropdownMenuItem(value: null, child: Text('الكل')),
              DropdownMenuItem(value: true, child: Text('نشط')),
              DropdownMenuItem(value: false, child: Text('معطل')),
            ],
          ),
        ],
      ),
    );
  }
}

class _VolunteerCard extends StatelessWidget {
  final Map<String, dynamic> volunteer;
  final Function(String, Map<String, dynamic>) onUpdate;
  final Function(String) onDelete;

  const _VolunteerCard({
    required this.volunteer,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = volunteer['is_active'] ?? false;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.tertiary.withAlpha(26),
              child: Icon(Icons.volunteer_activism_outlined,
                  color: colorScheme.tertiary),
            ),
            title: Text(volunteer['full_name'] ?? 'اسم غير متوفر',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text(volunteer['email'] ?? 'بريد إلكتروني غير متوفر'),
            trailing: Chip(
              label: Text(isActive ? 'نشط' : 'معطل'),
              backgroundColor:
                  (isActive ? Colors.green : Colors.grey).withAlpha(51),
              labelStyle: TextStyle(
                  color: isActive
                      ? Colors.green.shade800
                      : Colors.grey.shade800),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: Icon(isActive ? Icons.toggle_on : Icons.toggle_off,
                      color: isActive ? Colors.green : Colors.grey),
                  label: Text(isActive ? 'تعطيل' : 'تفعيل'),
                  onPressed: () =>
                      onUpdate(volunteer['id'], {'is_active': !isActive}),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  tooltip: 'حذف',
                  onPressed: () => onDelete(volunteer['id']),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
