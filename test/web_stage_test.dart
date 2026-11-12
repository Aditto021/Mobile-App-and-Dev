import 'package:feriwala/core/theme/app_theme.dart';
import 'package:feriwala/data/state/shop_state.dart';
import 'package:feriwala/shared/widgets/web_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Pumps WebStage in a window of [window] size and returns the screen size
/// the app inside it sees.
Future<Size> appScreenIn(WidgetTester tester, Size window) async {
  tester.view.physicalSize = window;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late Size seen;
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => Shop(),
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => WebStage(child: child!),
        home: Builder(
          builder: (context) {
            seen = MediaQuery.sizeOf(context);
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  expect(tester.takeException(), isNull);
  return seen;
}

void main() {
  testWidgets('phones use the whole window', (tester) async {
    expect(
      await appScreenIn(tester, const Size(390, 844)),
      const Size(390, 844),
    );
  });

  testWidgets('tablets show the app in a phone-sized frame', (tester) async {
    final screen = await appScreenIn(tester, const Size(820, 1180));
    expect(screen.width, 412);
    expect(screen.height, lessThanOrEqualTo(1180 - 48));
  });

  testWidgets('desktops add the showcase beside the frame', (tester) async {
    final screen = await appScreenIn(tester, const Size(1440, 900));
    expect(screen, const Size(412, 852));
    expect(find.text('bKash, Nagad, card or cash'), findsOneWidget);
  });

  testWidgets('windows too short for a frame use the whole window', (
    tester,
  ) async {
    expect(
      await appScreenIn(tester, const Size(1280, 560)),
      const Size(1280, 560),
    );
  });
}
