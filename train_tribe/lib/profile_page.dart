import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/loading_indicator.dart';
import 'utils/phone_number_helper.dart';
import 'utils/app_globals.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'widgets/profile_picture_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Removed duplicate upload code (handled elsewhere if needed)

  // Legacy handlers removed (handled by ProfilePicturePicker)

  void _showChangePictureDialog(AppLocalizations l, String username) {
    // Kept for compatibility if other code calls it; now opens the reusable picker directly.
    // The ProfilePicturePicker itself opens its internal dialog on tap.
  }

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
    GoRouter.of(context).go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return SafeArea(
        child: Center(child: Text(localizations.translate('error_loading_profile'))),
      );
    }
    return SafeArea(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
            onEditPicture: () => _showChangePictureDialog(localizations, username),
            stacked: !isWide, // pass layout info
          );

          return LayoutBuilder(builder: (ctx, constraints) {
            // Common top-right controls (language + theme dropdowns)
            Widget topRightControls = Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Lingua (icona)
                PopupMenuButton<Locale>(
                  tooltip: localizations.translate('change_language'),
                  icon: const Icon(Icons.language),
                  onSelected: (loc) => _saveLanguagePreference(loc),
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: const Locale('en'),
                      child: Row(
                        children: [
                          if (localizations.languageCode() == 'en') const Icon(Icons.check, size: 16),
                          if (localizations.languageCode() == 'en') const SizedBox(width: 6),
                          const Text('English'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: const Locale('it'),
                      child: Row(
                        children: [
                          if (localizations.languageCode() == 'it') const Icon(Icons.check, size: 16),
                          if (localizations.languageCode() == 'it') const SizedBox(width: 6),
                          const Text('Italiano'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 2), // era 4, ora più stretto
                // Tema (icona)
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: appTheme,
                  builder: (context, mode, _) {
                    IconData icon;
                    switch (mode) {
                      case ThemeMode.light:
                        icon = Icons.light_mode;
                        break;
                      case ThemeMode.dark:
                        icon = Icons.dark_mode;
                        break;
                      case ThemeMode.system:
                        icon = Icons.brightness_4;
                        break;
                    }
                    return PopupMenuButton<ThemeMode>(
                      tooltip: localizations.translate('change_theme'),
                      icon: Icon(icon),
                      onSelected: (m) {
                        int idx = m == ThemeMode.light
                            ? 0
                            : (m == ThemeMode.dark ? 1 : 2);
                        _saveThemePreference(idx);
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: ThemeMode.light,
                          child: Row(
                            children: [
                              if (mode == ThemeMode.light) const Icon(Icons.check, size: 16),
                              if (mode == ThemeMode.light) const SizedBox(width: 6),
                              Text(localizations.translate('light')),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: ThemeMode.dark,
                          child: Row(
                            children: [
                              if (mode == ThemeMode.dark) const Icon(Icons.check, size: 16),
                              if (mode == ThemeMode.dark) const SizedBox(width: 6),
                              Text(localizations.translate('dark')),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: ThemeMode.system,
                          child: Row(
                            children: [
                              if (mode == ThemeMode.system) const Icon(Icons.check, size: 16),
                              if (mode == ThemeMode.system) const SizedBox(width: 6),
                              Text(localizations.translate('system')),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            );

            // Bottom action buttons: equal width, edges aligned; wrap on very narrow
            const double gap = 12;
            const double targetWidth = 200; // larghezza desiderata massima
            const double minBtnWidth = 130; // larghezza minima prima di andare a wrap
            const double horizontalPadding = 32; // padding totale (16 + 16)
            final double effectiveWidth = constraints.maxWidth - horizontalPadding;
            final double available = effectiveWidth - gap;
            double btnWidth = targetWidth;
              if (available < targetWidth * 2) {
                btnWidth = available / 2; // si adatta
              }
            final bool wrapLayout = (available / 2) < minBtnWidth; // troppo stretto per due affiancati

            List<Widget> buildButtons(double width) => [
                  SizedBox(
                    width: width,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.restart_alt),
                      onPressed: () => _resetOnboarding(context, localizations),
                      label: Text(
                        localizations.translate('reset_onboarding'),
                        softWrap: true,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        GoRouter.of(context).go('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      label: Text(
                        localizations.translate('logout'),
                        softWrap: true,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ];

            Widget bottomActions;
            if (wrapLayout) {
              final buttons = buildButtons(double.infinity);
              bottomActions = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buttons[0],
                  const SizedBox(height: gap),
                  buttons[1],
                ],
              );
            } else {
              final btns = buildButtons(btnWidth);
              bottomActions = Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: btns,
              );
            }

            if (isWide) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            topRightControls,
                            const SizedBox(height: 16),
                            profileBox,
                            const SizedBox(height: 16),
                            bottomActions,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }

            // Narrow layout scrollable
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                topRightControls,
                const SizedBox(height: 4), // era 16, ora più stretto
                profileBox,
                const SizedBox(height: 16),
                bottomActions,
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
      ),
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
  final VoidCallback onEditPicture;
  final bool stacked;

  const _ProfileInfoBox({
    required this.username,
    required this.name,
    required this.surname,
    required this.email,
    required this.phone,
    required this.picture,
    required this.localizations,
    required this.onEditPicture,
  this.stacked = false,
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
              ProfilePicturePicker(
                firstName: name,
                lastName: surname,
                username: username,
                initialImageUrl: picture is String ? picture : null,
                onSelection: (sel) async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;
                  final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
                  if (sel.removed) {
                    await ref.update({'picture': FieldValue.delete()});
                  } else if (sel.generatedAvatarUrl != null) {
                    await ref.update({'picture': sel.generatedAvatarUrl});
                  } else if (sel.pickedFile != null) {
                    // Upload picked file (reuse existing method?) For simplicity, delegate to outer handler
                    // Not implemented here to avoid duplicating upload logic; could be extended.
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context).translate('saved'))),
                  );
                },
                size: 120,
              ),
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
                    extra: IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: localizations.translate('copy_username'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () {
                        final toCopy = username.isNotEmpty ? username : '';
                        if (toCopy.isEmpty) return;
                        Clipboard.setData(ClipboardData(text: toCopy));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(localizations.translate('copied'))),
                        );
                      },
                    ),
                    actions: [
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _showEditSimpleFieldDialog(
                          context,
                          localizations,
                          fieldKey: 'username',
                          currentValue: username,
                          buildTitle: () => '${localizations.translate('edit')} ${localizations.translate('username')}',
                          validator: (v) {
                            final trimmed = v.trim();
                            if (trimmed.isEmpty) return 'invalid';
                            if (trimmed.length < 3) return 'invalid';
                            // Allow letters, numbers, underscore, dot
                            final reg = RegExp(r'^[A-Za-z0-9._-]{3,}$');
                            if (!reg.hasMatch(trimmed)) return 'invalid';
                            return null;
                          },
                          asyncValidator: (v) async {
                            final trimmed = v.trim();
                            if (trimmed == username) return null; // unchanged
                            final snap = await FirebaseFirestore.instance
                                .collection('users')
                                .where('username', isEqualTo: trimmed)
                                .limit(1)
                                .get();
                            if (snap.docs.isNotEmpty) return 'error_username_taken';
                            return null;
                          },
                        ),
                        child: Text(localizations.translate('edit')),
                      ),
                    ],
                  ),
                  ProfileInfoRow(
                    label: localizations.translate('name'),
                    value: name.isNotEmpty ? name : '-',
                    actions: [
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _showEditSimpleFieldDialog(
                          context,
                          localizations,
                          fieldKey: 'name',
                          currentValue: name,
                          buildTitle: () => '${localizations.translate('edit')} ${localizations.translate('name')}',
                          validator: (v) {
                            final t = v.trim();
                            if (t.isEmpty) return 'invalid';
                            if (t.length > 40) return 'invalid';
                            return null;
                          },
                        ),
                        child: Text(localizations.translate('edit')),
                      ),
                    ],
                  ),
                  ProfileInfoRow(
                    label: localizations.translate('surname'),
                    value: surname.isNotEmpty ? surname : '-',
                    actions: [
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _showEditSimpleFieldDialog(
                          context,
                          localizations,
                          fieldKey: 'surname',
                          currentValue: surname,
                          buildTitle: () => '${localizations.translate('edit')} ${localizations.translate('surname')}',
                          validator: (v) {
                            final t = v.trim();
                            if (t.isEmpty) return 'invalid';
                            if (t.length > 40) return 'invalid';
                            return null;
                          },
                        ),
                        child: Text(localizations.translate('edit')),
                      ),
                    ],
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
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _showEditPhoneDialog(
                            context, localizations, phone ?? ''),
                        child: Text(localizations.translate('edit')),
                      ),
                    ],
                  ),
                ],
                stackedLayout: stacked,
              ),
            ]),
      ),
    );
  }
}


class ProfileInfoRow {
  final String label;
  final String value;
  final List<Widget>? actions;
  final Widget? extra; // separate single control column (e.g., copy button)
  ProfileInfoRow({required this.label, required this.value, this.actions, this.extra});
}

class _ProfileInfoTable extends StatelessWidget {
  final List<ProfileInfoRow> rows;
  final bool stackedLayout; // when true (mobile) show label above value
  const _ProfileInfoTable({required this.rows, this.stackedLayout = false});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (stackedLayout) {
      const double rowGap = 10; // space between rows
      const double labelValueGap = 2; // space between label and its value
      const double controlRowHeight = 36; // uniform height for value/control line
      return Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rows[i].label,
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: labelValueGap),
                SizedBox(
                  height: controlRowHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            rows[i].value,
                            style: textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (rows[i].extra != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: SizedBox(
                            height: controlRowHeight,
                            child: Center(child: rows[i].extra!),
                          ),
                        ),
                      if (rows[i].actions != null && rows[i].actions!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: SizedBox(
                            height: controlRowHeight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: rows[i].actions!,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (i != rows.length - 1) const SizedBox(height: rowGap),
          ],
        ],
      );
    }

    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),        // label
        1: FixedColumnWidth(20),          // spacer
        2: FlexColumnWidth(),             // value
        3: IntrinsicColumnWidth(),        // copy / extra single control
        4: IntrinsicColumnWidth(),        // actions (edit etc.)
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
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: r.extra ?? const SizedBox.shrink(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
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

/// Generic dialog to edit a simple text field (username, name, surname...)
void _showEditSimpleFieldDialog(
  BuildContext context,
  AppLocalizations l, {
  required String fieldKey, // Firestore field name
  required String currentValue,
  required String Function() buildTitle,
  String? Function(String value)? validator, // sync validator (returns key/message or null)
  Future<String?> Function(String value)? asyncValidator, // async validator (e.g. uniqueness)
}) {
  final ctrl = TextEditingController(text: currentValue);
  String? errorText;
  StateSetter? setStateLocal; // to update error state inside dialog
  // Tracks async validation in progress
  bool isChecking = false; // ignore: unused_local_variable (used inside dialog builder closures)

  Future<void> save() async {
    final raw = ctrl.text.trim();
    if (validator != null) {
      final res = validator(raw);
      if (res != null) {
        // Try translating error key; fallback to raw.
        final translated = l.translate(res);
        errorText = translated.isNotEmpty ? translated : res;
        // Trigger rebuild by calling (setStateLocal) which we'll capture.
        setStateLocal?.call(() {});
        return;
      }
    }
    if (asyncValidator != null) {
      isChecking = true;
      setStateLocal?.call(() {});
      final res = await asyncValidator(raw);
      isChecking = false;
      if (res != null) {
        final translated = l.translate(res);
        errorText = translated.isNotEmpty ? translated : res;
        setStateLocal?.call(() {});
        return;
      }
      setStateLocal?.call(() {});
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({fieldKey: raw});
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.translate('saved'))),
    );
  }


  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          setStateLocal = setState;
          return AlertDialog(
            title: Text(buildTitle()),
            content: SizedBox(
              width: 400,
              child: TextField(
                controller: ctrl,
                autofocus: true,
                maxLength: 40,
                onSubmitted: (_) => save(),
                decoration: InputDecoration(
                  labelText: buildTitle(),
                  counterText: '',
                  errorText: errorText,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l.translate('cancel')),
              ),
              ElevatedButton(
                onPressed: save,
                child: Text(l.translate('save')),
              ),
            ],
          );
        },
      );
    },
  );
}
