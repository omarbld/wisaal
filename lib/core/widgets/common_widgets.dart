import 'package:flutter/material.dart';
import '../theme.dart';

/// مكونات واجهة المستخدم المشتركة لجميع الأدوار
class CommonWidgets {
  /// بطاقة إحصائيات موحدة مع تصميم متسق
  static Widget buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    Color? color,
    VoidCallback? onTap,
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    final cardColor = color ?? COLOR_PRIMARY;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: ELEVATION_LOW,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
        child: Container(
          padding: const EdgeInsets.all(SPACING_MD),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cardColor.withValues(alpha: 0.05),
                cardColor.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: cardColor.withValues(alpha: 0.15),
                    radius: 24,
                    child: Icon(icon, color: cardColor, size: 24),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: COLOR_TEXT_SECONDARY,
                    ),
                ],
              ),
              const SizedBox(height: SPACING_MD),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: cardColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: SPACING_XS),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: COLOR_TEXT_PRIMARY,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: SPACING_XS),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: COLOR_TEXT_SECONDARY,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// عنوان قسم موحد مع تصميم متسق
  static Widget buildSectionTitle({
    required BuildContext context,
    required String title,
    String? subtitle,
    Widget? action,
    IconData? icon,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final titleColor = color ?? COLOR_TEXT_PRIMARY;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SPACING_MD,
        vertical: SPACING_SM,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: titleColor, size: 24),
            const SizedBox(width: SPACING_SM),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: SPACING_XS),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: COLOR_TEXT_SECONDARY,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  /// بطاقة عنصر قائمة موحدة
  static Widget buildListCard({
    required BuildContext context,
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    Color? accentColor,
    bool showBorder = false,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: SPACING_MD,
        vertical: SPACING_XS,
      ),
      elevation: ELEVATION_LOW,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
          border: showBorder && accentColor != null
              ? Border.all(color: accentColor.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: ListTile(
          leading: leading,
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: accentColor ?? COLOR_TEXT_PRIMARY,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: COLOR_TEXT_SECONDARY,
                  ),
                )
              : null,
          trailing: trailing,
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
          ),
        ),
      ),
    );
  }

  /// شريط تطبيق موحد مع تصميم متسق
  static PreferredSizeWidget buildAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
    Color? backgroundColor,
    String? role,
  }) {
    final roleColor = role != null ? AppTheme.getRoleColor(role) : null;

    return AppBar(
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: roleColor ?? COLOR_TEXT_PRIMARY,
            ),
      ),
      centerTitle: centerTitle,
      actions: actions,
      leading: leading,
      backgroundColor: backgroundColor ?? COLOR_WHITE,
      elevation: ELEVATION_LOW,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      iconTheme: IconThemeData(
        color: roleColor ?? COLOR_PRIMARY,
      ),
    );
  }

  /// زر عائم موحد
  static Widget buildFloatingActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    String? tooltip,
    Color? backgroundColor,
    String? role,
  }) {
    final buttonColor = role != null
        ? AppTheme.getRoleColor(role)
        : backgroundColor ?? COLOR_PRIMARY;

    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: buttonColor,
      elevation: ELEVATION_MEDIUM,
      child: Icon(icon, color: COLOR_WHITE),
    );
  }

  /// بطاقة تنبيه أو إشعار
  static Widget buildAlertCard({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    Color? color,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    final theme = Theme.of(context);
    final alertColor = color ?? COLOR_WARNING;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: SPACING_MD,
        vertical: SPACING_XS,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
          border:
              Border.all(color: alertColor.withValues(alpha: 0.3), width: 1),
          color: alertColor.withValues(alpha: 0.05),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: alertColor.withValues(alpha: 0.2),
            child: Icon(icon, color: alertColor),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: alertColor,
            ),
          ),
          subtitle: Text(
            message,
            style: theme.textTheme.bodyMedium,
          ),
          trailing: onDismiss != null
              ? IconButton(
                  icon: Icon(Icons.close, color: COLOR_TEXT_SECONDARY),
                  onPressed: onDismiss,
                )
              : null,
          onTap: onTap,
        ),
      ),
    );
  }

  /// شريط حالة موحد
  static Widget buildStatusChip({
    required String status,
    Color? color,
    IconData? icon,
  }) {
    Color chipColor;
    IconData chipIcon;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'مكتمل':
        chipColor = COLOR_SUCCESS;
        chipIcon = Icons.check_circle;
        break;
      case 'pending':
      case 'بانتظار':
        chipColor = COLOR_WARNING;
        chipIcon = Icons.hourglass_empty;
        break;
      case 'in_progress':
      case 'قيد التنفيذ':
        chipColor = COLOR_INFO;
        chipIcon = Icons.sync;
        break;
      case 'cancelled':
      case 'ملغي':
        chipColor = COLOR_ERROR;
        chipIcon = Icons.cancel;
        break;
      default:
        chipColor = color ?? COLOR_TEXT_SECONDARY;
        chipIcon = icon ?? Icons.info;
    }

    return Chip(
      avatar: Icon(chipIcon, size: 16, color: chipColor),
      label: Text(
        status,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      backgroundColor: chipColor.withValues(alpha: 0.1),
      side: BorderSide(color: chipColor.withValues(alpha: 0.3)),
    );
  }

  /// قائمة فارغة موحدة
  static Widget buildEmptyState({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    Widget? action,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final emptyColor = color ?? COLOR_TEXT_SECONDARY;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SPACING_XL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: emptyColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: SPACING_MD),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: emptyColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SPACING_SM),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: emptyColor.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: SPACING_LG),
              action,
            ],
          ],
        ),
      ),
    );
  }

  /// مؤشر تحميل موحد
  static Widget buildLoadingIndicator({
    String? message,
    Color? color,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: color ?? COLOR_PRIMARY,
          ),
          if (message != null) ...[
            const SizedBox(height: SPACING_MD),
            Text(
              message,
              style: TextStyle(
                color: COLOR_TEXT_SECONDARY,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// بطاقة معلومات سريعة
  static Widget buildInfoCard({
    required BuildContext context,
    required String title,
    required String value,
    IconData? icon,
    Color? color,
    String? trend,
    bool showTrend = false,
  }) {
    final theme = Theme.of(context);
    final cardColor = color ?? COLOR_PRIMARY;

    return Container(
      padding: const EdgeInsets.all(SPACING_MD),
      decoration: BoxDecoration(
        color: COLOR_WHITE,
        borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
        border: Border.all(color: cardColor.withValues(alpha: 0.2)),
        boxShadow: AppTheme.getElevationShadow(ELEVATION_LOW),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (icon != null) Icon(icon, color: cardColor, size: 20),
              if (showTrend && trend != null)
                Text(
                  trend,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: trend.startsWith('+') ? COLOR_SUCCESS : COLOR_ERROR,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: SPACING_SM),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: cardColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: SPACING_XS),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: COLOR_TEXT_SECONDARY,
            ),
          ),
        ],
      ),
    );
  }
}
