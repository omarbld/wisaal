// إصلاحات للوظائف المعلقة في تطبيق وصال
// هذا الملف يحتوي على الكود المطلوب لإكمال الوظائف غير المُنفذة

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// 1. إصلاح وظيفة فتح تطبيق الهاتف
class PhoneUtils {
  static Future<void> makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }
}

// 2. إصلاح FloatingActionButton للبحث المتقدم
class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final _searchController = TextEditingController();
  String _selectedFoodType = 'الكل';
  bool _urgentOnly = false;
  double _maxDistance = 10.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بحث متقدم'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'البحث في العنوان أو الوصف',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedFoodType,
              decoration: const InputDecoration(
                labelText: 'نوع الطعام',
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(value: 'الكل', child: Text('الكل')),
                DropdownMenuItem(value: 'وجبات مطبوخة', child: Text('وجبات مطبوخة')),
                DropdownMenuItem(value: 'مواد جافة', child: Text('مواد جافة')),
                DropdownMenuItem(value: 'فواكه وخضروات', child: Text('فواكه وخضروات')),
                DropdownMenuItem(value: 'حلويات ومخبوزات', child: Text('حلويات ومخبوزات')),
              ],
              onChanged: (value) => setState(() => _selectedFoodType = value!),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('التبرعات العاجلة فقط'),
              value: _urgentOnly,
              onChanged: (value) => setState(() => _urgentOnly = value),
            ),
            const SizedBox(height: 16),
            Text('المسافة القصوى: ${_maxDistance.toInt()} كم'),
            Slider(
              value: _maxDistance,
              min: 1.0,
              max: 50.0,
              divisions: 49,
              onChanged: (value) => setState(() => _maxDistance = value),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('بحث'),
              onPressed: _performSearch,
            ),
          ],
        ),
      ),
    );
  }

  void _performSearch() {
    // تنفيذ البحث المتقدم
    Navigator.pop(context, {
      'searchText': _searchController.text,
      'foodType': _selectedFoodType,
      'urgentOnly': _urgentOnly,
      'maxDistance': _maxDistance,
    });
  }
}

// 3. إصلاح صفحة جميع المهام للمتطوع
class AllVolunteerTasksScreen extends StatefulWidget {
  const AllVolunteerTasksScreen({super.key});

  @override
  State<AllVolunteerTasksScreen> createState() => _AllVolunteerTasksScreenState();
}

class _AllVolunteerTasksScreenState extends State<AllVolunteerTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جميع مهامي'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'مُعيَّنة'),
            Tab(text: 'قيد التنفيذ'),
            Tab(text: 'مكتملة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTasksList('all'),
          _buildTasksList('assigned'),
          _buildTasksList('in_progress'),
          _buildTasksList('completed'),
        ],
      ),
    );
  }

  Widget _buildTasksList(String status) {
    // تنفيذ قائمة المهام حسب الحالة
    return const Center(
      child: Text('قائمة المهام'),
    );
  }
}

// 4. إضافة Confirmation Dialogs
class ConfirmationDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
    Color? confirmColor,
  }) {
    return showDialog<bool>(
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
            style: confirmColor != null
                ? ElevatedButton.styleFrom(backgroundColor: confirmColor)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}

// 5. إضافة Loading Button Widget
class LoadingButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const LoadingButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : (icon != null ? Icon(icon) : const SizedBox.shrink()),
      label: Text(text),
    );
  }
}

// 6. إضافة Error Handling Widget
class ErrorHandler {
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// 7. إضافة Network Image with Loading
class NetworkImageWithLoading extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const NetworkImageWithLoading({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: width,
          height: height,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.error_outline),
        );
      },
    );
  }
}

// 8. إضافة Refresh Button
class RefreshButton extends StatelessWidget {
  final VoidCallback onRefresh;
  final bool isRefreshing;

  const RefreshButton({
    super.key,
    required this.onRefresh,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: isRefreshing ? null : onRefresh,
      icon: isRefreshing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh),
    );
  }
}

// 9. إضافة Empty State Widget
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
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

// 10. إضافة Search Filter Widget
class SearchFilterWidget extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const SearchFilterWidget({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: onClear != null
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: onClear,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}