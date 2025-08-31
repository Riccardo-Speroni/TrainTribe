import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/app_globals.dart';
import 'package:go_router/go_router.dart';
import 'l10n/app_localizations.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    final List<Map<String, String>> onboardingData = [
      {
        'title': localizations.translate('onboarding_title_1'),
        'description': localizations.translate('onboarding_desc_1'),
  'icon': '🚆',
      },
      {
        'title': localizations.translate('onboarding_title_2'),
        'description': localizations.translate('onboarding_desc_2'),
  'icon': '📱',
      },
      {
        'title': localizations.translate('onboarding_title_3'),
        'description': localizations.translate('onboarding_desc_3'),
  'icon': '🗓️',
      },
      {
        'title': localizations.translate('onboarding_title_4'),
        'description': localizations.translate('onboarding_desc_4'),
  'icon': '👥↔️🚆',
      },
  {
    'title': localizations.translate('onboarding_title_5'),
    'description': localizations.translate('onboarding_desc_5'),
  'icon': '🎉',
  },
    ];

    Future<void> completeOnboarding() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      GoRouter.of(context).go('/root');
    }

    void goToNextPage() {
      if (_currentPage < onboardingData.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        completeOnboarding();
      }
    }

    void skipOnboarding() {
      completeOnboarding();
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          // First page: language selector
          if (_currentPage == 0)
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: PopupMenuButton<String>(
                tooltip: localizations.translate('language'),
                icon: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
                onSelected: (val) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('language_code', val);
                  appLocale.value = Locale(val);
                  setState(() {});
                },
                itemBuilder: (context) => [
                  CheckedPopupMenuItem(
                    value: 'en',
                    checked: appLocale.value.languageCode == 'en',
                    child: const Text('English'),
                  ),
                  CheckedPopupMenuItem(
                    value: 'it',
                    checked: appLocale.value.languageCode == 'it',
                    child: const Text('Italiano'),
                  ),
                ],
              ),
            )
          else if (isMobile)
            TextButton(
              onPressed: _currentPage == onboardingData.length - 1
                  ? completeOnboarding
                  : skipOnboarding,
              child: Text(
                localizations.translate(
                    _currentPage == onboardingData.length - 1 ? 'finish' : 'skip'),
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            )
          else
            TextButton(
              onPressed: skipOnboarding,
              child: Text(
                localizations.translate('skip'),
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: onboardingData.length,
              itemBuilder: (context, index) {
                final data = onboardingData[index];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 32 : 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        data['icon'] ?? '',
                        style: const TextStyle(fontSize: 64),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        data['title']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        data['description']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Desktop/Web: Back button; Mobile: empty space
                if (!isMobile)
                  TextButton(
                    onPressed: _currentPage == 0
                        ? null
                        : () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                    child: Text(localizations.translate('back')),
                  )
                else
                  const SizedBox(width: 64),
                // Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    onboardingData.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 12 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                // Desktop/Web: Next/Finish; Mobile: Finish only on last page else placeholder
                if (!isMobile)
                  TextButton(
                    onPressed: goToNextPage,
                    child: Text(
                      _currentPage == onboardingData.length - 1
                          ? localizations.translate('finish')
                          : localizations.translate('next'),
                    ),
                  )
                else
                  const SizedBox(width: 64),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}