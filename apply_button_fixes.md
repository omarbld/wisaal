# تطبيق إصلاحات الأزرار على ملفات المشروع

## 📋 الإصلاحات المطلوبة

### 1. إصلاح زر الهاتف في `volunteer/screens/home_screen.dart`

**الموقع:** السطر حوالي 280
```dart
// استبدال هذا الكود:
IconButton(
  icon: Icon(Icons.phone, color: COLOR_VOLUNTEER_ACCENT),
  onPressed: () {
    // فتح تطبيق الهاتف
  },
),

// بهذا الكود:
IconButton(
  icon: Icon(Icons.phone, color: COLOR_VOLUNTEER_ACCENT),
  onPressed: () async {
    try {
      await PhoneUtils.makePhoneCall(_associationInfo!['phone']);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح تطبيق الهاتف: $e')),
        );
      }
    }
  },
),
```

### 2. إصلاح FloatingActionButton في `volunteer/screens/home_screen.dart`

**الموقع:** السطر حوالي 850
```dart
// استبدال هذا الكود:
FloatingActionButton.extended(
  onPressed: () {
    // التنقل لصفحة البحث المتقدم أو الخريطة
  },
  backgroundColor: COLOR_VOLUNTEER_ACCENT,
  icon: const Icon(Icons.search, color: Colors.white),
  label: const Text(
    'بحث متقدم',
    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  ),
);

// بهذا الكود:
FloatingActionButton.extended(
  onPressed: () async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AdvancedSearchScreen(),
      ),
    );
    if (result != null) {
      // تطبيق فلاتر البحث المتقدم
      _applyAdvancedSearch(result);
    }
  },
  backgroundColor: COLOR_VOLUNTEER_ACCENT,
  icon: const Icon(Icons.search, color: Colors.white),
  label: const Text(
    'بحث متقدم',
    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  ),
);
```

### 3. إصلاح رابط "عرض الكل" في `volunteer/screens/home_screen.dart`

**الموقع:** السطر حوالي 450
```dart
// استبدال هذا الكود:
TextButton(
  onPressed: () {
    // التنقل لصفحة جميع المهام
  },
  child: const Text('عرض الكل'),
),

// بهذا الكود:
TextButton(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AllVolunteerTasksScreen(),
      ),
    );
  },
  child: const Text('عرض الكل'),
),
```

### 4. إضافة Confirmation Dialog لحذف المستخدمين في `manager_users.dart`

```dart
// إضافة هذه الدالة:
Future<void> _deleteUser(String userId, String userName) async {
  final confirmed = await ConfirmationDialog.show(
    context: context,
    title: 'تأكيد الحذف',
    content: 'هل أنت متأكد من حذف المستخدم "$userName"؟\nهذا الإجراء لا يمكن التراجع عنه.',
    confirmText: 'حذف',
    confirmColor: Colors.red,
  );

  if (confirmed == true) {
    try {
      await _supabase.from('users').delete().eq('id', userId);
      if (mounted) {
        ErrorHandler.showSuccess(context, 'تم حذف المستخدم بنجاح');
        setState(() {}); // تحديث القائمة
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'فشل في حذف المستخدم: $e');
      }
    }
  }
}
```

### 5. إضافة Loading States للأزرار الحساسة

#### في `association_nearby_donations.dart`:
```dart
// استبدال زر قبول التبرع:
ElevatedButton(
  onPressed: () => _showAcceptDialog(donation, theme),
  child: const Text('قبول هذا التبرع'),
),

// بهذ�� الكود:
LoadingButton(
  text: 'قبول هذا التبرع',
  isLoading: _isAccepting,
  onPressed: () => _showAcceptDialog(donation, theme),
),
```

#### في `add_donation.dart`:
```dart
// استبدال زر الإرسال:
_loading
  ? const Center(child: CircularProgressIndicator())
  : ElevatedButton.icon(
      icon: const Icon(Icons.send_outlined),
      onPressed: _submit,
      label: const Text('إرسال التبرع'),
    ),

// بهذا الكود:
LoadingButton(
  text: 'إرسال التبرع',
  icon: Icons.send_outlined,
  isLoading: _loading,
  onPressed: _submit,
),
```

### 6. إضافة Error Handling محسن

#### في جميع الملفات التي تستخدم try-catch:
```dart
// استبدال هذا النمط:
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('خطأ: $e')),
  );
}

// بهذا النمط:
} catch (e) {
  if (mounted) {
    ErrorHandler.showError(context, 'حدث خطأ: $e');
  }
}
```

### 7. إضافة Empty States محسنة

#### في `donations_list.dart`:
```dart
// استبدال Empty State:
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.inbox_outlined,
          size: 80,
          color: colorScheme.onSurfaceVariant.withAlpha(128)),
      const SizedBox(height: 16),
      Text(
        'لا توجد تبرعات هنا',
        style: textTheme.titleLarge
            ?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    ],
  ),
);

// بهذا الكود:
EmptyStateWidget(
  icon: Icons.inbox_outlined,
  title: 'لا توجد تبرعات هنا',
  subtitle: 'ابدأ بإضافة تبرع جديد لرؤية قائمة تبرعاتك',
  action: ElevatedButton.icon(
    icon: const Icon(Icons.add),
    label: const Text('إضافة تبرع جديد'),
    onPressed: () {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddDonationScreen()),
      );
    },
  ),
),
```

### 8. إضافة Search Filter محسن

#### في `association_volunteers.dart`:
```dart
// إضافة حقل البحث في أعلى الصفحة:
SearchFilterWidget(
  hintText: 'البحث في أسماء المتطوعين...',
  onChanged: (value) {
    setState(() {
      _searchQuery = value;
    });
  },
  onClear: () {
    setState(() {
      _searchQuery = '';
    });
  },
),
```

### 9. إضافة Network Images محسنة

#### في جميع الملفات التي تستخدم NetworkImage:
```dart
// استبدال:
CircleAvatar(
  backgroundImage: NetworkImage(avatarUrl),
),

// بهذا الكود:
CircleAvatar(
  child: ClipOval(
    child: NetworkImageWithLoading(
      imageUrl: avatarUrl,
      width: 60,
      height: 60,
    ),
  ),
),
```

### 10. إضافة Refresh Buttons محسنة

#### في جميع AppBars:
```dart
// استبدال:
IconButton(
  icon: const Icon(Icons.refresh),
  onPressed: _loadData,
),

// بهذا الكود:
RefreshButton(
  onRefresh: _loadData,
  isRefreshing: _isRefreshing,
),
```

## 📁 ملفات جديدة مطلوبة

### 1. إنشاء `lib/common/widgets/`
- `loading_button.dart`
- `confirmation_dialog.dart`
- `error_handler.dart`
- `network_image_with_loading.dart`
- `refresh_button.dart`
- `empty_state_widget.dart`
- `search_filter_widget.dart`

### 2. إنشاء `lib/common/utils/`
- `phone_utils.dart`

### 3. إنشاء `lib/volunteer/screens/`
- `advanced_search_screen.dart`
- `all_volunteer_tasks_screen.dart`

## 🔧 خطوات التطبيق

### الخطوة 1: إضافة Dependencies
```yaml
# في pubspec.yaml
dependencies:
  url_launcher: ^6.2.2
```

### الخطوة 2: إنشاء الملفات الجديدة
نسخ الكود من `fix_pending_functions.dart` إلى الملفات المناسبة

### الخطوة 3: تطبيق الإصلاحات
تطبيق التغييرات المذكورة أعلاه على الملفات الموجودة

### الخطوة 4: إضافة Imports
```dart
// في كل ملف يستخدم الوظائف الجديدة:
import 'package:wisaal/common/widgets/loading_button.dart';
import 'package:wisaal/common/widgets/confirmation_dialog.dart';
import 'package:wisaal/common/widgets/error_handler.dart';
import 'package:wisaal/common/utils/phone_utils.dart';
```

### الخطوة 5: اختبار الوظائف
- اختبار جميع الأزرار المُحدثة
- التأكد من عمل Loading States
- التأكد من عمل Error Handling
- اختبار Confirmation Dialogs

## ✅ النتيجة المتوقعة

بعد تطبيق هذه الإصلاحات:
- **100% من الأزرار ستعمل بشكل صحيح**
- **تحسين كبير في تجربة المستخدم**
- **معالجة أخطاء أفضل**
- **Loading states واضحة**
- **Confirmation dialogs للعمليات الحساسة**

## 🎯 الأولويات

### أولوية عالية:
1. إصلاح زر الهاتف
2. إصلاح FloatingActionButton للبحث المتقدم
3. إضافة Confirmation Dialogs

### أولوية متوسطة:
4. إضافة Loading States
5. تحسين Error Handling
6. إضافة Empty States محسنة

### أولوية منخفضة:
7. تحسين Network Images
8. إضافة Search Filters محسنة
9. تحسين Refresh Buttons