import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/profile_picture_widget.dart';

class SuggestionsSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool loading;
  final bool contactsRequested;
  final List<Map<String, dynamic>> suggestions;
  final List<String> sentRequests;
  final VoidCallback onRefresh;
  final void Function(String uid) onAdd;

  const SuggestionsSection({
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.contactsRequested,
    required this.suggestions,
    required this.sentRequests,
    required this.onRefresh,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.contacts,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: Theme.of(context).textTheme.titleMedium),
                          if (subtitle != null && suggestions.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                subtitle!,
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: loading ? null : onRefresh,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.sync),
                label: Text(loading ? 'Scanning' : 'Scan'),
                style: FilledButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading && suggestions.isEmpty)
            Column(
              children: List.generate(3, (i) => i).map((_) => _loadingTile(context)).toList(),
            )
          else if (suggestions.isNotEmpty)
            Column(
              children: [
                ...suggestions.map((user) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: SuggestionCard(
                        username: (user['username'] ?? '').toString(),
                        contactName: (user['contactName'] ?? '').toString().isNotEmpty ? (user['contactName'] ?? '').toString() : null,
                        picture: (user['picture'] ?? '').toString(),
                        sent: sentRequests.contains((user['uid'] ?? '').toString()),
                        onAdd: () => onAdd((user['uid'] ?? '').toString()),
                      ),
                    )),
              ],
            )
          else if (!loading && contactsRequested)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l.translate('no_contact_suggestions'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _loadingTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            _skeletonCircle(36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonBar(width: 120, height: 12),
                  const SizedBox(height: 8),
                  _skeletonBar(width: 180, height: 10),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _skeletonCircle(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
      );

  Widget _skeletonBar({required double width, required double height}) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      );
}

class SuggestionCard extends StatelessWidget {
  final String username;
  final String? contactName;
  final VoidCallback onAdd;
  final String? picture;
  final bool sent;

  const SuggestionCard({
    required this.username,
    required this.contactName,
    required this.onAdd,
    this.picture,
    this.sent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ProfilePicture(
          picture: picture,
          size: 25,
          username: username,
          firstName: contactName,
          ringWidth: 2,
        ),
        title: Text(
          username,
          style: Theme.of(context).textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: contactName != null
            ? Row(
                children: [
                  const Icon(Icons.contact_page, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      contactName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : null,
        trailing: sent
            ? const Icon(Icons.check, color: Colors.green)
            : IconButton(
                icon: Icon(Icons.add, color: Colors.green),
                tooltip: 'Add',
                onPressed: onAdd,
              ),
      ),
    );
  }
}
