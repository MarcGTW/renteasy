import 'package:flutter_test/flutter_test.dart';
import 'package:rent_easy/main.dart';

void main() {
  testWidgets('RentEasy smoke test', (WidgetTester tester) async {
    // Собираем приложение RentEasyApp и вызываем отрисовку кадра
    await tester.pumpWidget(const RentEasyApp());

    // Проверяем, что главный виджет успешно запустился
    expect(find.byType(RentEasyApp), findsOneWidget);
  });
}