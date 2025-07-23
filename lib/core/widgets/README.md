# دليل استخدام الثيم الموحد - Wisaal App

## نظرة عامة

تم تطوير نظام ثيم موحد لتطبيق وصال لضمان التناسق البصري عبر جميع الأدوار (المتبرع، المتطوع، الجمعية، المدير) مع الحفاظ على الهوية المميزة لكل دور.

## هيكل الملفات

```
lib/core/
├── theme.dart                    # الثيم الأساسي والألوان
├── widgets/
│   ├── common_widgets.dart       # المكونات المشتركة
│   ├── role_themed_widgets.dart  # المكونات المخصصة لكل دور
│   └── README.md                # هذا الملف
```

## الألوان الأساسية

### الألوان العامة
- `COLOR_PRIMARY`: #26A69A (اللون الأساسي)
- `COLOR_BACKGROUND`: #F9F9F9 (خلفية التطبيق)
- `COLOR_ACCENT`: #FFC107 (لون التمييز)
- `COLOR_WHITE`: #FFFFFF (الأبيض)
- `COLOR_SUCCESS`: #4CAF50 (النجاح)
- `COLOR_WARNING`: #FF9800 (التحذير)
- `COLOR_ERROR`: #F44336 (الخطأ)
- `COLOR_INFO`: #2196F3 (المعلومات)

### الألوان المخصصة للأدوار
- `COLOR_DONOR_ACCENT`: #4CAF50 (المتبرع - أخضر)
- `COLOR_VOLUNTEER_ACCENT`: #2196F3 (المتطوع - أزرق)
- `COLOR_ASSOCIATION_ACCENT`: #9C27B0 (الجمعية - بنفسجي)
- `COLOR_MANAGER_ACCENT`: #FF5722 (المدير - برتقالي)

## نظام المسافات

```dart
const double SPACING_XS = 4.0;   // مسافة صغيرة جداً
const double SPACING_SM = 8.0;   // مسافة صغيرة
const double SPACING_MD = 16.0;  // مسافة متوسطة
const double SPACING_LG = 24.0;  // مسافة كبيرة
const double SPACING_XL = 32.0;  // مسافة كبيرة جداً
```

## نظام الحواف

```dart
const double BORDER_RADIUS_SMALL = 8.0;   // حواف صغيرة
const double BORDER_RADIUS_MEDIUM = 12.0; // حواف متوسطة
const double BORDER_RADIUS_LARGE = 16.0;  // حواف كبيرة
const double BORDER_RADIUS_XL = 24.0;     // حواف كبيرة جداً
```

## استخدام المكونات المشتركة

### 1. بطاقة الإحصائيات

```dart
import 'package:wisaal/core/widgets/common_widgets.dart';

CommonWidgets.buildStatCard(
  context: context,
  title: 'إجمالي التبرعات',
  value: '25',
  icon: Icons.favorite,
  color: COLOR_PRIMARY,
  onTap: () {
    // عند النقر
  },
  subtitle: 'هذا الشهر',
);
```

### 2. عنوان القسم

```dart
CommonWidgets.buildSectionTitle(
  context: context,
  title: 'التبرعات الحديثة',
  subtitle: 'آخر 5 تبرعات',
  icon: Icons.history,
  action: TextButton(
    onPressed: () {},
    child: Text('عرض الكل'),
  ),
);
```

### 3. بطاقة القائمة

```dart
CommonWidgets.buildListCard(
  context: context,
  title: 'تبرع طعام',
  subtitle: 'وجبات جاهزة للتوزيع',
  leading: Icon(Icons.fastfood),
  trailing: Icon(Icons.arrow_forward_ios),
  onTap: () {},
  accentColor: COLOR_SUCCESS,
  showBorder: true,
);
```

### 4. شريط التطبيق

```dart
CommonWidgets.buildAppBar(
  context: context,
  title: 'الصفحة الرئيسية',
  actions: [
    IconButton(
      icon: Icon(Icons.notifications),
      onPressed: () {},
    ),
  ],
  role: 'donor', // لتطبيق لون الدور
);
```

### 5. الزر العائم

```dart
CommonWidgets.buildFloatingActionButton(
  onPressed: () {},
  icon: Icons.add,
  tooltip: 'إضافة تبرع جديد',
  role: 'donor',
);
```

### 6. بطاقة التنبيه

```dart
CommonWidgets.buildAlertCard(
  context: context,
  title: 'تنبيه مهم',
  message: 'يوجد تبرعات جديدة تحتاج للمراجعة',
  icon: Icons.warning,
  color: COLOR_WARNING,
  onTap: () {},
  onDismiss: () {},
);
```

### 7. شريط الحالة

```dart
CommonWidgets.buildStatusChip(
  status: 'completed', // أو 'pending', 'in_progress', 'cancelled'
);
```

### 8. الحالة الفارغة

```dart
CommonWidgets.buildEmptyState(
  context: context,
  title: 'لا توجد تبرعات',
  message: 'لم يتم العثور على أي تبرعات حالياً',
  icon: Icons.inbox,
  action: ElevatedButton(
    onPressed: () {},
    child: Text('إضافة تبرع'),
  ),
);
```

### 9. مؤشر التحميل

```dart
CommonWidgets.buildLoadingIndicator(
  message: 'جاري تحميل البيانات...',
  color: COLOR_PRIMARY,
);
```

## استخدام المكونات المخصصة للأدوار

### للمتبرع

```dart
import 'package:wisaal/core/widgets/role_themed_widgets.dart';

// بطاقة إحصائيات المتبرع
RoleThemedWidgets.buildDonorStatCard(
  context: context,
  title: 'تبرعاتي',
  value: '12',
  icon: Icons.favorite,
  onTap: () {},
);

// شريط تطبيق المتبرع
RoleThemedWidgets.buildDonorAppBar(
  context: context,
  title: 'لوحة المتبرع',
  actions: [
    IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
  ],
);

// زر عائم المتبرع
RoleThemedWidgets.buildDonorFAB(
  onPressed: () {},
  icon: Icons.add,
  tooltip: 'إضافة تبرع',
);

// بطاقة التبرع
RoleThemedWidgets.buildDonationCard(
  context: context,
  donation: donationData,
  onTap: () {},
  onEdit: () {},
  onDelete: () {},
);
```

### للمتطوع

```dart
// بطاقة إحصائيات المتطوع
RoleThemedWidgets.buildVolunteerStatCard(
  context: context,
  title: 'مهامي',
  value: '8',
  icon: Icons.assignment,
);

// بطاقة المهمة
RoleThemedWidgets.buildTaskCard(
  context: context,
  task: taskData,
  onTap: () {},
  onAccept: () {},
  onComplete: () {},
);
```

### للجمعية

```dart
// بطاقة إحصائيات الجمعية
RoleThemedWidgets.buildAssociationStatCard(
  context: context,
  title: 'المتطوعين',
  value: '15',
  icon: Icons.people,
);

// بطاقة المتطوع
RoleThemedWidgets.buildVolunteerCard(
  context: context,
  volunteer: volunteerData,
  onTap: () {},
  onAssign: () {},
  onRate: () {},
);
```

### للمدير

```dart
// بطاقة إحصائيات المدير
RoleThemedWidgets.buildManagerStatCard(
  context: context,
  title: 'إجمالي المستخدمين',
  value: '150',
  icon: Icons.people,
);

// بطاقة نظرة عامة
RoleThemedWidgets.buildManagerOverviewCard(
  context: context,
  title: 'إحصائيات النظام',
  stats: [
    {
      'icon': Icons.people,
      'label': 'المستخدمين',
      'value': 150,
    },
    {
      'icon': Icons.business,
      'label': 'الجمعيات',
      'value': 25,
    },
  ],
  onViewAll: () {},
);
```

## الدوال المساعدة

### الحصول على لون الدور

```dart
Color roleColor = AppTheme.getRoleColor('donor');
```

### إنشاء ظلال متسقة

```dart
List<BoxShadow> shadows = AppTheme.getElevationShadow(ELEVATION_MEDIUM);
```

### التدرج الأساسي

```dart
LinearGradient gradient = AppTheme.getPrimaryGradient();
```

## أفضل الممارسات

1. **استخدم المكونات المشتركة**: دائماً استخدم المكونات من `CommonWidgets` أو `RoleThemedWidgets` بدلاً من إنشاء مكونات مخصصة.

2. **اتبع نظام المسافات**: استخدم ثوابت `SPACING_*` للمسافات.

3. **استخدم الألوان المحددة**: لا تستخدم ألوان مخصصة، التزم بالألوان المحددة في الثيم.

4. **حدد الدور**: عند استخدام المكونات، حدد الدور المناسب للحصول على اللون الصحيح.

5. **اختبر على جميع الأدوار**: تأكد من أن التصميم يعمل بشكل جيد على جميع الأدوار.

## مثال شامل

```dart
import 'package:flutter/material.dart';
import 'package:wisaal/core/theme.dart';
import 'package:wisaal/core/widgets/common_widgets.dart';
import 'package:wisaal/core/widgets/role_themed_widgets.dart';

class ExampleScreen extends StatelessWidget {
  final String userRole;
  
  const ExampleScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonWidgets.buildAppBar(
        context: context,
        title: 'مثال على الثيم الموحد',
        role: userRole,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SPACING_MD),
        child: Column(
          children: [
            // عنوان القسم
            CommonWidgets.buildSectionTitle(
              context: context,
              title: 'الإحصائيات',
              subtitle: 'نظرة سريعة على البيانات',
            ),
            
            // شبكة الإحصائيات
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              children: [
                _buildRoleStatCard(context, userRole),
                _buildRoleStatCard(context, userRole),
              ],
            ),
            
            const SizedBox(height: SPACING_LG),
            
            // قائمة العناصر
            CommonWidgets.buildSectionTitle(
              context: context,
              title: 'العناصر الحديثة',
            ),
            
            ...List.generate(3, (index) => 
              CommonWidgets.buildListCard(
                context: context,
                title: 'عنصر ${index + 1}',
                subtitle: 'وصف العنصر',
                leading: Icon(Icons.star),
                onTap: () {},
                accentColor: AppTheme.getRoleColor(userRole),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: CommonWidgets.buildFloatingActionButton(
        onPressed: () {},
        icon: Icons.add,
        role: userRole,
      ),
    );
  }
  
  Widget _buildRoleStatCard(BuildContext context, String role) {
    switch (role) {
      case 'donor':
        return RoleThemedWidgets.buildDonorStatCard(
          context: context,
          title: 'تبرعاتي',
          value: '12',
          icon: Icons.favorite,
        );
      case 'volunteer':
        return RoleThemedWidgets.buildVolunteerStatCard(
          context: context,
          title: 'مهامي',
          value: '8',
          icon: Icons.assignment,
        );
      case 'association':
        return RoleThemedWidgets.buildAssociationStatCard(
          context: context,
          title: 'المتطوعين',
          value: '15',
          icon: Icons.people,
        );
      case 'manager':
        return RoleThemedWidgets.buildManagerStatCard(
          context: context,
          title: 'المستخدمين',
          value: '150',
          icon: Icons.people,
        );
      default:
        return CommonWidgets.buildStatCard(
          context: context,
          title: 'إحصائية',
          value: '0',
          icon: Icons.info,
        );
    }
  }
}
```

هذا الدليل يوفر إرشادات شاملة لاستخدام النظام الموحد للثيم في تطبيق وصال، مما يضمن التناسق البصري والتجربة المتسقة عبر جميع الأدوار.
