// This file is ONLY used in widget tests to exercise layout logic of the real RootPage
// without triggering Firebase dependent pages (e.g., FriendsPage using AppServices).
// It mirrors the navigation structure with placeholder widgets.
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_bottom_navbar.dart';
import '../widgets/app_rail.dart';

class TestRootPage extends StatefulWidget {
  const TestRootPage({super.key});

  @override
  State<TestRootPage> createState() => _TestRootPageState();
}

class _TestRootPageState extends State<TestRootPage> {
  int currentPage = 0;
  bool railExpanded = false;

  List<String> pageTitles(BuildContext context) => [
        AppLocalizations.of(context).translate('home'),
        AppLocalizations.of(context).translate('friends'),
        AppLocalizations.of(context).translate('trains'),
        AppLocalizations.of(context).translate('calendar'),
        AppLocalizations.of(context).translate('profile'),
      ];

  @override
  Widget build(BuildContext context) {
    final titles = pageTitles(context);
    final width = MediaQuery.of(context).size.width;
    const railThreshold = 600.0;
    final useRail = width >= railThreshold;
    final pages = [
      const _Stub(label: 'home'),
      const _Stub(label: 'friends'),
      const _Stub(label: 'trains'),
      const _Stub(label: 'calendar'),
      const _Stub(label: 'profile'),
    ];
    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            Material(
              elevation: 1,
              child: AppRail(
                titles: titles,
                currentIndex: currentPage,
                onSelect: (i) => setState(() => currentPage = i),
                expanded: railExpanded,
                onToggleExpanded: (v) => setState(() => railExpanded = v),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: pages[currentPage]),
          ],
        ),
      );
    }
    return Scaffold(
      body: pages[currentPage],
      bottomNavigationBar: AppBottomNavBar(
        titles: titles,
        currentIndex: currentPage,
        onDestinationSelected: (i) => setState(() => currentPage = i),
      ),
    );
  }
}

class _Stub extends StatelessWidget {
  final String label;
  const _Stub({required this.label});
  @override
  Widget build(BuildContext context) => Center(child: Text(label));
}
