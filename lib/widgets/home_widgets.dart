import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Recent users list widget for home page
class RecentUsersCard extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final bool isLoading;
  final Color accentColor;

  const RecentUsersCard({
    super.key,
    required this.users,
    required this.isLoading,
    this.accentColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Users',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (users.isEmpty)
              const Center(
                child: Text(
                  'No recent users found',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: accentColor,
                      child: Text(
                        user['name']?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      user['name'] ?? 'Unknown User',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      user['email'] ?? 'No email',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    trailing: user['lastUpdated'] != null
                        ? Text(
                            DateFormat(
                              'MMM dd, HH:mm',
                            ).format(user['lastUpdated'].toDate()),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          )
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
