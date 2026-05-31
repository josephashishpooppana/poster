import 'package:birthday_poster_app/screens/menu_screen.dart';
import 'package:birthday_poster_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('MenuScreen shows app title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const MenuScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Poster App'), findsOneWidget);
    expect(find.text('Birthday Poster'), findsOneWidget);
  });
}
