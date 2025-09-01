import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/profile_picture_widget.dart';
import 'custom_text_button.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class FriendPopupDialog extends StatelessWidget {
  final String friend;
  final bool isGhosted;
  final VoidCallback onDelete;
  final VoidCallback onToggleGhost;
  final bool hasPhone;
  final String? picture;
  final String? firstName;
  final String? lastName;
  final String? phone;

  const FriendPopupDialog({
    super.key,
    required this.friend,
    required this.isGhosted,
    required this.onDelete,
    required this.onToggleGhost,
    required this.hasPhone,
    this.picture,
    this.firstName,
    this.lastName,
    this.phone,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    List<Widget> buttons = [
      if (hasPhone)
        SizedBox(
          height: 44,
          child: CustomTextButton(
            text: 'Whatsapp',
            iconWidget: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 18),
            color: Colors.green,
            onPressed: () {
              if (phone != null && phone!.isNotEmpty) {
                final uri = Uri.parse('https://api.whatsapp.com/send?phone=${Uri.encodeComponent(phone!)}');
                launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              Navigator.pop(context);
            },
          ),
        ),
      SizedBox(
        height: 44,
        child: CustomTextButton(
          text: isGhosted ? localizations.translate('unghost') : localizations.translate('ghost'),
          icon: isGhosted ? Icons.visibility : Icons.visibility_off,
          color: isGhosted ? Colors.green : Colors.redAccent,
          onPressed: onToggleGhost,
        ),
      ),
      SizedBox(
        height: 44,
        child: CustomTextButton(
          text: localizations.translate('delete'),
          icon: Icons.delete,
          color: Colors.redAccent,
          onPressed: onDelete,
        ),
      ),
    ];

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  friend,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                if ((firstName != null && firstName!.isNotEmpty) || (lastName != null && lastName!.isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      [if (firstName != null && firstName!.isNotEmpty) firstName, if (lastName != null && lastName!.isNotEmpty) lastName]
                          .join(' '),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ProfilePicture(
            picture: picture,
            username: friend,
            firstName: firstName,
            lastName: lastName,
            ringWidth: 5,
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...buttons.expand((btn) => [btn, const SizedBox(height: 8)]).toList()..removeLast(),
            ],
          ),
        ],
      ),
    );
  }
}
