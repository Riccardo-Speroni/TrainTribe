import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/app_services.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/profile_picture_widget.dart';

class FriendRequestsContainer extends StatelessWidget {
  final List<String> friendRequests;
  final void Function(String) onAccept;
  final void Function(String) onDecline;

  const FriendRequestsContainer({
    super.key,
    required this.friendRequests,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('friend_requests'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
      ...friendRequests.map((uid) => FutureBuilder<DocumentSnapshot>(
        future: AppServicesScope.of(context).firestore.collection('users').doc(uid).get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox(height: 48);
                  final user = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  final picture = (user['picture'] ?? '').toString();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        ProfilePicture(
                          picture: picture,
                          size: 25,
                          firstName: (user['name'] ?? '').toString(),
                          lastName: (user['surname'] ?? '').toString(),
                          username: (user['username'] ?? '').toString(),
                          ringWidth: 2,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(user['username'] ?? 'Unknown', style: const TextStyle(fontSize: 16)),
                        ),
                        IconButton(
                          key: Key('declineRequest_$uid'),
                          icon: const Icon(Icons.close, color: Colors.redAccent),
                          tooltip: localizations.translate('decline'),
                          onPressed: () => onDecline(uid),
                        ),
                        IconButton(
                          key: Key('acceptRequest_$uid'),
                          icon: const Icon(Icons.check, color: Colors.green),
                          tooltip: localizations.translate('accept'),
                          onPressed: () => onAccept(uid),
                        ),
                      ],
                    ),
                  );
                },
              )),
        ],
      ),
    );
  }
}
