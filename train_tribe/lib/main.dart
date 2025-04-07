import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'friends_page.dart';
import 'trains_page.dart';
import 'calendar_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'onboarding_page.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final String? languageCode = prefs.getString('language_code');
  appLocale.value = languageCode != null
      ? Locale(languageCode)
      : PlatformDispatcher.instance.locale;

  final int? themeModeIndex = prefs.getInt('theme_mode');
  appTheme.value = themeModeIndex != null 
      ? (
        themeModeIndex == 0 ? ThemeMode.light 
        : (themeModeIndex == 1 ? ThemeMode.dark 
        : ThemeMode.system)
      ) : ThemeMode.system;

  runApp(MyApp());
}

ValueNotifier<bool> isLoggedIn = ValueNotifier(false);
ValueNotifier<Locale> appLocale = ValueNotifier(PlatformDispatcher.instance.locale);
ValueNotifier<ThemeMode> appTheme = ValueNotifier(ThemeMode.system);


class MyApp extends StatefulWidget {
  MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  final GoRouter _router = GoRouter(
    refreshListenable: isLoggedIn, // Listen for login state changes
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

      if (!onboardingComplete && state.fullPath != '/onboarding') {
        print('Redirecting to onboarding page...');
        return '/onboarding'; // Redirect to onboarding if not completed
      } else if (!isLoggedIn.value && state.fullPath != '/login' && state.fullPath != '/signup' && state.fullPath != '/onboarding') {
        print('Redirecting to login page...');
        return '/login'; // Redirect to login if not logged in
      } else if (isLoggedIn.value && state.fullPath == '/login') {
        print('Already logged in, redirecting to root page...');
        return '/root'; // Redirect to home if already logged in
      } else {
        return null; // No redirection
      }
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/root', builder: (context, state) => const RootPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),
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

bool checkUserLoginStatus() {
  // TODO: session authentication logic
  return false;
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
      body: pages[currentPage],
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home), label: titles[0]),
          NavigationDestination(icon: const Icon(Icons.people), label: titles[1]),
          NavigationDestination(icon: const Icon(Icons.train), label: titles[2]),
          NavigationDestination(icon: const Icon(Icons.calendar_today), label: titles[3]),
          NavigationDestination(icon: const Icon(Icons.person), label: titles[4]),
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