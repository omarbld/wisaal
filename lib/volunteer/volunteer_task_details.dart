
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VolunteerTaskDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> donation;
  const VolunteerTaskDetailsScreen({super.key, required this.donation});

  @override
  State<VolunteerTaskDetailsScreen> createState() =>
      _VolunteerTaskDetailsScreenState();
}

class _VolunteerTaskDetailsScreenState
    extends State<VolunteerTaskDetailsScreen> {
  late Map<String, dynamic> _donationData;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _donationData = widget.donation;
  }

  Future<Map<String, dynamic>?> _fetchUser(String? id) async {
    if (id == null) return null;
    final supabase = Supabase.instance.client;
    final res = await supabase
        .from('users')
        .select('full_name, phone, city, avatar_url')
        .eq('id', id)
        .maybeSingle();
    return res;
  }

  Future<void> _updateTaskStatus(String newStatus) async {
    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;
      final donationId = _donationData['donation_id'];

      await supabase
          .from('donations')
          .update({'status': newStatus}).eq('donation_id', donationId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحديث حالة المهمة بنجاح!')),
        );
        setState(() {
          _donationData['status'] = newStatus;
        });
        print('New status: $newStatus');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحديث الحالة: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _scanQrCode(String expectedQrData, String nextStatus) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('مسح رمز QR')),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                Navigator.pop(context, barcodes.first.rawValue);
              }
            },
          ),
        ),
      ),
    );

    if (result != null) {
      if (result.trim() == expectedQrData.trim()) {
        await _updateTaskStatus(nextStatus);
        // إعادة بناء الواجهة مباشرة بعد تغيير الحالة
        setState(() {
          _donationData['status'] = nextStatus;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'رمز QR غير مطابق. تم مسح: [${result.trim()}] المتوقع: [${expectedQrData.trim()}]')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final donation = _donationData;

    return Scaffold(
      appBar: AppBar(
        title: Text(donation['title'] ?? 'تفاصيل المهمة'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('تفاصيل التبرع', textTheme, colorScheme),
            _buildInfoCard(children: [
              _buildDetailRow(Icons.description_outlined, 'الوصف',
                  donation['description'] ?? '', theme),
              _buildDetailRow(Icons.pie_chart_outline, 'الكمية',
                  donation['quantity']?.toString() ?? '', theme),
              _buildDetailRow(Icons.location_on_outlined, 'عنوان الاستلام',
                  donation['pickup_address'] ?? '', theme),
            ]),
            const SizedBox(height: 24),
            _buildPartyInfo('المتبرع', donation['donor_id'],
                Icons.person_outline, theme),
            const SizedBox(height: 16),
            _buildPartyInfo('الجمعية المستلمة', donation['association_id'],
                Icons.business_outlined, theme),
            const SizedBox(height: 24),
            if (_donationData['status'] == 'assigned')
              _buildActionCard(
                title: 'استلام التبرع من المتبرع',
                subtitle:
                    'عند الوصول للمتبرع، اطلب منه عرض رمز التأكيد الخاص به وقم بمسحه.',
                buttonLabel: 'مسح رمز المتبرع',
                qrData: donation['donor_qr_code'],
                onPressed: () =>
                    _scanQrCode(donation['donor_qr_code'], 'in_progress'),
                theme: theme,
              ),
            if (_donationData['status'] == 'in_progress')
              _buildActionCard(
                title: 'تسليم التبرع للجمعية',
                subtitle:
                    'عند الوصول للجمعية، اطلب منهم عرض رمز التأكيد الخاص بهم وقم بمسحه.',
                buttonLabel: 'مسح رمز الجمعية',
                qrData: donation['association_qr_code'],
                onPressed: () =>
                    _scanQrCode(donation['association_qr_code'], 'completed'),
                theme: theme,
              ),
            if (_donationData['status'] == 'completed')
              Column(
                children: [
                  Center(
                    child: Chip(
                      avatar: Icon(Icons.check_circle, color: Colors.green.shade700),
                      label: Text('المهمة مكتملة بنجاح'),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLogHoursSection(),
                  const SizedBox(height: 16),
                  _buildShareButtonsSection(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // نموذج تسجيل الساعات
  Widget _buildLogHoursSection() {
    final startController = TextEditingController();
    final endController = TextEditingController();
    final notesController = TextEditingController();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تسجيل ساعات العمل', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextField(
              controller: startController,
              decoration: const InputDecoration(
                labelText: 'وقت البدء (مثال: 14:00)',
                prefixIcon: Icon(Icons.access_time),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: endController,
              decoration: const InputDecoration(
                labelText: 'وقت الانتهاء (مثال: 16:00)',
                prefixIcon: Icon(Icons.access_time),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('تسجيل الساعات'),
              onPressed: () async {
                final supabase = Supabase.instance.client;
                final user = supabase.auth.currentUser;
                if (user == null) return;
                await supabase.rpc('log_volunteer_hours', params: {
                  'p_volunteer_id': user.id,
                  'p_donation_id': _donationData['donation_id'],
                  'p_start_time': startController.text,
                  'p_end_time': endController.text,
                  'p_notes': notesController.text,
                }).select();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الساعات بنجاح!')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // أزرار المشاركة الاجتماعية
  Widget _buildShareButtonsSection() {
    return FutureBuilder(
      future: _fetchShareText(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox();
        }
        final shareText = snapshot.data as String;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('مشاركة على تويتر'),
              onPressed: () {
                final url = 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(shareText)}';
                _launchUrl(url);
              },
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.facebook),
              label: const Text('مشاركة على فيسبوك'),
              onPressed: () {
                final url = 'https://www.facebook.com/sharer/sharer.php?u=&quote=${Uri.encodeComponent(shareText)}';
                _launchUrl(url);
              },
            ),
          ],
        );
      },
    );
  }

  Future<String> _fetchShareText() async {
    final supabase = Supabase.instance.client;
    final result = await supabase.rpc('generate_share_text', params: {
      'p_donation_id': _donationData['donation_id'],
    }).select();
    if (result is List && result.isNotEmpty) {
      return result.first as String;
    }
    return '';
  }

  void _launchUrl(String url) async {
    // استخدم أي مكتبة مثل url_launcher أو طريقة مناسبة لفتح الرابط
  }

  Widget _buildSectionHeader(
      String title, TextTheme textTheme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Card(
      child: Column(children: children),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String subtitle,
      ThemeData theme,
      [bool usePrimaryColor = true]) {
    return ListTile(
      leading: Icon(icon,
          color: usePrimaryColor
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: Text(subtitle, style: theme.textTheme.bodyLarge),
    );
  }

  Widget _buildPartyInfo(
      String title, String? userId, IconData icon, ThemeData theme) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return _buildInfoCard(children: [
            ListTile(title: Text(title), subtitle: const Text('معلومات غير متاحة'))
          ]);
        }
        final user = snapshot.data!;
        return _buildInfoCard(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: user['avatar_url'] != null
                    ? NetworkImage(user['avatar_url'])
                    : null,
                child: user['avatar_url'] == null ? Icon(icon) : null,
              ),
              title: Text(title, style: theme.textTheme.titleSmall),
              subtitle: Text(user['full_name'] ?? 'اسم غير معروف',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDetailRow(
                      Icons.location_city_outlined, 'المدينة', user['city'] ?? '', theme, false),
                  if (user['phone'] != null)
                    _buildDetailRow(
                        Icons.phone_outlined, 'الهاتف', user['phone'], theme, false),
                ],
              ),
            )
          ],
        );
      },
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required String buttonLabel,
    required String? qrData,
    required VoidCallback onPressed,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withAlpha(102),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.primaryContainer),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.qr_code_scanner_rounded, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (_loading)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: theme.textTheme.titleMedium,
                ),
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(buttonLabel),
                onPressed: onPressed,
              ),
          ],
        ),
      ),
    );
  }
}
