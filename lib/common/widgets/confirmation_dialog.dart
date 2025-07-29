import 'package:flutter/material.dart';

class ConfirmationDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
    Color? confirmColor,
    IconData? icon,
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: isDangerous ? Colors.red : Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDangerous ? Colors.red : null,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                cancelText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor ?? 
                  (isDangerous ? Colors.red : Theme.of(context).colorScheme.primary),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                confirmText,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool?> showDeleteConfirmation({
    required BuildContext context,
    required String itemName,
    String? additionalInfo,
  }) {
    return show(
      context: context,
      title: 'تأكيد الحذف',
      content: 'هل أنت متأكد من حذف "$itemName"؟'
          '${additionalInfo != null ? '\n\n$additionalInfo' : ''}'
          '\n\nهذا الإجراء لا يمكن التراجع عنه.',
      confirmText: 'حذف',
      cancelText: 'إلغاء',
      icon: Icons.delete_outline,
      isDangerous: true,
    );
  }

  static Future<bool?> showLogoutConfirmation({
    required BuildContext context,
  }) {
    return show(
      context: context,
      title: 'تسجيل الخروج',
      content: 'هل أنت متأكد من تسجيل الخروج من حسابك؟',
      confirmText: 'تسجيل الخروج',
      cancelText: 'إلغاء',
      icon: Icons.logout,
      isDangerous: true,
    );
  }

  static Future<bool?> showAcceptConfirmation({
    required BuildContext context,
    required String itemName,
    String? additionalInfo,
  }) {
    return show(
      context: context,
      title: 'تأكيد القبول',
      content: 'هل أنت متأكد من قبول "$itemName"؟'
          '${additionalInfo != null ? '\n\n$additionalInfo' : ''}',
      confirmText: 'قبول',
      cancelText: 'إلغاء',
      icon: Icons.check_circle_outline,
    );
  }
}