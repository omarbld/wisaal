
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DonorRateScreen extends StatefulWidget {
  final String taskId;
  final String ratedEntityId;
  final String entityType; // 'association' or 'volunteer'

  const DonorRateScreen({
    super.key,
    required this.taskId,
    required this.ratedEntityId,
    required this.entityType,
  });

  @override
  State<DonorRateScreen> createState() => _DonorRateScreenState();
}

class _DonorRateScreenState extends State<DonorRateScreen> {
  double _rating = 4.0;
  final _commentController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل');

      await supabase.from('ratings').insert({
        'rater_id': user.id,
        'rated_entity_id': widget.ratedEntityId,
        'task_id': widget.taskId,
        'rating': _rating.toInt(),
        'comment': _commentController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      // Also, update the donation entry to mark that rating has been given.
      await supabase
          .from('donations')
          .update({'rating': _rating.toInt()}).eq('donation_id', widget.taskId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('شكراً لك، تم إرسال تقييمك بنجاح!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ أثناء إرسال التقييم: ${e.toString()}';
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
    final entityName = widget.entityType == 'association' ? 'الجمعية' : 'المتطوع';

    return Scaffold(
      appBar: AppBar(
        title: Text('تقييم $entityName'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              'ما هو تقييمك للتجربة مع $entityName؟',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'يساعدنا تقييمك على تحسين جودة الخدمة',
              style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1.0;
                      });
                    },
                  );
                }),
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'أضف تعليقاً (اختياري)',
                hintText: 'صف لنا تجربتك...',
                prefixIcon: Icon(Icons.comment_outlined),
              ),
              maxLines: 4,
              textInputAction: TextInputAction.done,
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
                : ElevatedButton.icon(
                    icon: const Icon(Icons.send_outlined),
                    onPressed: _submit,
                    label: const Text('إرسال التقييم'),
                  ),
          ],
        ),
      ),
    );
  }
}
