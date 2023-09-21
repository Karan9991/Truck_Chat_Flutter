import 'dart:io';

import 'package:chat/chat/new_conversation.dart';
import 'package:chat/starredChat/starred_chat_list.dart';
import 'package:chat/home_screen.dart';
import 'package:chat/settings/settings.dart';
import 'package:chat/utils/ads.dart';
import 'package:chat/utils/avatar.dart';
import 'package:chat/utils/constants.dart';
import 'package:chat/utils/device_type.dart';
import 'package:chat/utils/lat_lng.dart';
import 'package:chat/utils/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_6.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chat/model/get_all_reply_messages.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import 'package:chat/utils/alert_dialog.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:chat/model/request.dart';

class Chat extends StatefulWidget {
  final String topic;
  final String serverMsgId;

  Chat({
    required this.topic,
    required this.serverMsgId,
  });

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  String _typedText = '';
  bool isStar = false;

  TextEditingController messageController = TextEditingController();
  List<ReplyMsg> filteredReplyMsgs = [];
  List<ReplyMsgg> sentMessages = [];
  int rid = 0;
  String emoji_id = '';
  int timestam = 0;
  String status_message = '';
  int statusCode = 0;
  List<ReplyMsg> replyMsgs = [];
  bool sendingMessage = false; // Added variable to track sending state
  String? shareprefuserId = SharedPrefs.getString('userId');
  int userId = 0;

  ScrollController _scrollController = ScrollController();
  String? currentUserHandle;
  String? currentUserEmojiId;
  String? currentUserId;

  String? emojiId;
  String? driverName;
  String? privateChatStatus;
  bool? privateChat;
  double? latitude;
  double? longitude;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  List<String> starredConversationList = [];
  bool isLoading = false;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false; // Track whether the ad is loaded
  static const int maxFailedLoadAttempts = 3;
  int _numInterstitialLoadAttempts = 0;
  // late BannerAd bannerAd;
  // bool isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();

    SharedPrefs.setBool('isUserOnPublicChatScreen', true);

    _firebaseMessaging.subscribeToTopic('all');

    userId = int.parse(shareprefuserId!);

    currentUserHandle =
        SharedPrefs.getString(SharedPrefsKeys.CURRENT_USER_CHAT_HANDLE);

    currentUserEmojiId =
        SharedPrefs.getInt(SharedPrefsKeys.CURRENT_USER_AVATAR_ID).toString();

    currentUserId = SharedPrefs.getString(SharedPrefsKeys.USER_ID);

    getData(widget.serverMsgId).then((_) {
      setState(() {
        isLoading = false;
      });
    });

    _refreshChat();

    checkChatStarredStatus();
  }

  // @override
  // void didChangeDependencies() {
  //   // TODO: implement didChangeDependencies

  //   bannerAd = BannerAd(
  //     size: AdSize.getInlineAdaptiveBannerAdSize(
  //         MediaQuery.of(context).size.width.toInt(), 60),
  //     adUnitId: AdHelper.bannerAdUnitId,
  //     listener: BannerAdListener(onAdFailedToLoad: (ad, error) {
  //       debugPrint("Ad Failed to Load");
  //       ad.dispose();
  //     }, onAdLoaded: (ad) {
  //       debugPrint("Ad Loaded");
  //       setState(() {
  //         isBannerAdLoaded = true;
  //       });
  //     }),
  //     request: const AdRequest(),
  //   );
  //   bannerAd.load();

  //   super.didChangeDependencies();
  // }

  @override
  void dispose() {
    _scrollController.dispose();

   // bannerAd.dispose();

    SharedPrefs.setBool('isUserOnPublicChatScreen', false);

    super.dispose();
  }

  void _refreshChat() {
    debugPrint('refresh chat');
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Refresh ChatList');

      getAllMessages(widget.serverMsgId);
    });
  }

  void scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
      );
    }
  }

  void filterReplyMsgs() {
    // debugPrint('reply messges in fliter replymsf');
    // debugPrint(replyMsgs);
    filteredReplyMsgs =
        replyMsgs.where((reply) => reply.topic == widget.topic).toList();
  }

  Future<void> getData(dynamic conversationId) async {
    setState(() {
      isLoading = true;
    });
    Map<String, double> locationData = await getLocation();
    latitude = locationData[Constants.LATITUDE]!;
    longitude = locationData[Constants.LONGITUDE]!;
    await getAllMessages(conversationId);

    WidgetsBinding.instance?.addPostFrameCallback((_) =>
        scrollToBottom()); // Call scrollToBottom() after the first frame is rendered
  }

  Future<void> sendFCMNotification(String topic, String message) async {
    final url = Uri.parse(MyFirebase.FIREBASE_NOTIFICATION_URL);
    final serverKey = MyFirebase
        .FIREBASE_CLOUD_MESSAGING_KEY_NOTIFICATION; // Replace with your FCM server key

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };

    final body = {
      'to': '/topics/$topic',
      'notification': {
        'body': 'Tap here to open TruckChat',
        'title': 'There are new messages!',
        'sound': 'default',
      },
      'data': {
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'type': 'public',
        'conversationId': widget.serverMsgId,
        'senderUserId':
            currentUserId, // Include the senderId in the data payload
      },
    };

    try {
      final response =
          await http.post(url, headers: headers, body: jsonEncode(body));
      if (response.statusCode == 200) {
        debugPrint('FCM notification sent successfully');
      } else {
        debugPrint('Failed to send FCM notification');
      }
    } catch (e) {
      debugPrint('Error sending FCM notification: $e');
    }
  }

  Future<void> sendPrivateChatNotification(
      String receiverFCMToken, String senderId, String receiverId) async {
    debugPrint('receiver token $receiverFCMToken');
    // Replace 'YOUR_SERVER_KEY' with your FCM server key
    String serverKey = MyFirebase.FIREBASE_CLOUD_MESSAGING_KEY_NOTIFICATION;
    String url = MyFirebase.FIREBASE_NOTIFICATION_URL;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(<String, dynamic>{
          'notification': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'body': 'Tap here to open TruckChat',
            'title': 'You got Private Chat Request',
            'sound': 'default',
          },
          // 'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'type': 'privatechat',
            'senderUserId': currentUserId,
            'receiverUserId': receiverId,
          },
          'to': receiverFCMToken,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Notification sent successfully');
      } else {
        debugPrint(
            'Failed to send notification. StatusCode: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to send notification. Error: $e');
    }
  }

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

    return token;
  }

  Future<bool> getAllMessages(dynamic conversationId) async {
    debugPrint('getAllMessages method called');
    debugPrint('Conversation Id  $conversationId');
    int statusCode = 0;
    String counts = '';

    String statusMessage = '';

    final url = Uri.parse(API.CHAT);

    Map<String, dynamic> requestBody = {
      API.SERVER_MESSAGE_ID: conversationId,
    };

    try {
      http.Response response = await http.post(
        url,
        headers: {API.CONTENT_TYPE: API.APPLICATION_JSON},
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 200) {
        // debugPrint('200');
        final result = response.body;

        debugPrint('---------------Chat Response---------------');
        debugPrint(result);

        debugPrint('response body $result');

        try {
          final jsonResult = jsonDecode(result);

          counts = jsonResult[API.COUNTS];

          final jsonReplyList = jsonResult[API.MESSAGE_REPLY_LIST];

          // debugPrint('jsonreplylist');
          // debugPrint(jsonReplyList);

          int countValue = int.parse(counts);

          // debugPrint(jsonReplyList.length);
          // Clear the replyMsgs list before adding new messages
          replyMsgs.clear();

          //if (counts == jsonReplyList.length) {
          for (var i = 0; i < countValue; ++i) {
            final jsonReply = jsonReplyList[i];
            final rid = jsonReply[API.SERVER_MSG_REPLY_ID];
            final replyMsg = jsonReply[API.REPLY_MSG];
            final uid = jsonReply[API.USER_ID];
            final emojiId = jsonReply[API.EMOJI_ID] ?? 0;
            final driverName = jsonReply['driver_name'] ?? '';
            final privateChat = jsonReply['private_chat'];

            debugPrint("server_msg_reply_id  $rid");
            debugPrint("reply_msg $replyMsg");
            debugPrint("user id  $uid");
            debugPrint("emoji_id $emojiId");
            debugPrint("driver_name $driverName");
            debugPrint("private_chat $privateChat");

            debugPrint('--------------------------');
            int timestamp;
            try {
              //  timestamp = int.tryParse(jsonReply['timestamp']) ?? 0;
              timestamp = jsonReply[API.TIMESTAMP] ?? 0;
              debugPrint('try in for $timestamp');
            } catch (e) {
              timestamp = 0;
              debugPrint('catch $timestamp');
            }
            //format code to separate chat handle with colon : with message

            String decodedMessage = replyMsg.replaceAll('%3A', ':');

            replyMsgs.add(ReplyMsg(rid, uid, decodedMessage, timestamp, emojiId,
                widget.topic, driverName, privateChat));
          }

          setState(() {
            // Update the conversation data
            // conversationTopics.add(conversationTopic);
            // conversationTimestamps.add(conversationTimestamp);
            // replyCounts.add(counts);
            this.replyMsgs = replyMsgs;

            filterReplyMsgs();
            // scrollToBottom();
            WidgetsBinding.instance
                ?.addPostFrameCallback((_) => scrollToBottom());
          });
        } catch (e) {
          debugPrint('catch 2 $e');
          statusMessage = e.toString();
//  final lineNumber = stackTrace.toString().split("\n")[1];
//       debugPrint("Error occurred at: $lineNumber");
          //     final errorDetails = FlutterErrorDetails(exception: e, stack: stackTrace);
          // FlutterError.reportError(errorDetails);
        }
      } else {
        statusMessage = 'Connection Error';
      }
    } catch (e) {
      debugPrint('${Constants.ERROR} $e');
    }
    //  }

    return false;
  }

  String formatUserHandle(String userHandle) {
    String formatString =
        ' %s: '; // The format string with %s placeholder and non-breaking space

    // Replace %s with userHandle
    String formattedString = formatString.replaceAll('%s', userHandle);

    return formattedString;
  }

  Future<bool> sendMessage(
    String message,
    String serverMsgId,
    int userId,
  ) async {
    // setState(() {
    //   sendingMessage = true; // Set sending state to true
    // });

    String? deviceId = SharedPrefs.getString(
          SharedPrefsKeys.SERIAL_NUMBER,
        ) ??
        '';

    String deviceType = getDeviceType();

    if (SharedPrefs.getInt(SharedPrefsKeys.CURRENT_USER_AVATAR_ID) != null) {
      emojiId =
          SharedPrefs.getInt(SharedPrefsKeys.CURRENT_USER_AVATAR_ID).toString();
      // debugPrint('new conversation emoji id $emojiId');
    } else {
      emojiId = '0';
      // debugPrint('new conversation emoji id $emojiId');
    }

    driverName =
        SharedPrefs.getString(SharedPrefsKeys.CURRENT_USER_CHAT_HANDLE) ?? '';
    privateChat = SharedPrefs.getBool(SharedPrefsKeys.PRIVATE_CHAT) ?? false;

    privateChatStatus = privateChat! ? '1' : '0';

//format code to separate chat handle with colon : with message
    String encodedMessage = message.replaceAll(':', '%3A');

    String formattedDriverName = formatUserHandle(driverName!);
    String formattedMessage = formattedDriverName + encodedMessage;

    debugPrint('formatted driver name $formattedDriverName');
    debugPrint('formatted message $formattedMessage');
    debugPrint('send message');
    debugPrint('message $message');
    debugPrint('formattedmessage $formattedMessage');
    debugPrint('latitude ${latitude.toString()}');
    debugPrint('longitude ${longitude.toString()}');
    debugPrint('drivername $driverName');
    debugPrint('private_chat $privateChatStatus');
    debugPrint('device_id $deviceId');
    debugPrint('message_device_type $deviceType');
    debugPrint('sermsgid $serverMsgId');
    debugPrint('userid $userId');
    debugPrint('emojiid $emojiId');

//concat username/chathandle with message
    // if (currentUserHandle != null) {
    //   message = '$currentUserHandle $message';
    // }

    //  int servermsgid = int.parse(serverMsgId);
    final url = API.SEND_MESSAGE; // Replace with your API endpoint
    final headers = {API.CONTENT_TYPE: API.APPLICATION_JSON};
    final body = jsonEncode({
      API.MESSAGE: formattedMessage,
      API.SERVER_MSG_ID: serverMsgId,
      API.USER_ID: userId,
      API.LATITUDE: latitude.toString(),
      API.LONGITUDE: longitude.toString(),
      API.EMOJI_ID: emojiId,
      'driver_name': driverName,
      'private_chat': privateChatStatus,
      "device_id": deviceId,
      // "device_package": "com.teletype.truckchat",

      "device_package": "com.teletype.truckchat2.android",
      "message_device_type": deviceType,
    });

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);

      debugPrint(response.body);

      if (response.statusCode == 200) {
        debugPrint('Message Sent');
        // setState(() {
        //   sendingMessage = false; // Set sending state to false

        //   WidgetsBinding.instance
        //       ?.addPostFrameCallback((_) => scrollToBottom());
        // });

        final jsonResult = jsonDecode(response.body);
        debugPrint('---------------Send Message Response---------------');

        debugPrint('send message response ${response.body}');
        int statusCode = jsonResult[API.STATUS] as int;

        /// debugPrint('status code $statusCode');
        await sendFCMNotification('all', 'message');

        // setState(() {
        //   sendingMessage = false; // Set sending state to false

        //   WidgetsBinding.instance
        //       ?.addPostFrameCallback((_) => scrollToBottom());
        // });

        if (jsonResult.containsKey(API.MESSAGE)) {
          String status_message = jsonResult[API.MESSAGE] as String;
          // debugPrint('status_message $status_message');

          // Add the sent message to the list
          // sentMessages.add(ReplyMsgg(serverMsgId, userId, message,
          //     DateTime.now().millisecondsSinceEpoch));
        } else {
          String status_message = '';
        }

        return true;
      } else {
        // setState(() {
        //   sendingMessage = false; // Set sending state to false
        // });
        status_message = 'Error: ${response.statusCode}';
      }
    } catch (e) {
      status_message = e.toString();
      debugPrint('catch $e');
      debugPrint('status message $status_message');
      // setState(() {
      //   sendingMessage = false; // Set sending state to false
      // });
    }

    return false;
  }

  Future<void> saveStarredConversations(
      List<String> starredConversationList) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? storedStarredConversations =
          prefs.getStringList('starredConversationList');

      if (storedStarredConversations != null) {
        if (storedStarredConversations.contains(widget.serverMsgId)) {
          // Conversation is already starred, remove it
          storedStarredConversations.remove(widget.serverMsgId);
        } else {
          // Conversation is not starred, add it
          storedStarredConversations.add(widget.serverMsgId);
        }
      } else {
        // No stored starred conversations, initialize the list
        storedStarredConversations = [widget.serverMsgId];
      }

      await prefs.setStringList(
        'starredConversationList',
        storedStarredConversations,
      );

      debugPrint('Starred conversations saved successfully');
    } catch (e) {
      debugPrint('Failed to save starred conversations: $e');
    }
  }

  // Retrieve starred conversations from SharedPreferences and check if the current chat is starred
  void checkChatStarredStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? starredConversationList =
        prefs.getStringList('starredConversationList');
    if (starredConversationList != null) {
      if (starredConversationList.contains(widget.serverMsgId)) {
        setState(() {
          isStar = true;
        });
      } else {
        setState(() {
          isStar = false;
        });
      }
    } else {
      setState(() {
        isStar = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Trigger showing the ad once it's loaded

    bool isPrivateChatEnabled =
        SharedPrefs.getBool(SharedPrefsKeys.PRIVATE_CHAT) ?? false;
    Color brightGreen =
        Color.fromRGBO(0, 255, 0, 1.0); // Custom bright green color

    return WillPopScope(
      onWillPop: () async {
        //showExitConversationDialog(context);
        return true; // Prevent the default back button behavior
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          iconTheme: const IconThemeData(
            color: Colors.white, // Set the color of the back arrow here
          ),
          title: const Text(
            Constants.APP_BAR_TITLE,
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: isStar
                  ? const Icon(
                      Icons.star,
                      color: Colors.yellow,
                    )
                  : const Icon(
                      Icons.star_border), // Toggle between the star icons
              onPressed: () {
                setState(() {
                  isStar = !isStar; // Toggle the starred status
                });
                saveStarredConversations(starredConversationList);
              },
            ),
            IconButton(
              icon: Image.asset(
                'assets/doublechat.png', // Replace 'doublechat_disabled.png' with the path to your disabled icon asset
                width: 30,
                height: 30,
                color: isPrivateChatEnabled ? null : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  isPrivateChatEnabled =
                      !isPrivateChatEnabled; // Toggle the state
                  SharedPrefs.setBool(SharedPrefsKeys.PRIVATE_CHAT,
                      isPrivateChatEnabled); // Save the state in shared preferences
                });
                // showPrivateChatDialog(context, isPrivateChatEnabled);
                showPrivateChatDialog(context, isPrivateChatEnabled, () async {
                  //  Navigator.of(context).pop();
                });
              },
            ),
            PopupMenuButton(
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem(
                    value: 'settings',
                    child: Text(Constants.SETTINGS),
                  ),
                  const PopupMenuItem(
                    value: 'tell a friend',
                    child: Text(Constants.TELL_A_FRIEND),
                  ),
                  const PopupMenuItem(
                    value: 'help',
                    child: Text(Constants.HELP),
                  ),
                  const PopupMenuItem(
                    value: 'starred chat',
                    child: Text(Constants.STARRED_CHAT),
                  ),
                  const PopupMenuItem(
                    value: 'report abuse',
                    child: Text(Constants.REPORT_ABUSE),
                  ),
                ];
              },
              onSelected: (value) {
                // Perform action when a pop-up menu item is selected
                switch (value) {
                  case 'settings':
                    //InterstitialAdManager.showInterstitialAd();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsScreen()),
                    );
                    break;
                  case 'tell a friend':
                    String email = Uri.encodeComponent("");
                    String subject =
                        Uri.encodeComponent(Constants.CHECK_OUT_TRUCKCHAT);
                    String body =
                        Uri.encodeComponent(Constants.I_AM_USING_TRUCKCHAT);
                    debugPrint(subject);
                    Uri mail =
                        Uri.parse("mailto:$email?subject=$subject&body=$body");
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
                        builder: (context) => StarredChatList(key: UniqueKey()),
                      ),
                    );
                    break;
                  case 'report abuse':
                    _showReportAbuseDialog(context);
                    break;
                }
              },
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.blue[300],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  widget.topic,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      // itemCount: filteredReplyMsgs.length + sentMessages.length,

                      itemCount: filteredReplyMsgs.length +
                          sentMessages.length +
                          (filteredReplyMsgs.length + sentMessages.length ~/ 4),

                      itemBuilder: (context, index) {
                        if (index % 5 == 4) {
                          // Check if it's the ad banner index
                          // The ad banner should be shown after every 5 items (0-based index)

                          //  return AdBannerWidget();
                          return CustomBannerAd(
                            key: UniqueKey(),
                          );
                          // return Container();
                          // isBannerAdLoaded
                          //     ? SizedBox(
                          //         width: double.infinity,
                          //         height: 60,
                          //         child: AdWidget(
                          //           ad: bannerAd,
                          //         ),
                          //       )
                          //     : const SizedBox();
                        } else {
                          // Calculate the actual index in the news list
                          final newIndex = index - (index ~/ 5);

                          if (newIndex < filteredReplyMsgs.length) {
                            final reply = filteredReplyMsgs[newIndex];
                            final replyMsg = reply.replyMsg;
                            final timestampp = reply.timestamp;
                            final driverName = reply.driverName;
                            final privateChat = reply.privateChat;

                            debugPrint(' private chat $privateChat');

                            DateTime dateTime =
                                DateTime.fromMillisecondsSinceEpoch(timestampp);
                            String formattedDateTime =
                                DateFormat('MMM d, yyyy h:mm:ss a')
                                    .format(dateTime);
                            final timestamp = formattedDateTime;

                            rid = reply.rid;
                            emoji_id = reply.emojiId;
                            timestam = timestampp;

                            bool isCurrentUser = reply.uid ==
                                userId; // Check if the user_id is equal to currentUserId

                            // Find the corresponding Avatar for the emoji_id
                            Avatar? matchingAvatar = avatars.firstWhere(
                              (avatar) => avatar.id == int.parse(reply.emojiId),
                              orElse: () => Avatar(id: 0, imagePath: ''),
                            );
                            // debugPrint('emoji id $emoji_id');
                            // debugPrint('matching avatar id ${matchingAvatar.id}');

                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: isCurrentUser
                                  ? ChatBubble(
                                      clipper: ChatBubbleClipper6(
                                          type: isCurrentUser
                                              ? BubbleType.sendBubble
                                              : BubbleType.receiverBubble),
                                      alignment: isCurrentUser
                                          ? Alignment.topRight
                                          : Alignment.topLeft,
                                      margin:
                                          const EdgeInsets.only(bottom: 16.0),
                                      backGroundColor: isCurrentUser
                                          ? Colors.blue[100]
                                          : Colors.blue[300],
                                      child: isCurrentUser
                                          ? Container(
                                              constraints: const BoxConstraints(
                                                  maxWidth: 250.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      if (SharedPrefs.getString(
                                                              SharedPrefsKeys
                                                                  .CURRENT_USER_AVATAR_IMAGE_PATH) !=
                                                          null)
                                                        Image.asset(
                                                          SharedPrefs.getString(
                                                              SharedPrefsKeys
                                                                  .CURRENT_USER_AVATAR_IMAGE_PATH)!,
                                                          width: 30,
                                                          height: 30,
                                                        ),
                                                      const SizedBox(
                                                          width: 8.0),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              replyMsg,
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .black,
                                                                  fontSize: 20),
                                                            ),
                                                            const SizedBox(
                                                                height: 4.0),
                                                            Text(
                                                              timestamp,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Container(
                                              constraints: const BoxConstraints(
                                                  maxWidth: 250.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      if (matchingAvatar.id !=
                                                          0)
                                                        Stack(
                                                          alignment:
                                                              const Alignment(
                                                                  2.6,
                                                                  -2.4), // Adjust the alignment here

                                                          children: [
                                                            Image.asset(
                                                              matchingAvatar
                                                                  .imagePath,
                                                              width: 30,
                                                              height: 30,
                                                            ),
                                                          ],
                                                        ),
                                                      if (privateChat ==
                                                          '1') // Check if privateChat is 1 to show the indicator
                                                        Padding(
                                                          padding: const EdgeInsets
                                                              .only(
                                                              top: 0.0,
                                                              right: 0.0,
                                                              left: 10,
                                                              bottom:
                                                                  10), // Add padding here
                                                          child: Container(
                                                            width: 10,
                                                            height: 10,
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  brightGreen,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                          ),
                                                        ),
                                                      const SizedBox(
                                                          width: 8.0),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              replyMsg,
                                                              style:
                                                                  const TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 20,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 4.0),
                                                            Text(timestamp),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                    )
                                  : GestureDetector(
                                      onLongPress: () {
                                        // Show the custom dialog when the message is long-pressed
                                        if (privateChat == '1') {
                                          messageLongPressDialog(
                                            context,
                                            () {
                                              // Handle Report Abuse action

                                              reportUser(
                                                  reply.uid.toString(),
                                                  reply.rid.toString(),
                                                  reply.replyMsg);
                                            },
                                            () {
                                              // Handle Ignore User action
                                              showIgnoreUserDialog(context, () {
                                                ignoreUser(getDeviceType(),
                                                    reply.uid.toString());
                                              });
                                            },
                                            () {
                                              // Handle Start Private Chat action
                                              // Implement the logic for starting a private chat here

                                              debugPrint(
                                                  'driver name $driverName ');

                                              String receiverUserName = '';
                                              if (driverName == '') {
                                                List<String> userName =
                                                    replyMsg.split(" ");
                                                receiverUserName = userName[0];
                                              } else {
                                                receiverUserName = driverName;
                                              }

                                              String? chatHandle = SharedPrefs
                                                  .getString(SharedPrefsKeys
                                                      .CURRENT_USER_CHAT_HANDLE);
                                              debugPrint(
                                                  'chat handle $chatHandle');
                                              int? avatarId = SharedPrefs
                                                  .getInt(SharedPrefsKeys
                                                      .CURRENT_USER_AVATAR_ID);

                                              debugPrint(
                                                  'current user emojiid $currentUserEmojiId');
                                              debugPrint('avatar id $avatarId');

                                              if (chatHandle == null) {
                                                showChatHandleDialog(context);
                                              } else if (avatarId == null) {
                                                showAvatarSelectionDialog(
                                                    context);
                                              } else {
                                                String realEmojiId =
                                                    avatarId.toString();
                                                String realChatHandle =
                                                    currentUserHandle ??
                                                        chatHandle;

                                                debugPrint(
                                                    'real emoji id $realEmojiId');
                                                sendRequest(
                                                    currentUserId!,
                                                    reply.uid.toString(),
                                                    realEmojiId,
                                                    currentUserHandle ??
                                                        chatHandle,
                                                    reply.emojiId,
                                                    capitalizeFirstLetter(
                                                        receiverUserName));
                                              }
                                            },
                                          );
                                        } else {
                                          messageLongPressDialogWithoutPrivateChat(
                                            context,
                                            () {
                                              // Handle Report Abuse action

                                              reportUser(
                                                  reply.uid.toString(),
                                                  reply.rid.toString(),
                                                  reply.replyMsg);
                                            },
                                            () {
                                              // Handle Ignore User action
                                              showIgnoreUserDialog(context, () {
                                                ignoreUser(getDeviceType(),
                                                    reply.uid.toString());
                                              });
                                            },
                                          );
                                        }
                                      },
                                      child: ChatBubble(
                                        clipper: ChatBubbleClipper6(
                                            type: isCurrentUser
                                                ? BubbleType.sendBubble
                                                : BubbleType.receiverBubble),
                                        alignment: isCurrentUser
                                            ? Alignment.topRight
                                            : Alignment.topLeft,
                                        margin:
                                            const EdgeInsets.only(bottom: 16.0),
                                        backGroundColor: isCurrentUser
                                            ? Colors.blue[100]
                                            : Colors.blue[300],
                                        child: isCurrentUser
                                            ? Container(
                                                constraints:
                                                    const BoxConstraints(
                                                        maxWidth: 250.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        if (SharedPrefs.getString(
                                                                SharedPrefsKeys
                                                                    .CURRENT_USER_AVATAR_IMAGE_PATH) !=
                                                            null)
                                                          Image.asset(
                                                            SharedPrefs.getString(
                                                                SharedPrefsKeys
                                                                    .CURRENT_USER_AVATAR_IMAGE_PATH)!,
                                                            width: 30,
                                                            height: 30,
                                                          ),
                                                        const SizedBox(
                                                            width: 8.0),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                replyMsg,
                                                                style: const TextStyle(
                                                                    color: Colors
                                                                        .black,
                                                                    fontSize:
                                                                        20),
                                                              ),
                                                              const SizedBox(
                                                                  height: 4.0),
                                                              Text(
                                                                timestamp,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Container(
                                                constraints:
                                                    const BoxConstraints(
                                                        maxWidth: 250.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        if (matchingAvatar.id !=
                                                            0)
                                                          Stack(
                                                            alignment:
                                                                const Alignment(
                                                                    2.6,
                                                                    -2.4), // Adjust the alignment here

                                                            children: [
                                                              Image.asset(
                                                                matchingAvatar
                                                                    .imagePath,
                                                                width: 30,
                                                                height: 30,
                                                              ),
                                                            ],
                                                          ),
                                                        if (privateChat ==
                                                            '1') // Check if privateChat is 1 to show the indicator
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 0.0,
                                                                    right: 0.0,
                                                                    left: 0,
                                                                    bottom:
                                                                        10), // Add padding here
                                                            child: Container(
                                                              width: 10,
                                                              height: 10,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color:
                                                                    brightGreen,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                            ),
                                                          ),
                                                        const SizedBox(
                                                            width: 8.0),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                replyMsg,
                                                                style:
                                                                    const TextStyle(
                                                                  color: Colors
                                                                      .black,
                                                                  fontSize: 20,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  height: 4.0),
                                                              Text(timestamp),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                      ),
                                    ),
                            );
                          } else {}
                        }
                      },
                    ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mic),
                    onPressed: () {
                      _toggleListening();
                    },
                  ),
                  Expanded(
                    child: TextField(
                      minLines: 1,
                      maxLines: 7,
                      controller: messageController,
                      decoration: const InputDecoration(
                        hintText: Constants.COMPOSE_MESSAGE,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  ClipOval(
                    child: FloatingActionButton(
                      onPressed: () async {
                        String message = messageController.text.trim();
                        if (!message.isEmpty) {
                          String? chatHandle = SharedPrefs.getString(
                              SharedPrefsKeys.CURRENT_USER_CHAT_HANDLE);
                          int? avatarId = SharedPrefs.getInt(
                              SharedPrefsKeys.CURRENT_USER_AVATAR_ID);
                          if (chatHandle == null) {
                            showChatHandleDialog(context);
                          } else if (avatarId == null) {
                            showAvatarSelectionDialog(context);
                          } else {
                            if (mounted) {
                              setState(() {
                                sendingMessage = true;
                              });
                            }
                            await sendMessage(
                              messageController.text,
                              widget.serverMsgId,
                              userId,
                            ).then((value) {
                              if (mounted) {
                                setState(() {
                                  messageController.clear();
                                  sendingMessage = false;
                                  WidgetsBinding.instance?.addPostFrameCallback(
                                      (_) => scrollToBottom());
                                });
                              }
                            });
                          }
                        }
                      },
                      backgroundColor: Colors.blue,
                      child: sendingMessage // Check sending state
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ) // Show progress indicator
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            CustomBannerAd(
              key: UniqueKey(),
            )
            // AdmobBanner(
            //   adUnitId: AdHelper.bannerAdUnitId,
            //   adSize: AdmobBannerSize.ADAPTIVE_BANNER(
            //       width: MediaQuery.of(context).size.width.toInt()),
            // )
          ],
        ),
      ),
    );
  }

  Future<void> sendRequest(String senderId, String receiverId, String emojiId,
      String userName, String receiverEmojiId, String receiverUserName) async {
    DatabaseReference requestsRef =
        FirebaseDatabase.instance.ref().child('requests');

    Request request = Request(
      senderId: senderId,
      receiverId: receiverId,
      status: 'pending',
      senderEmojiId: receiverEmojiId,
      senderUserName: receiverUserName,
      receiverEmojiId: emojiId,
      receiverUserName: userName,
    );
    requestsRef.push().set(request.toJson());

    debugPrint('senderid $senderId');
    debugPrint('receiver id $receiverId');

    final receiverFCMToken = await getFCMToken(receiverId);
    // Send notification to the receiver
    if (receiverFCMToken != null) {
      await sendPrivateChatNotification(
          receiverFCMToken ?? '', senderId, receiverId);
    } else {
      debugPrint('receiverFCMToken $receiverFCMToken');
    }

    sendPrivateChatRequest(context, 'Your request has been sent.',
        'Once user accepted your request chat list will appear in private chat tab');
  }

  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<bool> reportUser(
    String flagger_user_id,
    String post_id,
    String user_notes,
  ) async {
    debugPrint('flagger_user_id $flagger_user_id');
    debugPrint('post_id $post_id');
    debugPrint('user_notes $user_notes');

    int status_code = 0;
    final url = Uri.parse(API.REPORT_ABUSE);
    final headers = {'Content-Type': 'application/json'};

    try {
      final entity = {
        'user_id': userId,
        'post_id': post_id,
        'flagger_user_id': flagger_user_id,
        'user_notes': user_notes,
      };

      final response =
          await http.post(url, headers: headers, body: jsonEncode(entity));

      if (response.statusCode == 200) {
        final jsonResult = json.decode(response.body);
        debugPrint('json body ${response.body}');
        status_code = jsonResult['status'];
        debugPrint('status_code $status_code');

        if (status_code == 200) {
          showReportDialog(context, () {
            String email = Uri.encodeComponent("abuse@truckchatapp.com");
            String subject = Uri.encodeComponent("Report Abuse Truck Chat");
            String body = Uri.encodeComponent(
                "User Id:- $flagger_user_id \n\n Message Id:- $post_id \n\n Message:- $user_notes");
            debugPrint(subject);
            Uri mail = Uri.parse("mailto:$email?subject=$subject&body=$body");
            launchUrl(mail);
          });
          // showReportAbuseSuccessDialog(
          //     context, 'User Reported', 'Reported Message: ', user_notes);
        } else if (status_code == 501) {
          showReportDialog(context, () {
            String email = Uri.encodeComponent("abuse@truckchatapp.com");
            String subject = Uri.encodeComponent("Report Abuse Truck Chat");
            String body = Uri.encodeComponent(
                "User Id:- $flagger_user_id \n\n Message Id:- $post_id \n\n Message:- $user_notes");
            debugPrint(subject);
            Uri mail = Uri.parse("mailto:$email?subject=$subject&body=$body");
            launchUrl(mail);
          });
          // showReportAbuseSuccessDialog(context, 'User Already Reported',
          //     'Reported Message: ', user_notes);
        }

        if (jsonResult.containsKey('message')) {
          status_message = jsonResult['message'];
          debugPrint('status_message $status_message');
        } else {
          status_message = '';
        }

        return true;
      } else {
        status_message =
            'Server Error'; // Or handle other status codes appropriately
      }
    } catch (e) {
      status_message = e.toString();
    }

    return false;
  }

  Future<bool> ignoreUser(String deviceType, String ignoredUserId) async {
    final url = Uri.parse(API.IGNORE_USER);
    final headers = {'Content-Type': 'application/json'};

    debugPrint('deviceType $deviceType');
    debugPrint('ignoredUserId $ignoredUserId');

    int status_code = 0;

    try {
      //  final jsonArray = [ignoredUserId];

      final entity = {
        'user_id': userId,
        'device_type': deviceType,
        'ignore_user_id': ignoredUserId,
      };

      final response =
          await http.post(url, headers: headers, body: jsonEncode(entity));

      if (response.statusCode == 200) {
        final jsonResult = json.decode(response.body);
        debugPrint('json body ${response.body}');

        status_code = jsonResult['status'];
        debugPrint('status_code $status_code');

        if (status_code == 200) {
          showIgnoreUserSuccessDialog(context, 'User added in ignored list.');
        } else if (status_code == 500) {
          showIgnoreUserSuccessDialog(context, 'User already ignored');
        }

        if (jsonResult.containsKey('message')) {
          status_message = jsonResult['message'];
          debugPrint('status_message $status_message');
        } else {
          status_message = '';
        }

        return true;
      } else {
        status_message =
            'Server Error'; // Or handle other status codes appropriately
      }
    } catch (e) {
      status_message = e.toString();
    }

    return false;
  }

  void _showReportAbuseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(Constants.REPORT_ABUSE),
          content: const Text(DialogStrings.TO_REPORT_ABUSE),
          actions: [
            TextButton(
              child: const Text(DialogStrings.GOT_IT),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleListening() {
    _startListening();
  }

  void _startListening() async {
    bool available = await _speechToText.initialize();
    if (available) {
      _speechToText.listen(
        onResult: (result) {
          setState(() {
            messageController.text = result.recognizedWords;
            _typedText = result.recognizedWords;
          });
        },
        listenMode: stt.ListenMode.dictation,
        pauseFor: const Duration(seconds: 2),
      );
      setState(() {
        _isListening = true;
      });
    }
  }

  void _stopListening() {
    _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }
}
