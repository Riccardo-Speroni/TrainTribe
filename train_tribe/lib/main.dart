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
import 'services/app_services.dart';
import 'repositories/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'utils/app_globals.dart';
import 'widgets/app_rail.dart';
import 'widgets/app_bottom_navbar.dart';

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
  debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  debugPrint('Firebase initialized successfully');
  } catch (e) {
  debugPrint('Failed to initialize Firebase: $e');
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

  final services = AppServices(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    userRepository: FirestoreUserRepository(FirebaseFirestore.instance),
  );
  runApp(AppServicesScope(services: services, child: const MyApp()));
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
  debugPrint('Redirecting to onboarding page...');
        return '/onboarding';
      }

      // Rule 2: If not logged in, allow only onboarding/login/signup. Anything else -> login
      if (user == null) {
        final path = state.fullPath ?? '';
        const allowedUnauthed = ['/onboarding', '/login', '/signup'];
        if (!allowedUnauthed.contains(path)) {
          debugPrint('Unauthenticated, redirecting to login page...');
          return '/login';
        }
      }

      // Rule 3: Check if the user's profile is complete
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!userDoc.exists || userDoc.data()?['username'] == null) {
          // Redirect to complete_signup if profile is incomplete
          debugPrint('Redirecting to complete_signup page...');
          //FirebaseAuth.instance.signOut();  // DEBUG PURPOSES
          return '/complete_signup';
          // Rule 4: Redirect to root if already logged in and on login/signup page
        } else if (state.fullPath == '/login' || state.fullPath == '/signup') {
          debugPrint('Already logged in, redirecting to root page...');
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
  indicatorColor: scheme.primary.withValues(alpha: 0.15),
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
    final bool extended = railExpanded;

    List<Widget> pages = [
      const HomePage(),
      const FriendsPage(),
      const TrainsPage(),
      CalendarPage(railExpanded: railExpanded),
      const ProfilePage(),
    ];

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            Material(
              elevation: 1,
              color: Theme.of(context).colorScheme.surface,
              child: AppRail(
                titles: titles,
                currentIndex: currentPage,
                onSelect: (i) => setState(() => currentPage = i),
                expanded: extended,
                onToggleExpanded: (value) => setState(() => railExpanded = value),
              ),
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
      bottomNavigationBar: AppBottomNavBar(
        titles: titles,
        currentIndex: currentPage,
        onDestinationSelected: (index) => setState(() => currentPage = index),
      ),
    );
  }
}


