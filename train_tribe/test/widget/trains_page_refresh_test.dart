import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:train_tribe/trains_page.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:train_tribe/services/app_services.dart';
import 'package:train_tribe/repositories/user_repository.dart';
import 'package:train_tribe/utils/train_confirmation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';

Widget _wrap(Widget child) {
  final firestore = FakeFirebaseFirestore();
  final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'u1'), signedIn: true);
  final services = AppServices(
    firestore: firestore,
    auth: auth,
    userRepository: FirestoreUserRepository(firestore),
  );
  return AppServicesScope(
    services: services,
    child: MaterialApp(
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: const [Locale('en'), Locale('it')],
      home: child,
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('it');
  });
  testWidgets('TrainsPage RefreshIndicator triggers onRefresh in testMode', (tester) async {
    // Provide a fake confirmation service to avoid touching real Firebase
    final fakeStore = _FakeConfirmationStore();
    final confirmationSvc = TrainConfirmationService(store: fakeStore);

    await tester.pumpWidget(_wrap(TrainsPage(
      testMode: true,
      confirmationServiceOverride: confirmationSvc,
      testUserId: 'u1',
    )));
    await tester.pumpAndSettle();
    // RefreshIndicator should wrap the ListView when not loading
    final indicator = find.byType(RefreshIndicator);
    expect(indicator, findsOneWidget);
    // Pull-to-refresh: drag down on the list
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    // Start refresh
    await tester.pump(const Duration(milliseconds: 500));
    // Let it settle
    await tester.pumpAndSettle();
  });
}

class _FakeConfirmationStore implements ConfirmationStore {
  final Map<String, bool> _map = {};

  String _key(String dateStr, String trainId, String userId) => '$dateStr|$trainId|$userId';

  @override
  Future<bool> getConfirmation({required String dateStr, required String trainId, required String userId}) async {
    return _map[_key(dateStr, trainId, userId)] ?? false;
  }

  @override
  Future<void> setConfirmation(
      {required String dateStr, required String trainId, required String userId, required bool confirmed, required Timestamp now}) async {
    _map[_key(dateStr, trainId, userId)] = confirmed;
  }
}
