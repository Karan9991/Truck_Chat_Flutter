import 'package:chat/chat/conversation_data.dart';
import 'package:chat/chat/new_conversation.dart';
import 'package:chat/main.dart';
import 'package:chat/privateChat/pending_requests.dart';
import 'package:chat/privateChat/private_chat_homescreen.dart';
import 'package:chat/starredChat/starred_chat_list.dart';
import 'package:chat/news_tab.dart';
import 'package:chat/chat/chat_list.dart';
import 'package:chat/settings/settings.dart';
import 'package:chat/utils/ads.dart';
import 'package:chat/utils/alert_dialog.dart';
import 'package:chat/utils/constants.dart';
import 'package:chat/utils/device_type.dart';
import 'package:chat/utils/navigator_key.dart';
import 'package:chat/utils/register_user.dart';
import 'package:chat/utils/snackbar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:chat/utils/shared_pref.dart';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/foundation.dart';
import 'package:chat/utils/navigator_global.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  final int initialTabIndex; // Add this parameter to the constructor

  HomeScreen({
    required this.initialTabIndex,
  });

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String? currentUserId;
  PageController pageController = PageController(initialPage: 1);
  PageStorageBucket _bucket = PageStorageBucket();
  late TabController _tabController;
  //late AppLifecycleReactor _appLifecycleReactor;

  int _selectedIndex = 1;
  final List<Widget> _widgetOptions = [
    NewsTab(
      key: UniqueKey(),
    ),
    ChatListr(
      key: UniqueKey(),
    ),
    SponsorsTab(key: UniqueKey()),
    ReviewsTab(key: UniqueKey()),
    PrivateChatTab(key: UniqueKey()),
  ];

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // AdHelper().createInterstitialAd();
    //loadInterstitialAd();
    //Load AppOpen Ad

    //  AppOpenAdManager appOpenAdManager = AppOpenAdManager()..loadAd();
    //   _appLifecycleReactor = AppLifecycleReactor(
    //     appOpenAdManager: appOpenAdManager);

    print('init called on home screen');
    //InterstitialAdManager.initialize();

    _tabController = TabController(
        length: 5, vsync: this, initialIndex: widget.initialTabIndex);

    currentUserId = SharedPrefs.getString(SharedPrefsKeys.USER_ID);

    bool hasAgreed = SharedPrefs.getBool(SharedPrefsKeys.TERMS_AGREED) ?? false;
    if (!hasAgreed) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        showTermsOfServiceDialog(context);
        showLocationAccessDialog(context, () async {
          await registAndreqPermis();
        });
      });
    }

    getFirebaseTokenn();

    _refreshChatListWithFCM();

    //  _loadAndShowInterstitialAd();
  }

  Future<void> loadInterstitialAd() async {
    await AdHelper().createInterstitialAd();
  }

  Future<void> registAndreqPermis() async {
    await reqPermisioLocation();

    _refreshChatList();
  }

  Future<void> registrDevc() async {
    await registerDevice();
  }

  Future<void> reqPermisioLocation() async {
    final permissionStatus = await Geolocator.requestPermission();

    print('---------------permission test');
    print('permission status $permissionStatus');
    // final accuracyStatus = await Geolocator.getLocationAccuracy();
    // switch (accuracyStatus) {
    //   case LocationAccuracyStatus.reduced:
    //     print('accuracyStatus status $accuracyStatus');

    //     // Precise location switch is OFF.
    //     break;
    //   case LocationAccuracyStatus.precise:
    //     print('accuracyStatus status $accuracyStatus');

    //     // Precise location switch is ON.
    //     break;
    //   case LocationAccuracyStatus.unknown:
    //     print('accuracyStatus status $accuracyStatus');

    //     // The platform doesn't support this feature, for example an Android device.
    //     break;
    // }
    print('---------------permission test check location permission');

    // await checkLocationPermission();
  }

  Future<void> checkLocationPermission() async {
    final permissionStatus = await Geolocator.checkPermission();

    switch (permissionStatus) {
      case LocationPermission.denied:
        print("Location permission is denied.");
        break;
      case LocationPermission.deniedForever:
        print("Location permission is permanently denied.");
        break;
      case LocationPermission.unableToDetermine:
        print("Location permission is unableToDetermine.");
        break;
      case LocationPermission.whileInUse:
        print("Location permission is granted only while in use.");
        break;
      case LocationPermission.always:
        print("Location permission is granted always.");
        break;
    }
  }

  Future<void> getFirebaseTokenn() async {
    bool isAppInstall = await isAppInstalled();

    if (!isAppInstall) {
      await getFCMToken(currentUserId ?? '0');
    }
  }

  Future<bool> isAppInstalled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isAppInstalled = prefs.getBool('isAppInstalled') ?? false;
    return isAppInstalled;
  }

  Future<void> getFCMToken(String currentUserId) async {
    DatabaseReference fcmTokenRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(currentUserId)
        .child('fcmToken');

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();

    fcmTokenRef.set(token);
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isAppInstalled', true);
  }

  @override
  void dispose() {
    print('-----------------dddddddd-------------------------');
    //  AdHelper().disposeInterstitialAd();
    super.dispose();
    //InterstitialAdManager.dispose();
    _tabController.dispose();
  }

  void _refreshChatListWithFCM() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Public Chat Foreground notification received');
      Map<String, dynamic> data = message.data;
      final notificationType = data['type'];
      final conversationId = data[
          'conversationId']; // Assuming you receive the conversation ID in the notification data

      print('data ${message.data}');
      print('type $notificationType');

      if (notificationType == 'public') {
        List<Conversation> storedConversations = await getStoredConversations();
        Conversation? conversationToRefresh; // Initialize as nullable

        for (var conversation in storedConversations) {
          if (conversation.conversationId == conversationId &&
              !conversation.isDeleted) {
            conversationToRefresh = conversation;
            break;
          }
        }

        if (conversationToRefresh != null) {
          _refreshChatList();

          if (SharedPrefs.getBool(SharedPrefsKeys.CHAT_TONES)!) {
            FlutterBeep.beep();
          }
        }
      } else if (notificationType == 'newchat') {
        _refreshChatList();
        if (SharedPrefs.getBool(SharedPrefsKeys.CHAT_TONES)!) {
          FlutterBeep.beep();
        }
      } else if (notificationType == null) {
        print('notification null homescreen');
        // _refreshChatList();
        // if (SharedPrefs.getBool(SharedPrefsKeys.CHAT_TONES)!) {
        //   FlutterBeep.beep();
        // }
      }
    });
  }

  void _refreshChatList() {
    setState(() {
      // Update the key of the currently selected widget to force a rebuild
      _widgetOptions[_selectedIndex] = _getCurrentTabWidget();
    });
  }

  Widget _getCurrentTabWidget() {
    switch (_selectedIndex) {
      case 0:
        return NewsTab(
          key: UniqueKey(),
        );
      case 1:
        return ChatListr(key: UniqueKey());
      case 2:
        return SponsorsTab(key: UniqueKey());
      case 3:
        return ReviewsTab(key: UniqueKey());
      case 4:
        return PrivateChatTab(
          key: UniqueKey(),
        );
      default:
        return Container();
    }
  }

  void _showReportAbuseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(DialogStrings.REPORT_ABUSE),
          content: Text(DialogStrings.TO_REPORT_ABUSE),
          actions: [
            TextButton(
              child: Text(DialogStrings.GOT_IT),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void setupFirebaseMessaging(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showPrivateChatSentRequestPopUp(message.data, message, context);
      SharedPrefs.setBool('isPendingRequestScreenOpen', true);
    });
  }

  void showPrivateChatSentRequestPopUp(Map<String, dynamic> data,
      RemoteMessage message, BuildContext context) async {
    final notificationType = data['type'];

    if (notificationType == 'privatechat') {
      //OverlayManager.showPopup(context);
      GlobalNavigator.showAlertDialog('New Private Chat Request!',
          'Open your Private Chat and view pending requests to see who wants to connect.');
    }
  }

  void openPrivateChatTab(String senderId) {
    int privateChatTabIndex = 4; // Index of the Private Chat tab
    setState(() {
      _selectedIndex = privateChatTabIndex;
      _tabController.animateTo(
        privateChatTabIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    setupFirebaseMessaging(context);

    return OrientationBuilder(builder: (context, orientation) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
          appBar: AppBar(
            leading: Image.asset(
              'assets/ic_launcher.png',
              width: 34,
              height: 34,
            ),
            title: Text(Constants.APP_BAR_TITLE),
            actions: [
              IconButton(
                icon: Image.asset(
                  'assets/add_blog.png',
                  width: 30,
                  height: 30,
                ),
                onPressed: () {
                  // Perform action when chat icon is pressed
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NewConversationScreen()),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.grid_view_rounded),
                onPressed: () async {
                  // InterstitialAdManager.showInterstitialAd();

                  showMarkAsReadUnreadDialog(context);
                  // _refreshChatList();
                  // Perform action when grid box icon is pressed
                },
              ),
              PopupMenuButton(
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem(
                      child: Text(Constants.SETTINGS),
                      value: 'settings',
                    ),
                    PopupMenuItem(
                      child: Text(Constants.TELL_A_FRIEND),
                      value: 'tell a friend',
                    ),
                    PopupMenuItem(
                      child: Text(Constants.HELP),
                      value: 'help',
                    ),
                    PopupMenuItem(
                      child: Text(Constants.STARRED_CHAT),
                      value: 'starred chat',
                    ),
                    PopupMenuItem(
                      child: Text(Constants.REPORT_ABUSE),
                      value: 'report abuse',
                    ),
                    PopupMenuItem(
                      child: Text(Constants.REFRESH),
                      value: 'refresh',
                    ),
                    // if (!Platform.isIOS)
                    PopupMenuItem(
                      child: Text(Constants.EXIT),
                      value: 'exit',
                    ),
                  ];
                },
                onSelected: (value) async {
                  // Perform action when a pop-up menu item is selected
                  switch (value) {
                    case 'settings':
                      // InterstitialAdManager.showInterstitialAd();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SettingsScreen()),
                      );
                      break;
                    case 'tell a friend':
                      String email = Uri.encodeComponent("");
                      String subject =
                          Uri.encodeComponent(Constants.CHECK_OUT_TRUCKCHAT);
                      String body =
                          Uri.encodeComponent(Constants.I_AM_USING_TRUCKCHAT);
                      print(subject);
                      Uri mail = Uri.parse(
                          "mailto:$email?subject=$subject&body=$body");
                      launchUrl(mail);
                      break;
                    case 'help':
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Help()),
                      );
                      break;
                    case 'starred chat':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StarredChatList(key: UniqueKey()),
                        ),
                      );
                      break;
                    case 'report abuse':
                      _showReportAbuseDialog(context);
                      break;
                    case 'refresh':
                      _refreshChatList();

                      break;
                    case 'exit':
                      if (Platform.isIOS) {
                        // Handle iOS-specific exit behavior (e.g., display an alert)
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(DialogStrings.EXIT),
                            content: Text(DialogStrings.ARE_YOU_SURE),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(DialogStrings.CANCEL),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text(DialogStrings.EXIT),
                              ),
                            ],
                          ),
                        ).then((exitConfirmed) {
                          if (exitConfirmed ?? false) {
                            exit(0); // Exit the app
                          }
                        });
                      } else if (Platform.isAndroid) {
                        SystemNavigator.pop();
                      }
                      break;
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    NewsTab(
                      key: UniqueKey(),
                    ),
                    ChatListr(key: UniqueKey()),
                    SponsorsTab(key: UniqueKey()),
                    ReviewsTab(key: UniqueKey()),
                    PrivateChatTab(
                      key: UniqueKey(),
                    ),
                  ],
                ),
              ),
              BottomAppBar(
                //color: Colors.blue, // Set background color of the TabBar
                child: TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(
                      icon: Icon(Icons.article),
                      text: Constants.NEWS,
                    ),
                    Tab(icon: Icon(Icons.chat), text: Constants.CHATS),
                    Tab(icon: Icon(Icons.star), text: Constants.SPONSORS),
                    Tab(icon: Icon(Icons.rate_review), text: Constants.REVIEWS),
                    Tab(icon: Icon(Icons.person), text: 'Private'),
                  ],

                  unselectedLabelColor:
                      Colors.grey, // Color of unselected tab icon and text
                  labelColor:
                      Colors.blue, // Color of selected tab icon and text
                  labelPadding: EdgeInsets.symmetric(
                      horizontal: 6.0,
                      vertical: 0.0), // Add padding around the tab labels
                ),
              ),
            ],
          ),
          bottomNavigationBar: CustomBannerAd(
            key: UniqueKey(),
          ),

          // bottomNavigationBar: AdmobBanner(
          //   adUnitId: AdHelper.bannerAdUnitId,
          //   adSize: AdmobBannerSize.ADAPTIVE_BANNER(
          //     width: MediaQuery.of(context).size.width.toInt(),
          //   ),
          // ),
        ),
      );
    });
  }
}

class SponsorsTab extends StatelessWidget {
  final Key key;

  SponsorsTab({
    required this.key,
  });

  final String sponsorUrl = API.SPONSORS;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = {
    Factory(() => EagerGestureRecognizer())
  };
  @override
  Widget build(BuildContext context) {
    return Container(
      child: InAppWebView(
        gestureRecognizers: gestureRecognizers,
        initialUrlRequest: URLRequest(url: Uri.parse(sponsorUrl)),
      ),
    );
  }
}

class ReviewsTab extends StatefulWidget {
  const ReviewsTab({super.key});

  @override
  State<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<ReviewsTab> {
  late final WebViewController controller;
  final String sponsorUrl = API.REVIEWS;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = {
    Factory(() => EagerGestureRecognizer())
  };
  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..loadRequest(
        Uri.parse(sponsorUrl),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: MediaQuery.of(context).size.height, // Set explicit height
        child: WebViewWidget(
          gestureRecognizers: gestureRecognizers,
          controller: controller,
        ),
      ),
    );
  }
}

class Help extends StatelessWidget {
  final String sponsorUrl = API.HELP;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: InAppWebView(
        initialUrlRequest: URLRequest(url: Uri.parse(sponsorUrl)),
      ),
    );
  }
}

class PopupDialog extends StatefulWidget {
  @override
  _PopupDialogState createState() => _PopupDialogState();
}

class _PopupDialogState extends State<PopupDialog>
    with SingleTickerProviderStateMixin {
  late TabController _privateChatTabController;

  @override
  void initState() {
    super.initState();
    _privateChatTabController = TabController(
      length: 2,
      vsync: this, // Use the TickerProvider from SingleTickerProviderStateMixin
      initialIndex: 1,
    );
  }

  @override
  void dispose() {
    _privateChatTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return AlertDialog(
          title:
              Text('New Private Chat Request!', style: TextStyle(fontSize: 20)),
          content: SingleChildScrollView(
            child: Text(
                "You've received a private chat request. Open your Private Chat and view pending requests to see who wants to connect.",
                style: TextStyle(fontSize: 16)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                OverlayManager.hidePopup();
                // homescreen.openPrivateChatTab('senderId'); // Navigate to the private chat tab

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(
                      initialTabIndex: 4,
                    ),
                  ),
                );

                OverlayManager.hidePopup();
              },
              child: Text('View Requests'),
            ),
          ],
        );
      },
    );
  }
}

class OverlayManager {
  static OverlayEntry? _overlayEntry;

  static void showPopup(BuildContext context) {
    _overlayEntry = OverlayEntry(
      maintainState: true,
      builder: (BuildContext context) {
        return Positioned(
          top: MediaQuery.of(context).size.height *
              0.3, // Adjust the position as needed
          left: MediaQuery.of(context).size.width *
              0.0, // Adjust the position as needed
          right: MediaQuery.of(context).size.width *
              0.0, // Adjust the position as needed
          child: Center(child: PopupDialog()), // Center the dialog
        );
      },
    );

    Overlay.of(context)?.insert(_overlayEntry!);
  }

  static void showPopupFirstLaunch(BuildContext context) {
    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        return Positioned(
          top: MediaQuery.of(context).size.height *
              0.3, // Adjust the position as needed
          left: MediaQuery.of(context).size.width *
              0.0, // Adjust the position as needed
          right: MediaQuery.of(context).size.width *
              0.0, // Adjust the position as needed
          child: Container(), // Center the dialog
        );
      },
    );

    Overlay.of(context)?.insert(_overlayEntry!);
  }

  static void hidePopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
