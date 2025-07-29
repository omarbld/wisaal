# إصلاح مشكلة تعيين المتطوعين

## المشكلة
كانت هناك مشكلة عند تعيين المتطوعين من قبل الجمعيات، حيث كان يظهر الخطأ التالي:
```
PostgrestException(message: invalid input syntax for type uuid: "null", code: 22P02, details: , hint: null)
فشل تعيين المتطوع
```

## السبب
المشكلة كانت في عدم تطابق أسماء الأعمدة بين دالة قاعدة البيانات `get_volunteers_for_association` والكود في التطبيق:

### في قاعدة البيانات:
- الدالة ترجع `volunteer_id` 
- الدالة ترجع `avg_rating`
- الدالة ترجع `completed_tasks`

### في التطبيق:
- الكود كان يحاول الوصول إلى `id`
- الكود كان يحاول الوصول إلى `average_rating`
- الكود كان يحاول الوصول إلى `completed_tasks_count`

## الإصلاحات المطبقة

### 1. إصلاح ملف `association_select_volunteer.dart`
```dart
// قبل الإصلاح
Navigator.of(context).pop(volunteer['id'].toString());
Text(volunteer['average_rating']?.toStringAsFixed(1) ?? 'N/A')
Text(volunteer['completed_tasks_count']?.toString() ?? '0')

// بعد الإصلاح
Navigator.of(context).pop(volunteer['volunteer_id'].toString());
Text(volunteer['avg_rating']?.toStringAsFixed(1) ?? 'N/A')
Text(volunteer['completed_tasks']?.toString() ?? '0')
```

### 2. إصلاح ملف `association_volunteers.dart`
```dart
// قبل الإصلاح
return (b['average_rating'] ?? 0.0).compareTo(a['average_rating'] ?? 0.0);
final avgRating = volunteer['average_rating'] as double? ?? 0.0;

// بعد الإصلاح
return (b['avg_rating'] ?? 0.0).compareTo(a['avg_rating'] ?? 0.0);
final avgRating = volunteer['avg_rating'] as double? ?? 0.0;
```

### 3. إنشاء ملف إصلاح قاعدة البيانات
تم إنشاء ملف `fix_volunteer_assignment.sql` للتأكد من أن دالة قاعدة البيانات تعمل بشكل صحيح.

## النتيجة
بعد هذه الإصلاحات، يجب أن تعمل عملية تعيين المتطوعين بشكل صحيح دون ظهور خطأ UUID.

## ملاحظات
- ملف `manager_volunteers.dart` لم يحتج لإصلاح لأنه يستخدم استعلام مباشر من جدول `users` وليس دالة `get_volunteers_for_association`
- تم التأكد من أن جميع أسماء الأعمدة متطابقة بين قاعدة البيانات والتطبيق

## اختبار الإصلاح
لاختبار الإصلاح:
1. قم بتشغيل التطبيق
2. سجل دخول كجمعية
3. اذهب إلى تفاصيل تبرع مقبول
4. اضغط على "اختيار متطوع للمهمة"
5. اختر متطوع من القائمة
6. يجب أن تتم العملية بنجاح دون ظهور خطأ UUID