import 'package:flutter/material.dart';
import '../theme.dart';
import 'common_widgets.dart';

/// مكونات واجهة المستخدم المخصصة لكل دور مع الحفاظ على التناسق
class RoleThemedWidgets {
  /// بطاقة إحصائيات مخصصة للمتبرع
  static Widget buildDonorStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
    String? subtitle,
  }) {
    return CommonWidgets.buildStatCard(
      context: context,
      title: title,
      value: value,
      icon: icon,
      color: COLOR_DONOR_ACCENT,
      onTap: onTap,
      subtitle: subtitle,
    );
  }

  /// بطاقة إحصائيات مخصصة للمتطوع
  static Widget buildVolunteerStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
    String? subtitle,
  }) {
    return CommonWidgets.buildStatCard(
      context: context,
      title: title,
      value: value,
      icon: icon,
      color: COLOR_VOLUNTEER_ACCENT,
      onTap: onTap,
      subtitle: subtitle,
    );
  }

  /// بطاقة إحصائيات مخصصة للجمعية
  static Widget buildAssociationStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
    String? subtitle,
  }) {
    return CommonWidgets.buildStatCard(
      context: context,
      title: title,
      value: value,
      icon: icon,
      color: COLOR_ASSOCIATION_ACCENT,
      onTap: onTap,
      subtitle: subtitle,
    );
  }

  /// بطاقة إحصائيات مخصصة للمدير
  static Widget buildManagerStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
    String? subtitle,
  }) {
    return CommonWidgets.buildStatCard(
      context: context,
      title: title,
      value: value,
      icon: icon,
      color: COLOR_MANAGER_ACCENT,
      onTap: onTap,
      subtitle: subtitle,
    );
  }

  /// شريط تطبيق مخصص للمتبرع
  static PreferredSizeWidget buildDonorAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
  }) {
    return CommonWidgets.buildAppBar(
      context: context,
      title: title,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      role: 'donor',
    );
  }

  /// شريط تطبيق مخصص للمتطوع
  static PreferredSizeWidget buildVolunteerAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
  }) {
    return CommonWidgets.buildAppBar(
      context: context,
      title: title,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      role: 'volunteer',
    );
  }

  /// شريط تطبيق مخصص للجمعية
  static PreferredSizeWidget buildAssociationAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
  }) {
    return CommonWidgets.buildAppBar(
      context: context,
      title: title,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      role: 'association',
    );
  }

  /// شريط تطبيق مخصص للمدير
  static PreferredSizeWidget buildManagerAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
  }) {
    return CommonWidgets.buildAppBar(
      context: context,
      title: title,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      role: 'manager',
    );
  }

  /// زر عائم مخصص للمتبرع
  static Widget buildDonorFAB({
    required VoidCallback onPressed,
    required IconData icon,
    String? tooltip,
  }) {
    return CommonWidgets.buildFloatingActionButton(
      onPressed: onPressed,
      icon: icon,
      tooltip: tooltip,
      role: 'donor',
    );
  }

  /// زر عائم مخصص للمتطوع
  static Widget buildVolunteerFAB({
    required VoidCallback onPressed,
    required IconData icon,
    String? tooltip,
  }) {
    return CommonWidgets.buildFloatingActionButton(
      onPressed: onPressed,
      icon: icon,
      tooltip: tooltip,
      role: 'volunteer',
    );
  }

  /// زر عائم مخصص للجمعية
  static Widget buildAssociationFAB({
    required VoidCallback onPressed,
    required IconData icon,
    String? tooltip,
  }) {
    return CommonWidgets.buildFloatingActionButton(
      onPressed: onPressed,
      icon: icon,
      tooltip: tooltip,
      role: 'association',
    );
  }

  /// زر عائم مخصص للمدير
  static Widget buildManagerFAB({
    required VoidCallback onPressed,
    required IconData icon,
    String? tooltip,
  }) {
    return CommonWidgets.buildFloatingActionButton(
      onPressed: onPressed,
      icon: icon,
      tooltip: tooltip,
      role: 'manager',
    );
  }

  /// بطاقة تبرع موحدة للمتبرع
  static Widget buildDonationCard({
    required BuildContext context,
    required Map<String, dynamic> donation,
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    final theme = Theme.of(context);
    final status = donation['status'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: SPACING_MD,
        vertical: SPACING_XS,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
        child: Padding(
          padding: const EdgeInsets.all(SPACING_MD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.fastfood,
                    color: COLOR_DONOR_ACCENT,
                    size: 24,
                  ),
                  const SizedBox(width: SPACING_SM),
                  Expanded(
                    child: Text(
                      donation['title'] ?? 'بلا عنوان',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  CommonWidgets.buildStatusChip(status: status),
                ],
              ),
              const SizedBox(height: SPACING_SM),
              if (donation['description'] != null)
                Text(
                  donation['description'],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: COLOR_TEXT_SECONDARY,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: SPACING_SM),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: COLOR_TEXT_SECONDARY,
                  ),
                  const SizedBox(width: SPACING_XS),
                  Expanded(
                    child: Text(
                      donation['pickup_address'] ?? 'عنوان غير محدد',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: COLOR_TEXT_SECONDARY,
                      ),
                    ),
                  ),
                ],
              ),
              if (onEdit != null || onDelete != null) ...[
                const SizedBox(height: SPACING_SM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('تعديل'),
                        style: TextButton.styleFrom(
                          foregroundColor: COLOR_INFO,
                        ),
                      ),
                    if (onDelete != null)
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('حذف'),
                        style: TextButton.styleFrom(
                          foregroundColor: COLOR_ERROR,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// بطاقة مهمة موحدة للمتطوع
  static Widget buildTaskCard({
    required BuildContext context,
    required Map<String, dynamic> task,
    VoidCallback? onTap,
    VoidCallback? onAccept,
    VoidCallback? onComplete,
  }) {
    final theme = Theme.of(context);
    final status = task['status'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: SPACING_MD,
        vertical: SPACING_XS,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
        child: Padding(
          padding: const EdgeInsets.all(SPACING_MD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.assignment,
                    color: COLOR_VOLUNTEER_ACCENT,
                    size: 24,
                  ),
                  const SizedBox(width: SPACING_SM),
                  Expanded(
                    child: Text(
                      task['title'] ?? 'مهمة بلا عنوان',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  CommonWidgets.buildStatusChip(status: status),
                ],
              ),
              const SizedBox(height: SPACING_SM),
              if (task['description'] != null)
                Text(
                  task['description'],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: COLOR_TEXT_SECONDARY,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: SPACING_SM),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: COLOR_TEXT_SECONDARY,
                  ),
                  const SizedBox(width: SPACING_XS),
                  Text(
                    task['created_at'] ?? 'وقت غير محدد',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: COLOR_TEXT_SECONDARY,
                    ),
                  ),
                  const Spacer(),
                  if (task['distance'] != null) ...[
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: COLOR_VOLUNTEER_ACCENT,
                    ),
                    const SizedBox(width: SPACING_XS),
                    Text(
                      '${task['distance']} كم',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: COLOR_VOLUNTEER_ACCENT,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              if (onAccept != null || onComplete != null) ...[
                const SizedBox(height: SPACING_SM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onAccept != null)
                      ElevatedButton.icon(
                        onPressed: onAccept,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('قبول'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: COLOR_VOLUNTEER_ACCENT,
                        ),
                      ),
                    if (onComplete != null) ...[
                      const SizedBox(width: SPACING_SM),
                      ElevatedButton.icon(
                        onPressed: onComplete,
                        icon: const Icon(Icons.done_all, size: 16),
                        label: const Text('إكمال'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: COLOR_SUCCESS,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// بطاقة متطوع موحدة للجمعية
  static Widget buildVolunteerCard({
    required BuildContext context,
    required Map<String, dynamic> volunteer,
    VoidCallback? onTap,
    VoidCallback? onAssign,
    VoidCallback? onRate,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: SPACING_MD,
        vertical: SPACING_XS,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
        child: Padding(
          padding: const EdgeInsets.all(SPACING_MD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        COLOR_ASSOCIATION_ACCENT.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.person,
                      color: COLOR_ASSOCIATION_ACCENT,
                    ),
                  ),
                  const SizedBox(width: SPACING_SM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          volunteer['full_name'] ?? 'متطوع',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (volunteer['email'] != null)
                          Text(
                            volunteer['email'],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: COLOR_TEXT_SECONDARY,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (volunteer['is_active'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SPACING_SM,
                        vertical: SPACING_XS,
                      ),
                      decoration: BoxDecoration(
                        color: COLOR_SUCCESS.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(BORDER_RADIUS_SMALL),
                      ),
                      child: Text(
                        'نشط',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: COLOR_SUCCESS,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: SPACING_SM),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 16,
                    color: COLOR_ACCENT,
                  ),
                  const SizedBox(width: SPACING_XS),
                  Text(
                    'التقييم: ${volunteer['rating'] ?? 'غير مقيم'}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    'المهام: ${volunteer['completed_tasks'] ?? 0}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: COLOR_ASSOCIATION_ACCENT,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (onAssign != null || onRate != null) ...[
                const SizedBox(height: SPACING_SM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onAssign != null)
                      TextButton.icon(
                        onPressed: onAssign,
                        icon: const Icon(Icons.assignment_ind, size: 16),
                        label: const Text('تكليف'),
                        style: TextButton.styleFrom(
                          foregroundColor: COLOR_ASSOCIATION_ACCENT,
                        ),
                      ),
                    if (onRate != null)
                      TextButton.icon(
                        onPressed: onRate,
                        icon: const Icon(Icons.star_rate, size: 16),
                        label: const Text('تقييم'),
                        style: TextButton.styleFrom(
                          foregroundColor: COLOR_ACCENT,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// بطاقة إحصائيات شاملة للمدير
  static Widget buildManagerOverviewCard({
    required BuildContext context,
    required String title,
    required List<Map<String, dynamic>> stats,
    VoidCallback? onViewAll,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(SPACING_MD),
      child: Padding(
        padding: const EdgeInsets.all(SPACING_MD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dashboard,
                  color: COLOR_MANAGER_ACCENT,
                  size: 24,
                ),
                const SizedBox(width: SPACING_SM),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: COLOR_MANAGER_ACCENT,
                    ),
                  ),
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('عرض الكل'),
                  ),
              ],
            ),
            const SizedBox(height: SPACING_MD),
            ...stats
                .map((stat) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: SPACING_XS),
                      child: Row(
                        children: [
                          Icon(
                            stat['icon'] ?? Icons.info,
                            size: 20,
                            color: COLOR_TEXT_SECONDARY,
                          ),
                          const SizedBox(width: SPACING_SM),
                          Expanded(
                            child: Text(
                              stat['label'] ?? '',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            stat['value']?.toString() ?? '0',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: COLOR_MANAGER_ACCENT,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }
}
