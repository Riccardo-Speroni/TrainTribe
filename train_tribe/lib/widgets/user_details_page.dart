import 'package:flutter/material.dart';
import '../../services/app_services.dart';
import '../l10n/app_localizations.dart';
import '../utils/phone_number_helper.dart';
import 'profile_picture_picker.dart';

class UserDetailsPage extends StatefulWidget {
  final String? prefilledName;
  final String? prefilledSurname;
  final String? prefilledUsername;
  final String? prefilledPhone;
  final String? profilePicture;
  final VoidCallback? onBack;
  final VoidCallback onAction;
  final String actionButtonText;
  final void Function(ProfileImageSelection selection)? onProfileImageSelected;

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
    this.profilePicture,
    required this.onAction,
    required this.actionButtonText,
    required this.nameController,
    required this.surnameController,
    required this.usernameController,
    required this.phoneController,
    this.onProfileImageSelected,
    super.key,
  });

  @override
  UserDetailsPageState createState() => UserDetailsPageState();
}

class UserDetailsPageState extends State<UserDetailsPage> {
  bool isUsernameUnique = true;
  bool areMandatoryFieldsFilled = false;
  // Editable prefix with +39 default
  static const String _defaultDial = '+39';
  final TextEditingController _dialController = TextEditingController(text: _defaultDial);
  String? _prefixError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _validateMandatoryFields();
    final pre = widget.phoneController.text.trim();
    final parts = splitE164(pre);
    if (parts != null) {
      _dialController.text = parts.prefix;
      widget.phoneController.text = parts.number;
    }
  }

  @override
  void dispose() {
    _dialController.dispose();
    super.dispose();
  }

  void _validatePhoneInline(AppLocalizations localizations) {
    final dialRaw = _dialController.text.trim();
    final numRaw = widget.phoneController.text.trim();

    // Optional: if number is empty, clear errors
    if (numRaw.isEmpty) {
      setState(() {
        _prefixError = null;
        _phoneError = null;
      });
      return;
    }

    final prefixOk = validatePrefix(dialRaw);
    final numberDigitsOnly = validateNumberDigits(numRaw);
    final lengthOk = validateNumberLength(numRaw, dialRaw, minLen: kGenericMinLen, maxLen: kGenericMaxLen);

    setState(() {
      _prefixError = prefixOk ? null : localizations.translate('invalid');
      _phoneError = (numberDigitsOnly && lengthOk) ? null : localizations.translate('invalid_phone');
    });
  }

  String? _composeAndValidateE164(AppLocalizations localizations) {
    final dialRaw = _dialController.text.trim();
    final numRaw = widget.phoneController.text.trim();

    // Optional: empty number allowed
    if (numRaw.isEmpty) {
      _prefixError = null;
      _phoneError = null;
      return '';
    }
    final prefixOk = validatePrefix(dialRaw);
    final numberDigitsOnly = validateNumberDigits(numRaw);
    final lengthOk = validateNumberLength(numRaw, dialRaw, minLen: kGenericMinLen, maxLen: kGenericMaxLen);

    if (!(prefixOk && numberDigitsOnly && lengthOk)) {
      setState(() {
        _prefixError = prefixOk ? null : localizations.translate('invalid');
        _phoneError = (numberDigitsOnly && lengthOk) ? null : localizations.translate('invalid_phone');
      });
      return null;
    }
    final e164 = composeE164(dialRaw, numRaw, allowEmpty: false, minLen: kGenericMinLen, maxLen: kGenericMaxLen);
    return e164;
  }

  Future<void> _checkUsernameUniqueness(String username) async {
    final services = AppServicesScope.of(context);
    final unique = await services.userRepository.isUsernameUnique(username);
    if (!mounted) return;
    setState(() => isUsernameUnique = unique);
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.onBack != null)
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: widget.onBack,
                ),
              ),
            Center(
              child: ProfilePicturePicker(
                firstName: widget.nameController.text,
                lastName: widget.surnameController.text,
                username: widget.usernameController.text,
                initialImageUrl: widget.profilePicture is String ? widget.profilePicture : null,
                size: 110,
                ringWidth: 5,
                autoUpload: false, // defer upload until after user document creation
                onSelection: (sel) async {
                  if (widget.onProfileImageSelected != null) {
                    widget.onProfileImageSelected!(sel);
                  }
                },
              ),
            ),
            const SizedBox(height: 25),
            Text(
              localizations.translate('username'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              key: const Key('usernameField'),
              controller: widget.usernameController,
              onChanged: (value) {
                _validateMandatoryFields();
                _checkUsernameUniqueness(value.trim());
              },
              decoration: InputDecoration(
                labelText: localizations.translate('username'),
                border: const OutlineInputBorder(),
                errorText: isUsernameUnique ? null : localizations.translate('error_username_taken'),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              localizations.translate('name_surname'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('nameField'),
                    controller: widget.nameController,
                    onChanged: (_) => _validateMandatoryFields(),
                    decoration: InputDecoration(
                      labelText: localizations.translate('first_name'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    key: const Key('surnameField'),
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
            const SizedBox(height: 25),
            Text(
              localizations.translate('add_phone_number'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 90,
                  child: TextField(
                    key: const Key('dialField'),
                    controller: _dialController,
                    keyboardType: TextInputType.phone,
                    onChanged: (val) {
                      // Allow only '+' followed by digits; normalize live.
                      final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
                      final fixed = '+$digits';
                      if (fixed != _dialController.text) {
                        _dialController.value = TextEditingValue(
                          text: fixed,
                          selection: TextSelection.collapsed(offset: fixed.length),
                        );
                      }
                      _validatePhoneInline(localizations);
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      labelText: localizations.translate('prefix'),
                      border: const OutlineInputBorder(),
                      errorText: _prefixError,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    key: const Key('phoneField'),
                    controller: widget.phoneController,
                    keyboardType: TextInputType.phone,
                    onChanged: (value) {
                      // Strict: allow digits only; no spaces
                      final filtered = value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (filtered != value) {
                        widget.phoneController.value = TextEditingValue(
                          text: filtered,
                          selection: TextSelection.collapsed(offset: filtered.length),
                        );
                      }
                      _validatePhoneInline(localizations);
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      labelText: localizations.translate('phone_number'),
                      border: const OutlineInputBorder(),
                      helperText: localizations.translate('phone_number_note'),
                      helperMaxLines: 3,
                      errorText: _phoneError,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              key: const Key('actionButton'),
              style: ElevatedButton.styleFrom(
                backgroundColor: areMandatoryFieldsFilled && isUsernameUnique ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
              onPressed: areMandatoryFieldsFilled && isUsernameUnique
                  ? () {
                      final e164 = _composeAndValidateE164(localizations);
                      if (e164 == null) return;
                      widget.phoneController.text = e164;
                      widget.onAction();
                    }
                  : null,
              child: Text(widget.actionButtonText, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
