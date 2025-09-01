import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'friends_page.dart';
import 'trains_page.dart';
import 'calendar_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'complete_signup.dart';
import 'onboarding_page.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_size/window_size.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'utils/app_globals.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Set the minimum window size only on desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowMinSize(const Size(800, 500));
  }

  final String? languageCode = prefs.getString('language_code');
  appLocale.value = languageCode != null ? Locale(languageCode) : PlatformDispatcher.instance.locale;

  final int? themeModeIndex = prefs.getInt('theme_mode');
  appTheme.value = themeModeIndex != null
      ? (themeModeIndex == 0 ? ThemeMode.light : (themeModeIndex == 1 ? ThemeMode.dark : ThemeMode.system))
      : ThemeMode.system;

  // Initialize Firebase
  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }

  const useEmulator = false; // Set to true to use Firebase emulators

  // ignore: dead_code
  if (useEmulator) {
    // Firestore
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    // Auth
    FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    // Storage
    FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
    // Functions
    FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
  }

  runApp(MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Local Notifications
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();

    // Note: Since Windows is not supported by flutter_local_notifications, we don't use them on Windows.
    if(!Platform.isWindows)
    {
      _initNotifications();
      _startNotificationPolling();
    }
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initNotifications() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _startNotificationPolling() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final notificationsRef = FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid);

      final querySnapshot = await notificationsRef.get();
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final title = data['title'] ?? 'Notifica';
        final description = data['description'] ?? '';
        await _flutterLocalNotificationsPlugin.show(
          doc.id.hashCode,
          title,
          description,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'custom_notifications',
              'Custom Notifications',
              channelDescription: 'Notifiche personalizzate',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
            macOS: DarwinNotificationDetails(),
          ),
        );
        // Elimina la notifica dopo averla mostrata
        await doc.reference.delete();
      }
    });
  }

  final GoRouter _router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/root',
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
      final user = FirebaseAuth.instance.currentUser; // Check current session

      // Rule 1: Redirect to onboarding if not completed
      if (!onboardingComplete && state.fullPath != '/onboarding') {
        print('Redirecting to onboarding page...');
        return '/onboarding';
      }

      // Rule 2: If not logged in, allow only onboarding/login/signup. Anything else -> login
      if (user == null) {
        final path = state.fullPath ?? '';
        const allowedUnauthed = ['/onboarding', '/login', '/signup'];
        if (!allowedUnauthed.contains(path)) {
          print('Unauthenticated, redirecting to login page...');
          return '/login';
        }
      }

      // Rule 3: Check if the user's profile is complete
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!userDoc.exists || userDoc.data()?['username'] == null) {
          // Redirect to complete_signup if profile is incomplete
          print('Redirecting to complete_signup page...');
          //FirebaseAuth.instance.signOut();  // DEBUG PURPOSES
          return '/complete_signup';
          // Rule 4: Redirect to root if already logged in and on login/signup page
        } else if (state.fullPath == '/login' || state.fullPath == '/signup') {
          print('Already logged in, redirecting to root page...');
          return '/root';
        }
      }

      // No redirection needed
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),
      GoRoute(path: '/root', builder: (context, state) => const RootPage()),
      GoRoute(
        path: '/complete_signup',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?; // Retrieve extra data
          return CompleteSignUpPage(
            email: extra?['email'],
            name: extra?['name'],
            profilePicture: extra?['profilePicture'],
          );
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, child) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: appTheme,
          builder: (context, themeMode, child) {
            return MaterialApp.router(
              routerConfig: _router, // Use GoRouter for navigation
              debugShowCheckedModeBanner: false,
              theme: _buildAppTheme(Brightness.light),
              darkTheme: _buildAppTheme(Brightness.dark),
              themeMode: themeMode, // Use appTheme for theme mode
              locale: locale, // Set the current locale
              localizationsDelegates: const [
                AppLocalizations.delegate, // Custom localization delegate
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'), // English
                Locale('it'), // Italian
              ],
            );
          },
        );
      },
    );
  }
}

ThemeData _buildAppTheme(Brightness brightness) {
  final base = brightness == Brightness.light ? ThemeData.light() : ThemeData.dark();
  final scheme = base.colorScheme.copyWith(primary: Colors.green);
  return base.copyWith(
    colorScheme: scheme,
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: scheme.primary.withOpacity(0.15),
      backgroundColor: base.navigationBarTheme.backgroundColor, // keep default
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: scheme.primary);
        }
        return IconThemeData(color: scheme.onSurfaceVariant);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final style = const TextStyle(fontSize: 12);
        if (states.contains(WidgetState.selected)) {
          return style.copyWith(color: scheme.primary, fontWeight: FontWeight.w600);
        }
        return style.copyWith(color: scheme.onSurfaceVariant);
      }),
    ),
  );
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int currentPage = 0;
  // Stato per l'espansione manuale della rail quando non si è ancora nella soglia extended
  bool railExpanded = false;

  List<String> pageTitles(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return [
      localizations.translate('home'),
      localizations.translate('friends'),
      localizations.translate('trains'),
      localizations.translate('calendar'),
      localizations.translate('profile'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final titles = pageTitles(context);
    final width = MediaQuery.of(context).size.width;
    const railThreshold = 600.0;   // da questa larghezza in su mostra la rail
    final bool useRail = width >= railThreshold;
    // Stato extended determinato solo dal toggle manuale ora
    final bool extended = railExpanded;

    List<Widget> pages = [
      const HomePage(),
      const FriendsPage(),
      const TrainsPage(),
      CalendarPage(railExpanded: railExpanded),
      const ProfilePage(),
    ];

    if (useRail) {
      // Rail personalizzata sempre comprimibile/espandibile
      final ColorScheme scheme = Theme.of(context).colorScheme;
      final TextStyle labelStyle = Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 14);

      double _computeMaxLabelWidth() {
        double maxW = 0;
        final TextDirection textDirection = Directionality.of(context);
        for (final t in titles) {
          final tp = TextPainter(
            text: TextSpan(text: t, style: labelStyle),
            maxLines: 1,
            textDirection: textDirection,
          )..layout();
          if (tp.width > maxW) maxW = tp.width;
        }
        return maxW;
      }

      final double collapsedWidth = 72; // larghezza base stile NavigationRail
      final double hPad = 16; // padding orizzontale interno
      final double gap = 12;  // gap tra icona e label
      final double maxLabelWidth = extended ? _computeMaxLabelWidth() : 0;
      final double dynamicExtendedWidth = collapsedWidth + (maxLabelWidth > 0 ? (maxLabelWidth + gap + hPad) : 0);

      Widget buildDestination(int index) {
        final bool selected = currentPage == index;
        final Color selectedIconColor = scheme.primary;
        final Color unselectedIconColor = scheme.onSurfaceVariant;
        final Color selectedBg = scheme.primary.withOpacity(0.12);
        final iconList = [
          Icons.home,
          Icons.people,
          Icons.train,
          Icons.calendar_today,
          Icons.person,
        ];
        final icon = Icon(iconList[index], color: selected ? selectedIconColor : unselectedIconColor, size: 24);
        final label = Text(titles[index], style: labelStyle.copyWith(
          color: selected ? selectedIconColor : scheme.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ));
        return SizedBox(
          height: 56,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => currentPage = index),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: selected ? selectedBg : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  icon,
                  if (extended) ...[
                    SizedBox(width: gap),
                    Flexible(child: label),
                  ],
                ],
              ),
            ),
          ),
        );
      }

      Widget buildRail() {
        return LayoutBuilder(
          builder: (context, constraints) {
            final int itemCount = titles.length;
            const double itemHeight = 56;
            const double itemSpacing = 8; // margin vertical complessiva (4+4)
            final double contentHeight = itemCount * itemHeight + (itemCount - 1) * itemSpacing;
            const double toggleTotalHeight = 52; // bottone + padding
            final double available = constraints.maxHeight;
            double topPad = (available - toggleTotalHeight - contentHeight) / 2;
            if (topPad < 12) topPad = 12;

            if (!extended) {
              return SizedBox(
                width: collapsedWidth,
                child: Column(
                  children: [
                    SizedBox(height: topPad),
                    for (int i = 0; i < titles.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => setState(() => currentPage = i),
                          child: Container(
                            width: 56,
                            height: itemHeight,
                            decoration: BoxDecoration(
                              color: currentPage == i ? scheme.primary.withOpacity(0.12) : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              [Icons.home, Icons.people, Icons.train, Icons.calendar_today, Icons.person][i],
                              color: currentPage == i ? scheme.primary : scheme.onSurfaceVariant,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RailToggleButton(
                        expanded: false,
                        onPressed: () => setState(() => railExpanded = true),
                      ),
                    ),
                  ],
                ),
              );
            }

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: dynamicExtendedWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: topPad),
                  for (int i = 0; i < titles.length; i++) buildDestination(i),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _RailToggleButton(
                        expanded: true,
                        onPressed: () => setState(() => railExpanded = false),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }

      return Scaffold(
        body: Row(
          children: [
            Material(
              elevation: 1,
              color: Theme.of(context).colorScheme.surface,
              child: buildRail(),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: pages[currentPage],
              ),
            ),
          ],
        ),
      );
    }

    // Layout compatto: NavigationBar in basso
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: pages[currentPage],
      ),
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home), label: titles[0]),
          NavigationDestination(icon: const Icon(Icons.people), label: titles[1]),
          NavigationDestination(icon: const Icon(Icons.train), label: titles[2]),
          NavigationDestination(icon: const Icon(Icons.calendar_today), label: titles[3]),
          NavigationDestination(icon: const Icon(Icons.person), label: titles[4]),
        ],
        onDestinationSelected: (int index) {
          setState(() { currentPage = index; });
        },
        selectedIndex: currentPage,
      ),
    );
  }
}

class _RailToggleButton extends StatelessWidget {
  final bool expanded;
  final VoidCallback onPressed;
  const _RailToggleButton({required this.expanded, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceVariant.withOpacity(0.8),
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            expanded ? Icons.chevron_left : Icons.chevron_right,
            size: 22,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

