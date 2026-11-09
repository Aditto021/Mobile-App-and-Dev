import 'package:feriwala/core/services/app_update_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AppUpdates.channel, null);
  });

  Widget harness() => MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => checkForAppUpdates(context),
          child: const Text('Check'),
        ),
      ),
    ),
  );

  testWidgets('unpublished feed does not claim the app is up to date', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          AppUpdates.channel,
          (call) async => {'feedReady': false, 'available': false},
        );
    await tester.pumpWidget(harness());
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    // The checking snackbar may be queued before the result snackbar.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(
      find.text('The online update feed has not been published yet.'),
      findsOneWidget,
    );
    expect(find.text('You have the latest version.'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('update download is explicit and opens the Android installer', (
    tester,
  ) async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AppUpdates.channel, (call) async {
          calls.add(call.method);
          if (call.method == 'check') {
            return {
              'feedReady': true,
              'available': true,
              'versionName': '1.2.0',
              'notes': 'Faster scrolling',
            };
          }
          return true;
        });
    await tester.pumpWidget(harness());
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.text('Update to 1.2.0'), findsOneWidget);
    expect(calls, ['check']);
    await tester.tap(find.text('Download update'));
    await tester.pumpAndSettle();
    expect(calls, ['check', 'download', 'install']);
    expect(find.text('Update to 1.2.0'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('install permission is requested only after the download', (
    tester,
  ) async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AppUpdates.channel, (call) async {
          calls.add(call.method);
          if (call.method == 'check') {
            return {
              'feedReady': true,
              'available': true,
              'versionName': '1.2.0',
            };
          }
          if (call.method == 'install') return false;
          return true;
        });
    await tester.pumpWidget(harness());
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download update'));
    await tester.pumpAndSettle();
    expect(find.text('Open settings'), findsOneWidget);
    expect(calls, ['check', 'download', 'install']);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(calls.last, 'allowInstalls');
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
