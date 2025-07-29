import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'donor_rate_screen.dart';

class DonationDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> donation;
  const DonationDetailsScreen({super.key, required this.donation});

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(donation['title'] ?? 'تفاصيل التبرع'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('تفاصيل التبرع', textTheme, colorScheme),
            _buildInfoCard(
              children: [
                _buildDetailRow(Icons.description_outlined, 'الوصف', donation['description'] ?? '', theme),
                _buildDetailRow(Icons.pie_chart_outline, 'الكمية', donation['quantity']?.toString() ?? '', theme),
                _buildDetailRow(Icons.category_outlined, 'نوع الطعام', donation['food_type'] ?? '', theme),
                _buildDetailRow(Icons.date_range_outlined, 'تاريخ الانتهاء', donation['expiry_date']?.toString().substring(0, 10) ?? '', theme),
                _buildDetailRow(Icons.location_on_outlined, 'عنوان الاستلام', donation['pickup_address'] ?? '', theme),
                _buildStatusChip(donation['status'] ?? '', theme),
                ],
                ),
                if (donation['status'] == 'assigned' || donation['status'] == 'in_progress') ...[
                const SizedBox(height: 24),
                _buildSectionHeader('رمز التأكيد (للمتطوع)', textTheme, colorScheme),
                _buildQrCodeCard(donation['donor_qr_code'] ?? donation['donation_id']?.toString() ?? '', theme),
                ],
                const SizedBox(height: 24),
                _buildAssignedPartyCard(donation, textTheme, colorScheme),
            const SizedBox(height: 24),
            _buildRatingButton(context, donation),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, TextTheme textTheme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Card(
      child: Column(children: children),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String subtitle, ThemeData theme) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: Text(subtitle, style: theme.textTheme.bodyLarge),
    );
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Chip(
            label: Text(_statusText(status)),
            backgroundColor: _statusColor(status, theme),
            labelStyle: TextStyle(color: theme.colorScheme.onPrimary),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCodeCard(String data, ThemeData theme) {
    return Card(
      color: theme.colorScheme.primaryContainer.withAlpha(128), // 0.5 opacity
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'يرجى إظهار هذا الرمز للمتطوع لتأكيد عملية الاستلام.',
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(
              data: data,
              version: QrVersions.auto,
              size: 180,
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedPartyCard(Map<String, dynamic> d, TextTheme textTheme, ColorScheme colorScheme) {
    if (d['status'] == 'pending') {
      return const SizedBox.shrink();
    }
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchAssociationOrVolunteer(d),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final info = snapshot.data;
        if (info == null) return const SizedBox.shrink();

        final type = info['type'] == 'association' ? 'الجمعية المسؤولة' : 'المتطوع المسؤول';
        final name = info['name'] ?? 'غير متوفر';
        final phone = info['phone'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader(type, textTheme, colorScheme),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(info['type'] == 'association' ? Icons.business_outlined : Icons.person_outline, color: colorScheme.onPrimaryContainer),
                  ),
                  title: Text(name),
                  subtitle: phone != null ? Text(phone) : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRatingButton(BuildContext context, Map<String, dynamic> d) {
    if (d['status'] != 'completed') {
      return const SizedBox.shrink();
    }
    return ElevatedButton.icon(
      icon: const Icon(Icons.star_outline),
      label: const Text('تقييم التجربة'),
      onPressed: () async {
        String? ratedEntityId;
        String entityType = 'association';
        if (d['volunteer_id'] != null) {
          ratedEntityId = d['volunteer_id'].toString();
          entityType = 'volunteer';
        } else if (d['association_id'] != null) {
          ratedEntityId = d['association_id'].toString();
          entityType = 'association';
        }

        if (ratedEntityId != null && d['id'] != null) {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DonorRateScreen(
                taskId: d['id'].toString(),
                ratedEntityId: ratedEntityId ?? '',
                entityType: entityType,
              ),
            ),
          );
          if (result == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('شكراً لك، تم إرسال تقييمك بنجاح!')),
            );
          }
        }
      },
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
        return theme.colorScheme.onSurface.withAlpha(128);
    }
  }

  Future<Map<String, dynamic>?> _fetchAssociationOrVolunteer(Map<String, dynamic> d) async {
    final supabase = Supabase.instance.client;
    if (d['association_id'] != null) {
      final res = await supabase.from('users').select('full_name, phone').eq('id', d['association_id']).maybeSingle();
      if (res != null) {
        return {'type': 'association', 'name': res['full_name'], 'phone': res['phone']};
      }
    }
    if (d['volunteer_id'] != null) {
      final res = await supabase.from('users').select('full_name, phone').eq('id', d['volunteer_id']).maybeSingle();
      if (res != null) {
        return {'type': 'volunteer', 'name': res['full_name'], 'phone': res['phone']};
      }
    }
    return null;
  }
}
