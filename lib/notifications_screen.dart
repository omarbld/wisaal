
import 'package:flutter/material.dart';
import 'package:wisaal/core/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    // Placeholder for Supabase call
    await Future.delayed(const Duration(seconds: 1));
    return [
      {
        'id': 1,
        'title': 'مهمة جديدة بالقرب منك',
        'body': 'يوجد تبرع جديد بالخبز على بعد 2 كم.',
        'is_read': false,
        'created_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      },
      {
        'id': 2,
        'title': 'تم تأكيد استلام التبرع',
        'body': 'شكرًا لك على توصيل تبرع \'وجبات ساخنة\'.',
        'is_read': true,
        'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التنبيهات'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد تنبيهات'));
          }
          final notifications = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(SPACING_UNIT * 2),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(context, notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, Map<String, dynamic> notification) {
    final isRead = notification['is_read'] as bool;
    return Card(
      margin: const EdgeInsets.only(bottom: SPACING_UNIT * 2),
      elevation: 2,
      shadowColor: Colors.black.withAlpha(25),
      child: ListTile(
        title: Text(
          notification['title']!,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
              ),
        ),
        subtitle: Text(notification['body']!, style: Theme.of(context).textTheme.bodyMedium),
        trailing: const Icon(Icons.notifications, color: COLOR_PRIMARY),
      ),
    );
  }
}
