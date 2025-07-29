import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class OtpScreen extends StatefulWidget {
  final String email;
  final Map<String, dynamic>? userData;
  final String? activationCode;
  final bool isVolunteerRegistration;

  const OtpScreen({
    super.key,
    required this.email,
    this.userData,
    this.activationCode,
    this.isVolunteerRegistration = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      setState(() => _error = 'يجب أن يتكون الرمز من 6 أرقام');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final supabaseClient = supabase.Supabase.instance.client;
      final response = await supabaseClient.auth.verifyOTP(
        type: supabase.OtpType.email,
        email: widget.email,
        token: _otpController.text.trim(),
      );

      if (response.user != null) {
        final user = response.user!;

        if (widget.userData != null) {
          // تسجيل جديد: أدخل البيانات
          if (widget.isVolunteerRegistration) {
            try {
              await supabaseClient.rpc(
                'register_volunteer',
                params: {
                  'p_user_id': user.id, // <-- Pass the authenticated user ID
                  'p_full_name': widget.userData!['full_name'],
                  'p_email': widget.email,
                  'p_phone': widget.userData!['phone'],
                  'p_city': widget.userData!['city'],
                  'p_activation_code': widget.activationCode,
                },
              );
            } catch (e) {
              setState(() {
                _error = 'فشل تسجيل المتطوع. الرجاء التأكد من صحة كود التفعيل.';
              });
              return; // Stop execution if volunteer registration fails
            }
          } else if (widget.userData != null) {
            await supabaseClient.from('users').insert({
              'id': user.id,
              'email': widget.email,
              ...widget.userData!,
            });
          }
        } else {
          // تسجيل دخول: تأكد من وجود المستخدم
          final userProfile = await supabaseClient
              .from('users')
              .select('id')
              .eq('id', user.id)
              .maybeSingle();

          if (userProfile == null) {
            // المستخدم غير موجود، وجهه للتسجيل
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('الحساب غير موجود، يرجى إنشاء حساب جديد.')),
              );
              Navigator.of(context).pushReplacementNamed('/register');
            }
            return;
          }
        }

        // توجيه المستخدم بعد النجاح
        final finalRole = (widget.userData?['role']) ??
            (await supabaseClient
                .from('users')
                .select('role')
                .eq('id', user.id)
                .single())['role'];

        if (mounted) {
          if (finalRole == 'donor') {
            Navigator.of(context).pushReplacementNamed('/donor');
          } else if (finalRole == 'association') {
            Navigator.of(context).pushReplacementNamed('/association');
          } else if (finalRole == 'volunteer') {
            Navigator.of(context).pushReplacementNamed('/volunteer');
          } else if (finalRole == 'manager') {
            Navigator.of(context).pushReplacementNamed('/manager');
          } else {
            Navigator.of(context).pushReplacementNamed('/auth');
          }
        }
      } else {
        setState(() => _error = 'رمز التحقق غير صحيح أو منتهي الصلاحية');
      }
    } on supabase.AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('التحقق من الرمز'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.mark_email_read_outlined,
                  size: 80, color: colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'تم إرسال رمز التحقق إلى بريدك الإلكتروني',
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: textTheme.bodyLarge
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'رمز التحقق المكون من 6 أرقام',
                  counterText: "", // Hide the counter
                ),
                textAlign: TextAlign.center,
                maxLength: 6,
                style: textTheme.headlineMedium?.copyWith(letterSpacing: 10),
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _verifyOtp,
                      child: const Text('التحقق والمتابعة'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
