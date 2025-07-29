import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:wisaal/common/widgets/loading_button.dart';
import 'package:wisaal/common/widgets/error_handler.dart';
import 'package:wisaal/common/widgets/confirmation_dialog.dart';
import 'package:wisaal/common/widgets/empty_state_widget.dart';
import 'package:wisaal/common/widgets/search_filter_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class AssociationNearbyDonationsImprovedScreen extends StatefulWidget {
  const AssociationNearbyDonationsImprovedScreen({super.key});

  @override
  State<AssociationNearbyDonationsImprovedScreen> createState() =>
      _AssociationNearbyDonationsImprovedScreenState();
}

class _AssociationNearbyDonationsImprovedScreenState
    extends State<AssociationNearbyDonationsImprovedScreen> {
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _donations = [];
  List<Map<String, dynamic>> _filteredDonations = [];
  bool _loading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, urgent, recent
  final Map<String, bool> _acceptingStates = {};

  @override
  void initState() {
    super.initState();
    _fetchNearbyDonations();
  }

  Future<void> _fetchNearbyDonations() async {
    setState(() => _loading = true);
    
    try {
      // في تطبيق حقيقي، هذا سيستخدم موقع الجمعية للعثور على التبرعات القريبة
      // الآن نجلب جميع التبرعات المعلقة
      final res = await _supabase
          .from('donations')
          .select('''
            *,
            donor:donor_id(full_name, phone, city, avatar_url)
          ''')
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(50);
      
      setState(() {
        _donations = List<Map<String, dynamic>>.from(res);
        _applyFilters();
      });
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'خطأ في تحميل التبرعات: ${ErrorHandler.getErrorMessage(e)}');
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    var filtered = _donations.where((donation) {
      // تطبيق فلتر البحث
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final title = (donation['title'] ?? '').toString().toLowerCase();
        final description = (donation['description'] ?? '').toString().toLowerCase();
        final address = (donation['pickup_address'] ?? '').toString().toLowerCase();
        final donorName = (donation['donor']?['full_name'] ?? '').toString().toLowerCase();
        
        if (!title.contains(searchLower) && 
            !description.contains(searchLower) && 
            !address.contains(searchLower) &&
            !donorName.contains(searchLower)) {
          return false;
        }
      }
      
      // تطبيق فلتر النوع
      switch (_selectedFilter) {
        case 'urgent':
          return donation['is_urgent'] == true;
        case 'recent':
          final createdAt = DateTime.parse(donation['created_at']);
          final now = DateTime.now();
          return now.difference(createdAt).inHours <= 24;
        default:
          return true;
      }
    }).toList();
    
    setState(() {
      _filteredDonations = filtered;
    });
  }

  Future<void> _acceptDonation(Map<String, dynamic> donation) async {
    final donationId = donation['donation_id'];
    
    // تأكيد القبول
    final confirmed = await ConfirmationDialog.showAcceptConfirmation(
      context: context,
      itemName: donation['title'] ?? 'التبرع',
      additionalInfo: 'العنوان: ${donation['pickup_address'] ?? 'غير محدد'}\nالمتبرع: ${donation['donor']?['full_name'] ?? 'غير معروف'}',
    );

    if (confirmed != true) return;

    setState(() {
      _acceptingStates[donationId] = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل');

      await _supabase.from('donations').update({
        'status': 'accepted',
        'association_id': user.id,
      }).eq('donation_id', donationId);

      if (mounted) {
        ErrorHandler.showSuccess(context, 'تم قبول التبرع بنجاح! 🎉');
        _fetchNearbyDonations(); // إعادة تحميل القائمة
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'خطأ في قبول التبرع: ${ErrorHandler.getErrorMessage(e)}');
      }
    } finally {
      setState(() {
        _acceptingStates.remove(donationId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('التبرعات المتاحة'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNearbyDonations,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث والفلاتر
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                SearchFilterWidget(
                  hintText: 'البحث في التبرعات...',
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _applyFilters();
                  },
                  onClear: () {
                    setState(() {
                      _searchQuery = '';
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 12),
                FilterChipGroup(
                  chips: const [
                    FilterChipData(label: 'الكل', value: 'all', icon: Icons.all_inclusive),
                    FilterChipData(label: 'عاجل', value: 'urgent', icon: Icons.priority_high),
                    FilterChipData(label: 'حديث', value: 'recent', icon: Icons.schedule),
                  ],
                  selectedIndex: ['all', 'urgent', 'recent'].indexOf(_selectedFilter),
                  onSelectionChanged: (index) {
                    setState(() {
                      _selectedFilter = ['all', 'urgent', 'recent'][index];
                    });
                    _applyFilters();
                  },
                ),
              ],
            ),
          ),
          
          // قائمة التبرعات
          Expanded(
            child: _buildDonationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationsList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_donations.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.location_off_outlined,
        title: 'لا توجد تبرعات متاحة',
        subtitle: 'لا توجد تبرعات جديدة في منطقتك حالياً',
      );
    }

    if (_filteredDonations.isEmpty) {
      return EmptySearchWidget(
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : 'الفلتر المحدد',
        onClearSearch: () {
          setState(() {
            _searchQuery = '';
            _selectedFilter = 'all';
          });
          _applyFilters();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNearbyDonations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredDonations.length,
        itemBuilder: (context, index) {
          final donation = _filteredDonations[index];
          return _buildDonationCard(donation);
        },
      ),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> donation) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUrgent = donation['is_urgent'] == true;
    final donationId = donation['donation_id'];
    final isAccepting = _acceptingStates[donationId] == true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUrgent ? 4 : 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isUrgent ? Border.all(color: Colors.red, width: 2) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان والحالة العاجلة
              Row(
                children: [
                  Expanded(
                    child: Text(
                      donation['title'] ?? 'بلا عنوان',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isUrgent ? Colors.red : null,
                      ),
                    ),
                  ),
                  if (isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              if (donation['description'] != null && donation['description'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    donation['description'],
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              
              // تفاصيل التبرع
              _buildDetailRow(Icons.scale, 'الكمية', donation['quantity']?.toString() ?? 'غير محدد'),
              _buildDetailRow(Icons.category, 'النوع', donation['food_type'] ?? 'غير محدد'),
              _buildDetailRow(Icons.location_on, 'العنوان', donation['pickup_address'] ?? 'غير محدد'),
              
              // معلومات المتبرع
              if (donation['donor'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: colorScheme.primary.withAlpha((255 * 0.2).round()),
                        backgroundImage: donation['donor']['avatar_url'] != null
                            ? NetworkImage(donation['donor']['avatar_url'])
                            : null,
                        child: donation['donor']['avatar_url'] == null
                            ? Icon(Icons.person, color: colorScheme.primary)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              donation['donor']['full_name'] ?? 'متبرع',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (donation['donor']['city'] != null)
                              Text(
                                donation['donor']['city'],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (donation['donor']['phone'] != null)
                        IconButton(
                          icon: const Icon(Icons.phone),
                          onPressed: () async {
                            final phone = donation['donor']?['phone'];
                            if (phone != null) {
                              final Uri launchUri = Uri(
                                scheme: 'tel',
                                path: phone,
                              );
                              if (await canLaunchUrl(launchUri)) {
                                await launchUrl(launchUri);
                              } else {
                                if (mounted) {
                                  ErrorHandler.showError(context, 'تعذر إجراء الاتصال');
                                }
                              }
                            }
                          },
                          tooltip: 'اتصال',
                        ),
                    ],
                  ),
                ),
              ],
              
              // التوقيت
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    timeago.format(DateTime.parse(donation['created_at']), locale: 'ar'),
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  if (donation['expiry_date'] != null)
                    Text(
                      'ينتهي: ${DateTime.parse(donation['expiry_date']).day}/${DateTime.parse(donation['expiry_date']).month}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // زر القبول
              SizedBox(
                width: double.infinity,
                child: LoadingButton(
                  text: 'قبول هذا التبرع',
                  icon: Icons.check_circle_outline,
                  isLoading: isAccepting,
                  onPressed: () => _acceptDonation(donation),
                  backgroundColor: isUrgent ? Colors.red : colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// إضافة FilterChipGroup إذا لم تكن موجودة في search_filter_widget.dart
class FilterChipGroup extends StatelessWidget {
  final List<FilterChipData> chips;
  final int selectedIndex;
  final ValueChanged<int> onSelectionChanged;

  const FilterChipGroup({
    super.key,
    required this.chips,
    required this.selectedIndex,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.asMap().entries.map((entry) {
          final index = entry.key;
          final chip = entry.value;
          final isSelected = selectedIndex == index;
          
          return Padding(
            padding: EdgeInsets.only(right: index < chips.length - 1 ? 8 : 0),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (chip.icon != null) ...[
                    Icon(
                      chip.icon,
                      size: 16,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(chip.label),
                ],
              ),
              onSelected: (selected) {
                if (selected) {
                  onSelectionChanged(index);
                }
              },
              selectedColor: Theme.of(context).colorScheme.primary,
              checkmarkColor: Theme.of(context).colorScheme.onPrimary,
              labelStyle: TextStyle(
                color: isSelected 
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class FilterChipData {
  final String label;
  final String value;
  final IconData? icon;

  const FilterChipData({
    required this.label,
    required this.value,
    this.icon,
  });
}