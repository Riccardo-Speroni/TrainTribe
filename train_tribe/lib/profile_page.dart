import 'package:flutter/material.dart';
import 'settings_page.dart';
import 'l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/profile_picture_widget.dart';
import 'utils/loading_indicator.dart';
import 'utils/phone_number_helper.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text(localizations.translate('error_loading_profile')));
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoadingIndicator();
        }
        final data = snapshot.data!.data() ?? {};
        final username = data['username'] ?? '';
        final name = data['name'] ?? '';
        final surname = data['surname'] ?? '';
        final email = data['email'] ?? '';
        final phone = data['phone'];
        final picture = data['picture']; // URL or initials

        return Center(
          child: Column(
            children: [
              const Spacer(flex: 1),
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsPage()),
                    );
                  },
                ),
              ),
              const Spacer(flex: 1),
              ProfilePicture(
                picture: picture,
                size: 50,
              ),
              Text(username.isNotEmpty ? username : localizations.translate('username')),
              const Spacer(flex: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$name $surname'),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      // Add button functionality here
                    },
                    child: Text(localizations.translate('edit')),
                  ),
                ],
              ),
              const Spacer(flex: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(email),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      // Add button functionality here
                    },
                    child: Text(localizations.translate('edit')),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      // Add button functionality here
                    },
                    child: Text(localizations.translate('verify')),
                  ),
                ],
              ),
              const Spacer(flex: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text((phone != null && phone.toString().isNotEmpty) ? phone : localizations.translate('phone_number')),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _showEditPhoneDialog(context, localizations, phone?.toString() ?? ''),
                    child: Text(localizations.translate('edit')),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      // Add button functionality here
                    },
                    child: Text(localizations.translate('verify')),
                  ),
                ],
              ),
              const Spacer(flex: 4),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut(); // Sign out from Firebase
                  GoRouter.of(context).go('/login'); // Redirect to login page using GoRouter
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Red button for disconnect
                  foregroundColor: Colors.white,
                ),
                child: Text(localizations.translate('logout')), // Localized text for Logout
              ),
              const Spacer(flex: 1),
            ],
          ),
        );
      },
    );
  }
}

void _showEditPhoneDialog(BuildContext context, AppLocalizations l, String currentE164) async {
  final dialCtrl = TextEditingController(text: kItalyPrefix);
  final numCtrl = TextEditingController();
  String? prefixError;
  String? numberError;

  final parts = splitE164(currentE164);
  if (parts != null) {
    dialCtrl.text = parts.prefix;
    numCtrl.text = parts.number;
  }

  void validateInline(StateSetter setStateLocal) {
    final p = dialCtrl.text.trim();
    final n = numCtrl.text.trim();
    if (n.isEmpty) {
      setStateLocal(() {
        prefixError = null;
        numberError = null;
      });
      return;
    }
    final pOk = validatePrefix(p);
    final dOk = validateNumberDigits(n);
    final lenOk = validateNumberLength(n, p, minLen: kGenericMinLen, maxLen: kGenericMaxLen);
    setStateLocal(() {
      prefixError = pOk ? null : l.translate('invalid_phone');
      numberError = (dOk && lenOk) ? null : l.translate('invalid_phone');
    });
  }

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setStateLocal) {
        return AlertDialog(
          title: Text(l.translate('add_phone_number')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: dialCtrl,
                      keyboardType: TextInputType.phone,
                      onChanged: (v) {
                        final fixed = sanitizePrefix(v);
                        if (fixed != dialCtrl.text) {
                          dialCtrl.value = TextEditingValue(
                            text: fixed,
                            selection: TextSelection.collapsed(offset: fixed.length),
                          );
                        }
                        validateInline(setStateLocal);
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        labelText: l.translate('prefix'),
                        border: const OutlineInputBorder(),
                        errorText: prefixError,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: numCtrl,
                      keyboardType: TextInputType.phone,
                      onChanged: (v) {
                        final filtered = sanitizeNumber(v);
                        if (filtered != v) {
                          numCtrl.value = TextEditingValue(
                            text: filtered,
                            selection: TextSelection.collapsed(offset: filtered.length),
                          );
                        }
                        validateInline(setStateLocal);
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        labelText: l.translate('phone_number'),
                        border: const OutlineInputBorder(),
                        errorText: numberError,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final e164 = composeE164(dialCtrl.text, numCtrl.text, allowEmpty: false);
                if (e164 == null) {
                  validateInline(setStateLocal);
                  return;
                }
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'phone': e164});
                }
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.translate('saved'))),
                );
              },
              child: Text(l.translate('save')),
            ),
          ],
        );
      });
    },
  );
}
