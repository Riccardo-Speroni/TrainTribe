import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../dialogs/edit_profile_field_dialogs.dart';
import 'profile_picture_picker.dart';
import 'package:flutter/services.dart';

class ProfileInfoBox extends StatelessWidget {
  final String username;
  final String name;
  final String surname;
  final String email;
  final String? phone;
  final dynamic picture;
  final AppLocalizations l;
  final bool stacked;
  const ProfileInfoBox({
    super.key,
    required this.username,
    required this.name,
    required this.surname,
    required this.email,
    required this.phone,
    required this.picture,
    required this.l,
    this.stacked = false,
  });

  // Testing overrides
  static bool debugBypassFirebase = false; // when true do not touch Firebase
  static Future<void> Function(String field, dynamic value)? debugUpdateField; // optional field update hook
  static bool debugHidePicturePicker = false; // for widget tests to avoid building picker

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
            if (!debugHidePicturePicker)
              ProfilePicturePicker(
              firstName: name,
              lastName: surname,
              username: username,
              initialImageUrl: picture is String ? picture : null,
              ringWidth: 5,
              onSelection: (sel) async {
                if (debugBypassFirebase) {
                  if (debugUpdateField != null) {
                    if (sel.removed) {
                      await debugUpdateField!.call('picture', null);
                    } else if (sel.generatedAvatarUrl != null) {
                      await debugUpdateField!.call('picture', sel.generatedAvatarUrl);
                    }
                  }
                  return;
                }
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;
                  final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
                  if (sel.removed) {
                    await ref.update({'picture': FieldValue.delete()});
                  } else if (sel.generatedAvatarUrl != null) {
                    await ref.update({'picture': sel.generatedAvatarUrl});
                  }
                } catch (_) {}
              },
              size: 120,
            ),
            const SizedBox(height: 8),
            Text(
              username.isNotEmpty ? username : l.translate('username'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(height: 32),
            _ProfileInfoTable(
              rows: _buildRows(context),
              stackedLayout: stacked,
            ),
          ],
        ),
      ),
    );
  }

  List<ProfileInfoRow> _buildRows(BuildContext context) {
    return [
      ProfileInfoRow(
        fieldKey: 'username',
        label: l.translate('username'),
        value: username.isNotEmpty ? username : '-',
        extra: IconButton(
          key: const Key('profile_username_copy_button'),
          icon: const Icon(Icons.copy, size: 18),
          tooltip: l.translate('copy_username'),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () {
            final toCopy = username.isNotEmpty ? username : '';
            if (toCopy.isEmpty) return;
            Clipboard.setData(ClipboardData(text: toCopy));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.translate('copied'))),
            );
          },
        ),
        actions: [
          TextButton(
            key: const Key('profile_username_edit_button'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => showEditSimpleFieldDialog(
              context,
              l,
              fieldKey: 'username',
              currentValue: username,
              buildTitle: () => '${l.translate('edit')} ${l.translate('username')}',
              validator: (v) {
                final trimmed = v.trim();
                if (trimmed.isEmpty) return 'invalid';
                if (trimmed.length < 3) return 'invalid';
                final reg = RegExp(r'^[A-Za-z0-9._-]{3,}$');
                if (!reg.hasMatch(trimmed)) return 'invalid';
                return null;
              },
              asyncValidator: (v) async {
                final trimmed = v.trim();
                if (trimmed == username) return null;
                final snap = await FirebaseFirestore.instance
                    .collection('users')
                    .where('username', isEqualTo: trimmed)
                    .limit(1)
                    .get();
                if (snap.docs.isNotEmpty) return 'error_username_taken';
                return null;
              },
            ),
            child: Text(l.translate('edit')),
          ),
        ],
      ),
      ProfileInfoRow(
        fieldKey: 'name',
        label: l.translate('name'),
        value: name.isNotEmpty ? name : '-',
        actions: [
          TextButton(
    key: const Key('profile_name_edit_button'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => showEditSimpleFieldDialog(
              context,
              l,
              fieldKey: 'name',
              currentValue: name,
              buildTitle: () => '${l.translate('edit')} ${l.translate('name')}',
              validator: (v) {
                final t = v.trim();
                if (t.isEmpty) return 'invalid';
                if (t.length > 40) return 'invalid';
                return null;
              },
            ),
            child: Text(l.translate('edit')),
          ),
        ],
      ),
  ProfileInfoRow(
        fieldKey: 'surname',
        label: l.translate('surname'),
        value: surname.isNotEmpty ? surname : '-',
        actions: [
          TextButton(
    key: const Key('profile_surname_edit_button'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => showEditSimpleFieldDialog(
              context,
              l,
              fieldKey: 'surname',
              currentValue: surname,
              buildTitle: () => '${l.translate('edit')} ${l.translate('surname')}',
              validator: (v) {
                final t = v.trim();
                if (t.isEmpty) return 'invalid';
                if (t.length > 40) return 'invalid';
                return null;
              },
            ),
            child: Text(l.translate('edit')),
          ),
        ],
      ),
  ProfileInfoRow(
    fieldKey: 'email',
    label: l.translate('email'),
    value: email.isNotEmpty ? email : '-',
      ),
  ProfileInfoRow(
    fieldKey: 'phone_number',
    label: l.translate('phone_number'),
    value: (phone != null && phone!.isNotEmpty) ? phone! : '-',
        actions: [
          TextButton(
    key: const Key('profile_phone_edit_button'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => showEditPhoneDialog(context, l, phone ?? ''),
            child: Text(l.translate('edit')),
          ),
        ],
      ),
    ];
  }
}

class ProfileInfoRow {
  final String label;
  final String value;
  final List<Widget>? actions;
  final Widget? extra;
  final String? fieldKey; // stable identifier independent of localized label
  ProfileInfoRow({required this.label, required this.value, this.actions, this.extra, this.fieldKey});
}

class _ProfileInfoTable extends StatelessWidget {
  final List<ProfileInfoRow> rows;
  final bool stackedLayout;
  const _ProfileInfoTable({required this.rows, this.stackedLayout = false});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (stackedLayout) {
      const double rowGap = 10;
      const double labelValueGap = 2;
      const double controlRowHeight = 36;
      return Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            Column(
              key: ValueKey('profile_row_' + (rows[i].fieldKey ?? rows[i].label.toLowerCase())),
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
        0: IntrinsicColumnWidth(),
        1: FixedColumnWidth(20),
        2: FlexColumnWidth(),
        3: IntrinsicColumnWidth(),
        4: IntrinsicColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (final r in rows)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  key: r.fieldKey != null ? ValueKey('profile_row_' + r.fieldKey!) : null,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      r.label,
                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
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
