import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/profile_picture_widget.dart';
import 'utils/loading_indicator.dart';
import 'utils/phone_number_helper.dart';
import 'utils/app_globals.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _saveLanguagePreference(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    appLocale.value = locale;
  }

  Future<void> _saveThemePreference(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', index);
    appTheme.value = index == 0
        ? ThemeMode.light
        : (index == 1 ? ThemeMode.dark : ThemeMode.system);
  }


  Future<void> _resetOnboarding(BuildContext context, AppLocalizations l) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', false);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.translate('onboarding_reset_done'))),
      );
    }
  }

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

        // Responsive layout: two boxes (profile info + settings). Vertical on narrow, horizontal on wide.
        final isWide = MediaQuery.of(context).size.width >= 700;

        Widget profileBox = _ProfileInfoBox(
          username: username,
          name: name,
          surname: surname,
          email: email,
          phone: phone?.toString(),
          picture: picture,
          localizations: localizations,
        );

        Widget settingsBox = _SettingsBox(
          localizations: localizations,
          saveThemePreference: _saveThemePreference,
          saveLanguagePreference: _saveLanguagePreference,
          resetOnboarding: _resetOnboarding,
        );

        return LayoutBuilder(builder: (ctx, constraints) {
          if (isWide) {
            // Wide layout: equal height cards matching tallest content, not full screen.
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: profileBox),
                        const SizedBox(width: 16),
                        Expanded(child: settingsBox),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        GoRouter.of(context).go('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(localizations.translate('logout')),
                    ),
                  ),
                ],
              ),
            );
          }

            // Narrow (mobile): scrollable vertical stack.
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                profileBox,
                const SizedBox(height: 16),
                settingsBox,
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      GoRouter.of(context).go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(localizations.translate('logout')),
                  ),
                ),
              ],
            );

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                  child: content,
                ),
              ),
            );
        });
      },
    );
  }
}


class _ProfileInfoBox extends StatelessWidget {
  final String username;
  final String name;
  final String surname;
  final String email;
  final String? phone;
  final dynamic picture; // could be URL / initials
  final AppLocalizations localizations;

  const _ProfileInfoBox({
    required this.username,
    required this.name,
    required this.surname,
    required this.email,
    required this.phone,
    required this.picture,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProfilePicture(picture: picture, size: 70),
              const SizedBox(height: 8),
              Text(
                username.isNotEmpty ? username : localizations.translate('username'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Divider(height: 32),
              _ProfileInfoTable(
                rows: [
                  ProfileInfoRow(
                    label: localizations.translate('username'),
                    value: username.isNotEmpty ? username : '-',
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: localizations.translate('copy_username'),
                        onPressed: () {
                          final toCopy = username.isNotEmpty ? username : '';
                          if (toCopy.isEmpty) return;
                          Clipboard.setData(ClipboardData(text: toCopy));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(localizations.translate('copied'))),
                          );
                        },
                      ),
                    ],
                  ),
                  ProfileInfoRow(
                    label: localizations.translate('name'),
                    value: name.isNotEmpty ? name : '-',
                  ),
                  ProfileInfoRow(
                    label: localizations.translate('surname'),
                    value: surname.isNotEmpty ? surname : '-',
                  ),
                  ProfileInfoRow(
                    label: localizations.translate('email'),
                    value: email.isNotEmpty ? email : '-',
                  ),
                  ProfileInfoRow(
                    label: localizations.translate('phone_number'),
                    value: (phone != null && phone!.isNotEmpty) ? phone! : '-',
                    actions: [
                      TextButton(
                        onPressed: () => _showEditPhoneDialog(
                            context, localizations, phone ?? ''),
                        child: Text(localizations.translate('edit')),
                      ),
                    ],
                  ),
                ],
              ),
            ]),
      ),
    );
  }
}

class _SettingsBox extends StatelessWidget {
  final AppLocalizations localizations;
  final Future<void> Function(int) saveThemePreference;
  final Future<void> Function(Locale) saveLanguagePreference;
  final Future<void> Function(BuildContext, AppLocalizations) resetOnboarding;

  const _SettingsBox({
    required this.localizations,
    required this.saveThemePreference,
    required this.saveLanguagePreference,
    required this.resetOnboarding,
  });

  int _themeModeToIndex(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 0;
      case ThemeMode.dark:
        return 1;
  case ThemeMode.system:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.translate('settings'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.language),
                const SizedBox(width: 8),
                Text(localizations.translate('language')),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButton<Locale>(
              value: Locale(localizations.languageCode()),
              onChanged: (Locale? newLocale) {
                if (newLocale != null) {
                  saveLanguagePreference(newLocale);
                }
              },
              items: const [
                DropdownMenuItem(value: Locale('en'), child: Text('english')),
                DropdownMenuItem(value: Locale('it'), child: Text('italiano')),
              ],
            ),
            const SizedBox(height: 24),
            Text(localizations.translate('theme')),
            const SizedBox(height: 8),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: appTheme,
              builder: (context, mode, _) {
                final idx = _themeModeToIndex(mode);
                return ToggleButtons(
                  isSelected: [0, 1, 2].map((i) => i == idx).toList(),
                  onPressed: (i) => saveThemePreference(i),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(localizations.translate('light')),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(localizations.translate('dark')),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(localizations.translate('system')),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.restart_alt),
              onPressed: () => resetOnboarding(context, localizations),
              label: Text(localizations.translate('reset_onboarding')),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileInfoRow {
  final String label;
  final String value;
  final List<Widget>? actions;
  ProfileInfoRow({required this.label, required this.value, this.actions});
}

class _ProfileInfoTable extends StatelessWidget {
  final List<ProfileInfoRow> rows;
  const _ProfileInfoTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),        // label
        1: FixedColumnWidth(30),          // spacer
        2: FlexColumnWidth(),             // value
        3: IntrinsicColumnWidth(),        // actions
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (final r in rows)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  r.label,
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox.shrink(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Text(
                  r.value,
                  style: textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 0),
                child: (r.actions != null && r.actions!.isNotEmpty)
                    ? Row(mainAxisSize: MainAxisSize.min, children: r.actions!)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
      ],
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
