import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'association_select_volunteer.dart';
import 'association_rate_volunteer.dart';

const String pickupByVolunteer = 'by_volunteer';

class AssociationDonationDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> donation;
  const AssociationDonationDetailsScreen({super.key, required this.donation});

  @override
  State<AssociationDonationDetailsScreen> createState() =>
      _AssociationDonationDetailsScreenState();
}

class _AssociationDonationDetailsScreenState
    extends State<AssociationDonationDetailsScreen> {
  late Map<String, dynamic> d;
  late final RealtimeChannel _donationChannel;

  @override
  void initState() {
    super.initState();
    d = widget.donation;
    _setupDonationListener();

    // Also check the initial state in case it's already completed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkStatusAndNavigate(d);
      }
    });
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_donationChannel);
    super.dispose();
  }

  void _setupDonationListener() {
    _donationChannel = Supabase.instance.client
        .channel('public:donations:donation_id=eq.${d['donation_id']}');
    _donationChannel.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'UPDATE',
        schema: 'public',
        table: 'donations',
        filter: 'donation_id=eq.${d['donation_id']}',
      ),
      (payload, [ref]) {
        if (mounted) {
          final newDonation = payload['new'] as Map<String, dynamic>;
          setState(() {
            // Update the local state with the new data
            d = newDonation;
          });
          _checkStatusAndNavigate(newDonation);
        }
      },
    );
    _donationChannel.subscribe();
  }

  void _checkStatusAndNavigate(Map<String, dynamic> donation) async {
    final needsRating = donation['status'] == 'completed' &&
        donation['volunteer_id'] != null &&
        donation['rating'] == null;

    if (needsRating && mounted) {
      final volunteer = await _fetchUser(donation['volunteer_id']);
      final volunteerName = volunteer?['full_name'] ?? 'Unknown Volunteer';

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AssociationRateVolunteerScreen(
            volunteerName: volunteerName,
            donationId: donation['donation_id'],
          ),
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _fetchUser(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('users')
          .select('full_name, phone, city')
          .eq('id', userId)
          .single();
      return res;
    } catch (e) {
      return null;
    }
  }

  Future<void> _chooseVolunteer() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final selectedVolunteerId = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AssociationSelectVolunteerScreen(associationId: user.id),
      ),
    );

    if (selectedVolunteerId != null) {
      try {
        final volunteerData = await _fetchUser(selectedVolunteerId);
        final volunteerName = volunteerData?['full_name'] ?? 'متطوع';

        await supabase.from('donations').update({
          'volunteer_id': selectedVolunteerId,
          'status': 'assigned',
          'method_of_pickup': pickupByVolunteer,
        }).eq('donation_id', d['donation_id']);

        if (mounted) {
          setState(() {
            d['volunteer_id'] = selectedVolunteerId;
            d['status'] = 'assigned';
            d['method_of_pickup'] = pickupByVolunteer;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم تعيين $volunteerName للمهمة بنجاح.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل تعيين المتطوع: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل التبرع'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('معلومات المتبرع', theme),
            _buildDonorInfo(theme),
            _buildSectionHeader('تفاصيل التبرع', theme),
            _buildDonationInfo(theme),
            const Divider(height: 32),
            _buildPickupLogic(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildDonorInfo(ThemeData theme) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchUser(d['donor_id']?.toString() ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return _buildInfoCard(children: [const Text('معلومات المتبرع غير متوفرة')]);
        }
        final user = snapshot.data!;
        return _buildInfoCard(
          children: [
            ListTile(
                leading: Icon(Icons.person_outline,
                    color: theme.colorScheme.primary),
                title: Text(user['full_name'] ?? 'غير متوفر'),
                subtitle: const Text('الاسم الكامل')),
            if (user['phone'] != null)
              ListTile(
                  leading: Icon(Icons.phone_outlined,
                      color: theme.colorScheme.primary),
                  title: Text(user['phone']),
                  subtitle: const Text('رقم الهاتف')),
            if (user['city'] != null)
              ListTile(
                  leading: Icon(Icons.location_city_outlined,
                      color: theme.colorScheme.primary),
                  title: Text(user['city']),
                  subtitle: const Text('المدينة')),
          ],
        );
      },
    );
  }

  Widget _buildDonationInfo(ThemeData theme) {
    return _buildInfoCard(
      children: [
        ListTile(
            leading: Icon(Icons.title, color: theme.colorScheme.primary),
            title: Text(d['title'] ?? ''),
            subtitle: const Text('اسم التبرع')),
        ListTile(
            leading: Icon(Icons.description_outlined,
                color: theme.colorScheme.primary),
            title: Text(d['description'] ?? ''),
            subtitle: const Text('الوصف')),
        ListTile(
            leading: Icon(Icons.pie_chart_outline,
                color: theme.colorScheme.primary),
            title: Text(d['quantity']?.toString() ?? ''),
            subtitle: const Text('الكمية')),
        ListTile(
            leading:
                Icon(Icons.place_outlined, color: theme.colorScheme.primary),
            title: Text(d['pickup_address'] ?? 'لم يحدد'),
            subtitle: const Text('العنوان')),
        ListTile(
          leading: Icon(Icons.history_toggle_off_outlined,
              color: theme.colorScheme.primary),
          title: Text(_statusText(d['status'] ?? '')),
          subtitle: const Text('الحالة'),
          trailing: Chip(
            label: Text(_statusText(d['status'] ?? '')),
            backgroundColor: _statusColor(d['status'] ?? '', theme),
            labelStyle: TextStyle(
                color: theme.colorScheme.brightness == Brightness.dark
                    ? Colors.black
                    : Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildPickupLogic(ThemeData theme) {
    switch (d['status']) {
      case 'pending':
        return _buildAcceptButton(theme);
      case 'accepted':
        return _buildChooseVolunteerButton(theme);
      case 'assigned':
      case 'in_progress':
        return _buildAssignedVolunteerInfo(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAcceptButton(ThemeData theme) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.check_circle_outline),
      label: const Text('قبول التبرع'),
      onPressed: () async {
        await Supabase.instance.client.from('donations').update({
          'status': 'accepted',
          'association_id': Supabase.instance.client.auth.currentUser!.id,
        }).eq('donation_id', d['donation_id']);
        setState(() => d['status'] = 'accepted');
      },
    );
  }

  Widget _buildChooseVolunteerButton(ThemeData theme) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.send_outlined),
      label: const Text('اختيار متطوع للمهمة'),
      onPressed: _chooseVolunteer,
    );
  }

  Widget _buildAssignedVolunteerInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('المتطوع المسؤول', theme),
        FutureBuilder<Map<String, dynamic>?>(
          future: _fetchUser(d['volunteer_id'] ?? ''),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final volunteer = snapshot.data!;
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(volunteer['full_name'] ?? 'متطوع غير معروف'),
                subtitle: Text(volunteer['phone'] ?? 'رقم هاتف غير متوفر'),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('رمز تأكيد التسليم', theme),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('اطلب من المتطوع مسح هذا الرمز عند تسليم التبرع'),
                const SizedBox(height: 12),
                QrImageView(
                  data: d['association_qr_code'] ?? '',
                  version: QrVersions.auto,
                  size: 150,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status, ThemeData theme) {
    switch (status) {
      case 'pending':
        return theme.colorScheme.secondary;
      case 'accepted':
      case 'in_progress':
        return theme.colorScheme.tertiary;
      case 'completed':
        return theme.colorScheme.primary;
      case 'cancelled':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurface.withAlpha(128); // 0.5 opacity
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'بانتظار القبول';
      case 'accepted':
        return 'مقبولة';
      case 'in_progress':
        return 'جاري الاستلام';
      case 'completed':
        return 'تم التسليم';
      case 'cancelled':
        return 'ملغاة';
      default:
        return status;
    }
  }
}
