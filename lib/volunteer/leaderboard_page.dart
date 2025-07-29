import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({Key? key}) : super(key: key);

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<dynamic> _leaders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final List data = await Supabase.instance.client
          .rpc('get_leaderboard')
          .select();
      setState(() {
        _leaders = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      // يمكن إضافة معالجة للأخطاء هنا
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المتصدرون')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _leaders.length,
              itemBuilder: (context, index) {
                final leader = _leaders[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${leader['rank']}'),
                  ),
                  title: Text(leader['full_name'] ?? ''),
                  trailing: Text('${leader['points']} نقطة'),
                );
              },
            ),
    );
  }
}
