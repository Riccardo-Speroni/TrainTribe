import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'services/app_services.dart';
import 'widgets/user_details_page.dart';
import 'l10n/app_localizations.dart';

class CompleteSignUpPage extends StatefulWidget {
  final String? email;
  final String? name;
  final String? profilePicture;

  const CompleteSignUpPage({
    this.email,
    this.name,
    this.profilePicture,
    super.key,
  });

  @override
  State<CompleteSignUpPage> createState() => _CompleteSignUpPageState();
}

class _CompleteSignUpPageState extends State<CompleteSignUpPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill the name field with the value from Google/Facebook
    nameController.text = widget.name ?? '';
  }

  Future<void> _saveUserToDatabase(BuildContext context) async {
    final services = AppServicesScope.of(context);
    final user = services.auth.currentUser;
    if (user == null) return;

    try {
      await services.userRepository.saveUserProfile(user.uid, {
        'email': widget.email,
        'name': nameController.text.trim(),
        'surname': surnameController.text.trim(),
        'username': usernameController.text.trim(),
        'phone': phoneController.text.trim(),
        'picture': widget.profilePicture,
      });

      // Navigate to the main app
      if (context.mounted) {
        GoRouter.of(context).go('/root');
      } else {
        throw Exception('Context is not mounted');
      }
    } catch (e) {
      _showErrorDialog(context, AppLocalizations.of(context).translate('error_unexpected'));
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('error')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).translate('ok')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

  AppServicesScope.of(context); // ensure scope present

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(localizations.translate('complete_profile')),
        ),
        automaticallyImplyLeading: false, // Remove default back button
      ),
  body: UserDetailsPage(
        nameController: nameController,
        surnameController: surnameController,
        usernameController: usernameController,
        phoneController: phoneController,
        onAction: () => _saveUserToDatabase(context),
        actionButtonText: localizations.translate('save'),
        profilePicture: widget.profilePicture,
      ),
    );
  }
}
