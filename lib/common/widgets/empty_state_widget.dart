import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Color? iconColor;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconColor,
    this.iconSize = 80,
    this.padding = const EdgeInsets.all(32.0),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? theme.colorScheme.onSurfaceVariant.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(178),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyDonationsWidget extends StatelessWidget {
  final VoidCallback? onAddDonation;

  const EmptyDonationsWidget({
    super.key,
    this.onAddDonation,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.inbox_outlined,
      title: 'لا توجد تبرعات هنا',
      subtitle: 'ابدأ بإضافة تبرع جديد لرؤية قائمة تبرعاتك',
      action: onAddDonation != null
          ? ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('إضافة تبرع جديد'),
              onPressed: onAddDonation,
            )
          : null,
    );
  }
}

class EmptyTasksWidget extends StatelessWidget {
  final String? customMessage;

  const EmptyTasksWidget({
    super.key,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.assignment_outlined,
      title: 'لا توجد مهام',
      subtitle: customMessage ?? 'لا توجد مهام متاحة في الوقت الحالي',
    );
  }
}

class EmptyVolunteersWidget extends StatelessWidget {
  final VoidCallback? onInviteVolunteers;

  const EmptyVolunteersWidget({
    super.key,
    this.onInviteVolunteers,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.people_outline,
      title: 'لا يوجد متطوعون',
      subtitle: 'قم بإنشاء أكواد تفعيل لدعوة متطوعين جدد',
      action: onInviteVolunteers != null
          ? ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('إنشاء كود تفعيل'),
              onPressed: onInviteVolunteers,
            )
          : null,
    );
  }
}

class EmptyNotificationsWidget extends StatelessWidget {
  const EmptyNotificationsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.notifications_none_outlined,
      title: 'لا توجد إشعارات',
      subtitle: 'ستظهر الإشعارات الجديدة هنا',
    );
  }
}

class EmptySearchWidget extends StatelessWidget {
  final String searchQuery;
  final VoidCallback? onClearSearch;

  const EmptySearchWidget({
    super.key,
    required this.searchQuery,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.search_off_outlined,
      title: 'لا توجد نتائج',
      subtitle: 'لم نجد أي نتائج لـ "$searchQuery"',
      action: onClearSearch != null
          ? TextButton.icon(
              icon: const Icon(Icons.clear),
              label: const Text('مسح البحث'),
              onPressed: onClearSearch,
            )
          : null,
    );
  }
}

class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorWidget({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.wifi_off_outlined,
      title: 'لا يوجد اتصال بالإنترنت',
      subtitle: 'تحقق من اتصالك بالإنترنت وحاول مرة أخرى',
      iconColor: Colors.red.shade400,
      action: onRetry != null
          ? ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: onRetry,
            )
          : null,
    );
  }
}

class ServerErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const ServerErrorWidget({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: 'حدث خطأ في الخادم',
      subtitle: 'نعتذر عن الإزعاج. يرجى المحاولة مرة أخرى لاحقاً',
      iconColor: Colors.orange.shade400,
      action: onRetry != null
          ? ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: onRetry,
            )
          : null,
    );
  }
}