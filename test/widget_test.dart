import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rent_easy/data/auth_api.dart';
import 'package:rent_easy/data/token_store.dart';
import 'package:rent_easy/main.dart';
import 'package:rent_easy/router.dart';

void main() {
  setUpAll(() {
    router = buildRouter(initialLocation: '/login');
  });

  testWidgets('RentEasy smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      Provider<AuthApi>(
        create: (_) => AuthApi('http://localhost:8080', TokenStore()),
        child: const RentEasyApp(),
      ),
    );

    expect(find.byType(RentEasyApp), findsOneWidget);
    expect(find.text('Вход в RentEasy'), findsOneWidget);
  });
}
