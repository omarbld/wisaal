import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wisaal/core/theme.dart';
import 'package:wisaal/common/widgets/loading_button.dart';
import 'package:wisaal/common/widgets/error_handler.dart';
import 'package:wisaal/common/widgets/empty_state_widget.dart';
import 'package:wisaal/volunteer/volunteer_task_details.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final _searchController = TextEditingController();
  final _supabase = Supabase.instance.client;
  
  String _selectedFoodType = 'الكل';
  bool _urgentOnly = false;
  double _maxDistance = 10.0;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _hasSearched = false;

  final List<String> _foodTypes = [
    'الكل',
    'وجبات مطبوخة',
    'مواد جافة',
    'فواكه وخضروات',
    'حلويا�� ومخبوزات',
    'مشروبات',
    'أخرى',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل');
      }

      // الحصول على معرف الجمعية المرتبطة بالمتطوع
      final volunteerData = await _supabase
          .from('users')
          .select('associated_with_association_id')
          .eq('id', user.id)
          .single();

      final associationId = volunteerData['associated_with_association_id'];
      if (associationId == null) {
        throw Exception('لم يتم العثور على الجمعية المرتبطة');
      }

      // بناء الاستعلام
      var query = _supabase
          .from('donations')
          .select('''
            *, 
            donor:donor_id(full_name, phone, city),
            association:association_id(full_name)
          ''')
          .eq('association_id', associationId)
          .in_('status', ['pending', 'accepted']);

      // تطبيق الفلاتر
      if (_searchController.text.isNotEmpty) {
        query = query.or(
          'title.ilike.%${_searchController.text}%,'
          'description.ilike.%${_searchController.text}%,'
          'pickup_address.ilike.%${_searchController.text}%'
        );
      }

      if (_selectedFoodType != 'الكل') {
        query = query.eq('food_type', _selectedFoodType);
      }

      if (_urgentOnly) {
        query = query.eq('is_urgent', true);
      }

      final results = await query
          .order('created_at', ascending: false)
          .limit(50);

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(results);
      });
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'خطأ في البحث: ${e.toString()}');
      }
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _acceptDonation(String donationId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('donations')
          .update({
            'volunteer_id': user.id,
            'status': 'assigned',
          })
          .eq('donation_id', donationId);

      if (mounted) {
        ErrorHandler.showSuccess(context, 'تم قبول التبرع بنجاح! 🎉');
        _performSearch(); // إعادة البحث لتحديث ال��تائج
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'خطأ في قبول التبرع: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بحث متقدم'),
        centerTitle: true,
        backgroundColor: COLOR_VOLUNTEER_ACCENT,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // قسم البحث والفلاتر
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(77),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // حقل البحث
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'البحث في العنوان أو الوصف أو العنوان',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
                const SizedBox(height: 16),
                
                // نوع الطعام
                DropdownButtonFormField<String>(
                  value: _selectedFoodType,
                  decoration: const InputDecoration(
                    labelText: 'نوع الطعام',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  items: _foodTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedFoodType = value!),
                ),
                const SizedBox(height: 16),
                
                // التبرعات العاجلة فقط
                SwitchListTile(
                  title: const Text('التبرعات العاجلة فقط'),
                  subtitle: const Text('إظهار التبرعات ذات الأولوية العالية'),
                  value: _urgentOnly,
                  onChanged: (value) => setState(() => _urgentOnly = value),
                  activeColor: COLOR_VOLUNTEER_ACCENT,
                ),
                
                // المسافة القصوى
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المسافة القصوى: ${_maxDistance.toInt()} كم',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Slider(
                      value: _maxDistance,
                      min: 1.0,
                      max: 50.0,
                      divisions: 49,
                      activeColor: COLOR_VOLUNTEER_ACCENT,
                      onChanged: (value) => setState(() => _maxDistance = value),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // زر البحث
                LoadingButton(
                  text: 'بحث',
                  icon: Icons.search,
                  isLoading: _isSearching,
                  onPressed: _performSearch,
                  backgroundColor: COLOR_VOLUNTEER_ACCENT,
                  foregroundColor: Colors.white,
                ),
              ],
            ),
          ),
          
          // النتائج
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!_hasSearched) {
      return const EmptyStateWidget(
        icon: Icons.search,
        title: 'ابدأ البحث',
        subtitle: 'استخدم الفلاتر أعلاه للعثور على التبرعات المناسبة',
      );
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off,
        title: 'لا توجد نتائج',
        subtitle: 'لم نجد أي تبرعات تطابق معايير البحث',
        action: TextButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('بحث جديد'),
          onPressed: () {
            _searchController.clear();
            setState(() {
              _selectedFoodType = 'الكل';
              _urgentOnly = false;
              _maxDistance = 10.0;
              _hasSearched = false;
              _searchResults.clear();
            });
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _performSearch,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final donation = _searchResults[index];
          return _buildDonationCard(donation);
        },
      ),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> donation) {
    final isUrgent = donation['is_urgent'] == true;
    final canAccept = donation['status'] == 'pending';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VolunteerTaskDetailsScreen(donation: donation),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان والحالة
              Row(
                children: [
                  Expanded(
                    child: Text(
                      donation['title'] ?? 'تبرع',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'عاجل',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // الوصف
              if (donation['description'] != null)
                Text(
                  donation['description'],
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              
              const SizedBox(height: 8),
              
              // التفاصيل
              Row(
                children: [
                  Icon(Icons.scale, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'الكمية: ${donation['quantity'] ?? 'غير محدد'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    donation['food_type'] ?? 'غير محدد',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // المتبرع والعنوان
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    donation['donor']?['full_name'] ?? 'متبرع',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              
              if (donation['pickup_address'] != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        donation['pickup_address'],
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              
              // زر القبول
              if (canAccept) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.volunteer_activism),
                    label: const Text('قبول هذا التبرع'),
                    onPressed: () => _acceptDonation(donation['donation_id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: COLOR_VOLUNTEER_ACCENT,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}