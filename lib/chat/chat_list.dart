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
// import 'package:geolocator/geolocator.dart';

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

//   LocationPermission? _locationPermission;

//   @override
//   bool get wantKeepAlive => true;

//   SharedPreferences? prefs;

//   @override
//   void initState() {
//     super.initState();

//     // WidgetsBinding.instance.addObserver(this);

//     getData().then((_) {
//       setState(() {
//         isLoading = false;
//       });
//     });
//   }

//   @override
//   void dispose() {
//     //  WidgetsBinding.instance.removeObserver(this);

//     super.dispose();
//   }

//   Future<void> storedList() async {
//     List<Conversation> storedConversations = await getStoredConversations();
//     for (var conversation in storedConversations) {
//       print('Conversation ID: ${conversation.conversationId}');
//       print('Reply Count: ${conversation.replyCount}');
//       print('Is Read: ${conversation.isRead}');
//       print('---------------------');
//     }
//   }

//   Future<void> getData() async {
//     _locationPermission = await Geolocator.checkPermission();

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
//     };

//     try {
//       http.Response response = await http.post(
//         url,
//         headers: {API.CONTENT_TYPE: API.APPLICATION_JSON},
//         body: jsonEncode('response body $requestBody'),
//       );

//       if (response.statusCode == 200) {
//         print('---------------ChatList Response---------------');
//         print('server response ${response.body}');

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
//               print('---------------Messsage Replies Response---------------');

//               print(response.body);

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
//         print('server error else');
//         // Handle connection error
//       }
//     } catch (e) {
//       print('error catch $e');
//       // Handle exception
//     }
//   }

//   Future<void> _deleteChat(String conversationId) async {
//     List<Conversation> storedConversations = await getStoredConversations();
//     print('Before Deletion:');
//     for (var conversation in storedConversations) {
//       print(
//           'Conversation ID: ${conversation.conversationId}, isDeleted: ${conversation.isDeleted}');
//     }

//     int conversationIndex = storedConversations.indexWhere(
//         (conversation) => conversation.conversationId == conversationId);

//     if (conversationIndex != -1) {
//       storedConversations[conversationIndex].isDeleted = true;
//       await storeConversations(storedConversations);

//       setState(() {
//         print('After Deletion:');
//         for (var conversation in storedConversations) {
//           print(
//               'Conversation ID: ${conversation.conversationId}, isDeleted: ${conversation.isDeleted}');
//         }
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: null,
//       body: FutureBuilder<List<Conversation>>(
//         future: getStoredConversations(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting ||
//               isLoading) {
//             // if (isLoading) {
//             return Center(
//               child: CircularProgressIndicator(),
//             );
//           } else if (snapshot.connectionState == ConnectionState.done) {
//             List<Conversation> storedConversations =
//                 snapshot.data ?? []; // Use cached data

//             if (storedConversations.isNotEmpty) {
//               final filteredConversations = storedConversations
//                   .where((conversation) => !conversation.isDeleted)
//                   .toList();

//               return ListView.builder(
//                   itemCount: filteredConversations.length +
//                       (filteredConversations.length ~/ 4),
//                   itemBuilder: (context, index) {
//                     if (index % 5 == 4) {
//                       // Check if it's the ad banner index
//                       // The ad banner should be shown after every 5 items (0-based index)
//                       return CustomBannerAd(
//                         key: UniqueKey(),
//                       );
//                     } else {
//                       final conversationIndex = index - (index ~/ 5);
//                       if (conversationIndex >= filteredConversations.length) {
//                         // Return an empty container for out-of-range index
//                         return Container();
//                       }
//                       final conversation =
//                           filteredConversations[conversationIndex];

//                       final topic =
//                           conversation.topic; // Use topic from conversation
//                       final timestampp = conversation
//                           .timestamp; // Use timestamp from conversation
//                       final count = conversation
//                           .replyCount; // Use replyCount from conversation
//                       final serverMsgID = conversation
//                           .conversationId; // Use serverMsgId from conversation

//                       DateTime dateTime =
//                           DateTime.fromMillisecondsSinceEpoch(timestampp);
//                       String formattedDateTime =
//                           DateFormat('MMM d, yyyy h:mm:ss a').format(dateTime);
//                       final timestamp = formattedDateTime;
//                       final isRead = conversation.isRead;

//                       // print('List item read status $isRead');

//                       return GestureDetector(
//                         onTap: () async {
//                           if (!isRead) {
//                             // Mark conversation as read
//                             conversation.isRead = true;
//                             await storeConversations(storedConversations);
//                             setState(() {}); // Trigger a rebuild of the widget
//                           }

//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => Chat(
//                                 topic: topic,
//                                 serverMsgId: serverMsgID,
//                               ),
//                             ),
//                           ).then((_) {
//                             // Called when returning from the chat screen
//                             setState(() {}); // Trigger a rebuild of the widget
//                           });
//                         },
//                         onLongPress: () {
//                           showDialog(
//                             context: context,
//                             builder: (BuildContext context) {
//                               return AlertDialog(
//                                 content: Column(
//                                   mainAxisSize: MainAxisSize.min,
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     isRead
//                                         ? _buildDialogOption(
//                                             DialogStrings.MARK_CHAT_THIS_UNREAD,
//                                             DialogStrings.MARK_CHAT_UNREAD,
//                                             () async {
//                                             print('Chat UnRead');
//                                             conversation.isRead = false;
//                                             await storeConversations(
//                                                 storedConversations);
//                                             setState(() {});

//                                             Navigator.of(context)
//                                                 .pop(); // Close the dialog if needed
//                                           })
//                                         : _buildDialogOption(
//                                             DialogStrings.MARK_CHAT_READ,
//                                             DialogStrings.MESSAGE_ICON_WILL,
//                                             () async {
//                                             print('Chat Read');
//                                             conversation.isRead = true;
//                                             await storeConversations(
//                                                 storedConversations);
//                                             setState(() {});

//                                             Navigator.of(context)
//                                                 .pop(); // Close the dialog if needed
//                                           }),
//                                     _buildDialogOption(
//                                       DialogStrings
//                                           .DELETE_CHAT, // New option: Delete Chat
//                                       DialogStrings
//                                           .CHAT_WILL_BE_DELETED, // New message for deletion
//                                       () async {
//                                         Navigator.of(context).pop();
//                                         showDeleteChatDialog(
//                                             context,
//                                             () => {
//                                                   _deleteChat(conversation
//                                                       .conversationId),
//                                                 });
//                                       },
//                                     ),
//                                   ],
//                                 ),
//                                 actions: [
//                                   TextButton(
//                                     child: Text(DialogStrings.CANCEL),
//                                     onPressed: () {
//                                       Navigator.of(context).pop();
//                                     },
//                                   ),
//                                 ],
//                               );
//                             },
//                           );
//                         },
//                         child: Card(
//                           elevation: 2,
//                           color: Colors.blue[300],
//                           margin:
//                               EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                           child: ListTile(
//                             title: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 isRead
//                                     ? SizedBox()
//                                     : Row(
//                                         children: [
//                                           Icon(
//                                             Icons.chat,
//                                             size: 17,
//                                           ),
//                                           SizedBox(width: 8),
//                                         ],
//                                       ),
//                                 Text(
//                                   topic,
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: isRead
//                                         ? FontWeight.normal
//                                         : FontWeight.bold,
//                                   ),
//                                   overflow: TextOverflow
//                                       .ellipsis, // Show ellipsis if the text overflows
//                                   maxLines: 3, // Show only one line of text
//                                 ),
//                               ],
//                             ),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Padding(
//                                   padding: EdgeInsets.only(bottom: 5, top: 8),
//                                   child: Text(
//                                     '${Constants.LAST_ACTIVE}$timestamp',
//                                     style: TextStyle(fontSize: 14),
//                                   ),
//                                 ),
//                                 Padding(
//                                   padding: EdgeInsets.only(bottom: 5),
//                                   child: Text(
//                                     '${Constants.REPLIES}$count',
//                                     style: TextStyle(
//                                       fontSize: 14,
//                                       fontWeight: isRead
//                                           ? FontWeight.normal
//                                           : FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             trailing: Icon(Icons.arrow_forward_ios,
//                                 color: Colors.white),
//                           ),
//                         ),
//                       );
//                     }
//                   });
//             } else {
//               return Center(
//                 // child: Text(''),
//                 child: CircularProgressIndicator(),
//               );
//             }
//           } else {
//             // Handle error case
//             return Center(
//               child: Text(''),

//               // child: CircularProgressIndicator(),
//             );
//           }
//         },
//       ),
//     );
//   }

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
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//               ),
//             ),
//             SizedBox(height: 4),
//             Text(
//               subtitle,
//               style: TextStyle(color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

//test chat data not cming
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
import 'package:geolocator/geolocator.dart';

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

  LocationPermission? _locationPermission;

  @override
  bool get wantKeepAlive => true;

  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();

    getData().then((_) {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> storedList() async {
    List<Conversation> storedConversations = await getStoredConversations();
    for (var conversation in storedConversations) {
      print('Conversation ID: ${conversation.conversationId}');
      print('Reply Count: ${conversation.replyCount}');
      print('Is Read: ${conversation.isRead}');
      print('---------------------');
    }
  }

  Future<void> getData() async {
    _locationPermission = await Geolocator.checkPermission();

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
        print('---------------ChatList Response---------------');
        print('server response ${response.body}');

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
              print('---------------Messsage Replies Response---------------');

              print(response.body);

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
        print('server error else');
        // Handle connection error
      }
    } catch (e) {
      print('error catch $e');
      // Handle exception
    }
  }

  Future<void> _deleteChat(String conversationId) async {
    List<Conversation> storedConversations = await getStoredConversations();
    print('Before Deletion:');
    for (var conversation in storedConversations) {
      print(
          'Conversation ID: ${conversation.conversationId}, isDeleted: ${conversation.isDeleted}');
    }

    int conversationIndex = storedConversations.indexWhere(
        (conversation) => conversation.conversationId == conversationId);

    if (conversationIndex != -1) {
      storedConversations[conversationIndex].isDeleted = true;
      await storeConversations(storedConversations);

      setState(() {
        print('After Deletion:');
        for (var conversation in storedConversations) {
          print(
              'Conversation ID: ${conversation.conversationId}, isDeleted: ${conversation.isDeleted}');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: FutureBuilder<List<Conversation>>(
        future: getStoredConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              isLoading) {
            // if (isLoading) {
            return Center(
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
                      // Check if it's the ad banner index
                      // The ad banner should be shown after every 5 items (0-based index)
                      return CustomBannerAd(
                        key: UniqueKey(),
                      );
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
                          ).then((_) {
                            // Called when returning from the chat screen
                            // setState(() {}); // Trigger a rebuild of the widget
                          });
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
                                            print('Chat UnRead');
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
                                            print('Chat Read');
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
                                    child: Text(DialogStrings.CANCEL),
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
                          margin:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                isRead
                                    ? SizedBox()
                                    : Row(
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
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 5),
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
                            trailing: Icon(Icons.arrow_forward_ios,
                                color: Colors.white),
                          ),
                        ),
                      );
                    }
                  });
            } else {
              return Center(
                // child: Text(''),
                child: CircularProgressIndicator(),
              );
            }
          } else {
            // Handle error case
            return Center(
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
