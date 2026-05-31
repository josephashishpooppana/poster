import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/menu_screen.dart';
import 'services/anniversary_notification_service.dart';
import 'services/notification_router.dart';
import 'services/poster_fonts.dart';
import 'services/priest_repository.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  PosterFonts.ensureLoaded();
  runApp(const PosterApp());
}

class PosterApp extends StatefulWidget {
  const PosterApp({super.key});

  @override
  State<PosterApp> createState() => _PosterAppState();
}

class _PosterAppState extends State<PosterApp> {
  static const _permissionPromptKey = 'notification_permission_prompted';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await AnniversaryNotificationService.instance.initialize(
      onTap: NotificationRouter.handlePayload,
    );
    await PriestRepository.instance.initialize();
    await AnniversaryNotificationService.instance.rescheduleAll();
    await _handleLaunchNotification();
    if (!mounted) return;
    await _maybePromptForNotifications();
  }

  Future<void> _handleLaunchNotification() async {
    final details =
        await AnniversaryNotificationService.instance.launchDetails();
    final payload = details?.notificationResponse?.payload;
    if (payload != null && payload.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationRouter.handlePayload(payload);
      });
    }
  }

  Future<void> _maybePromptForNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_permissionPromptKey) == true) return;

    await prefs.setBool(_permissionPromptKey, true);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final context = NotificationRouter.navigatorKey.currentContext;
      if (context == null) return;

      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Anniversary reminders'),
          content: const Text(
            'The app can remind you at midnight on clergy birthdays and '
            'ordination anniversaries. Tap Create Poster on a reminder to '
            'open a prefilled poster draft.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Enable reminders'),
            ),
          ],
        ),
      );

      if (accepted == true) {
        await AnniversaryNotificationService.instance.requestPermissions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poster App — Diocese of Cochin',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      navigatorKey: NotificationRouter.navigatorKey,
      home: const MenuScreen(),
    );
  }
}
