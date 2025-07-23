
import 'package:flutter/material.dart';
import 'package:wisaal/common/donation_chat.dart';

class AssociationTaskDetailsScreen extends StatelessWidget {
  final String donationId;

  const AssociationTaskDetailsScreen({super.key, required this.donationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المهمة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DonationChatScreen(donationId: donationId),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Text('تفاصيل المهمة للتبرع رقم: $donationId'),
      ),
    );
  }
}
