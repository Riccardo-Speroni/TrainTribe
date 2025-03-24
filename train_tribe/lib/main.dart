import 'package:flutter/material.dart';
import 'home_page.dart';
import 'friends_page.dart';
import 'trains_page.dart';
import 'calendar_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(MyApp());
}

ValueNotifier<bool> isLoggedIn = ValueNotifier(false);

class MyApp extends StatelessWidget {
  MyApp({super.key});

 final GoRouter _router = GoRouter(
  refreshListenable: isLoggedIn, // Listen for login state changes
  redirect: (context, state) {

    if (!isLoggedIn.value && state.fullPath != '/login' && state.fullPath != '/signup') {
      return '/login'; // Redirect to login if not logged in
    } else  if (isLoggedIn.value && state.fullPath == '/login'){
      return '/root'; // Redirect to home if already logged in
    }
    else {return null;}
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/root', builder: (context, state) => const RootPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),
  ],
);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router, // Use GoRouter for navigation
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draft'),
      ),
      body: pages[currentPage],
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Friends'),
          NavigationDestination(icon: Icon(Icons.train), label: 'Trains'),
          NavigationDestination(
              icon: Icon(Icons.calendar_today), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
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