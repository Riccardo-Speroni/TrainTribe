import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/loading_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'widgets/locale_theme_selector.dart';
import 'widgets/profile_info_box.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Removed duplicate upload code (handled elsewhere if needed)

  // Legacy handlers removed (handled by ProfilePicturePicker)

  // Picture change handled within ProfilePicturePicker in modular widget.

  // Language & theme saving now handled by LocaleThemeSelector widget.


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
