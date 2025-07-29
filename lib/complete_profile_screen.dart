
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'core/services/location_service.dart';

enum UserRole { donor, association, volunteer, manager }

const Map<UserRole, String> roleNames = {
  UserRole.donor: 'متبرع',
  UserRole.association: 'جمعية',
  UserRole.volunteer: 'متطوع',
  UserRole.manager: 'مدير',
};

const associationCode = '826627BO';
const managerCode = '01200602TB';

class CompleteProfileScreen extends StatefulWidget {
  final String email;
  const CompleteProfileScreen({super.key, required this.email});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  String? _selectedCity;
  UserRole? _selectedRole;
  Position? _currentPosition;
  bool _agreedToTerms = false;
  bool _loading = false;
  String? _error;

  Future<void> _getCurrentLocation() async {
    try {
      Position? position = await LocationService.getCurrentLocation(context);
      if (position != null) {
        setState(() {
          _currentPosition = position;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تحديد موقعك بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطأ في تحديد الموقع: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null || _selectedCity == null) {
      setState(() => _error = 'يرجى اختيار الدور والمدينة');
      return;
    }
    if (!_agreedToTerms) {
      setState(() => _error = 'يجب الموافقة على الشروط والأحكام');
      return;
    }

    // التحقق من كود التفعيل للجمعيات والمديرين
    if (_selectedRole == UserRole.association || _selectedRole == UserRole.manager) {
      final code = _codeController.text.trim();
      if (code.isEmpty) {
        setState(() => _error = 'يرجى إدخال كود التفعيل');
        return;
      }
      
      if (_selectedRole == UserRole.association && code != associationCode) {
        setState(() => _error = 'كود التفعيل غير صحيح للجمعيات');
        return;
      }
      
      if (_selectedRole == UserRole.manager && code != managerCode) {
        setState(() => _error = 'كود التفعيل غير صحيح للمديرين');
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('غير مصرح');

      // إنشاء بيانات المستخدم
      final userData = {
        'id': user.id,
        'full_name': _nameController.text.trim(),
        'email': widget.email,
        'role': _selectedRole.toString().split('.').last,
        'phone': '+212${_phoneController.text.trim()}',
        'city': _selectedCity,
        'created_at': DateTime.now().toIso8601String(),
      };

      // إضافة الموقع إذا كان متاحاً
      if (_currentPosition != null) {
        userData['location'] = 'POINT(${_currentPosition!.longitude} ${_currentPosition!.latitude})';
      }

      // إدراج بيانات المستخدم
      await supabase.from('users').insert(userData);

      // حفظ الموقع في جدول المواقع المباشرة إذا كان متاحاً
      if (_currentPosition != null) {
        await LocationService.saveUserLocation(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
      }

      // فحص التكرار في البيانات
      await LocationService.checkForDuplicateLocations();

      if (mounted) {
        // عرض رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إنشاء حسابك بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );

        // الانتقال إلى الصفحة المناسبة
        final role = _selectedRole.toString().split('.').last;
        Navigator.of(context).pushReplacementNamed('/$role');
      }
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ: ${e.toString()}';
      });
      
      // عرض رسالة خطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطأ في إنشاء الحساب: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('إكمال الملف الشخصي')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: widget.email,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixText: '+212 ', prefixIcon: Icon(Icons.phone_outlined)),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCity,
                decoration: const InputDecoration(labelText: 'المدينة', prefixIcon: Icon(Icons.location_city_outlined)),
                items: ['العيون', 'الرباط', 'الدار البيضاء'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCity = v),
                validator: (v) => v == null ? 'الحقل مطلوب' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'اختر الدور', prefixIcon: Icon(Icons.work_outline)),
                items: UserRole.values.map((role) => DropdownMenuItem(value: role, child: Text(roleNames[role]!))).toList(),
                onChanged: (role) => setState(() => _selectedRole = role),
                validator: (v) => v == null ? 'الحقل مطلوب' : null,
              ),
              if (_selectedRole == UserRole.association || _selectedRole == UserRole.manager)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(labelText: 'كود التفعيل', prefixIcon: Icon(Icons.lock_outline)),
                    obscureText: true,
                    validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: Text(_currentPosition == null ? 'تحديد موقعي تلقائيًا' : 'تم تحديد الموقع'),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('أوافق على الشروط والأحكام وسياسة الخصوصية'),
                value: _agreedToTerms,
                onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('إنشاء الحساب'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
