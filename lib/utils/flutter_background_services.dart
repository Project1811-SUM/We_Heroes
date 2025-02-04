import 'dart:async';
import 'dart:ui';

import 'package:background_location/background_location.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shake/shake.dart';
import 'package:telephony/telephony.dart';
import 'package:vibration/vibration.dart';
import 'package:we_heroes/db/db_services.dart';
import 'package:we_heroes/model/contactsm.dart';

/// Sends an emergency message with the user's current location.
Future<void> sendMessage(String messageBody) async {
  List<TContact> contactList = await DatabaseHelper().getContactList();
  if (contactList.isEmpty) {
    Fluttertoast.showToast(msg: "No emergency contacts found. Please add a number.");
  } else {
    for (var contact in contactList) {
      await Telephony.backgroundInstance.sendSms(
        to: contact.number,
        message: messageBody,
      );
      Fluttertoast.showToast(msg: "Emergency message sent to ${contact.number}");
    }
  }
}

/// Initializes the background service.
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  /// Defines the Android notification channel for the background service.
  AndroidNotificationChannel channel = AndroidNotificationChannel(
    'we_heroes_channel', // Unique Channel ID
    'WeHeroes Background Service', // Name
    description: 'This service runs background tasks for safety features.', // Fixes "description" error
    importance: Importance.defaultImportance, // Corrected Importance
    playSound: false,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    iosConfiguration: IosConfiguration(),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: 'we_heroes_channel', // Matches channel ID above
      initialNotificationTitle: 'WeHeroes Service Running',
      initialNotificationContent: 'Initializing background services...',
      foregroundServiceNotificationId: 999,
    ),
  );

  service.startService();
}

/// Background service entry point.
@pragma('vm-entry-point')
void onStart(ServiceInstance service) async {
  Location? currentLocation;
  DartPluginRegistrant.ensureInitialized();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });

    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  /// Configures background location tracking.
  await BackgroundLocation.setAndroidNotification(
    title: 'Location tracking is running!',
    message: 'WeHeroes is monitoring your safety in the background.',
    icon: '@mipmap/ic_launcher',
  );

  BackgroundLocation.startLocationService(distanceFilter: 20);
  BackgroundLocation.getLocationUpdates((location) {
    currentLocation = location;
  });

  if (service is AndroidServiceInstance) {
    if (await service.isForegroundService()) {
      ShakeDetector.autoStart(
        shakeThresholdGravity: 7.0,
        shakeSlopTimeMS: 500,
        shakeCountResetTime: 3000,
        minimumShakeCount: 1,
        onPhoneShake: () async {
          if (await Vibration.hasVibrator() ?? false) {
            Vibration.vibrate(duration: 1000);
          }
          String messageBody = "Emergency! My location: "
              "https://www.google.com/maps/search/?api=1&query=${currentLocation?.latitude}%2C${currentLocation?.longitude}";
          sendMessage(messageBody);
        },
      );

      flutterLocalNotificationsPlugin.show(
        999,
        'WeHeroes',
        currentLocation == null
            ? 'Please enable location for safety features'
            : 'Shake feature active - Location: ${currentLocation?.latitude}, ${currentLocation?.longitude}',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'we_heroes_channel',
            'WeHeroes Background Service',
            icon: 'ic_bg_service_small',
            ongoing: true,
          ),
        ),
      );
    }
  }
}
