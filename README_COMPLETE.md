# وصال - تطبيق مكافحة هدر الطعام

## نظرة عامة
وصال هو تطبيق ذكي مصمم لمكافحة هدر الطعام في المغرب، خاصة في منطقة العيون-الساقية الحمراء. يربط التطبيق بين المتبرعين والجمعيات الخيرية والمتطوعين لضمان وصول الطعام الفائض إلى المحتاجين.

## الميزات الرئيسية

### للمتبرعين
- إضافة تبرعات غذائية مع الصور والتفاصيل
- تتبع حالة التبرعات في الوقت الفعلي
- نظام النقاط والمكافآت
- خريطة التبرعات
- لوحة المتصدرين

### للجمعيات الخيرية
- استعراض وقبول التبرعات المتاحة
- إدارة المتطوعين
- تعيين المهام للمتطوعين
- تقييم أداء المتطوعين
- تقارير مفصلة عن الأنشطة
- ��نشاء أكواد تفعيل للمتطوعين

### للمتطوعين
- استعراض المهام المعينة
- مسح رموز QR لتأكيد الاستلام والتسليم
- تتبع الموقع أثناء التوصيل
- نظام النقاط والتقييمات

### للمديرين
- لوحة تحكم شاملة
- إدارة جميع المستخدمين
- إحصائيات وتقارير متقدمة
- خريطة شاملة لجميع الأنشطة
- إدارة أكواد التفعيل

## التقنيات المستخدمة

### Frontend
- **Flutter**: إطار العمل الرئيسي
- **Dart**: لغة البرمجة
- **Google Maps**: للخرائط والموقع
- **QR Code**: لمسح الرموز
- **Image Picker**: لاختيار الصور

### Backend
- **Supabase**: قاعدة البيانات والمصادقة
- **PostgreSQL**: قاعدة البيانات
- **PostGIS**: للبيانات الجغرافية
- **Row Level Security**: للأمان

### الحزم المستخدمة
```yaml
dependencies:
  flutter:
    sdk: flutter
  fl_chart: ^0.68.0
  image_picker: ^1.0.4
  qr_flutter: ^4.1.0
  mobile_scanner: ^5.1.0
  supabase_flutter: ^1.10.7
  google_fonts: ^6.1.0
  flutter_localizations:
    sdk: flutter
  flutter_dotenv: ^5.1.0
  geolocator: ^10.1.0
  timeago: ^3.6.0
  intl: ^0.20.2
  printing: ^5.11.1
  pdf: ^3.10.8
  path_provider: ^2.0.15
  bidi: ^2.0.13
  dartarabic: ^0.3.1
  google_maps_flutter: ^2.5.0
```

## هيكل المشروع

```
lib/
├── core/                    # الملفات الأساسية
│   ├── constants.dart       # الثوابت
│   ├── theme.dart          # التصميم
│   ├── utils.dart          # الأدوات المساعدة
│   ├── services/           # الخدمات
│   │   ├── location_service.dart
│   │   ├── image_service.dart
│   │   └── notification_service.dart
│   └── widgets/            # الواجهات المشتركة
│       ├── custom_app_bar.dart
│       ├── custom_button.dart
│       ├── custom_card.dart
│       ├── custom_text_field.dart
│       ├── loading_widget.dart
│       ├── empty_state_widget.dart
│       └── error_widget.dart
├── donor/                  # شاشات المتبرع
├── association/            # شاشات الجمعية
├── volunteer/              # شاشات المتطوع
├── manager/                # شاشات المدير
├── auth_screen.dart        # شاشة المصادقة
├── register_screen.dart    # شاشة التسجيل
├── otp_screen.dart         # شاشة رمز التحقق
├── main.dart              # نقطة البداية
└── supabase_config.dart   # إعدادات Supabase
```

## قاعدة البيانات

### الجداول الرئيسية
- `users`: المستخدمون
- `donations`: التبرعات
- `notifications`: الإشعارات
- `ratings`: التقييمات
- `activation_codes`: أكواد التفعيل
- `badges`: الشارات
- `user_badges`: شارات المستخدمين
- `volunteer_logs`: سجلات المتطوعين
- `stats`: الإحصائيات

### الدوال المهمة
- `register_volunteer()`: تسجيل متطوع جديد
- `get_volunteers_for_association()`: جلب متطوعي الجمعية
- `generate_activation_code()`: إنشاء أكواد تفعيل
- `get_association_report_data()`: بيانات تقارير الجمعية
- `get_map_data()`: بيانات الخريطة
- `get_gamification_data()`: بيانات التلعيب

## التثبيت والتشغيل

### المتطلبات
- Flutter SDK (3.0.0 أو أحدث)
- Dart SDK
- Android Studio / VS Code
- حساب Supabase

### خطوات التثبيت

1. **استنساخ المشروع**
```bash
git clone [repository-url]
cd wisall
```

2. **تثبيت التبعيات**
```bash
flutter pub get
```

3. **إعداد Supabase**
- إنشاء مشروع جديد في Supabase
- تشغيل ملف `wisaal_schema_final.sql` في قاعدة البيانات
- تشغيل ملف `missing_sql_functions.sql` لإضافة الدوال المفقودة
- تحديث ملف `.env` بمعلومات المشروع

4. **إعداد Google Maps**
- الحصول على API Key من Google Cloud Console
- تحديث ملف `web/index.html` بالمفتاح الجديد
- إضافة المفتاح في ملفات Android/iOS

5. **تشغيل التطبيق**
```bash
flutter run
```

## الإعدادات

### ملف .env
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### أكواد التفعيل الافتراضية
- كود الجمعيات: `826627BO`
- كود المدير: `01200602TB`

## الأمان

### Row Level Security (RLS)
- جميع الجداول محمية بـ RLS
- المستخدمون يمكنهم الوصول فقط لبياناتهم
- المديرون لديهم صلاحيات كاملة
- الجمعيات يمكنها إدارة متطوعيها فقط

### المصادقة
- مصادقة عبر البريد الإلكتروني مع OTP
- جلسات آمنة مع Supabase Auth
- تشفير كلمات المرور

## المساهمة

### إرشادات المساهمة
1. Fork المشروع
2. إنشاء branch جديد للميزة
3. Commit التغييرات
4. Push إلى Branch
5. إنشاء Pull Request

### معايير الكود
- استخدام التعليقات باللغة العربية
- اتباع معايير Dart/Flutter
- كتابة اختبارات للميزات الجديدة
- توثيق الدوال والكلاسات

## الاختبار

### تشغيل الاختبارات
```bash
flutter test
```

### أنواع الاختبارات
- Unit Tests للدوال
- Widget Tests للواجهات
- Integration Tests للتدفقات الكاملة

## النشر

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## الدعم والمساعدة

### المشاكل الشائعة
1. **خطأ في الموقع**: تأكد من تفعيل خدمات الموقع
2. **مشاكل الصور**: تحقق من صلاحيات الكاميرا
3. **مشاكل الاتصال**: تأكد من إعدادات Supabase

### التواصل
- البريد الإلكتروني: [email]
- GitHub Issues: [repository-url]/issues

## الترخيص
هذا المشروع مرخص تحت رخصة MIT - راجع ملف LICENSE للتفاصيل.

## الشكر والتقدير
- فريق Flutter لإطار العمل الرائع
- فريق Supabase للخدمات السحابية
- مجتمع المطورين العرب للدعم والمساعدة

---

**وصال - نصل الخير، ونحفظ النعمة** 🌟