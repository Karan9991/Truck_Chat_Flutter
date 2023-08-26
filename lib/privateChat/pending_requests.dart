import 'package:chat/utils/avatar.dart';
import 'package:chat/utils/constants.dart';
import 'package:chat/utils/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:chat/utils/alert_dialog.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

class PendingRequestsScreen extends StatelessWidget {
  final String currentUserId; // The ID of the current user

  String emojiId = '';
  String userName = '';
  String receiverEmojiId = '';
  String receiverUserName = '';
  String senderId = '';
  String receiverId = '';
  String? currentUserHandle;
  String? currentUserEmojiId;
  DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();

  PendingRequestsScreen({required this.currentUserId});

  void acceptRequest(String requestId, BuildContext context) {
    String? chatHandle =
        SharedPrefs.getString(SharedPrefsKeys.CURRENT_USER_CHAT_HANDLE);
    int? avatarId = SharedPrefs.getInt(SharedPrefsKeys.CURRENT_USER_AVATAR_ID);
    if (chatHandle == null) {
      showChatHandleDialog(context);
    } else if (avatarId == null) {
      showAvatarSelectionDialog(context);
    } else {
      currentUserHandle =
          SharedPrefs.getString(SharedPrefsKeys.CURRENT_USER_CHAT_HANDLE);

      currentUserEmojiId =
          SharedPrefs.getInt(SharedPrefsKeys.CURRENT_USER_AVATAR_ID).toString();

      DatabaseReference requestRef =
          FirebaseDatabase.instance.ref().child('requests/$requestId');

      requestRef.update({'status': 'accepted'}).then((_) async {
        DatabaseEvent event = await requestRef.once();
        DataSnapshot snapshot = event.snapshot;

        var requestData = snapshot.value as Map<dynamic, dynamic>;
        if (requestData != null) {
          senderId = requestData['senderId'];
          receiverId = requestData['receiverId'];
          emojiId = requestData['senderEmojiId'];
          userName = requestData['senderUserName'];
          receiverEmojiId = requestData['receiverEmojiId'];
          receiverUserName = requestData['receiverUserName'];

                     final receiverFCMToken = await getFCMToken(senderId);
        // Send notification to the receiver
        await sendNotificationToReceiver(receiverFCMToken ?? '', senderId,
            receiverId,);


          await _initializeChat(senderId, receiverId);
          await requestRef.remove();

    
        }
      });
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

  Future<void> _initializeChat(String userId, String receiverId) async {
    var timestamp = DateTime.now().millisecondsSinceEpoch;

    // Update the chat list for the sender (widget.userId)
    await _updateChatList(userId, receiverId, '', timestamp, emojiId, userName);

    // Update the chat list for the receiver (widget.receiverId)
    await _updateChatList(
        receiverId, userId, '', timestamp, receiverEmojiId, receiverUserName);
  }

  Future<void> _updateChatList(
      String userId,
      String otherUserId,
      String lastMessage,
      int timestamp,
      String emojiId,
      String userName) async {
    try {
      await _databaseReference
          .child('chatList')
          .child(userId)
          .child(otherUserId)
          .set({
        'userName': userName,
        'emojiId': emojiId,
        'receiverId': otherUserId,
        'lastMessage': lastMessage,
        'timestamp': timestamp,
        'newMessages': false,
      });
    } catch (error) {
      print('Error updating chat list: $error');
    }
  }


  void rejectRequest(String requestId) {
    DatabaseReference requestRef =
        FirebaseDatabase.instance.ref().child('requests/$requestId');
    requestRef.remove(); // Remove the entire request node from the database
  }

  Future<void> sendNotificationToReceiver(String receiverFCMToken,
      String senderId, String receiverId,) async {
    print('receiver token $receiverFCMToken');
    // Replace 'YOUR_SERVER_KEY' with your FCM server key
    String serverKey =
        MyFirebase.FIREBASE_CLOUD_MESSAGING_KEY_NOTIFICATION;
    String url = MyFirebase.FIREBASE_NOTIFICATION_URL;

    // Replace 'YOUR_NOTIFICATION_TITLE' and 'YOUR_NOTIFICATION_BODY' with your desired notification title and body
    String notificationTitle = 'Private chat request accepted';
    String notificationBody = 'Tap to open TruckChat';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(<String, dynamic>{
          'notification': <String, dynamic>{
            'body': notificationBody,
            'title': notificationTitle,
            'sound': 'default',
          },
          // 'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'type': 'private',
            'senderUserId': currentUserId,
            'receiverUserId': receiverId,
          },
          'to': receiverFCMToken,
        }),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully');
      } else {
        print(
            'Failed to send notification. StatusCode: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to send notification. Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    DatabaseReference requestsRef =
        FirebaseDatabase.instance.ref().child('requests');

    return Scaffold(
      body: StreamBuilder(
        stream: requestsRef
            .orderByChild('receiverId')
            .equalTo(currentUserId)
            .onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.snapshot.value == null) {
            return Center(
              child: Text('No pending requests.'),
            );
          }

          Map<dynamic, dynamic> requestsData =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          List<Widget> requestWidgets = [];

          requestsData.forEach((requestId, requestData) {
            if (requestData['status'] == 'pending') {
              senderId = requestData['senderId'];
              receiverId = requestData['receiverId'];
              emojiId = requestData['senderEmojiId'];
              userName = requestData['senderUserName'];
              receiverEmojiId = requestData['receiverEmojiId'];
              receiverUserName = requestData['receiverUserName'];
              // Find the corresponding Avatar for the emoji_id
              Avatar? matchingAvatar = avatars.firstWhere(
                (avatar) => avatar.id == int.parse(receiverEmojiId),
                orElse: () => Avatar(id: 0, imagePath: ''),
              );

              requestWidgets.add(Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage(matchingAvatar.imagePath),
                  ),
                  title: Text(
                      receiverUserName), // Replace senderName with the actual sender's name
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => acceptRequest(requestId, context),
                        child: Text(
                          'Accept',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.green, // Set the background color to green
                          foregroundColor:
                              Colors.white, // Set the text color to white
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => rejectRequest(requestId),
                        child: Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.red, // Set the background color to green
                          foregroundColor:
                              Colors.white, // Set the text color to white
                        ),
                      ),
                    ],
                  ),
                ),
              ));
            }
          });

          if (requestWidgets.isEmpty) {
            return Center(
              child: Text('No pending requests.'),
            );
          }

          return ListView(
            children: requestWidgets,
          );
        },
      ),
    );
  }
}
