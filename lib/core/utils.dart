import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

class AppUtils {
  // Date formatting
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'ar').format(date);
  }
  
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm', 'ar').format(dateTime);
  }
  
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm', 'ar').format(time);
  }
  
  // Status translations
  static String translateDonationStatus(String status) {
    return AppConstants.donationStatusTranslations[status] ?? status;
  }
  
  static String translateUserRole(String role) {
    return AppConstants.userRoleTranslations[role] ?? role;
  }
  
  // Status colors
  static Color getDonationStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'pending':
        return colorScheme.secondary;
      case 'accepted':
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return colorScheme.error;
      default:
        return colorScheme.onSurface.withValues(alpha: 0.7);
    }
  }
  
  // Status icons
  static IconData getDonationStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'accepted':
        return Icons.check;
      case 'assigned':
        return Icons.assignment_ind;
      case 'in_progress':
        return Icons.delivery_dining;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
  
  // Validation helpers
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  static bool isValidPhone(String phone) {
    return RegExp(r'^\d{10}$').hasMatch(phone);
  }
  
  static bool isValidOTP(String otp) {
    return RegExp(r'^\d{6}$').hasMatch(otp);
  }
  
  // Distance calculation
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} م';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} كم';
    }
  }
  
  // Show snackbar helper
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
          ? Theme.of(context).colorScheme.error 
          : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  // Show confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
  
  // Loading dialog
  static void showLoadingDialog(BuildContext context, {String message = 'جاري التحميل...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
  
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
  
  // Generate QR code content
  static String generateQRContent(String donationId, String type) {
    return '${type}_${donationId}';
  }
  
  // Parse QR code content
  static Map<String, String>? parseQRContent(String content) {
    final parts = content.split('_');
    if (parts.length == 2) {
      return {
        'type': parts[0],
        'donationId': parts[1],
      };
    }
    return null;
  }
  
  // Calculate points for actions
  static int calculateDonationPoints(Map<String, dynamic> donation) {
    int basePoints = AppConstants.pointsPerDonation;
    
    // Bonus for urgent donations
    if (donation['is_urgent'] == true) {
      basePoints += 5;
    }
    
    // Bonus for large quantities
    final quantity = donation['quantity'] as int? ?? 1;
    if (quantity > 10) {
      basePoints += 5;
    }
    
    return basePoints;
  }
  
  static int calculateVolunteerPoints(Map<String, dynamic> task) {
    int basePoints = AppConstants.pointsPerVolunteerTask;
    
    // Bonus for urgent tasks
    if (task['is_urgent'] == true) {
      basePoints += 10;
    }
    
    return basePoints;
  }
  
  // Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
  
  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
  
  // Check if date is expired
  static bool isExpired(DateTime expiryDate) {
    return DateTime.now().isAfter(expiryDate);
  }
  
  // Get urgency level based on expiry date
  static String getUrgencyLevel(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inHours;
    
    if (difference <= 6) {
      return 'عاجل جداً';
    } else if (difference <= 24) {
      return 'عاجل';
    } else if (difference <= 48) {
      return 'متوسط';
    } else {
      return 'عادي';
    }
  }
  
  static Color getUrgencyColor(DateTime expiryDate, ColorScheme colorScheme) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inHours;
    
    if (difference <= 6) {
      return Colors.red;
    } else if (difference <= 24) {
      return Colors.orange;
    } else if (difference <= 48) {
      return Colors.yellow.shade700;
    } else {
      return colorScheme.primary;
    }
  }
}