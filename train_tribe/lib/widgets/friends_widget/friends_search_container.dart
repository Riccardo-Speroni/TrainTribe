import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/profile_picture_widget.dart';

class FriendsSearchContainer extends StatelessWidget {
  final TextEditingController searchController;
  final void Function(String) onSearchChanged;
  final void Function(String) onSearchSubmitted;
  final List<MapEntry<String, dynamic>> filteredFriends;
  final List<Map<String, dynamic>> usersToAdd;
  final List<String> sentRequests;
  final void Function(String, bool) onToggleVisibility;
  final void Function(BuildContext, String, String, bool, bool) onShowFriendDialog;
  final void Function(String) onSendFriendRequest;
  final bool searching;

  const FriendsSearchContainer({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.filteredFriends,
    required this.usersToAdd,
    required this.sentRequests,
    required this.onToggleVisibility,
    required this.onShowFriendDialog,
    required this.onSendFriendRequest,
    required this.searching,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: localizations.translate('add_or_search_friends'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    ),
                    onChanged: onSearchChanged,
                    onSubmitted: onSearchSubmitted,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Center(
              child: Text(
                localizations.translate('search_and_add_friends_hint'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (filteredFriends.isNotEmpty)
            ...filteredFriends.map((entry) => FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(entry.key).get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();

                    final friendData = entry.value as Map<String, dynamic>;
                    final isGhosted = friendData['ghosted'] == true;
                    final user = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                    final username = (user['username'] ?? 'Unknown').toString();
                    final hasPhone = (user['phone'] ?? '').toString().isNotEmpty;
                    final picture = (user['picture'] ?? '').toString();

                    final query = searchController.text.trim().toLowerCase();
                    final matches = query.isEmpty || username.toLowerCase().startsWith(query);
                    if (!matches) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: ProfilePicture(
                          picture: picture,
                          size: 25,
                          firstName: (user['name'] ?? '').toString(),
                          lastName: (user['surname'] ?? '').toString(),
                          username: username,
                          ringWidth: 2,
                        ),
                        title: Text(username),
                        trailing: IconButton(
                          icon: Icon(
                            isGhosted ? Icons.visibility_off : Icons.visibility,
                            color: isGhosted ? Colors.redAccent : Colors.green,
                          ),
                          tooltip: isGhosted ? localizations.translate('unghost') : localizations.translate('ghost'),
                          onPressed: () => onToggleVisibility(entry.key, isGhosted),
                        ),
                        onTap: () => onShowFriendDialog(context, entry.key, username, isGhosted, hasPhone),
                      ),
                    );
                  },
                )),
          if (filteredFriends.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  localizations.translate('no_friends_found'),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          if (searching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (usersToAdd.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      localizations.translate('add_new_friends'),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),
            ...usersToAdd.map((user) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: ProfilePicture(
                      picture: (user['picture'] ?? '').toString(),
                      size: 25,
                      firstName: (user['name'] ?? '').toString(),
                      lastName: (user['surname'] ?? '').toString(),
                      username: (user['username'] ?? '').toString(),
                      ringWidth: 2,
                    ),
                    title: Text(
                      user['username'] ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        sentRequests.contains(user['uid']) ? Icons.check : Icons.add,
                        color: Colors.green,
                      ),
                      tooltip: sentRequests.contains(user['uid'])
                          ? localizations.translate('friend_request_sent')
                          : localizations.translate('add_friend'),
                      onPressed: sentRequests.contains(user['uid']) ? null : () => onSendFriendRequest(user['uid']),
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
