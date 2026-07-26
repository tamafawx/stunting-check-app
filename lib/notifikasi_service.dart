import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  // Channel ini WAJIB ada & idnya harus sama persis dengan yang dipakai
  // saat show() notifikasi di bawah.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'Notifikasi Penting', // nama yang muncul di setting HP user
    description: 'Channel ini dipakai untuk notifikasi penting.',
    importance: Importance.high,
  );

  Future<void> initNotification() async {
    // 1. Minta izin notifikasi (Android 13+ & iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await _fcm.subscribeToTopic('all_users');
    }

    // 2. Setup flutter_local_notifications (wajib untuk foreground)
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    await _localNotif.initialize(settings: initSettings);

    // Buat channel-nya di Android (wajib untuk Android 8.0 ke atas)
    await _localNotif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // 3. Handler background & terminated (biarkan default system yang urus)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Handler FOREGROUND — ini kunci dari masalah kamu.
    // Saat app lagi dibuka, sistem TIDAK otomatis nampilin notifikasi,
    // jadi kita harus tampilkan manual pakai flutter_local_notifications.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotif.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
  }
}
