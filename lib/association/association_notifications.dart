
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class AssociationNotificationsScreen extends StatefulWidget {
  const AssociationNotificationsScreen({super.key});

  @override
  State<AssociationNotificationsScreen> createState() =>
      _AssociationNotificationsScreenState();
}

class _AssociationNotificationsScreenState
    extends State<AssociationNotificationsScreen> {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final res = await _supabase
        .from('notifications')
        .select()
        .or('user_id.eq.${user.id},user_id.is.null') // Fetch user-specific and global notifications
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> _markAsRead(int id) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true}).eq('id', id);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('ar', timeago.ArMessages());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'تحديث',
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchNotifications(),
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
                    Icon(Icons.notifications_off_outlined,
                        size: 80,
                        color: colorScheme.onSurfaceVariant.withAlpha(128)),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد إشعارات جديدة',
                      style: textTheme.titleLarge
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }
            final notifications = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: notifications.length,
              itemBuilder: (context, i) {
                final n = notifications[i];
                final isRead = n['is_read'] ?? false;
                return Card(
                  elevation: isRead ? 0 : 2,
                  color: isRead
                      ? theme.cardColor
                      : colorScheme.primaryContainer.withAlpha(77),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isRead
                          ? colorScheme.onSurface.withAlpha(26)
                          : colorScheme.primary,
                      child: Icon(
                        Icons.notifications_active_outlined,
                        color: isRead
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onPrimary,
                      ),
                    ),
                    title: Text(n['title'] ?? 'إشعار جديد',
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n['body'] ?? '', style: textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Text(
                          timeago.format(DateTime.parse(n['created_at']), locale: 'ar'),
                          style: textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    onTap: () => _markAsRead(n['id']),
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
