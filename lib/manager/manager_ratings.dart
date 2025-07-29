
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class ManagerRatingsScreen extends StatefulWidget {
  const ManagerRatingsScreen({super.key});

  @override
  State<ManagerRatingsScreen> createState() => _ManagerRatingsScreenState();
}

class _ManagerRatingsScreenState extends State<ManagerRatingsScreen> {
  final _supabase = Supabase.instance.client;
  int? _ratingFilter;

  Future<List<Map<String, dynamic>>> _fetchRatings() async {
    var query = _supabase
        .from('ratings')
        .select(
            '*, rater:users!ratings_rater_id_fkey(full_name), rated:users!ratings_volunteer_id_fkey(full_name)');

    if (_ratingFilter != null) {
      query = query.eq('rating', _ratingFilter!);
    }

    final res = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مراجعة التقييمات'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchRatings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('لا توجد تقييمات بهذه المواصفات'));
                }
                final ratings = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: ratings.length,
                    itemBuilder: (context, index) {
                      return _RatingCard(rating: ratings[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('تصفية حسب النجوم:'),
          const SizedBox(width: 16),
          DropdownButton<int>(
            value: _ratingFilter,
            hint: const Text('الكل'),
            onChanged: (value) => setState(() => _ratingFilter = value),
            items: [
              const DropdownMenuItem(value: null, child: Text('الكل')),
              ...List.generate(5, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1} نجوم'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  final Map<String, dynamic> rating;

  const _RatingCard({required this.rating});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rater = rating['rater']?['full_name'] ?? 'مجهول';
    final rated = rating['rated']?['full_name'] ?? 'مجهول';
    final comment = rating['comment'];
    final starRating = rating['rating'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(child: Icon(Icons.rate_review_outlined, color: theme.colorScheme.primary)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: theme.textTheme.bodyMedium,
                          children: [
                            TextSpan(text: rater, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const TextSpan(text: ' قيّم '),
                            TextSpan(text: rated, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(DateTime.parse(rating['created_at']), locale: 'ar'),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < starRating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber.shade700,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            if (comment != null && comment.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0, right: 52, left: 16),
                child: Text(
                  comment,
                  style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
