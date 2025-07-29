import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:wisaal/common/widgets/loading_button.dart';
import 'package:wisaal/common/widgets/error_handler.dart';
import 'package:wisaal/common/widgets/confirmation_dialog.dart';

class AddDonationImprovedScreen extends StatefulWidget {
  const AddDonationImprovedScreen({super.key});

  @override
  State<AddDonationImprovedScreen> createState() => _AddDonationImprovedScreenState();
}

class _AddDonationImprovedScreenState extends State<AddDonationImprovedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _quantityController = TextEditingController();
  final _typeController = TextEditingController();
  final _addressController = TextEditingController();
  Position? _currentPosition;
  DateTime? _expiryDate;
  bool _isUrgent = false;
  String? _pickupMethod;
  bool _loading = false;
  bool _gettingLocation = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _quantityController.dispose();
    _typeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _gettingLocation = true);
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ErrorHandler.showError(context, 'تم رفض إذن الموقع');
          }
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ErrorHandler.showError(
            context, 
            'إذن الموقع مرفوض نهائياً. يرجى تفعيله من إعدادات التطبيق'
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      setState(() {
        _currentPosition = pos;
        _addressController.text = '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
      });
      
      if (mounted) {
        ErrorHandler.showSuccess(context, 'تم تحديد الموقع بنجاح');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'تعذر الحصول على الموقع: $e');
      }
    } finally {
      setState(() => _gettingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ErrorHandler.showError(context, 'يرجى تعبئة جميع الحقول المطلوبة');
      return;
    }

    if (_expiryDate == null) {
      ErrorHandler.showError(context, 'يرجى اختيار تاريخ انتهاء الصلاحية');
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      ErrorHandler.showError(context, 'يرجى إدخال عنوان الاستلام');
      return;
    }

    // تأكيد الإرسال
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'تأكيد إرسال التبرع',
      content: 'هل أنت متأكد من إرسال هذا التبرع؟\n\nالعنوان: ${_titleController.text}\nالكمية: ${_quantityController.text}',
      confirmText: 'إرسال',
      icon: Icons.send,
    );

    if (confirmed != true) return;

    setState(() => _loading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل');
      
      final donationId = const Uuid().v4();
      final donorQrCode = 'donor-$donationId';
      
      final donation = {
        'donation_id': donationId,
        'donor_id': user.id,
        'status': 'pending',
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'quantity': int.tryParse(_quantityController.text.trim()) ?? 1,
        'food_type': _typeController.text.trim(),
        'expiry_date': _expiryDate!.toIso8601String(),
        'is_urgent': _isUrgent,
        'method_of_pickup': _pickupMethod,
        'created_at': DateTime.now().toIso8601String(),
        'location': _currentPosition != null
            ? 'POINT(${_currentPosition!.longitude} ${_currentPosition!.latitude})'
            : null,
        'pickup_address': _addressController.text.trim(),
        'donor_qr_code': donorQrCode,
      };
      
      final res = await supabase.from('donations').insert(donation).select().single();
      
      if (mounted) {
        ErrorHandler.showSuccess(context, 'تم إرسال التبرع بنجاح! 🎉');
        Navigator.of(context).pop(res);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'حدث خطأ أثناء إرسال التبرع: ${ErrorHandler.getErrorMessage(e)}');
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة تبرع جديد'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader('معلومات التبرع', textTheme, colorScheme),
              _buildTextField(
                controller: _titleController,
                label: 'اسم الطعام',
                icon: Icons.label_outline,
                hint: 'مثال: خبز، أرز، دجاج...',
                required: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descController,
                label: 'وصف دقيق',
                icon: Icons.description_outlined,
                hint: 'اكتب تفاصيل عن نوعية أو حالة الطعام',
                maxLines: 3,
                required: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _quantityController,
                      label: 'الكمية',
                      icon: Icons.pie_chart_outline,
                      hint: 'العدد أو الوزن',
                      keyboardType: TextInputType.number,
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'نوع الطعام *',
                        prefixIcon: const Icon(Icons.category_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'وجبات مطبوخة', child: Text('وجبات مطبوخة')),
                        DropdownMenuItem(value: 'مواد جافة', child: Text('مواد جافة')),
                        DropdownMenuItem(value: 'فواكه وخضروات', child: Text('فواكه وخضروات')),
                        DropdownMenuItem(value: 'حلويات ومخبوزات', child: Text('حلويات ومخبوزات')),
                        DropdownMenuItem(value: 'مشروبات', child: Text('مشروبات')),
                        DropdownMenuItem(value: 'أخرى', child: Text('أخرى')),
                      ],
                      onChanged: (value) {
                        _typeController.text = value ?? '';
                      },
                      validator: (v) => v == null || v.isEmpty ? 'هذا الحقل مطلوب' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDatePicker(context, textTheme, colorScheme),
              const SizedBox(height: 24),
              _buildSectionHeader('معلومات الاستلام', textTheme, colorScheme),
              _buildTextField(
                controller: _addressController,
                label: 'عنوان الاستلام',
                icon: Icons.location_on_outlined,
                hint: 'اكتب العنوان أو استخدم GPS',
                required: true,
                suffixIcon: LoadingIconButton(
                  icon: Icons.my_location,
                  isLoading: _gettingLocation,
                  onPressed: _getCurrentLocation,
                  tooltip: 'تحديد الموقع تلقائياً',
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: SwitchListTile(
                  title: const Text('تبرع عاجل'),
                  subtitle: const Text('سيتم إعطاء أولوية لهذا التبرع'),
                  value: _isUrgent,
                  onChanged: (v) => setState(() => _isUrgent = v),
                  secondary: Icon(
                    Icons.priority_high, 
                    color: _isUrgent ? Colors.red : colorScheme.primary,
                  ),
                  activeColor: Colors.red,
                ),
              ),
              const SizedBox(height: 32),
              LoadingButton(
                text: 'إرسال التبرع',
                icon: Icons.send_outlined,
                isLoading: _loading,
                onPressed: _submit,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'ملاحظة: سيتم إشعار الجمعيات القريبة بتبرعك وستتمكن من متابعة حالة التبرع من خلال التطبيق.',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, TextTheme textTheme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        prefixIcon: Icon(icon),
        hintText: hint,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(77),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: required 
          ? (v) => v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null
          : null,
    );
  }

  Widget _buildDatePicker(BuildContext context, TextTheme textTheme, ColorScheme colorScheme) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('ar'),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: colorScheme,
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _expiryDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.surfaceContainerHighest.withAlpha(77),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تاريخ انتهاء الصلاحية *',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _expiryDate == null
                        ? 'اختر تاريخاً'
                        : DateFormat('EEEE, d MMMM yyyy', 'ar').format(_expiryDate!),
                    style: textTheme.bodyLarge?.copyWith(
                      color: _expiryDate == null 
                          ? colorScheme.onSurfaceVariant.withAlpha(153)
                          : colorScheme.onSurface,
                      fontWeight: _expiryDate == null ? FontWeight.normal : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}