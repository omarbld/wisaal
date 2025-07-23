
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AssociationInventoryScreen extends StatefulWidget {
  const AssociationInventoryScreen({super.key});

  @override
  State<AssociationInventoryScreen> createState() => _AssociationInventoryScreenState();
}

class _AssociationInventoryScreenState extends State<AssociationInventoryScreen> {
  late Future<List<Map<String, dynamic>>> _inventoryFuture;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _inventoryFuture = _fetchInventory();
  }

  Future<List<Map<String, dynamic>>> _fetchInventory() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await supabase
        .from('donations')
        .select('*')
        .eq('association_id', user.id)
        .in_('status', ['completed']);

    if (response == null) {
      return [];
    }
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المخزون'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _inventoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          final inventory = snapshot.data!;
          if (inventory.isEmpty) {
            return const Center(child: Text('المخزون فارغ حالياً.'));
          }
          return ListView.builder(
            itemCount: inventory.length,
            itemBuilder: (context, index) {
              final donation = inventory[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(donation['title'] ?? 'تبرع غير مسمى'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الكمية: ${donation['quantity']}'),
                      if (donation['expiry_date'] != null)
                        Text('تاريخ الصلاحية: ${DateFormat.yMd().format(DateTime.parse(donation['expiry_date']))}'),
                      Text('أضيف في: ${DateFormat.yMd().add_jm().format(DateTime.parse(donation['created_at']))}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  }
