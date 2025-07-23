import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

class AddDonationScreen extends StatefulWidget {
  const AddDonationScreen({super.key});

  @override
  State<AddDonationScreen> createState() => _AddDonationScreenState();
}

class _AddDonationScreenState extends State<AddDonationScreen> {
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
  String? _error;

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _error = 'تم رفض إذن الموقع');
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _currentPosition = pos);
    } catch (e) {
      setState(() => _error = 'تعذر الحصول على الموقع: $e');
    }
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    if (!_formKey.currentState!.validate() ||
        _expiryDate == null ||
        _addressController.text.trim().isEmpty) {
      setState(() {
        _loading = false;
        _error = 'يرجى تعبئة جميع الحقول وكتابة الموقع (يدويًا أو عبر GPS).';
      });
      return;
    }
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
        'location': (_currentPosition != null &&
                _addressController.text.trim() ==
                    '${_currentPosition!.latitude}, ${_currentPosition!.longitude}')
            ? 'POINT(${_currentPosition!.longitude} ${_currentPosition!.latitude})'
            : null,
        'pickup_address': _addressController.text.trim(),
        'donor_qr_code': donorQrCode,
      };
      final res =
          await supabase.from('donations').insert(donation).select().single();
      if (mounted) {
        Navigator.of(context).pop(res);
      }
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ: ${e.toString()}';
      });
    } finally {
      setState(() {
        _loading = false;
      });
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
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descController,
                label: 'وصف دقيق',
                icon: Icons.description_outlined,
                hint: 'اكتب تفاصيل عن نوعية أو حالة الطعام',
                maxLines: 3,
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
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'نوع الطعام',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'وجبات مطبوخة', child: Text('وجبات مطبوخة')),
                        DropdownMenuItem(value: 'مواد جافة', child: Text('مواد جافة')),
                        DropdownMenuItem(value: 'فواكه وخضروات', child: Text('فواكه وخضروات')),
                        DropdownMenuItem(value: 'حلويات ومخبوزات', child: Text('حلويات ومخبوزات')),
                        DropdownMenuItem(value: 'أخرى', child: Text('أخرى')),
                      ],
                      onChanged: (value) {
                        _typeController.text = value ?? '';
                      },
                      validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
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
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location),
                  tooltip: 'تحديد الموقع تلقائيًا',
                  onPressed: () async {
                    await _getCurrentLocation();
                    if (_currentPosition != null) {
                      _addressController.text =
                          '${_currentPosition!.latitude}, ${_currentPosition!.longitude}';
                      setState(() {});
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('تبرع عاجل'),
                subtitle: const Text('سيتم إعطاء أولوية لهذا التبرع'),
                value: _isUrgent,
                onChanged: (v) => setState(() => _isUrgent = v),
                secondary: Icon(Icons.priority_high, color: colorScheme.primary),
                activeColor: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Card(
                  color: colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.send_outlined),
                      onPressed: _submit,
                      label: const Text('إرسال التبرع'),
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
      child: Text(
        title,
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
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
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        hintText: hint,
        suffixIcon: suffixIcon,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (v) => v == null || v.isEmpty ? 'هذا الحقل مطلوب' : null,
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
        );
        if (picked != null) setState(() => _expiryDate = picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'تاريخ انتهاء الصلاحية',
          prefixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          _expiryDate == null
              ? 'اختر تاريخاً'
              : DateFormat('EEEE, d MMMM yyyy', 'ar').format(_expiryDate!),
          style: textTheme.bodyLarge,
        ),
      ),
    );
  }
}
