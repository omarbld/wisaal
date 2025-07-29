
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManagerAssociationsScreen extends StatefulWidget {
  const ManagerAssociationsScreen({super.key});

  @override
  State<ManagerAssociationsScreen> createState() =>
      _ManagerAssociationsScreenState();
}

class _ManagerAssociationsScreenState extends State<ManagerAssociationsScreen> {
  final _supabase = Supabase.instance.client;
  String _searchQuery = '';
  bool? _isActiveFilter;

  Future<List<Map<String, dynamic>>> _fetchAssociations() async {
    var query = _supabase.from('users').select().eq('role', 'association');

    if (_searchQuery.isNotEmpty) {
      query = query.ilike('full_name', '%$_searchQuery%');
    }
    if (_isActiveFilter != null) {
      query = query.eq('is_active', _isActiveFilter!);
    }

    final res = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> _updateAssociation(String id, Map<String, dynamic> data) async {
    await _supabase.from('users').update(data).eq('id', id);
    setState(() {}); // Refresh the list
  }

  Future<void> _deleteAssociation(String id) async {
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
              future: _fetchAssociations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('لا توجد جمعيات بهذه المواصفات'));
                }
                final associations = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: associations.length,
                    itemBuilder: (context, index) {
                      return _AssociationCard(
                        association: associations[index],
                        onUpdate: _updateAssociation,
                        onDelete: _deleteAssociation,
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
                hintText: 'بحث باسم الجمعية...',
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
              DropdownMenuItem(value: true, child: Text('نشطة')),
              DropdownMenuItem(value: false, child: Text('معطلة')),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssociationCard extends StatelessWidget {
  final Map<String, dynamic> association;
  final Function(String, Map<String, dynamic>) onUpdate;
  final Function(String) onDelete;

  const _AssociationCard({
    required this.association,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = association['is_active'] ?? false;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primary.withAlpha(26),
              child: Icon(Icons.business_outlined, color: colorScheme.primary),
            ),
            title: Text(association['full_name'] ?? 'اسم غير متوفر',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text(association['email'] ?? 'بريد إلكتروني غير متوفر'),
            trailing: Chip(
              label: Text(isActive ? 'نشطة' : 'معطلة'),
              backgroundColor: (isActive ? Colors.green : Colors.grey).withAlpha(51),
              labelStyle: TextStyle(color: isActive ? Colors.green.shade800 : Colors.grey.shade800),
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
                      onUpdate(association['id'], {'is_active': !isActive}),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  tooltip: 'حذف',
                  onPressed: () => onDelete(association['id']),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
