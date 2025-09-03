import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';
import '../utils/phone_number_helper.dart';

// Dialog per modificare un semplice campo testuale (username, nome, cognome)
Future<void> showEditSimpleFieldDialog(
  BuildContext context,
  AppLocalizations l, {
  required String fieldKey,
  required String currentValue,
  required String Function() buildTitle,
  String? Function(String value)? validator,
  Future<String?> Function(String value)? asyncValidator,
}) async {
  final ctrl = TextEditingController(text: currentValue);
  String? errorText;
  StateSetter? setStateLocal;

  Future<void> save() async {
    final raw = ctrl.text.trim();
    if (validator != null) {
      final res = validator(raw);
      if (res != null) {
        final translated = l.translate(res);
        errorText = translated.isNotEmpty ? translated : res;
        setStateLocal?.call(() {});
        return;
      }
    }
  if (asyncValidator != null) {
      final res = await asyncValidator(raw);
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
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  await showDialog(
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

// Dialog per modificare / aggiungere il numero di telefono
Future<void> showEditPhoneDialog(BuildContext context, AppLocalizations l, String currentE164) async {
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
      setStateLocal(() { prefixError = null; numberError = null; });
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

  await showDialog(
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
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
              },
              child: Text(l.translate('save')),
            ),
          ],
        );
      });
    },
  );
}
