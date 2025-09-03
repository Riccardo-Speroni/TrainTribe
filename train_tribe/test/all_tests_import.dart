// ignore_for_file: unused_import
// This file forces inclusion of top-level library files for coverage.
// Avoid importing part files directly (those with part-of directives) to prevent analyzer errors.

import 'package:train_tribe/main.dart';
import 'package:train_tribe/login_page.dart';
import 'package:train_tribe/signup_page.dart';
import 'package:train_tribe/home_page.dart';
import 'package:train_tribe/friends_page.dart';
import 'package:train_tribe/trains_page.dart';
import 'package:train_tribe/calendar_page.dart';
import 'package:train_tribe/profile_page.dart';
import 'package:train_tribe/complete_signup.dart';
import 'package:train_tribe/onboarding_page.dart';
import 'package:train_tribe/models/calendar_event.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:train_tribe/utils/app_globals.dart';
import 'package:train_tribe/utils/auth_adapter.dart';
import 'package:train_tribe/utils/calendar_functions.dart';
import 'package:train_tribe/utils/events_firebase.dart';
import 'package:train_tribe/utils/firebase_exception_handler.dart';
import 'package:train_tribe/utils/image_uploader.dart';
import 'package:train_tribe/utils/loading_indicator.dart';
import 'package:train_tribe/utils/phone_number_helper.dart';
import 'package:train_tribe/utils/profile_picture_widget.dart';
import 'package:train_tribe/utils/redirect_logic.dart';
import 'package:train_tribe/utils/station_names.dart';
import 'package:train_tribe/utils/train_confirmation.dart';
import 'package:train_tribe/dialogs/edit_profile_field_dialogs.dart';
import 'package:train_tribe/widgets/user_details_page.dart';
import 'package:train_tribe/widgets/train_card.dart';
import 'package:train_tribe/widgets/profile_picture_picker.dart';
import 'package:train_tribe/widgets/profile_info_box.dart';
import 'package:train_tribe/widgets/mood_toggle.dart';
import 'package:train_tribe/widgets/logo_pattern_background.dart';
import 'package:train_tribe/widgets/locale_theme_selector.dart';
import 'package:train_tribe/widgets/legend_dialog.dart';
// Calendar composite widgets (import public ones only if they are top-level libs)
import 'package:train_tribe/widgets/calendar_widgets/calendar_cells.dart';
import 'package:train_tribe/widgets/calendar_widgets/event_dialogs.dart';
import 'package:train_tribe/widgets/calendar_widgets/calendar_event_widget.dart';
import 'package:train_tribe/widgets/calendar_widgets/calendar_columns.dart';

void main() {}
