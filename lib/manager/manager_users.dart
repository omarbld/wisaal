
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManagerUsersScreen extends StatefulWidget {
  const ManagerUsersScreen({super.key});

  @override
  State<ManagerUsersScreen> createState() => _ManagerUsersScreenState();
}

class _ManagerUsersScreenState extends State<ManagerUsersScreen> {
  final _supabase = Supabase.instance.client;
  String _searchQuery = '';
  String? _roleFilter;

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    var query = _supabase.from('users').select();

    if (_searchQuery.isNotEmpty) {
      query = query.or(
        'full_name.ilike.%$_searchQuery%,email.ilike.%$_searchQuery%',
      );
    }
    if (_roleFilter != null) {
      query = query.eq('role', _roleFilter!);
    }

    final res = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> _updateUser(String id, Map<String, dynamic> data) async {
    await _supabase.from('users').update(data).eq('id', id);
    setState(() {}); // Refresh the list
  }

  Future<void> _deleteUser(String id) async {
    await _supabase.from('users').delete().eq('id', id);
    setState(() {}); // Refresh the list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('لا يوجد مستخدمون بهذه المواصفات'));
                }
                final users = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      return _UserCard(user: users[index], onUpdate: _updateUser, onDelete: _deleteUser);
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
                hintText: 'بحث بالاسم أو البريد الإلكتروني...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _roleFilter,
            hint: const Text('كل الأدوار'),
            onChanged: (value) => setState(() => _roleFilter = value),
            items: [
              const DropdownMenuItem(value: null, child: Text('الكل')),
              const DropdownMenuItem(value: 'donor', child: Text('متبرع')),
              const DropdownMenuItem(value: 'volunteer', child: Text('متطوع')),
              const DropdownMenuItem(value: 'association', child: Text('جمعية')),
              const DropdownMenuItem(value: 'manager', child: Text('مدير')),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final Function(String, Map<String, dynamic>) onUpdate;
  final Function(String) onDelete;

  const _UserCard({required this.user, required this.onUpdate, required this.onDelete});

  void _showEditRoleDialog(BuildContext context) {
    String? selectedRole = user['role'];
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('تعديل دور المستخدم'),
              content: DropdownButton<String>(
                value: selectedRole,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'donor', child: Text('متبرع')),
                  DropdownMenuItem(value: 'volunteer', child: Text('متطوع')),
                  DropdownMenuItem(value: 'association', child: Text('جمعية')),
                  DropdownMenuItem(value: 'manager', child: Text('مدير')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedRole = value;
                    });
                  }
                },
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
                ElevatedButton(onPressed: () {
                  onUpdate(user['id'], {'role': selectedRole});
                  Navigator.of(context).pop();
                }, child: const Text('حفظ')),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleText = _getRoleText(user['role']);
    final roleColor = _getRoleColor(user['role'], theme.colorScheme);
    final isActive = user['is_active'] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: roleColor.withAlpha(26),
              child: Icon(_getRoleIcon(user['role']), color: roleColor),
            ),
            title: Text(user['full_name'] ?? 'اسم غير متوفر', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text(user['email'] ?? 'بريد إلكتروني غير متوفر', style: theme.textTheme.bodySmall),
            trailing: Chip(
              label: Text(roleText, style: TextStyle(color: roleColor, fontSize: 12)),
              backgroundColor: roleColor.withAlpha(26),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.location_city_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(user['city'] ?? 'غير محدد', style: theme.textTheme.bodySmall),
                const Spacer(),
                Icon(Icons.calendar_today_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(user['created_at'] != null ? (user['created_at'] as String).substring(0, 10) : '', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: Icon(isActive ? Icons.toggle_on : Icons.toggle_off, color: isActive ? Colors.green : Colors.grey, size: 28),
                  label: Text(isActive ? 'نشط' : 'معطل'),
                  onPressed: () => onUpdate(user['id'], {'is_active': !isActive}),
                ),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'تعديل الدور', onPressed: () => _showEditRoleDialog(context)),
                    IconButton(icon: const Icon(Icons.notifications_outlined), tooltip: 'إرسال إشعار', onPressed: () => _showNotificationDialog(context, user)),
                    IconButton(icon: Icon(Icons.delete_outline, color: theme.colorScheme.error), tooltip: 'حذف', onPressed: () => _showDeleteConfirmationDialog(context, user, onDelete)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  String _getRoleText(String? role) {
    switch (role) {
      case 'donor': return 'متبرع';
      case 'volunteer': return 'متطوع';
      case 'association': return 'جمعية';
      case 'manager': return 'مدير';
      default: return 'غير معروف';
    }
  }

  IconData _getRoleIcon(String? role) {
    switch (role) {
      case 'donor': return Icons.card_giftcard_outlined;
      case 'volunteer': return Icons.volunteer_activism_outlined;
      case 'association': return Icons.business_outlined;
      case 'manager': return Icons.admin_panel_settings_outlined;
      default: return Icons.person_outline;
    }
  }

  Color _getRoleColor(String? role, ColorScheme colorScheme) {
    switch (role) {
      case 'donor': return colorScheme.secondary;
      case 'volunteer': return colorScheme.tertiary;
      case 'association': return Colors.blue.shade700;
      case 'manager': return colorScheme.primary;
      default: return Colors.grey;
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, Map<String, dynamic> user, Function(String) onDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد أنك تريد حذف المستخدم ${user['full_name']}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              onDelete(user['id']);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showNotificationDialog(BuildContext context, Map<String, dynamic> user) {
    final _titleController = TextEditingController();
    final _bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إرسال إشعار إلى ${user['full_name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'العنوان')),
            TextField(controller: _bodyController, decoration: const InputDecoration(labelText: 'النص')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              try {
                await Supabase.instance.client.from('notifications').insert({
                  'user_id': user['id'],
                  'title': _titleController.text,
                  'body': _bodyController.text,
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الإشعار بنجاح')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل إرسال الإشعار: ${e.toString()}')));
              }
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }
}
