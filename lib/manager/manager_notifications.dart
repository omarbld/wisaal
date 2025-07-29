
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManagerNotificationsScreen extends StatefulWidget {
  const ManagerNotificationsScreen({super.key});

  @override
  State<ManagerNotificationsScreen> createState() =>
      _ManagerNotificationsScreenState();
}

class _ManagerNotificationsScreenState
    extends State<ManagerNotificationsScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _selectedRole;
  bool _loading = false;

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _loading = true);
    try {
      await _supabase.rpc('send_bulk_notification', params: {
        'p_title': _titleController.text.trim(),
        'p_body': _bodyController.text.trim(),
        'p_role': _selectedRole,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال الإشعارات بنجاح')),
        );
        _titleController.clear();
        _bodyController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إرسال الإشعارات: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إرسال إشعارات مخصصة'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'عنوان الإشعار'),
                validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(labelText: 'محتوى الإشعار'),
                maxLines: 5,
                validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'إرسال إلى'),
                hint: const Text('الجميع'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('الجميع')),
                  DropdownMenuItem(value: 'donor', child: Text('المتبرعين فقط')),
                  DropdownMenuItem(value: 'association', child: Text('الجمعيات فقط')),
                  DropdownMenuItem(value: 'volunteer', child: Text('المتطوعين فقط')),
                ],
                onChanged: (value) => setState(() => _selectedRole = value),
              ),
              const Spacer(),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _sendNotification,
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('إرسال الآن'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
