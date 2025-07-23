
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManagerActivationCodesScreen extends StatefulWidget {
  const ManagerActivationCodesScreen({super.key});

  @override
  State<ManagerActivationCodesScreen> createState() => _ManagerActivationCodesScreenState();
}

class _ManagerActivationCodesScreenState extends State<ManagerActivationCodesScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  String _selectedRole = 'volunteer';
  bool _loading = false;

  Future<List<Map<String, dynamic>>> _fetchCodes() async {
    final res = await _supabase.from('activation_codes').select().order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> _generateCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _loading = true);
    try {
      await _supabase.from('activation_codes').insert({
        'code': _codeController.text.trim(),
        'role': _selectedRole,
        'created_by_association_id': _supabase.auth.currentUser!.id,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء رمز التفعيل بنجاح')),
        );
        _codeController.clear();
        setState(() {}); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إنشاء الرمز: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteCode(String id) async {
    await _supabase.from('activation_codes').delete().eq('id', id);
    setState(() {}); // Refresh the list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة رموز التفعيل'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCreationForm(),
            const Divider(height: 32),
            const Text('الرموز الحالية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchCodes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('خطأ: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('لا توجد رموز لعرضها'));
                  }
                  final codes = snapshot.data!;
                  return ListView.builder(
                    itemCount: codes.length,
                    itemBuilder: (context, index) {
                      return _CodeCard(code: codes[index], onDelete: _deleteCode);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'رمز التفعيل',
              prefixIcon: Icon(Icons.vpn_key_outlined),
            ),
            validator: (v) => v == null || v.isEmpty ? 'الحقل مطلوب' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: const InputDecoration(
              labelText: 'الدور',
              prefixIcon: Icon(Icons.person_outline),
            ),
            items: const [
              DropdownMenuItem(value: 'volunteer', child: Text('متطوع')),
              DropdownMenuItem(value: 'association', child: Text('جمعية')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedRole = value);
              }
            },
          ),
          const SizedBox(height: 24),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _generateCode,
                  icon: const Icon(Icons.add),
                  label: const Text('إنشاء الرمز'),
                ),
        ],
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  final Map<String, dynamic> code;
  final Function(String) onDelete;

  const _CodeCard({required this.code, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUsed = code['is_used'] ?? false;
    final role = code['role'] == 'volunteer' ? 'متطوع' : 'جمعية';

    return Card(
      color: isUsed ? Colors.grey.shade300 : theme.colorScheme.surfaceContainerHighest,
      child: ListTile(
        leading: Icon(isUsed ? Icons.check_circle : Icons.vpn_key_outlined, color: isUsed ? Colors.green : theme.colorScheme.primary),
        title: Text(code['code'], style: TextStyle(fontWeight: FontWeight.bold, decoration: isUsed ? TextDecoration.lineThrough : TextDecoration.none)),
        subtitle: Text('الدور: $role'),
        trailing: isUsed
            ? null
            : IconButton(
                icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                onPressed: () => onDelete(code['id']),
              ),
      ),
    );
  }
}
