
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssociationSelectVolunteerScreen extends StatefulWidget {
  final String associationId;
  const AssociationSelectVolunteerScreen({super.key, required this.associationId});

  @override
  State<AssociationSelectVolunteerScreen> createState() =>
      _AssociationSelectVolunteerScreenState();
}

class _AssociationSelectVolunteerScreenState
    extends State<AssociationSelectVolunteerScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _allVolunteers = [];
  List<Map<String, dynamic>> _filteredVolunteers = [];

  @override
  void initState() {
    super.initState();
    _fetchVolunteers();
  }

  Future<void> _fetchVolunteers() async {
    try {
      final res = await _supabase.rpc(
        'get_volunteers_for_association',
        params: {'p_association_id': widget.associationId},
      );
      setState(() {
        _allVolunteers = List<Map<String, dynamic>>.from(res);
        _filteredVolunteers = _allVolunteers;
      });
    } catch (e) {
      // Handle error
    }
  }

  void _filterVolunteers(String query) {
    final filtered = _allVolunteers.where((v) {
      final name = v['full_name']?.toString().toLowerCase() ?? '';
      return name.contains(query.toLowerCase());
    }).toList();
    setState(() {
      _filteredVolunteers = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختيار متطوع للمهمة'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _filterVolunteers,
              decoration: InputDecoration(
                hintText: 'بحث باسم المتطوع...',
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchVolunteers,
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _filteredVolunteers.length,
                itemBuilder: (context, index) {
                  final volunteer = _filteredVolunteers[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.tertiary.withAlpha(26),
                        child: Icon(Icons.volunteer_activism_outlined, color: colorScheme.tertiary),
                      ),
                      title: Text(volunteer['full_name'] ?? 'اسم غير معروف', style: textTheme.titleMedium),
                      subtitle: Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber.shade700, size: 16),
                          const SizedBox(width: 4),
                          Text(volunteer['average_rating']?.toStringAsFixed(1) ?? 'N/A'),
                          const SizedBox(width: 12),
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                          const SizedBox(width: 4),
                          Text(volunteer['completed_tasks_count']?.toString() ?? '0'),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.of(context).pop(volunteer['id'].toString());
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
