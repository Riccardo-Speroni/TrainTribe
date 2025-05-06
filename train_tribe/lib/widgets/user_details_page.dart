import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';

class UserDetailsPage extends StatefulWidget {
  final String? prefilledName;
  final String? prefilledSurname;
  final String? prefilledUsername;
  final String? prefilledPhone;
  final VoidCallback? onBack;
  final VoidCallback onAction;
  final String actionButtonText;

  // Accept controllers from the parent widget
  final TextEditingController nameController;
  final TextEditingController surnameController;
  final TextEditingController usernameController;
  final TextEditingController phoneController;

  const UserDetailsPage({
    this.prefilledName,
    this.prefilledSurname,
    this.prefilledUsername,
    this.prefilledPhone,
    this.onBack,
    required this.onAction,
    required this.actionButtonText,
    required this.nameController,
    required this.surnameController,
    required this.usernameController,
    required this.phoneController,
    super.key,
  });

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  bool isUsernameUnique = true;
  bool areMandatoryFieldsFilled = false;

  @override
  void initState() {
    super.initState();
    _validateMandatoryFields();
  }

  Future<void> _checkUsernameUniqueness(String username) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    setState(() {
      isUsernameUnique = querySnapshot.docs.isEmpty;
    });
  }

  void _validateMandatoryFields() {
    setState(() {
      areMandatoryFieldsFilled = widget.nameController.text.trim().isNotEmpty &&
          widget.surnameController.text.trim().isNotEmpty &&
          widget.usernameController.text.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.onBack != null)
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
            ),
          Image.asset('images/djungelskog.jpg', height: 100),
          const SizedBox(height: 20),
          Text(
            localizations.translate('choose_username'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: widget.usernameController,
            onChanged: (value) {
              _validateMandatoryFields();
              _checkUsernameUniqueness(value.trim());
            },
            decoration: InputDecoration(
              labelText: localizations.translate('username'),
              border: const OutlineInputBorder(),
              errorText: isUsernameUnique
                  ? null
                  : localizations.translate('error_username_taken'),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            localizations.translate('name_surname'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.nameController,
                  onChanged: (_) => _validateMandatoryFields(),
                  decoration: InputDecoration(
                    labelText: localizations.translate('first_name'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.surnameController,
                  onChanged: (_) => _validateMandatoryFields(),
                  decoration: InputDecoration(
                    labelText: localizations.translate('last_name'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            localizations.translate('add_phone_number'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextField(
            controller: widget.phoneController,
            decoration: InputDecoration(
              labelText: localizations.translate('phone_number'),
              border: const OutlineInputBorder(),
              helperText: localizations.translate('phone_number_note'),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: areMandatoryFieldsFilled && isUsernameUnique
                ? widget.onAction
                : null,
            child: Text(widget.actionButtonText),
          ),
        ],
      ),
    );
  }
}