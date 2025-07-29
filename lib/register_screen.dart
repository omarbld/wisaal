import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wisaal/terms_and_conditions_screen.dart';
import 'otp_screen.dart';

enum UserRole { donor, association, volunteer, manager }

class NewRegisterScreen extends StatefulWidget {
  const NewRegisterScreen({super.key});

  @override
  State<NewRegisterScreen> createState() => _NewRegisterScreenState();
}

class _NewRegisterScreenState extends State<NewRegisterScreen> {
  int _currentStep = 0;
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>()
  ];
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  String? _selectedCity;
  UserRole? _selectedRole;
  bool _agreedToTerms = false;
  String? _error;
  bool _isLoading = false;
  int _termsTapCount = 0;
  bool _showManagerRole = false;

  // Cities of Laâyoune-Sakia El Hamra region
  final List<String> _cities = ['العيون', 'طرفاية', 'بوجدور', 'السمارة'];

  String _translateRole(UserRole role) {
    switch (role) {
      case UserRole.donor:
        return 'متبرع';
      case UserRole.association:
        return 'جمعية';
      case UserRole.volunteer:
        return 'متطوع';
      case UserRole.manager:
        return 'مدير';
    }
  }

  Future<void> _submit() async {
    // Validate all forms up to the current step
    for (int i = 0; i <= _currentStep; i++) {
      if (!_formKeys[i].currentState!.validate()) {
        setState(() => _error = 'يرجى تعبئة جميع الحقول الإلزامية.');
        return;
      }
    }
    if (!_agreedToTerms) {
      setState(() => _error = 'يجب الموافقة على الشروط والأحكام للمتابعة.');
      return;
    }

    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final email = _emailController.text.trim();
      final role = _selectedRole!;

      final userData = {
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _selectedCity!,
        'role': role.name,
      };

      final activationCode = _codeController.text.trim();
      final isVolunteerRegistration = role == UserRole.volunteer;

      await supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo:
            'io.supabase.wisaal://login-callback/', // Your deep link
      );

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              email: email,
              userData: userData,
              activationCode: activationCode.isNotEmpty ? activationCode : null,
              isVolunteerRegistration: isVolunteerRegistration,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'حدث خطأ غير متوقع: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.textTheme.bodyLarge?.color,
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          final isLastStep = _currentStep == _buildSteps().length - 1;
          if (_formKeys[_currentStep].currentState!.validate()) {
            if (isLastStep) {
              _submit();
            } else {
              setState(() => _currentStep += 1);
            }
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        onStepTapped: (step) => setState(() => _currentStep = step),
        steps: _buildSteps(),
        controlsBuilder: (context, details) {
          final isLastStep = _currentStep == _buildSteps().length - 1;
          return Padding(
            padding: const EdgeInsets.only(top: 32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  TextButton.icon(
                    onPressed: details.onStepCancel,
                    icon: const Icon(Icons.arrow_back_ios_new),
                    label: const Text('السابق'),
                  ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : Icon(isLastStep
                          ? Icons.check_circle_outline
                          : Icons.arrow_forward_ios_outlined),
                  label: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isLastStep ? 'إنشاء الحساب' : 'التالي'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('الحساب'),
        content: _buildStepContent(
          formKey: _formKeys[0],
          children: [
            _buildTextField(
              controller: _emailController,
              label: 'البريد الإلكتروني',
              icon: Icons.email_outlined,
              validator: (v) => (v == null || v.isEmpty || !v.contains('@'))
                  ? 'الرجاء إدخال بريد إلكتروني صحيح'
                  : null,
            ),
          ],
        ),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('المعلومات'),
        content: _buildStepContent(
          formKey: _formKeys[1],
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'الاسم الكامل',
              icon: Icons.person_outline,
              validator: (v) => (v == null || v.isEmpty) ? 'الاسم مطلوب' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'رقم الهاتف',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'رقم الهاتف مطلوب';
                }
                if (v.length != 10) {
                  return 'يجب أن يتكون رقم الهاتف من 10 أرقام';
                }
                if (int.tryParse(v) == null) {
                  return 'الرجاء إدخال أرقام فقط';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              value: _selectedCity,
              label: 'المدينة',
              icon: Icons.location_city_outlined,
              items: _cities,
              onChanged: (v) => setState(() => _selectedCity = v),
            ),
          ],
        ),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('الدور'),
        content: _buildStepContent(
          formKey: _formKeys[2],
          children: [
            _buildDropdownField<UserRole>(
              value: _selectedRole,
              label: 'اختر الدور',
              icon: Icons.work_outline,
              items: _showManagerRole
                  ? UserRole.values
                  : UserRole.values
                      .where((role) => role != UserRole.manager)
                      .toList(),
              itemBuilder: (role) => DropdownMenuItem(
                value: role,
                child: Text(_translateRole(role)),
              ),
              onChanged: (v) => setState(() => _selectedRole = v),
            ),
            if (_selectedRole == UserRole.association ||
                _selectedRole == UserRole.volunteer ||
                _selectedRole == UserRole.manager)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: _buildTextField(
                  controller: _codeController,
                  label: 'كود التفعيل',
                  icon: Icons.vpn_key_outlined,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'كود التفعيل مطلوب';
                    }
                    if (_selectedRole == UserRole.manager &&
                        v != '01200602TB') {
                      return 'كود تفعيل المدير غير صحيح';
                    }
                    return null;
                  },
                ),
              ),
            const SizedBox(height: 24),
            _buildTermsAndConditions(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _error!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        isActive: _currentStep >= 2,
        state: _currentStep == 2 ? StepState.editing : StepState.indexed,
      ),
    ];
  }

  Widget _buildStepContent(
      {required GlobalKey<FormState> formKey, required List<Widget> children}) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      validator: validator,
      keyboardType: keyboardType,
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<T> items,
    required void Function(T?) onChanged,
    DropdownMenuItem<T> Function(T)? itemBuilder,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      items: items
          .map(itemBuilder ??
              (item) =>
                  DropdownMenuItem(value: item, child: Text(item.toString())))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'هذا الحقل مطلوب' : null,
    );
  }

  Widget _buildTermsAndConditions() {
    return CheckboxListTile(
      title: RichText(
        text: TextSpan(
          text: 'أوافق على ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
          children: <TextSpan>[
            TextSpan(
              text: 'الشروط والأحكام',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const TermsAndConditionsScreen()));
                },
            ),
          ],
        ),
      ),
      value: _agreedToTerms,
      onChanged: (v) {
        setState(() {
          _agreedToTerms = v ?? false;
          _termsTapCount++;
          if (_termsTapCount >= 7) {
            _showManagerRole = true;
          }
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}
