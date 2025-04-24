import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'dart:io';

class FirebaseExceptionHandler {
  static String signInErrorMessage(BuildContext context, String errorCode) {
    final localizations = AppLocalizations.of(context);

    if (Platform.isWindows && errorCode == "unknown-error") {
      return localizations.translate("firebase_windows_error");
    }

    switch (errorCode) {
      case 'email-already-in-use':
        return localizations.translate('error_email_already_in_use');
      case 'invalid-email':
        return localizations.translate('error_invalid_email');
      case 'operation-not-allowed':
        return localizations.translate('error_operation_not_allowed');
      case 'weak-password':
        return localizations.translate('error_weak_password');
      case 'too-many-requests':
        return localizations.translate('error_too_many_requests');
      case 'user-token-expired':
        return localizations.translate('error_user_token_expired');
      case 'network-request-failed':
        return localizations.translate('error_network_request_failed');
      default:
        return localizations.translate('error_unexpected');
    }
  }

  static String logInErrorMessage(BuildContext context, String errorCode) {
    final localizations = AppLocalizations.of(context);

    if (Platform.isWindows && errorCode == "unknown-error") {
      return localizations.translate("firebase_windows_error");
    }

    switch (errorCode) {
      case "invalid-credential":
        return localizations.translate("login_error_credentials");
      case "invalid-email":
        return localizations.translate("login_error_credentials");
      case "wrong-password":
        return localizations.translate("login_error_credentials");
      case "user-not-found":
        return localizations.translate("login_error_credentials");
      case "user-disabled":
        return localizations.translate("login_error_user_disabled");
      case "too-many-requests":
        return localizations.translate("login_error_generic");
      case "operation-not-allowed":
        return localizations.translate("login_error_generic");
      case "network-request-failed":
        return localizations.translate("login_error_no_internet");
      default:
        return localizations.translate("login_error_generic");
    }
  }
}
