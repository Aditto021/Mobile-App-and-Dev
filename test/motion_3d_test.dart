import 'package:feriwala/core/theme/app_theme.dart';
import 'package:feriwala/features/checkout/card_preview_3d.dart';
import 'package:feriwala/shared/widgets/motion_3d.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  theme: AppTheme.dark,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(
      body: Center(child: SizedBox(width: 320, child: child)),
    ),
  ),
);

void main() {
  testWidgets('tilt cards still receive taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        Tilt3D(
          child: GestureDetector(
            onTap: () => taps++,
            child: const SizedBox(height: 120, child: Text('card')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('card'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('tilt is skipped when reduced motion is on', (tester) async {
    await tester.pumpWidget(
      host(const Tilt3D(child: Text('still')), reduceMotion: true),
    );
    expect(
      find.descendant(
        of: find.byType(Tilt3D),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
  });

  testWidgets('card preview shows typed digits, then flips for the CVV', (
    tester,
  ) async {
    final number = TextEditingController(text: '4111 1111');
    final expiry = TextEditingController(text: '08/29');
    final cvv = TextEditingController(text: '123');
    addTearDown(() {
      number.dispose();
      expiry.dispose();
      cvv.dispose();
    });
    Widget card(bool back) => host(
      CardPreview3D(
        number: number,
        expiry: expiry,
        cvv: cvv,
        holder: 'Aditi Rahman',
        showBack: back,
      ),
    );

    await tester.pumpWidget(card(false));
    expect(find.text('4111  1111  ••••  ••••'), findsOneWidget);
    expect(find.text('VISA'), findsOneWidget);
    expect(find.text('ADITI RAHMAN'), findsOneWidget);
    expect(find.text('08/29'), findsOneWidget);

    await tester.pumpWidget(card(true));
    await tester.pumpAndSettle();
    expect(find.text('•••'), findsOneWidget);
    expect(find.text('VISA'), findsNothing);
  });
}
