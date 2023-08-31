import 'package:chat/chat/conversation_data.dart' as conversation;

import 'package:chat/chat/new_conversation.dart';
import 'package:chat/starredChat/starred_chat.dart';
import 'package:chat/starredChat/starred_conversation_data.dart';

import 'package:chat/settings/settings.dart';
import 'package:chat/utils/ads.dart';
import 'package:chat/utils/constants.dart';
import 'package:chat/utils/shared_pref.dart';
import 'package:chat/model/get_all_reply_messages.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chat/home_screen.dart';
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_beep/flutter_beep.dart';
//import 'package:admob_flutter/admob_flutter.dart';

class StarredChatList extends StatefulWidget {
  final Key key;

  StarredChatList({
    required this.key,
  });

  @override
  _StarredChatListState createState() => _StarredChatListState();
}

class _StarredChatListState extends State<StarredChatList>
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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // InterstitialAdManager.initialize();

    getData().then((_) {
      setState(() {
        isLoading = false;
      });
    });

    _refreshChatListWithFCM();
    // storedList();
  }

  @override
  void dispose() {
    super.dispose();
//InterstitialAdManager.dispose();

    // conversationTimer?.cancel();
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
        List<conversation.Conversation> storedConversations =
            await conversation.getStoredConversations();
        conversation.Conversation?
            conversationToRefresh; // Initialize as nullable

        for (var conversation in storedConversations) {
          if (conversation.conversationId == conversationId &&
              !conversation.isDeleted) {
            conversationToRefresh = conversation;
            break;
          }
        }

        if (conversationToRefresh != null) {
          getData().then((_) {
            setState(() {
              isLoading = false;
            });
          });
          if (SharedPrefs.getBool(SharedPrefsKeys.CHAT_TONES)!) {
            FlutterBeep.beep();
          }
        }
      } else if (notificationType == 'newchat') {
        getData().then((_) {
          setState(() {
            isLoading = false;
          });
        });
        if (SharedPrefs.getBool(SharedPrefsKeys.CHAT_TONES)!) {
          FlutterBeep.beep();
        }
      } else if (notificationType == null) {
        getData().then((_) {
          setState(() {
            isLoading = false;
          });
        });
        if (SharedPrefs.getBool(SharedPrefsKeys.CHAT_TONES)!) {
          FlutterBeep.beep();
        }
      }
    });
  }

  Future<void> getData() async {
    await getConversationsData();
  }

  Future<List<String>> getStarredConversations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String> starredConversations =
        prefs.getStringList('starredConversationList') ?? [];

    return starredConversations;
  }

  Future<void> getConversationsData() async {
    String? userId = SharedPrefs.getString(SharedPrefsKeys.USER_ID);
    double? storedLatitude = SharedPrefs.getDouble(SharedPrefsKeys.LATITUDE);
    double? storedLongitude = SharedPrefs.getDouble(SharedPrefsKeys.LONGITUDE);

    Uri url = Uri.parse(API.CONVERSATION_LIST);
    Map<String, dynamic> requestBody = {
      API.USER_ID: userId,
      API.LATITUDE: storedLatitude.toString(),
      API.LONGITUDE: storedLongitude.toString(),
      "max_hours": "36",
      "max_posts": "80",
      "device_package": "com.teletype.truckchat2.android",
    };

    try {
      http.Response response = await http.post(
        url,
        headers: {API.CONTENT_TYPE: API.APPLICATION_JSON},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        print('---------------ChatList Response---------------');
        print(response.body);
        // print('--------------------------------------');

        List<String> starredConversationList = await getStarredConversations();

        print('Starred shareprefs List $starredConversationList');

        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // List<dynamic> serverMsgIds = jsonResponse[API.SERVER_MSG_ID];
        List<dynamic> serverMsgIds = starredConversationList;

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

              // print('--------------------------------------');

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
      } else {
        // Handle connection error
      }
    } catch (e) {
      // Handle exception
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue, // Set the desired color here

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context); // Navigate back when back button is pressed
          },
        ),
        title: Text(
          'Starred Chats',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Conversation>>(
              future: getStoredConversations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.connectionState == ConnectionState.done) {
                  List<Conversation> storedConversations =
                      snapshot.data ?? []; // Use cached data
                  print('Stored Starred Conversations: $storedConversations');

                  if (storedConversations.isEmpty) {
                    return Center(
                      child: Text(Constants.NO_CONVERSATION_FOUND),
                    );
                  } else if (storedConversations.isNotEmpty) {
                    return ListView.builder(
                      // itemCount: conversationTopics.length,
                      itemCount: storedConversations.length +
                          (storedConversations.length ~/ 4),
                      itemBuilder: (context, index) {
                        if (index % 5 == 4) {
                          // Check if it's the ad banner index
                          // The ad banner should be shown after every 5 items (0-based index)

                          return CustomBannerAd(
                            key: UniqueKey(),
                          );
                        } else {
                          // Calculate the actual index in the conversation topics list
                          final conversationIndex = index - (index ~/ 5);
                          final conversation =
                              storedConversations[conversationIndex];

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
                              DateFormat('MMM d, yyyy h:mm:ss a')
                                  .format(dateTime);
                          final timestamp = formattedDateTime;

                          final isRead = conversation.isRead;

                          // print('List item read status $isRead');

                          return GestureDetector(
                            onTap: () async {
                              if (!isRead) {
                                // Mark conversation as read
                                conversation.isRead = true;
                                await storeConversations(storedConversations);
                                setState(
                                    () {}); // Trigger a rebuild of the widget
                              }

                              Navigator.pop(
                                  context); // Remove the last screen from the stack

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StarredChat(
                                    topic: topic,
                                    serverMsgId: serverMsgID,
                                  ),
                                ),
                              ).then((_) {
                                // Called when returning from the chat screen
                                setState(
                                    () {}); // Trigger a rebuild of the widget
                              });
                            },
                            onLongPress: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        isRead
                                            ? _buildDialogOption(
                                                DialogStrings
                                                    .MARK_CHAT_THIS_UNREAD,
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
                              margin: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: ListTile(
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    isRead
                                        ? Row(
                                            children: [
                                              Icon(
                                                Icons.star,
                                                color: Colors.yellow,
                                              ),
                                              SizedBox(width: 8),
                                            ],
                                          )
                                        : Row(
                                            children: [
                                              Icon(
                                                Icons.star,
                                                color: Colors.yellow,
                                              ),
                                              SizedBox(width: 8),
                                              Icon(
                                                Icons.chat,
                                                size: 17,
                                                color: Colors.white,
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
                                      padding:
                                          EdgeInsets.only(bottom: 5, top: 8),
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
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    );
                  } else {
                    // Handle error case
                    return Center(
                      child: Text(''),
                    );
                  }
                } else {
                  // Handle error case
                  return Center(
                    child: Text(''),
                  );
                }
              },
            ),
          ),
          // AdmobBanner(
          //   adUnitId: AdHelper.bannerAdUnitId,
          //   adSize: AdmobBannerSize.ADAPTIVE_BANNER(
          //     width: MediaQuery.of(context).size.width.toInt(),
          //   ),
          // ),
        ],
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
