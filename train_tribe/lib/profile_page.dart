import 'services/app_services.dart';
import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/loading_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/locale_theme_selector.dart';
import 'widgets/profile_info_box.dart';
import 'widgets/logo_title.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class ProfilePageTestOverrides {
  static bool? debugOverrideInitialized;
  static User? debugUser;
  static FirebaseFirestore? debugFirestore;
  static bool debugBypassFirebaseAuth = false; // when true, never touch FirebaseAuth.instance
  static Future<void> Function()? debugSignOutFn; // optional test hook
  static void reset() {
    debugOverrideInitialized = null;
    debugUser = null;
    debugFirestore = null;
    debugBypassFirebaseAuth = false;
    debugSignOutFn = null;
  }
}

class _ProfilePageState extends State<ProfilePage> {
  // Removed duplicate upload code (handled elsewhere if needed)

  // Legacy handlers removed (handled by ProfilePicturePicker)

  // Picture change handled within ProfilePicturePicker in modular widget.

  // Language & theme saving now handled by LocaleThemeSelector widget.

  // (Runtime uses Firebase.* directly; tests set values on ProfilePageTestOverrides)

  Future<void> _resetOnboarding(BuildContext context, AppLocalizations l) async {
    final router = GoRouter.of(context); // capture before await
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', false);
    if (!mounted) return;
    router.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final isInitialized = ProfilePageTestOverrides.debugOverrideInitialized ??
        (() {
          try {
            return Firebase.apps.isNotEmpty;
          } catch (_) {
            return false;
          }
        })();
    if (!isInitialized) {
      return const SafeArea(child: Center(child: Text('Firebase not initialized')));
    }
    User? user;
    if (ProfilePageTestOverrides.debugBypassFirebaseAuth) {
      user = ProfilePageTestOverrides.debugUser;
    } else {
      try {
        // Use injected AppServices auth if available, else fallback
        final services = AppServicesScope.of(context);
        user = ProfilePageTestOverrides.debugUser ?? (services.auth.currentUser);
      } catch (_) {
        user = ProfilePageTestOverrides.debugUser; // fallback
      }
    }
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          centerTitle: MediaQuery.of(context).size.width >= 600,
          title: const LogoTitle(),
        ),
        body: SafeArea(child: Center(child: Text(localizations.translate('error_loading_profile')))),
      );
    }
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: MediaQuery.of(context).size.width >= 600,
        title: const LogoTitle(),
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            final services = AppServicesScope.of(context);
            final firestore = ProfilePageTestOverrides.debugFirestore ?? services.firestore;
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: firestore.collection('users').doc(user!.uid).snapshots(),
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

                Widget profileBox = ProfileInfoBox(
                  username: username,
                  name: name,
                  surname: surname,
                  email: email,
                  phone: phone?.toString(),
                  picture: picture,
                  l: localizations,
                  stacked: !isWide,
                );
                // ...existing code...
                // (rest of builder unchanged)

                return LayoutBuilder(builder: (ctx, constraints) {
                  // Common top-right controls (language + theme dropdowns)
                  Widget topRightControls = const Align(
                    alignment: Alignment.centerRight,
                    child: LocaleThemeSelector(),
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
                            key: const Key('profile_reset_onboarding_button'),
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
                            key: const Key('profile_logout_button'),
                            icon: const Icon(Icons.logout),
                            onPressed: () async {
                              final router = GoRouter.of(context); // capture
                              if (ProfilePageTestOverrides.debugSignOutFn != null) {
                                await ProfilePageTestOverrides.debugSignOutFn!();
                              } else {
                                await AppServicesScope.of(context).auth.signOut();
                              }
                              if (!mounted) return;
                              router.go('/login');
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
                      key: const Key('profile_bottom_actions'),
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
                      key: const Key('profile_bottom_actions'),
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
            );
          },
        ),
      ),
    );
  }
}
