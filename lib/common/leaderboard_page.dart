
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late Future<List<Map<String, dynamic>>> _leaderboardFuture;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = _fetchLeaderboard();
  }

  Future<List<Map<String, dynamic>>> _fetchLeaderboard() async {
    final response = await supabase
        .rpc('get_leaderboard')
        .order('rank');
        
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الصدارة'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _leaderboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          final leaderboard = snapshot.data!;
          if (leaderboard.isEmpty) {
            return const Center(child: Text('لا توجد بيانات لعرضها.'));
          }
          return ListView.builder(
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final entry = leaderboard[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: Text('#${entry['rank']}', style: Theme.of(context).textTheme.headlineSmall),
                  title: Text(entry['user_name'] ?? 'مستخدم غير معروف'),
                  subtitle: Text('النقاط: ${entry['points']}'),
                  trailing: Icon(entry['category'] == 'volunteer' ? Icons.person : Icons.group),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
