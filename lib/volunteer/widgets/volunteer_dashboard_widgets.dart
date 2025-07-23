import 'package:flutter/material.dart';
import 'package:wisaal/core/theme.dart';

/// مجموعة من الويدجت المخصصة للوحة تحكم المتطوع
class VolunteerDashboardWidgets {
  /// بطاقة إحصائية متحركة
  static Widget buildAnimatedStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Animation<double> animation,
    VoidCallback? onTap,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animation.value),
          child: Opacity(
            opacity: animation.value,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(SPACING_MD),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.1),
                      color.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(height: SPACING_XS),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// بطاقة مهمة سريعة
  static Widget buildQuickTaskCard({
    required Map<String, dynamic> task,
    required VoidCallback onTap,
    required Animation<double> animation,
  }) {
    final status = task['status'];
    Color statusColor = status == 'assigned' ? COLOR_WARNING : COLOR_INFO;
    String statusText = status == 'assigned' ? 'مُعيَّنة' : 'قيد التنفيذ';
    IconData statusIcon =
        status == 'assigned' ? Icons.assignment : Icons.pending_actions;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - animation.value), 0),
          child: Opacity(
            opacity: animation.value,
            child: Container(
              width: 280,
              margin: const EdgeInsets.only(right: SPACING_SM),
              child: Card(
                elevation: 4,
                shadowColor: statusColor.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
                  side: BorderSide(color: statusColor.withValues(alpha: 0.2)),
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
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(statusIcon,
                                  color: statusColor, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task['title'] ?? 'مهمة',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: SPACING_XS),
                        if (task['donor'] != null)
                          Row(
                            children: [
                              Icon(Icons.person,
                                  size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'من: ${task['donor']['full_name']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        if (task['pickup_address'] != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  task['pickup_address'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// بطاقة تبرع محسنة
  static Widget buildEnhancedDonationCard({
    required Map<String, dynamic> donation,
    required VoidCallback onAccept,
    required VoidCallback onViewDetails,
    required Animation<double> animation,
  }) {
    final isUrgent = donation['is_urgent'] == true;
    final hasExpiry = donation['expiry_date'] != null;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * animation.value),
          child: Opacity(
            opacity: animation.value,
            child: Card(
              elevation: 3,
              shadowColor: isUrgent
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
                side: BorderSide(
                  color: isUrgent
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.transparent,
                  width: isUrgent ? 2 : 0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with image/icon
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isUrgent
                            ? [Colors.red[50]!, Colors.red[100]!]
                            : [Colors.grey[50]!, Colors.grey[100]!],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(BORDER_RADIUS_MEDIUM),
                        topRight: Radius.circular(BORDER_RADIUS_MEDIUM),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            _getFoodIcon(donation['food_type']),
                            color:
                                isUrgent ? Colors.red[300] : Colors.grey[400],
                            size: 40,
                          ),
                        ),
                        if (isUrgent)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.priority_high,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                  const Text(
                                    'عاجل',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (hasExpiry)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    _formatExpiryDate(donation['expiry_date']),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(SPACING_SM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            donation['title'] ?? 'تبرع',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.scale,
                                  size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${donation['quantity'] ?? 'غير محدد'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.person,
                                  size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  donation['donor']?['full_name'] ?? 'متبرع',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: onViewDetails,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: COLOR_VOLUNTEER_ACCENT),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  child: Text(
                                    'تفاصيل',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: COLOR_VOLUNTEER_ACCENT,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: onAccept,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: COLOR_VOLUNTEER_ACCENT,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    elevation: 2,
                                  ),
                                  child: const Text(
                                    'قبول',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// بطاقة معلومات الجمعية
  static Widget buildAssociationInfoCard({
    required Map<String, dynamic> associationInfo,
    required Animation<double> animation,
    VoidCallback? onCall,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: Container(
              margin: const EdgeInsets.all(SPACING_MD),
              padding: const EdgeInsets.all(SPACING_LG),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    COLOR_VOLUNTEER_ACCENT.withValues(alpha: 0.1),
                    COLOR_VOLUNTEER_ACCENT.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(BORDER_RADIUS_LARGE),
                border: Border.all(
                  color: COLOR_VOLUNTEER_ACCENT.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: COLOR_VOLUNTEER_ACCENT.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: COLOR_VOLUNTEER_ACCENT.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor:
                          COLOR_VOLUNTEER_ACCENT.withValues(alpha: 0.1),
                      backgroundImage: associationInfo['avatar_url'] != null
                          ? NetworkImage(associationInfo['avatar_url'])
                          : null,
                      child: associationInfo['avatar_url'] == null
                          ? Icon(
                              Icons.business,
                              color: COLOR_VOLUNTEER_ACCENT,
                              size: 30,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: SPACING_MD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تعمل مع',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          associationInfo['full_name'] ?? 'جمعية',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: COLOR_VOLUNTEER_ACCENT,
                          ),
                        ),
                        if (associationInfo['city'] != null)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                associationInfo['city'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (associationInfo['phone'] != null)
                    Container(
                      decoration: BoxDecoration(
                        color: COLOR_VOLUNTEER_ACCENT.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.phone,
                          color: COLOR_VOLUNTEER_ACCENT,
                        ),
                        onPressed: onCall,
                        tooltip: 'اتصال بالجمعية',
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// أيقونة نوع الطعام
  static IconData _getFoodIcon(String? foodType) {
    switch (foodType?.toLowerCase()) {
      case 'fruits':
      case 'فواكه':
        return Icons.apple;
      case 'vegetables':
      case 'خضروات':
        return Icons.eco;
      case 'meat':
      case 'لحوم':
        return Icons.restaurant;
      case 'dairy':
      case 'ألبان':
        return Icons.local_drink;
      case 'bread':
      case 'خبز':
        return Icons.bakery_dining;
      case 'canned':
      case 'معلبات':
        return Icons.inventory;
      default:
        return Icons.fastfood_outlined;
    }
  }

  /// تنسيق تاريخ الانتهاء
  static String _formatExpiryDate(String? expiryDate) {
    if (expiryDate == null) return '';

    try {
      final date = DateTime.parse(expiryDate);
      final now = DateTime.now();
      final difference = date.difference(now).inDays;

      if (difference <= 0) {
        return 'منتهي';
      } else if (difference == 1) {
        return 'غداً';
      } else if (difference <= 7) {
        return '${difference}د';
      } else {
        return '${date.day}/${date.month}';
      }
    } catch (e) {
      return '';
    }
  }
}
