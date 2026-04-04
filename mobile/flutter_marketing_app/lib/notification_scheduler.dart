import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationScheduler {
  NotificationScheduler._();

  static final NotificationScheduler instance = NotificationScheduler._();

  static const String _channelId = 'avenor_marketing_updates';
  static const String _channelName = 'Avenor Marketing Updates';
  static const String _channelDescription =
      'Notifikasi dari superadmin untuk tim marketing.';
  static const String _notifiedNotificationIdsKey =
      'marketing_notified_notification_ids';
  static const String _readNotificationIdsKey =
      'marketing_read_notification_ids';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      ),
    );

    await _plugin.initialize(initializationSettings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
    ));

    _initialized = true;
  }

  Future<void> syncServerNotifications(
      List<Map<String, dynamic>> notifications) async {
    await initialize();

    final prefs = await SharedPreferences.getInstance();
    final notifiedIds = _readIds(prefs, _notifiedNotificationIdsKey);
    final unseenNotifications = notifications.where((item) {
      final id = _notificationId(item);
      return id != null && !notifiedIds.contains(id);
    }).toList();

    if (unseenNotifications.isEmpty) {
      return;
    }

    final unseenCount = unseenNotifications.length;

    for (final item in unseenNotifications) {
      final id = _notificationId(item);
      if (id == null) {
        continue;
      }

      await _plugin.show(
        id,
        item['title']?.toString() ?? 'Notifikasi Baru',
        item['body']?.toString() ?? item['excerpt']?.toString() ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            category: AndroidNotificationCategory.message,
            visibility: NotificationVisibility.public,
            ticker: item['title']?.toString(),
            number: unseenCount,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            badgeNumber: unseenCount,
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
        payload: jsonEncode(item),
      );
    }

    notifiedIds.addAll(unseenNotifications
        .map(_notificationId)
        .whereType<int>());
    await prefs.setStringList(
      _notifiedNotificationIdsKey,
      notifiedIds.take(200).map((id) => '$id').toList(),
    );
  }

  Future<void> markNotificationsSeen(List<Map<String, dynamic>> notifications) async {
    await initialize();

    final prefs = await SharedPreferences.getInstance();
    final readIds = _readIds(prefs, _readNotificationIdsKey);

    for (final item in notifications) {
      final id = _notificationId(item);
      if (id != null) {
        readIds.add(id);
      }
    }

    await prefs.setStringList(
      _readNotificationIdsKey,
      readIds.take(200).map((id) => '$id').toList(),
    );

    await _plugin.cancelAll();
  }

  Future<int> countUnreadNotifications(
      List<Map<String, dynamic>> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = _readIds(prefs, _readNotificationIdsKey);
    return notifications.where((item) {
      final id = _notificationId(item);
      return id != null && !readIds.contains(id);
    }).length;
  }

  Future<void> clearStoredState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notifiedNotificationIdsKey);
    await prefs.remove(_readNotificationIdsKey);
    await _plugin.cancelAll();
  }

  Set<int> _readIds(SharedPreferences prefs, String key) {
    return (prefs.getStringList(key) ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  int? _notificationId(Map<String, dynamic> item) {
    return (item['id'] as num?)?.toInt();
  }
}
