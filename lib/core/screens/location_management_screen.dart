import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/location_service.dart';

/// صفحة إدارة الموقع الجغرافي
class LocationManagementScreen extends StatefulWidget {
  const LocationManagementScreen({Key? key}) : super(key: key);

  @override
  State<LocationManagementScreen> createState() => _LocationManagementScreenState();
}

class _LocationManagementScreenState extends State<LocationManagementScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, double>? _savedLocation;
  Position? _currentLocation;
  List<Map<String, dynamic>> _nearbyUsers = [];
  List<Map<String, dynamic>> _nearbyDonations = [];

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الموقع'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // قسم الموقع الحالي
              _buildCurrentLocationSection(),
              
              const SizedBox(height: 20),
              
              // قسم الموقع المحفوظ
              _buildSavedLocationSection(),
              
              const SizedBox(height: 20),
              
              // قسم المستخدمين القريبين
              _buildNearbyUsersSection(),
              
              const SizedBox(height: 20),
              
              // قسم التبرعات القريبة
              _buildNearbyDonationsSection(),
              
              const SizedBox(height: 20),
              
              // قسم الأدوات
              _buildToolsSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// قسم الموقع الحالي
  Widget _buildCurrentLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.my_location,
                  color: _currentLocation != null ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                const Text(
                  'الموقع الحالي',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_currentLocation != null) ...[
              _buildLocationInfo(
                'خط العرض',
                _currentLocation!.latitude.toStringAsFixed(6),
                Icons.place,
              ),
              const SizedBox(height: 8),
              _buildLocationInfo(
                'خط الطول',
                _currentLocation!.longitude.toStringAsFixed(6),
                Icons.place,
              ),
              const SizedBox(height: 8),
              _buildLocationInfo(
                'دقة الموقع',
                '${_currentLocation!.accuracy.toStringAsFixed(1)} متر',
                Icons.gps_fixed,
              ),
              const SizedBox(height: 16),
            ] else ...[
              const Text(
                'لم يتم تحديد الموقع الحالي بعد',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
            ],
            
            // عرض رسالة الخطأ إن وجدت
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _getCurrentLocation,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(_isLoading ? 'جاري التحديد...' : 'تحديد الموقع الحالي'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// قسم الموقع المحفوظ
  Widget _buildSavedLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bookmark_border,
                  color: _savedLocation != null ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 12),
                const Text(
                  'الموقع المحفوظ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_savedLocation != null) ...[
              _buildLocationInfo(
                'خط العرض',
                _savedLocation!['latitude']!.toStringAsFixed(6),
                Icons.place,
              ),
              const SizedBox(height: 8),
              _buildLocationInfo(
                'خط الطول',
                _savedLocation!['longitude']!.toStringAsFixed(6),
                Icons.place,
              ),
              
              if (_currentLocation != null) ...[
                const SizedBox(height: 8),
                _buildLocationInfo(
                  'المسافة من الموقع الحالي',
                  '${LocationService.calculateDistance(
                    _currentLocation!.latitude,
                    _currentLocation!.longitude,
                    _savedLocation!['latitude']!,
                    _savedLocation!['longitude']!,
                  ).toStringAsFixed(0)} متر',
                  Icons.straighten,
                ),
              ],
              
              const SizedBox(height: 16),
            ] else ...[
              const Text(
                'لم يتم حفظ أي موقع بعد',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
            ],
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveCurrentLocation,
                    icon: const Icon(Icons.save),
                    label: const Text('حفظ الموقع الحالي'),
                  ),
                ),
                if (_savedLocation != null) ...[
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _clearSavedLocation,
                    icon: const Icon(Icons.delete),
                    tooltip: 'حذف الموقع المحفوظ',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// قسم المستخدمين القريبين
  Widget _buildNearbyUsersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: Colors.orange),
                const SizedBox(width: 12),
                const Text(
                  'المستخدمون القريبون',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_nearbyUsers.isNotEmpty)
                  Chip(
                    label: Text('${_nearbyUsers.length}'),
                    backgroundColor: Colors.orange.withValues(alpha: 0.2),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_nearbyUsers.isEmpty) ...[
              const Text(
                'لا يوجد مستخدمون قريبون (في نطاق 10 كم)',
                style: TextStyle(color: Colors.grey),
              ),
            ] else ...[
              ...(_nearbyUsers.take(5).map((user) => _buildUserTile(user))),
              if (_nearbyUsers.length > 5) ...[
                const SizedBox(height: 8),
                Text(
                  'و ${_nearbyUsers.length - 5} مستخدمين آخرين...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// قسم التبرعات القريبة
  Widget _buildNearbyDonationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.volunteer_activism, color: Colors.green),
                const SizedBox(width: 12),
                const Text(
                  'التبرعات القريبة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_nearbyDonations.isNotEmpty)
                  Chip(
                    label: Text('${_nearbyDonations.length}'),
                    backgroundColor: Colors.green.withValues(alpha: 0.2),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_nearbyDonations.isEmpty) ...[
              const Text(
                'لا توجد تبرعات قريبة (في نطاق 10 كم)',
                style: TextStyle(color: Colors.grey),
              ),
            ] else ...[
              ...(_nearbyDonations.take(3).map((donation) => _buildDonationTile(donation))),
              if (_nearbyDonations.length > 3) ...[
                const SizedBox(height: 8),
                Text(
                  'و ${_nearbyDonations.length - 3} تبرعات أخرى...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// قسم الأدوات
  Widget _buildToolsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.build, color: Colors.purple),
                SizedBox(width: 12),
                Text(
                  'أدوات إضافية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('فحص التكرار في البيانات'),
              subtitle: const Text('البحث عن بيانات مكررة في قاعدة البيانات'),
              onTap: _checkDuplicates,
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.settings_applications),
              title: const Text('إعدادات الموقع'),
              subtitle: const Text('فتح إعدادات الموقع في النظام'),
              onTap: () => Geolocator.openLocationSettings(),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.app_settings_alt),
              title: const Text('إعدادات التطبيق'),
              subtitle: const Text('فتح إعدادات التطبيق في النظام'),
              onTap: () => Geolocator.openAppSettings(),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء معلومات الموقع
  Widget _buildLocationInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  /// بناء عنصر المستخدم
  Widget _buildUserTile(Map<String, dynamic> user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getRoleColor(user['role']),
        child: Icon(
          _getRoleIcon(user['role']),
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(user['full_name'] ?? 'غير محدد'),
      subtitle: Text(
        '${user['role']} ��� ${user['distance_km'].toStringAsFixed(1)} كم',
      ),
      dense: true,
    );
  }

  /// بناء عنصر التبرع
  Widget _buildDonationTile(Map<String, dynamic> donation) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: donation['is_urgent'] ? Colors.red : Colors.green,
        child: Icon(
          donation['is_urgent'] ? Icons.priority_high : Icons.volunteer_activism,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(donation['title'] ?? 'غير محدد'),
      subtitle: Text(
        '${donation['food_type'] ?? 'طعام'} • ${donation['distance_km'].toStringAsFixed(1)} كم',
      ),
      dense: true,
    );
  }

  /// الحصول على لون الدور
  Color _getRoleColor(String role) {
    switch (role) {
      case 'donor':
        return Colors.blue;
      case 'volunteer':
        return Colors.green;
      case 'association':
        return Colors.orange;
      case 'manager':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// الحصول على أيقونة الدور
  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'donor':
        return Icons.person;
      case 'volunteer':
        return Icons.volunteer_activism;
      case 'association':
        return Icons.business;
      case 'manager':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  /// تحميل الموقع المحفوظ
  Future<void> _loadSavedLocation() async {
    try {
      final location = await LocationService.getUserSavedLocation();
      setState(() {
        _savedLocation = location;
      });
    } catch (e) {
      debugPrint('خطأ في تحميل الموقع المحفوظ: $e');
    }
  }

  /// الحصول على الموقع الحالي
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Position? position = await LocationService.getCurrentLocation(context);
      if (position != null) {
        setState(() {
          _currentLocation = position;
        });
        await _loadNearbyData();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// حفظ الموقع الحالي
  Future<void> _saveCurrentLocation() async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد الموقع الحالي أولاً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    bool success = await LocationService.saveUserLocation(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      context: context,
    );

    if (success) {
      await _loadSavedLocation();
    }
  }

  /// حذف الموقع المحفوظ
  Future<void> _clearSavedLocation() async {
    // هذه الوظيفة تحتاج إلى تنفيذ في LocationService
    setState(() {
      _savedLocation = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حذف الموقع المحفوظ'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// تحميل البيانات القريبة
  Future<void> _loadNearbyData() async {
    if (_currentLocation == null) return;

    try {
      final supabase = Supabase.instance.client;
      
      // تحميل المستخدمين القريبين
      final nearbyUsersResponse = await supabase.rpc(
        'get_nearby_users',
        params: {
          'p_latitude': _currentLocation!.latitude,
          'p_longitude': _currentLocation!.longitude,
          'p_radius_km': 10,
        },
      );

      // تحميل التبرعات القريبة
      final nearbyDonationsResponse = await supabase.rpc(
        'get_nearby_donations',
        params: {
          'p_latitude': _currentLocation!.latitude,
          'p_longitude': _currentLocation!.longitude,
          'p_radius_km': 10,
        },
      );

      setState(() {
        _nearbyUsers = List<Map<String, dynamic>>.from(nearbyUsersResponse ?? []);
        _nearbyDonations = List<Map<String, dynamic>>.from(nearbyDonationsResponse ?? []);
      });
    } catch (e) {
      debugPrint('خطأ في تحميل البيانات القريبة: $e');
    }
  }

  /// فحص التكرار
  Future<void> _checkDuplicates() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري فحص التكرار...'),
          ],
        ),
      ),
    );

    await LocationService.checkForDuplicateLocations();
    
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم فحص التكرار. راجع وحدة التحكم للتفاصيل.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// تحديث البيانات
  Future<void> _refreshData() async {
    await _loadSavedLocation();
    if (_currentLocation != null) {
      await _loadNearbyData();
    }
  }
}