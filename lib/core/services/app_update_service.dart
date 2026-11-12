/// MODULE: App update service — In the direct-download build only, checks
/// the online release feed for a newer APK and shows the download / install
/// dialog (Android, via a platform channel). The Google Play build leaves
/// updates to Play.
///
/// Contains: AppUpdateInfo, AppUpdates, _UpdateDialog, _UpdateDialogState.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/brand_config.dart';

class AppUpdateInfo {
  final bool feedReady;
  final bool available;
  final String versionName;
  final String notes;

  const AppUpdateInfo({
    required this.feedReady,
    required this.available,
    required this.versionName,
    required this.notes,
  });

  factory AppUpdateInfo.fromMap(Map<String, dynamic> data) => AppUpdateInfo(
    feedReady: data['feedReady'] == true,
    available: data['available'] == true,
    versionName: data['versionName'] as String? ?? '',
    notes: data['notes'] as String? ?? '',
  );
}

class AppUpdates {
  static const channel = MethodChannel('feriwala/updates');

  /// Direct-download build (`--dart-define=SIDELOAD=true`). The Google Play
  /// build leaves updates to Play and never installs packages itself.
  static bool sideload = const bool.fromEnvironment('SIDELOAD');

  static bool get supported =>
      sideload && !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// The app version, in any build.
  static bool get canReadVersion =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static Future<String> get version async =>
      canReadVersion ? await channel.invokeMethod<String>('version') ?? '' : '';
  static Future<AppUpdateInfo> check() async => AppUpdateInfo.fromMap(
    await channel.invokeMapMethod<String, dynamic>('check') ?? {},
  );
}

bool _checking = false;
bool _dialogOpen = false;
DateTime? _lastAutomaticCheck;

Future<void> checkForAppUpdates(
  BuildContext context, {
  bool automatic = false,
}) async {
  if (!AppUpdates.supported) {
    if (!automatic) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Install the Android app to use online updates.'),
        ),
      );
    }
    return;
  }
  if (_checking || _dialogOpen) return;
  final now = DateTime.now();
  if (automatic &&
      _lastAutomaticCheck != null &&
      now.difference(_lastAutomaticCheck!) < const Duration(minutes: 15)) {
    return;
  }
  if (automatic) _lastAutomaticCheck = now;
  _checking = true;
  if (!automatic) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking for updates…'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  try {
    final update = await AppUpdates.check();
    if (!context.mounted) return;
    if (update.available) {
      _dialogOpen = true;
      try {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _UpdateDialog(update: update),
        );
      } finally {
        _dialogOpen = false;
      }
    } else if (!automatic) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            update.feedReady
                ? 'You have the latest version.'
                : 'The online update feed has not been published yet.',
          ),
        ),
      );
    }
  } on PlatformException catch (error) {
    if (!automatic && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ??
                'Could not check for updates. Try again when online.',
          ),
        ),
      );
    }
  } finally {
    _checking = false;
  }
}

class _UpdateDialog extends StatefulWidget {
  final AppUpdateInfo update;
  const _UpdateDialog({required this.update});
  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _busy = false;
  bool _downloaded = false;
  bool _needsPermission = false;
  String? _message;

  Future<void> _update() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (!_downloaded) {
        await AppUpdates.channel.invokeMethod<bool>('download');
        _downloaded = true;
      }
      final opened =
          await AppUpdates.channel.invokeMethod<bool>('install') ?? false;
      if (!mounted) return;
      if (opened) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _needsPermission = true;
          _message =
              'Allow ${Brand.appName} to install updates in Android settings, then return here and tap Install.';
        });
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _message = error.message ?? 'Update failed. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _settings() async {
    try {
      await AppUpdates.channel.invokeMethod<void>('allowInstalls');
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _message =
              error.message ?? 'Open Android app settings to allow updates.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text('Update to ${widget.update.versionName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _busy
                  ? 'Downloading and verifying your update. Keep the app open…'
                  : widget.update.notes.isNotEmpty
                  ? widget.update.notes
                  : 'A new version is ready to install.',
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: LinearProgressIndicator(),
              ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_message!),
              ),
            if (!_busy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Android will ask you to confirm installation. Your saved app data will stay on this device.',
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
        if (_needsPermission)
          TextButton(
            onPressed: _busy ? null : _settings,
            child: const Text('Open settings'),
          ),
        FilledButton(
          onPressed: _busy ? null : _update,
          child: Text(_downloaded ? 'Install' : 'Download update'),
        ),
      ],
    ),
  );
}
