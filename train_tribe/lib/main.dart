import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Imposta la dimensione minima della finestra solo su piattaforme desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowMinSize(const Size(400, 600)); // Dimensione minima: 400x600
  }

  final String? languageCode = prefs.getString('language_code');
  appLocale.value = languageCode != null
      ? Locale(languageCode)
      : PlatformDispatcher.instance.locale;

  final int? themeModeIndex = prefs.getInt('theme_mode');
  appTheme.value = themeModeIndex != null
      ? (themeModeIndex == 0
          ? ThemeMode.light
          : (themeModeIndex == 1 ? ThemeMode.dark : ThemeMode.system))
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

  // Inizializza notifiche locali
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin,
    // Altre piattaforme se necessario
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Mostra una notifica di test
  // await flutterLocalNotificationsPlugin.show(
  //   0,
  //   'Test Notifica',
  //   'Questa è una notifica di test!',
  //   const NotificationDetails(
  //     android: AndroidNotificationDetails(
  //       'test_channel',
  //       'Test Channel',
  //       channelDescription: 'Canale per notifiche di test',
  //       importance: Importance.max,
  //       priority: Priority.high,
  //     ),
  //     iOS: DarwinNotificationDetails(),
  //     macOS: DarwinNotificationDetails(),
  //   ),
  // );

  runApp(MyApp());
}

ValueNotifier<Locale> appLocale =
    ValueNotifier(PlatformDispatcher.instance.locale);
ValueNotifier<ThemeMode> appTheme = ValueNotifier(ThemeMode.system);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  final GoRouter _router = GoRouter(
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

      // Rule 2: Redirect to login if not logged in and restrict access to login/signup pages
      if (user == null &&
          ((state.fullPath != '/login' && state.fullPath != '/signup') ||
              (state.fullPath == '/'))) {
        print('Redirecting to login page...');
        return '/login';
      }

      // Rule 3: Check if the user's profile is complete
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
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
      GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),
      GoRoute(path: '/root', builder: (context, state) => const RootPage()),
      GoRoute(
        path: '/complete_signup',
        builder: (context, state) {
          final extra =
              state.extra as Map<String, dynamic>?; // Retrieve extra data
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
              theme: ThemeData.light().copyWith(
                colorScheme: ThemeData.light().colorScheme.copyWith(
                      primary: Colors.green,
                    ),
              ), // Light theme
              darkTheme: ThemeData.dark().copyWith(
                colorScheme: ThemeData.dark().colorScheme.copyWith(
                      primary: Colors.green,
                    ),
              ), // Dark theme
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

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int currentPage = 0;
  List<Widget> pages = const [
    HomePage(),
    FriendsPage(),
    TrainsPage(),
    CalendarPage(),
    ProfilePage(),
  ];

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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Add padding to the page
        child: pages[currentPage],
      ),
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home), label: titles[0]),
          NavigationDestination(
              icon: const Icon(Icons.people), label: titles[1]),
          NavigationDestination(
              icon: const Icon(Icons.train), label: titles[2]),
          NavigationDestination(
              icon: const Icon(Icons.calendar_today), label: titles[3]),
          NavigationDestination(
              icon: const Icon(Icons.person), label: titles[4]),
        ],
        onDestinationSelected: (int index) {
          setState(() {
            currentPage = index;
          });
        },
        selectedIndex: currentPage,
      ),
    );
  }
}
