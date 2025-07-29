
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class AssociationProfileScreen extends StatefulWidget {
  const AssociationProfileScreen({super.key});

  @override
  State<AssociationProfileScreen> createState() =>
      _AssociationProfileScreenState();
}

class _AssociationProfileScreenState extends State<AssociationProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _supabase = Supabase.instance.client;
  String? _avatarUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() => _loading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final profileFuture = _supabase
            .from('users')
            .select('full_name, phone, city, avatar_url')
            .eq('id', user.id)
            .single();

        final donationsFuture = _supabase
            .from('donations')
            .select('status')
            .eq('association_id', user.id);

        final volunteersFuture = _supabase
            .from('users')
            .select('id')
            .eq('associated_with_association_id', user.id);

        final results = await Future.wait([profileFuture, donationsFuture, volunteersFuture]);
        final profile = results[0] as Map<String, dynamic>;
        // final donations = results[1] as List<dynamic>;
        // final volunteers = results[2] as List<dynamic>;

        setState(() {
          _nameController.text = profile['full_name'] ?? '';
          _phoneController.text = profile['phone'] ?? '';
          _cityController.text = profile['city'] ?? '';
          _avatarUrl = profile['avatar_url'];
          // You can use the donations and volunteers data to show stats, e.g.:
          // _completedDonations = donations.where((d) => d['status'] == 'completed').length;
          // _totalVolunteers = volunteers.length;
        });
      }
    } catch (e) {
      _showError('حدث خطأ أثناء جلب البيانات');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('users').update({
          'full_name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'city': _cityController.text.trim(),
        }).eq('id', user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح')),
          );
        }
      }
    } catch (e) {
      _showError('فشل تحديث الملف الشخصي');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _uploadAvatar() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
    );
    if (imageFile == null) return;

    setState(() => _loading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      final filePath = '${user.id}/$fileName';

      await _supabase.storage.from('avatars').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: imageFile.mimeType),
          );

      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
      await _supabase
          .from('users')
          .update({'avatar_url': imageUrl}).eq('id', user.id);

      setState(() => _avatarUrl = imageUrl);
      _showSuccess('تم تحديث الصورة الرمزية بنجاح');
    } catch (e) {
      _showError('فشل رفع الصورة');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي للجمعية'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchProfile,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _avatarUrl != null
                                ? NetworkImage(_avatarUrl!)
                                : null,
                            child: _avatarUrl == null
                                ? Icon(Icons.business_outlined, size: 60, color: colorScheme.primary)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: colorScheme.primary,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.white),
                                onPressed: _uploadAvatar,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الجمعية',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'المدينة',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save_outlined),
                      onPressed: _updateProfile,
                      label: const Text('حفظ التغييرات'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
