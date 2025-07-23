import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssociationRateVolunteerScreen extends StatefulWidget {
  final String volunteerName;
  final int donationId;

  const AssociationRateVolunteerScreen({
    super.key,
    required this.volunteerName,
    required this.donationId,
  });

  @override
  State<AssociationRateVolunteerScreen> createState() =>
      _AssociationRateVolunteerScreenState();
}

class _AssociationRateVolunteerScreenState
    extends State<AssociationRateVolunteerScreen> {
  double _rating = 0;
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl, // ✅ دعم RTL
      child: Scaffold(
        appBar: AppBar(
          title: Text('تقييم ${widget.volunteerName}'),
          backgroundColor: colorScheme.primary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'كيف كانت تجربتك مع ${widget.volunteerName}؟',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'معرّف التبرع: ${widget.donationId}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 30),
                Text(
                  'تقييمك',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber, // لون النجوم
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
                const SizedBox(height: 30),
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    labelText: 'أضف تعليقًا (اختياري)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                  ),
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    textStyle: theme.textTheme.titleLarge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _submitRating,
                  label: const Text('إرسال التقييم'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار تقييم قبل الإرسال.')),
      );
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('donations').update({
        'rating': _rating,
        'rating_comment': _commentController.text,
      }).eq('donation_id', widget.donationId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال التقييم بنجاح!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في إرسال التقييم: $e')),
      );
    }
  }
}
