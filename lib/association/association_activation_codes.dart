import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class AssociationActivationCodesScreen extends StatefulWidget {
  const AssociationActivationCodesScreen({super.key});

  @override
  State<AssociationActivationCodesScreen> createState() =>
      _AssociationActivationCodesScreenState();
}

class _AssociationActivationCodesScreenState
    extends State<AssociationActivationCodesScreen> {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> _fetchCodes() async {
    final res = await _supabase
        .from('activation_codes')
        .select()
        .eq('role', 'volunteer')
        .eq('is_used', false)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> _createNewCode() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final result = await _supabase.rpc('generate_activation_code_enhanced',
          params: {'p_association_id': user.id, 'p_count': 1}).select();

      if (result.isNotEmpty) {
        final newCode = result.first['generated_code'];
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم إنشاء الكود: $newCode')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إنشاء الكود: $e')),
        );
      }
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('أكواد تفعيل المتطوعين'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchCodes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.no_encryption_gmailerrorred_outlined,
                        size: 80,
                        color: colorScheme.onSurfaceVariant.withAlpha(128)),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد أكواد متاحة حالياً',
                      style: textTheme.titleLarge
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    const Text('اضغط على الزر أدناه لإنشاء كود جديد'),
                  ],
                ),
              );
            }
            final codes = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: codes.length,
              itemBuilder: (context, i) {
                final code = codes[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.secondary.withAlpha(26),
                      child: Icon(Icons.vpn_key_outlined,
                          color: colorScheme.secondary),
                    ),
                    title: SelectableText(
                      code['code'],
                      style: textTheme.titleLarge?.copyWith(
                          fontFamily: 'RobotoMono',
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'تم إنشاؤه ${timeago.format(DateTime.parse(code['created_at']), locale: 'ar')}',
                      style: textTheme.bodySmall,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy_outlined),
                      tooltip: 'نسخ الكود',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code['code']));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ الكود بنجاح')),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewCode,
        label: const Text('إنشاء كود جديد'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
