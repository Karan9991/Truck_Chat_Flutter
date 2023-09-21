import 'package:chat/chat/new_conversation.dart';
import 'package:chat/chat/chat.dart';
import 'package:chat/main.dart';
import 'package:chat/settings/settings.dart';
import 'package:chat/utils/ads.dart';
import 'package:chat/utils/alert_dialog.dart';
import 'package:chat/utils/constants.dart';
import 'package:chat/utils/lat_lng.dart';
import 'package:chat/utils/register_user.dart';
import 'package:chat/utils/shared_pref.dart';
import 'package:chat/model/get_all_reply_messages.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chat/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:chat/chat/conversation_data.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_settings/app_settings.dart';
//import 'package:geolocator/geolocator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ChatListr extends StatefulWidget {
  final Key key;

  ChatListr({
    required this.key,
  });

  @override
  ChatListrState createState() => ChatListrState();
}

class ChatListrState extends State<ChatListr>
    with AutomaticKeepAliveClientMixin {
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  List<String> conversationTopics = [];
  List<int> conversationTimestamps = [];
  List<String> replyCounts = [];
  List<ReplyMsg> replyMsgs = [];
  int statusCode = 0;
  String statusMessage = '';
  List<String> serverMsgIds = [];
  bool isLoading = false;
  bool isAppInstalled = false;
  // late BannerAd bannerAd;
  // bool isBannerAdLoaded = false;

  @override
  bool get wantKeepAlive => true;

  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();

    getData().then((_) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  // @override
  // void didChangeDependencies() {
  //   // TODO: implement didChangeDependencies

  //       bannerAd = BannerAd(
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
   // bannerAd.dispose();
    super.dispose();
  }

  Future<void> storedList() async {
    List<Conversation> storedConversations = await getStoredConversations();
    for (var conversation in storedConversations) {
      debugPrint('Conversation ID: ${conversation.conversationId}');
      debugPrint('Reply Count: ${conversation.replyCount}');
      debugPrint('Is Read: ${conversation.isRead}');
      debugPrint('---------------------');
    }
  }

  Future<void> getData() async {
    await getConversationsData();
  }

  Future<void> getConversationsData() async {
    String? userId = SharedPrefs.getString(SharedPrefsKeys.USER_ID);
    double? storedLatitude = SharedPrefs.getDouble(SharedPrefsKeys.LATITUDE);
    double? storedLongitude = SharedPrefs.getDouble(SharedPrefsKeys.LONGITUDE);
    // Map<String, double> locationData = await getLocation();
    //   double? storedLatitude = locationData[Constants.LATITUDE]!;
    //   double? storedLongitude = locationData[Constants.LONGITUDE]!;

    Uri url = Uri.parse(API.CONVERSATION_LIST);
    Map<String, dynamic> requestBody = {
      API.USER_ID: userId,
      API.LATITUDE: storedLatitude.toString(),
      API.LONGITUDE: storedLongitude.toString(),
      //   "max_hours": "36",
      //   "max_posts": "80",

      //   "device_package": "com.teletype.truckchat2.android",
    };

    try {
      http.Response response = await http.post(
        url,
        headers: {API.CONTENT_TYPE: API.APPLICATION_JSON},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        debugPrint('---------------ChatList Response---------------');
        debugPrint('server response ${response.body}');

        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        List<dynamic> serverMsgIds = jsonResponse[API.SERVER_MSG_ID];
        List<String> serverMsgIdsList =
            List<String>.from(serverMsgIds.map((e) => e.toString()));

        this.serverMsgIds = serverMsgIdsList;

        int statusCode = 0;
        String counts = '';
        int conversationTimestamp = 0;
        List<ReplyMsg> replyMsgs = [];
        String statusMessage = '';
        String conversationTopic = '';

        List<Conversation> conversations = [];
        List<Conversation> storedConversations = await getStoredConversations();

        final url = Uri.parse(API.CHAT);

        // print('Stored Conversations: $storedConversations');

        for (var serverMessageId in serverMsgIdsList) {
          Map<String, dynamic> requestBody = {
            API.SERVER_MESSAGE_ID: serverMessageId,
          };

          try {
            http.Response response = await http.post(
              url,
              headers: {API.CONTENT_TYPE: API.APPLICATION_JSON},
              body: jsonEncode(requestBody),
            );

            if (response.statusCode == 200) {
              final result = response.body;
              debugPrint(
                  '---------------Messsage Replies Response---------------');

              debugPrint(response.body);

              try {
                final jsonResult = jsonDecode(result);

                counts = jsonResult[API.COUNTS];
                conversationTopic = jsonResult[API.ORIGINAL];
                conversationTimestamp = jsonResult[API.TIMESTAMP] ?? 0;

                conversationTopics.add(conversationTopic);
                conversationTimestamps.add(conversationTimestamp);
                replyCounts.add(counts);

                // Create a Conversation object
                Conversation conversation = Conversation(
                  conversationId: serverMessageId,
                  topic: conversationTopic,
                  timestamp: conversationTimestamp,
                  replyCount: counts,
                  isRead: false,
                );

                // Check if the conversation already exists in stored conversations
                Conversation existingConversation =
                    storedConversations.firstWhere(
                  (c) => c.conversationId == serverMessageId,
                  orElse: () => conversation,
                );

                // Check if the reply count matches
                if (existingConversation.replyCount != counts) {
                  // If reply count doesn't match, mark as read
                  conversation.isRead = false;
                  //  print('Marked as unread: $serverMessageId');
                  // print(
                  //    'Conversation: $serverMessageId - Stored Reply Count: ${existingConversation.replyCount}, Fetched Reply Count: $counts');
                } else {
                  // Otherwise, preserve the existing isRead status
                  conversation.isRead = existingConversation.isRead;
                }

                if (existingConversation.isDeleted == false) {
                  conversation.isDeleted = false;
                } else {
                  conversation.isDeleted = true;
                }

                conversations.add(conversation);
              } catch (e) {
                // Handle JSON decoding error
              }
            } else {
              // Handle connection error
            }
          } catch (e) {
            // Handle exception
          }
        }

        // Store conversations in shared preferences
        await storeConversations(conversations);
        setState(() {
          // isLoading = false;
        });
      } else {
        debugPrint('server error else');
        // Handle connection error
      }
    } catch (e) {
      debugPrint('error catch $e');
      // Handle exception
    }
  }

  Future<void> _deleteChat(String conversationId) async {
    List<Conversation> storedConversations = await getStoredConversations();
    //print('Before Deletion:');
    //  for (var conversation in storedConversations) {
    // print(
    //     'Conversation ID: ${conversation.conversationId}, isDeleted: ${conversation.isDeleted}');
    // }

    int conversationIndex = storedConversations.indexWhere(
        (conversation) => conversation.conversationId == conversationId);

    if (conversationIndex != -1) {
      storedConversations[conversationIndex].isDeleted = true;
      await storeConversations(storedConversations);

      setState(() {
        //  print('After Deletion:');
        //  for (var conversation in storedConversations) {
        // print(
        //     'Conversation ID: ${conversation.conversationId}, isDeleted: ${conversation.isDeleted}');
        // }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: null,
      body: FutureBuilder<List<Conversation>>(
        future: getStoredConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              isLoading) {
            // if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.connectionState == ConnectionState.done) {
            List<Conversation> storedConversations =
                snapshot.data ?? []; // Use cached data

            if (storedConversations.isNotEmpty) {
              final filteredConversations = storedConversations
                  .where((conversation) => !conversation.isDeleted)
                  .toList();

              return ListView.builder(
                  itemCount: filteredConversations.length +
                      (filteredConversations.length ~/ 4),
                  itemBuilder: (context, index) {
                    if (index % 5 == 4) {
                      // Check if it's the ad
                      // index
                      // The ad banner should be shown after every 5 items (0-based index)
                      // return Container();
                      return CustomBannerAd(
                        key: UniqueKey(),
                      );
                      // return isBannerAdLoaded
                      //     ? SizedBox(
                      //         width: double.infinity,
                      //         height: 60,
                      //         child: AdWidget(
                      //           ad: bannerAd,
                      //         ),
                      //       )
                      //     : const SizedBox();
                    } else {
                      final conversationIndex = index - (index ~/ 5);
                      if (conversationIndex >= filteredConversations.length) {
                        // Return an empty container for out-of-range index
                        return Container();
                      }
                      final conversation =
                          filteredConversations[conversationIndex];

                      final topic =
                          conversation.topic; // Use topic from conversation
                      final timestampp = conversation
                          .timestamp; // Use timestamp from conversation
                      final count = conversation
                          .replyCount; // Use replyCount from conversation
                      final serverMsgID = conversation
                          .conversationId; // Use serverMsgId from conversation

                      DateTime dateTime =
                          DateTime.fromMillisecondsSinceEpoch(timestampp);
                      String formattedDateTime =
                          DateFormat('MMM d, yyyy h:mm:ss a').format(dateTime);
                      final timestamp = formattedDateTime;
                      final isRead = conversation.isRead;

                      // print('List item read status $isRead');

                      return GestureDetector(
                        onTap: () async {
                          if (!isRead) {
                            // Mark conversation as read
                            conversation.isRead = true;
                            await storeConversations(storedConversations);
                            setState(() {}); // Trigger a rebuild of the widget
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Chat(
                                topic: topic,
                                serverMsgId: serverMsgID,
                              ),
                            ),
                          );
                        },
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    isRead
                                        ? _buildDialogOption(
                                            DialogStrings.MARK_CHAT_THIS_UNREAD,
                                            DialogStrings.MARK_CHAT_UNREAD,
                                            () async {
                                            // print('Chat UnRead');
                                            conversation.isRead = false;
                                            await storeConversations(
                                                storedConversations);
                                            setState(() {});

                                            Navigator.of(context)
                                                .pop(); // Close the dialog if needed
                                          })
                                        : _buildDialogOption(
                                            DialogStrings.MARK_CHAT_READ,
                                            DialogStrings.MESSAGE_ICON_WILL,
                                            () async {
                                            // print('Chat Read');
                                            conversation.isRead = true;
                                            await storeConversations(
                                                storedConversations);
                                            setState(() {});

                                            Navigator.of(context)
                                                .pop(); // Close the dialog if needed
                                          }),
                                    _buildDialogOption(
                                      DialogStrings
                                          .DELETE_CHAT, // New option: Delete Chat
                                      DialogStrings
                                          .CHAT_WILL_BE_DELETED, // New message for deletion
                                      () async {
                                        Navigator.of(context).pop();
                                        showDeleteChatDialog(
                                            context,
                                            () => {
                                                  _deleteChat(conversation
                                                      .conversationId),
                                                });
                                      },
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text(DialogStrings.CANCEL),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Card(
                          elevation: 2,
                          color: Colors.blue[300],
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                isRead
                                    ? const SizedBox()
                                    : const Row(
                                        children: [
                                          Icon(
                                            Icons.chat,
                                            size: 17,
                                          ),
                                          SizedBox(width: 8),
                                        ],
                                      ),
                                Text(
                                  topic,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                                  overflow: TextOverflow
                                      .ellipsis, // Show ellipsis if the text overflows
                                  maxLines: 3, // Show only one line of text
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(bottom: 5, top: 8),
                                  child: Text(
                                    '${Constants.LAST_ACTIVE}$timestamp',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Text(
                                    '${Constants.REPLIES}$count',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isRead
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios,
                                color: Colors.white),
                          ),
                        ),
                      );
                    }
                  });
            } else {
              return const Center(
                // child: Text(''),
                child: CircularProgressIndicator(),
              );
            }
          } else {
            // Handle error case
            return const Center(
              child: Text(''),

              // child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  Widget _buildDialogOption(String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

//performance profiling
// import 'package:chat/chat/new_conversation.dart';
// import 'package:chat/chat/chat.dart';
// import 'package:chat/main.dart';
// import 'package:chat/settings/settings.dart';
// import 'package:chat/utils/ads.dart';
// import 'package:chat/utils/alert_dialog.dart';
// import 'package:chat/utils/constants.dart';
// import 'package:chat/utils/lat_lng.dart';
// import 'package:chat/utils/register_user.dart';
// import 'package:chat/utils/shared_pref.dart';
// import 'package:chat/model/get_all_reply_messages.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:chat/home_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'dart:async';
// import 'package:chat/chat/conversation_data.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:app_settings/app_settings.dart';
// //import 'package:geolocator/geolocator.dart';

// class ChatListr extends StatefulWidget {
//   final Key key;

//   ChatListr({
//     required this.key,
//   });

//   @override
//   ChatListrState createState() => ChatListrState();
// }

// class ChatListrState extends State<ChatListr>
//     with AutomaticKeepAliveClientMixin {
//   final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
//   List<String> conversationTopics = [];
//   List<int> conversationTimestamps = [];
//   List<String> replyCounts = [];
//   List<ReplyMsg> replyMsgs = [];
//   int statusCode = 0;
//   String statusMessage = '';
//   List<String> serverMsgIds = [];
//   bool isLoading = false;
//   bool isAppInstalled = false;

//   @override
//   bool get wantKeepAlive => true;

//   SharedPreferences? prefs;

//   @override
//   void initState() {
//     super.initState();

//     getData().then((_) {
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   Future<void> storedList() async {
//     List<Conversation> storedConversations = await getStoredConversations();
//     for (var conversation in storedConversations) {
//       debugPrint('Conversation ID: ${conversation.conversationId}');
//       debugPrint('Reply Count: ${conversation.replyCount}');
//       debugPrint('Is Read: ${conversation.isRead}');
//       debugPrint('---------------------');
//     }
//   }

//   Future<void> getData() async {
//     await getConversationsData();
//   }

//   Future<void> getConversationsData() async {
//     String? userId = SharedPrefs.getString(SharedPrefsKeys.USER_ID);
//     double? storedLatitude = SharedPrefs.getDouble(SharedPrefsKeys.LATITUDE);
//     double? storedLongitude = SharedPrefs.getDouble(SharedPrefsKeys.LONGITUDE);
//     // Map<String, double> locationData = await getLocation();
//     //   double? storedLatitude = locationData[Constants.LATITUDE]!;
//     //   double? storedLongitude = locationData[Constants.LONGITUDE]!;

//     Uri url = Uri.parse(API.CONVERSATION_LIST);
//     Map<String, dynamic> requestBody = {
//       API.USER_ID: userId,
//       API.LATITUDE: storedLatitude.toString(),
//       API.LONGITUDE: storedLongitude.toString(),
//       //   "max_hours": "36",
//       //   "max_posts": "80",

//       //   "device_package": "com.teletype.truckchat2.android",
//     };

//     try {
//       http.Response response = await http.post(
//         url,
//         headers: {API.CONTENT_TYPE: API.APPLICATION_JSON},
//         body: jsonEncode(requestBody),
//       );

//       if (response.statusCode == 200) {
//         debugPrint('---------------ChatList Response---------------');
//         debugPrint('server response ${response.body}');

//         Map<String, dynamic> jsonResponse = jsonDecode(response.body);

//         List<dynamic> serverMsgIds = jsonResponse[API.SERVER_MSG_ID];
//         List<String> serverMsgIdsList =
//             List<String>.from(serverMsgIds.map((e) => e.toString()));

//         this.serverMsgIds = serverMsgIdsList;

//         int statusCode = 0;
//         String counts = '';
//         int conversationTimestamp = 0;
//         List<ReplyMsg> replyMsgs = [];
//         String statusMessage = '';
//         String conversationTopic = '';

//         List<Conversation> conversations = [];
//         List<Conversation> storedConversations = await getStoredConversations();

//         final url = Uri.parse(API.CHAT);

//         // print('Stored Conversations: $storedConversations');

//         for (var serverMessageId in serverMsgIdsList) {
//           Map<String, dynamic> requestBody = {
//             API.SERVER_MESSAGE_ID: serverMessageId,
//           };

//           try {
//             http.Response response = await http.post(
//               url,
//               headers: {API.CONTENT_TYPE: API.APPLICATION_JSON},
//               body: jsonEncode(requestBody),
//             );

//             if (response.statusCode == 200) {
//               final result = response.body;
//               debugPrint(
//                   '---------------Messsage Replies Response---------------');

//               debugPrint(response.body);

//               try {
//                 final jsonResult = jsonDecode(result);

//                 counts = jsonResult[API.COUNTS];
//                 conversationTopic = jsonResult[API.ORIGINAL];
//                 conversationTimestamp = jsonResult[API.TIMESTAMP] ?? 0;

//                 conversationTopics.add(conversationTopic);
//                 conversationTimestamps.add(conversationTimestamp);
//                 replyCounts.add(counts);

//                 // Create a Conversation object
//                 Conversation conversation = Conversation(
//                   conversationId: serverMessageId,
//                   topic: conversationTopic,
//                   timestamp: conversationTimestamp,
//                   replyCount: counts,
//                   isRead: false,
//                 );

//                 // Check if the conversation already exists in stored conversations
//                 Conversation existingConversation =
//                     storedConversations.firstWhere(
//                   (c) => c.conversationId == serverMessageId,
//                   orElse: () => conversation,
//                 );

//                 // Check if the reply count matches
//                 if (existingConversation.replyCount != counts) {
//                   // If reply count doesn't match, mark as read
//                   conversation.isRead = false;
//                   //  print('Marked as unread: $serverMessageId');
//                   // print(
//                   //    'Conversation: $serverMessageId - Stored Reply Count: ${existingConversation.replyCount}, Fetched Reply Count: $counts');
//                 } else {
//                   // Otherwise, preserve the existing isRead status
//                   conversation.isRead = existingConversation.isRead;
//                 }

//                 if (existingConversation.isDeleted == false) {
//                   conversation.isDeleted = false;
//                 } else {
//                   conversation.isDeleted = true;
//                 }

//                 conversations.add(conversation);
//               } catch (e) {
//                 // Handle JSON decoding error
//               }
//             } else {
//               // Handle connection error
//             }
//           } catch (e) {
//             // Handle exception
//           }
//         }

//         // Store conversations in shared preferences
//         await storeConversations(conversations);
//         setState(() {
//           // isLoading = false;
//         });
//       } else {
//         debugPrint('server error else');
//         // Handle connection error
//       }
//     } catch (e) {
//       debugPrint('error catch $e');
//       // Handle exception
//     }
//   }

//   Future<void> _deleteChat(String conversationId) async {
//     List<Conversation> storedConversations = await getStoredConversations();
//     //print('Before Deletion:');
//     //  for (var conversation in storedConversations) {
//     // print(
//     //     'Conversation ID: ${conversation.conversationId}, isDeleted: ${conversation.isDeleted}');
//     // }

//     int conversationIndex = storedConversations.indexWhere(
//         (conversation) => conversation.conversationId == conversationId);

//     if (conversationIndex != -1) {
//       storedConversations[conversationIndex].isDeleted = true;
//       await storeConversations(storedConversations);

//       setState(() {
//         //  print('After Deletion:');
//         //  for (var conversation in storedConversations) {
//         // print(
//         //     'Conversation ID: ${conversation.conversationId}, isDeleted: ${conversation.isDeleted}');
//         // }
//       });
//     }
//   }

//   // @override
//   // Widget build(BuildContext context) {
//   //   super.build(context);
//   //   return Scaffold(
//   //     appBar: null,
//   //     body: FutureBuilder<List<Conversation>>(
//   //       future: getStoredConversations(),
//   //       builder: (context, snapshot) {
//   //         if (snapshot.connectionState == ConnectionState.waiting ||
//   //             isLoading) {
//   //           // if (isLoading) {
//   //           return const Center(
//   //             child: CircularProgressIndicator(),
//   //           );
//   //         } else if (snapshot.connectionState == ConnectionState.done) {
//   //           List<Conversation> storedConversations =
//   //               snapshot.data ?? []; // Use cached data

//   //           if (storedConversations.isNotEmpty) {
//   //             final filteredConversations = storedConversations
//   //                 .where((conversation) => !conversation.isDeleted)
//   //                 .toList();

//   //             return ListView.builder(
//   //                 itemCount: filteredConversations.length +
//   //                     (filteredConversations.length ~/ 4),
//   //                 itemBuilder: (context, index) {
//   //                   if (index % 5 == 4) {
//   //                     // Check if it's the ad
//   //                     // index
//   //                     // The ad banner should be shown after every 5 items (0-based index)
//   //                     //return Container();
//   //                     return CustomBannerAd(
//   //                       key: UniqueKey(),
//   //                     );
//   //                   } else {
//   //                     final conversationIndex = index - (index ~/ 5);
//   //                     if (conversationIndex >= filteredConversations.length) {
//   //                       // Return an empty container for out-of-range index
//   //                       return Container();
//   //                     }
//   //                     final conversation =
//   //                         filteredConversations[conversationIndex];

//   //                     final topic =
//   //                         conversation.topic; // Use topic from conversation
//   //                     final timestampp = conversation
//   //                         .timestamp; // Use timestamp from conversation
//   //                     final count = conversation
//   //                         .replyCount; // Use replyCount from conversation
//   //                     final serverMsgID = conversation
//   //                         .conversationId; // Use serverMsgId from conversation

//   //                     DateTime dateTime =
//   //                         DateTime.fromMillisecondsSinceEpoch(timestampp);
//   //                     String formattedDateTime =
//   //                         DateFormat('MMM d, yyyy h:mm:ss a').format(dateTime);
//   //                     final timestamp = formattedDateTime;
//   //                     final isRead = conversation.isRead;

//   //                     // print('List item read status $isRead');

//   //                     return GestureDetector(
//   //                       onTap: () async {
//   //                         if (!isRead) {
//   //                           // Mark conversation as read
//   //                           conversation.isRead = true;
//   //                           await storeConversations(storedConversations);
//   //                           setState(() {}); // Trigger a rebuild of the widget
//   //                         }

//   //                         Navigator.push(
//   //                           context,
//   //                           MaterialPageRoute(
//   //                             builder: (context) => Chat(
//   //                               topic: topic,
//   //                               serverMsgId: serverMsgID,
//   //                             ),
//   //                           ),
//   //                         );
//   //                       },
//   //                       onLongPress: () {
//   //                         showDialog(
//   //                           context: context,
//   //                           builder: (BuildContext context) {
//   //                             return AlertDialog(
//   //                               content: Column(
//   //                                 mainAxisSize: MainAxisSize.min,
//   //                                 crossAxisAlignment: CrossAxisAlignment.start,
//   //                                 children: [
//   //                                   isRead
//   //                                       ? _buildDialogOption(
//   //                                           DialogStrings.MARK_CHAT_THIS_UNREAD,
//   //                                           DialogStrings.MARK_CHAT_UNREAD,
//   //                                           () async {
//   //                                           // print('Chat UnRead');
//   //                                           conversation.isRead = false;
//   //                                           await storeConversations(
//   //                                               storedConversations);
//   //                                           setState(() {});

//   //                                           Navigator.of(context)
//   //                                               .pop(); // Close the dialog if needed
//   //                                         })
//   //                                       : _buildDialogOption(
//   //                                           DialogStrings.MARK_CHAT_READ,
//   //                                           DialogStrings.MESSAGE_ICON_WILL,
//   //                                           () async {
//   //                                           // print('Chat Read');
//   //                                           conversation.isRead = true;
//   //                                           await storeConversations(
//   //                                               storedConversations);
//   //                                           setState(() {});

//   //                                           Navigator.of(context)
//   //                                               .pop(); // Close the dialog if needed
//   //                                         }),
//   //                                   _buildDialogOption(
//   //                                     DialogStrings
//   //                                         .DELETE_CHAT, // New option: Delete Chat
//   //                                     DialogStrings
//   //                                         .CHAT_WILL_BE_DELETED, // New message for deletion
//   //                                     () async {
//   //                                       Navigator.of(context).pop();
//   //                                       showDeleteChatDialog(
//   //                                           context,
//   //                                           () => {
//   //                                                 _deleteChat(conversation
//   //                                                     .conversationId),
//   //                                               });
//   //                                     },
//   //                                   ),
//   //                                 ],
//   //                               ),
//   //                               actions: [
//   //                                 TextButton(
//   //                                   child: const Text(DialogStrings.CANCEL),
//   //                                   onPressed: () {
//   //                                     Navigator.of(context).pop();
//   //                                   },
//   //                                 ),
//   //                               ],
//   //                             );
//   //                           },
//   //                         );
//   //                       },
//   //                       child: Card(
//   //                         elevation: 2,
//   //                         color: Colors.blue[300],
//   //                         margin: const EdgeInsets.symmetric(
//   //                             horizontal: 16, vertical: 8),
//   //                         child: ListTile(
//   //                           title: Column(
//   //                             crossAxisAlignment: CrossAxisAlignment.start,
//   //                             children: [
//   //                               isRead
//   //                                   ? const SizedBox()
//   //                                   : const Row(
//   //                                       children: [
//   //                                         Icon(
//   //                                           Icons.chat,
//   //                                           size: 17,
//   //                                         ),
//   //                                         SizedBox(width: 8),
//   //                                       ],
//   //                                     ),
//   //                               Text(
//   //                                 topic,
//   //                                 style: TextStyle(
//   //                                   fontSize: 18,
//   //                                   fontWeight: isRead
//   //                                       ? FontWeight.normal
//   //                                       : FontWeight.bold,
//   //                                 ),
//   //                                 overflow: TextOverflow
//   //                                     .ellipsis, // Show ellipsis if the text overflows
//   //                                 maxLines: 3, // Show only one line of text
//   //                               ),
//   //                             ],
//   //                           ),
//   //                           subtitle: Column(
//   //                             crossAxisAlignment: CrossAxisAlignment.start,
//   //                             children: [
//   //                               Padding(
//   //                                 padding: EdgeInsets.only(bottom: 5, top: 8),
//   //                                 child: Text(
//   //                                   '${Constants.LAST_ACTIVE}$timestamp',
//   //                                   style: const TextStyle(fontSize: 14),
//   //                                 ),
//   //                               ),
//   //                               Padding(
//   //                                 padding: const EdgeInsets.only(bottom: 5),
//   //                                 child: Text(
//   //                                   '${Constants.REPLIES}$count',
//   //                                   style: TextStyle(
//   //                                     fontSize: 14,
//   //                                     fontWeight: isRead
//   //                                         ? FontWeight.normal
//   //                                         : FontWeight.bold,
//   //                                   ),
//   //                                 ),
//   //                               ),
//   //                             ],
//   //                           ),
//   //                           trailing: const Icon(Icons.arrow_forward_ios,
//   //                               color: Colors.white),
//   //                         ),
//   //                       ),
//   //                     );
//   //                   }
//   //                 });
//   //           } else {
//   //             return const Center(
//   //               // child: Text(''),
//   //               child: CircularProgressIndicator(),
//   //             );
//   //           }
//   //         } else {
//   //           // Handle error case
//   //           return const Center(
//   //             child: Text(''),

//   //             // child: CircularProgressIndicator(),
//   //           );
//   //         }
//   //       },
//   //     ),
//   //   );
//   // }

//   @override
//   Widget build(BuildContext context) {
//     super.build(context);

//     return Scaffold(
//       appBar: null,
//       body: FutureBuilder<List<Conversation>>(
//         future: getStoredConversations(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting ||
//               isLoading) {
//             return const Center(
//               child: CircularProgressIndicator(),
//             );
//           } else if (snapshot.hasError) {
//             return const Center(
//               child: Text('Error fetching data'), // Show an error message
//             );
//           }

//           List<Conversation> storedConversations = snapshot.data ?? [];
//           if (storedConversations.isEmpty) {
//             return const Center(
//               child: CircularProgressIndicator(),
//             );
//           }

//           final filteredConversations = storedConversations
//               .where((conversation) => !conversation.isDeleted)
//               .toList();

//           return ListView.separated(
//               itemCount: filteredConversations.length,
//               separatorBuilder: (BuildContext context, int index) =>
//                   const Divider(height: 1, color: Colors.white), // Added a separator
//               itemBuilder: (context, index) {
//                 if (index % 5 == 4) {
//                   // This is the index where the ad banner should be shown
//                   return CustomBannerAd(
//                     key: UniqueKey(),
//                   );
//                 } else {
//                   final conversationIndex = index - (index ~/ 5);
//                   if (conversationIndex >= filteredConversations.length) {
//                     // Return an empty container for out-of-range index
//                     return Container();
//                   }

//                   final conversation = filteredConversations[index];
//                   final topic = conversation.topic;
//                   final timestamp = DateTime.fromMillisecondsSinceEpoch(
//                           conversation.timestamp)
//                       .toLocal()
//                       .toString()
//                       .split('.')[0];
//                   final count = conversation.replyCount;
//                   final isRead = conversation.isRead;

//                   return GestureDetector(
//                     onTap: () async {
//                       if (!isRead) {
//                         conversation.isRead = true;
//                         await storeConversations(storedConversations);
//                         setState(() {});
//                       }

//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => Chat(
//                             topic: topic,
//                             serverMsgId: conversation.conversationId,
//                           ),
//                         ),
//                       );
//                     },
//                     onLongPress: () {
//                       showDialog(
//                         context: context,
//                         builder: (BuildContext context) {
//                           return AlertDialog(
//                             content: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 _buildDialogOption(
//                                   isRead
//                                       ? DialogStrings.MARK_CHAT_THIS_UNREAD
//                                       : DialogStrings.MARK_CHAT_READ,
//                                   isRead
//                                       ? DialogStrings.MARK_CHAT_UNREAD
//                                       : DialogStrings.MESSAGE_ICON_WILL,
//                                   () async {
//                                     conversation.isRead = !isRead;
//                                     await storeConversations(
//                                         storedConversations);
//                                     setState(() {});
//                                     Navigator.of(context).pop();
//                                   },
//                                 ),
//                                 _buildDialogOption(
//                                   DialogStrings.DELETE_CHAT,
//                                   DialogStrings.CHAT_WILL_BE_DELETED,
//                                   () async {
//                                     Navigator.of(context).pop();
//                                     showDeleteChatDialog(
//                                       context,
//                                       () => _deleteChat(
//                                           conversation.conversationId),
//                                     );
//                                   },
//                                 ),
//                               ],
//                             ),
//                             actions: [
//                               TextButton(
//                                 child: const Text(DialogStrings.CANCEL),
//                                 onPressed: () {
//                                   Navigator.of(context).pop();
//                                 },
//                               ),
//                             ],
//                           );
//                         },
//                       );
//                     },
//                     child: Card(
//                       elevation: 2,
//                       color: Colors.blue[300],
//                       margin: const EdgeInsets.symmetric(
//                           horizontal: 16, vertical: 8),
//                       child: ListTile(
//                         title: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             if (!isRead)
//                               const Row(
//                                 children: [
//                                   Icon(
//                                     Icons.chat,
//                                     size: 17,
//                                   ),
//                                   SizedBox(width: 8),
//                                 ],
//                               ),
//                             Text(
//                               topic,
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: isRead
//                                     ? FontWeight.normal
//                                     : FontWeight.bold,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                               maxLines: 3,
//                             ),
//                           ],
//                         ),
//                         subtitle: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Padding(
//                               padding: const EdgeInsets.only(bottom: 5, top: 8),
//                               child: Text(
//                                 '${Constants.LAST_ACTIVE}$timestamp',
//                                 style: const TextStyle(fontSize: 14),
//                               ),
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.only(bottom: 5),
//                               child: Text(
//                                 '${Constants.REPLIES}$count',
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   fontWeight: isRead
//                                       ? FontWeight.normal
//                                       : FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         trailing: const Icon(Icons.arrow_forward_ios,
//                             color: Colors.white),
//                       ),
//                     ),
//                   );
//                 }
                
//               });
//         },
//       ),
//     );
//   }

//   //   Widget _buildDialogOption(String title, String subtitle, VoidCallback onTap) {
// //     return GestureDetector(
// //       onTap: onTap,
// //       child: Padding(
// //         padding: const EdgeInsets.only(bottom: 16.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Text(
// //               title,
// //               style: const TextStyle(
// //                 fontWeight: FontWeight.bold,
// //                 fontSize: 18,
// //               ),
// //             ),
// //             const SizedBox(height: 4),
// //             Text(
// //               subtitle,
// //               style: const TextStyle(color: Colors.grey),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

//   Widget _buildDialogOption(String title, String subtitle, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Padding(
//         padding: const EdgeInsets.only(bottom: 16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               subtitle,
//               style: const TextStyle(color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
