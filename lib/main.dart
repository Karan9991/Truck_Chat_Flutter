import 'dart:convert';
import 'dart:io';
import 'package:chat/chat/conversation_data.dart';
import 'package:chat/chat/new_conversation.dart';
import 'package:chat/home_screen.dart';
import 'package:chat/privateChat/chat.dart';
import 'package:chat/privateChat/pending_requests.dart';
import 'package:chat/privateChat/private_chat_homescreen.dart';
import 'package:chat/utils/ads.dart';
import 'package:chat/utils/alert_dialog.dart';
import 'package:chat/utils/avatar.dart';
import 'package:chat/utils/chat_handle.dart';
import 'package:chat/utils/constants.dart';
import 'package:chat/utils/device_type.dart';
import 'package:chat/utils/register_user.dart';
import 'package:chat/utils/shared_pref.dart';
import 'package:chat/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:http/http.dart' as http;
import 'package:device_info/device_info.dart';
import 'model/get_all_reply_messages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:chat/utils/navigator_key.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
//import 'package:geolocator/geolocator.dart';

Future<void> backgroundHandler(RemoteMessage message) async {
  debugPrint("backgroundHandler: ${message.notification}");
  // Handle the background message here
  await SharedPrefs.init();
  bool? notifications = SharedPrefs.getBool(SharedPrefsKeys.NOTIFICATIONS);
  if (notifications!) {
    handleFCMMessage(message.data, message);
  }
}

AppOpenAd? myAppOpenAd;

loadAppOpenAd() {
  AppOpenAd.load(
      adUnitId: AdHelper.openAppAdUnitId, //Your ad Id from admob
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            myAppOpenAd = ad;
            myAppOpenAd!.show();
          },
          onAdFailedToLoad: (error) {}),
      orientation: AppOpenAd.orientationPortrait);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  MobileAds.instance.initialize();

  await loadAppOpenAd();

  configLocalNotification();
  _configureFCM();

  await SharedPrefs.init();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isAppInstalled = prefs.getBool('isAppInstalled') ?? false;

  if (!isAppInstalled) {
    await initNotificationsAndSoundPrefs();
    await registerDevice();
  }

  FirebaseMessaging.onBackgroundMessage(backgroundHandler);

  //await AdHelper().createInterstitialAd();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  void showLocationDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Location Data'),
          content: const Text('Would you like to share your location data?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                // Handle user's decision to share location data
                // You can perform any necessary actions here
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Truck Chat',
      
      navigatorKey: navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(
              initialTabIndex: 1,
            ),
        '/privateChat': (context) => PrivateChatTab(key: UniqueKey()),
    '/newConversation': (context) => NewConversationScreen(),
      },
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        
      //   useMaterial3: true,
      //   primarySwatch: Colors.blue,
      //       colorScheme: ColorScheme.fromSeed(
      // seedColor: Colors.blue,
   // ),
        
      ),
    );
  }
}

  // primaryColor: Colors.blue,
  //       colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),

Future<String?> getFCMToken(String receiverId) async {
  DatabaseReference fcmTokenRef = FirebaseDatabase.instance
      .ref()
      .child('users')
      .child(receiverId)
      .child('fcmToken');

  // Check if the token already exists in the database
  DatabaseEvent event = await fcmTokenRef.once();
  DataSnapshot dataSnapshot = event.snapshot;

  String? token = dataSnapshot.value as String?;

  if (token == null) {
    // If the token doesn't exist in the database, generate a new token
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    token = await messaging.getToken();

    if (token != null) {
      // Store the newly generated token in the database
      fcmTokenRef.set(token);
    }
  }

  return token;
}

Future<void> initNotificationsAndSoundPrefs() async {
  SharedPrefs.setBool(SharedPrefsKeys.CHAT_TONES, true);
  SharedPrefs.setBool(SharedPrefsKeys.NOTIFICATIONS, true);
  SharedPrefs.setBool(SharedPrefsKeys.NOTIFICATIONS_TONE, true);
  SharedPrefs.setBool(SharedPrefsKeys.VIBRATE, true);
  SharedPrefs.setBool(SharedPrefsKeys.PRIVATE_CHAT, true);
  SharedPrefs.setBool('isUserOnChatScreen', false);
  SharedPrefs.setBool('isUserOnPublicChatScreen', false);
  SharedPrefs.setBool('isPendingRequestScreenOpen', false);
  SharedPrefs.setInt('interstitialAdCounter', 0);
}

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void _configureFCM() {
  _firebaseMessaging.requestPermission();
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Foreground notification received');
    debugPrint('data ${message.data}');

    bool? notifications = SharedPrefs.getBool(SharedPrefsKeys.NOTIFICATIONS);
    if (notifications!) {
      handleFCMMessage(message.data, message);
    }
  });
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('onMessageOpenedApp----------------->');
  });
}

void handleFCMMessage(Map<String, dynamic> data, RemoteMessage message) async {
  debugPrint('--------------------------Notification-----------------------------');
  String title = 'There are new messages!';
  String body = 'Tap here to open TruckChat';
  final senderId = data['senderUserId'];
  final notificationType = data['type'];
  final conversationId = data[
      'conversationId']; // Assuming you receive the conversation ID in the notification data

  debugPrint('sender id $senderId');
  debugPrint('type $notificationType');
  debugPrint('--------------------------Notification-----------------------------');

  if (message.notification != null) {
    title = message.notification!.title ?? 'There are new messages!';
    body = message.notification!.body ?? 'Tap here to open TruckChat';
  } else {
    title = 'There are new messages!';
    body = 'Tap here to open TruckChat';
  }

  String? currentUserId = SharedPrefs.getString(SharedPrefsKeys.USER_ID);

  if (notificationType == 'public') {
    debugPrint('if public');
    if (!SharedPrefs.getBool('isUserOnPublicChatScreen')!) {
      debugPrint('if isUserOnPublicChatScreen');

      if (currentUserId != senderId) {
        List<Conversation> storedConversations = await getStoredConversations();
        Conversation? conversationToRefresh; // Initialize as nullable
        debugPrint('if curren');

        for (var conversation in storedConversations) {
          if (conversation.conversationId == conversationId &&
              !conversation.isDeleted) {
            debugPrint('if conversationToRefresh ${conversation.isDeleted}');

            conversationToRefresh = conversation;
            break;
          } else {
            debugPrint(
                'else conversationid  ${conversation.conversationId} $conversationId ${conversation.isDeleted} ${conversation.topic}');
          }
        }

        if (conversationToRefresh != null) {
          debugPrint('if conversationToRefresh nulled $conversationToRefresh');

          showNotification(Constants.FCM_NOTIFICATION_TITLE,
              Constants.FCM_NOTIFICATION_BODY);
        } else {
          debugPrint('else conversationToRefresh $conversationToRefresh');
        }
      }
    }
  } else if (notificationType == 'private') {
    debugPrint('if private');

    if (!SharedPrefs.getBool('isUserOnChatScreen')!) {
      showNotification(title, body);
    }
  } else if (notificationType == 'privatechat') {
    debugPrint('if privatechat');

    showNotification(title, body);
  } else if (notificationType == 'newchat') {
    debugPrint('if newchat');

    showNotification(title, body);
  } else if (notificationType == null) {
    debugPrint('null notificatoin');

    // if (!SharedPrefs.getBool('isUserOnPublicChatScreen')!) {
    //   showNotification(title, body);
    // }
  }
}

Future<String> getNotificationChannelId() async {
  bool notificationTone =
      SharedPrefs.getBool(SharedPrefsKeys.NOTIFICATIONS_TONE) ?? false;
  bool notificationVibrate =
      SharedPrefs.getBool(SharedPrefsKeys.VIBRATE) ?? false;

  // Default channel ID for when both notification tone and vibrate are disabled
  String channelId = 'default_channel';

  switch (notificationTone) {
    case true:
      switch (notificationVibrate) {
        case true:
          channelId = 'tone_and_vibrate_channel';
          break;
        case false:
          channelId = 'tone_channel';
          break;
      }
      break;
    case false:
      switch (notificationVibrate) {
        case true:
          channelId = 'vibrate_channel';
          break;
        case false:
          channelId = 'silent_channel';
          break;
      }
      break;
  }

  return channelId;
}

void showNotification(String? title, String? body) async {
  //check user preferences for notification and vibrate
  String channelId = await getNotificationChannelId();
  bool shouldPlaySound =
      (channelId == 'tone_channel' || channelId == 'tone_and_vibrate_channel');
  bool shouldEnableVibration = (channelId == 'vibrate_channel' ||
      channelId == 'tone_and_vibrate_channel');

  AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    channelId,
    'Truck Chat',
    playSound: shouldPlaySound,
    enableVibration: shouldEnableVibration,
    importance: Importance.max,
    priority: Priority.high,
  );

  DarwinNotificationDetails iOSPlatformChannelSpecifics =
      const DarwinNotificationDetails();

  NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
    payload: null,
  );
}

void configLocalNotification() {
  AndroidInitializationSettings initializationSettingsAndroid =
      const AndroidInitializationSettings('@drawable/ic_launcher');
  DarwinInitializationSettings initializationSettingsIOS =
      const DarwinInitializationSettings();
  InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

class LocationPermissionObserver extends NavigatorObserver {
  bool settingsScreenOpened = false;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute is MaterialPageRoute) {
      settingsScreenOpened = true;
    }
    super.didPush(route, previousRoute);
  }

  void userReturnedFromSettingsScreen() {
    settingsScreenOpened = false;
  }
}
