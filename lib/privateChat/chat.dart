// import 'dart:convert';
// import 'dart:io';

// import 'package:chat/utils/ads.dart';
// import 'package:chat/utils/alert_dialog.dart';
// import 'package:chat/utils/avatar.dart';
// import 'package:chat/utils/constants.dart';
// import 'package:chat/utils/shared_pref.dart';
// import 'package:chat/utils/snackbar.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/services.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:photo_view/photo_view.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:http/http.dart' as http;
// import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'dart:async';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:intl/intl.dart';

// class ChatScreen extends StatefulWidget {
//   final String userId;
//   final String receiverId;
//   final String receiverUserName;
//   final String receiverEmojiId;

//   static final chatScreenKey = GlobalKey<_ChatScreenState>();

//   ChatScreen({
//     required this.userId,
//     required this.receiverId,
//     required this.receiverUserName,
//     required this.receiverEmojiId,
//   });

//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   TextEditingController _messageController = TextEditingController();
//   DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
//   List<Map<dynamic, dynamic>> _messages = [];
//   bool _isBlocked = false;
//   String? currentUserName;
//   stt.SpeechToText _speechToText = stt.SpeechToText();
//   bool _isListening = false;
//   String _typedText = '';
//   String? currentUserId;
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();
//   String? _currentDate;
//   String? _lastDisplayedDate;

//   @override
//   void initState() {
//     super.initState();

//     // AdHelper().showInterstitialAd();
//     // AdHelper.showInterstitialAd2TimesIn24Hours();

//     SharedPrefs.setBool('isUserOnChatScreen', true);

//     currentUserName =
//         SharedPrefs.getString(SharedPrefsKeys.CURRENT_USER_CHAT_HANDLE);

//     currentUserId = SharedPrefs.getString(SharedPrefsKeys.USER_ID).toString();

//     _updateNewMessage(false);

//     _loadMessages();

//     _loadBlockStatus();
//   }

//   @override
//   void dispose() {
//     //  AdHelper().disposeInterstitialAd();

//     SharedPrefs.setBool('isUserOnChatScreen', false);

//     super.dispose();
//   }

//   void _loadBlockStatus() async {
//     bool isBlocked = await isUserBlocked(widget.userId, widget.receiverId);
//     setState(() {
//       _isBlocked = isBlocked;
//     });
//   }

//   void _updateNewMessage(bool newMessages) async {
//     DataSnapshot snapshot = await _databaseReference
//         .child('chatList')
//         .child(widget.userId)
//         .child(widget.receiverId)
//         .get();
//     if (snapshot.value != null) {
//       DatabaseReference updateNewMessage = FirebaseDatabase.instance
//           .ref()
//           .child('chatList')
//           .child(widget.userId)
//           .child(widget.receiverId);

//       updateNewMessage.update({'newMessages': newMessages});
//     }
//   }

//   void _loadMessages() {
//     _databaseReference
//         .child('messages')
//         .child(widget.userId)
//         .child(widget.receiverId)
//         .onValue
//         .listen((event) {
//       DataSnapshot snapshot = event.snapshot;
//       if (snapshot.value != null && snapshot.value is Map) {
//         Map<dynamic, dynamic>? messageMap =
//             snapshot.value as Map<dynamic, dynamic>?;
//         if (messageMap != null) {
//           List<Map<dynamic, dynamic>> messagesList = [];

//           // Convert the map of messages to a list of messages
//           messageMap.forEach((key, value) {
//             messagesList.add(value);
//           });

//           setState(() {
//             _messages = messagesList;
//           });
//         }
//       } else {
//         setState(() {
//           _messages = [];
//         });
//       }
//     });
//   }

//   void _sendMessage() async {
//     String? chatHandle =
//         SharedPrefs.getString(SharedPrefsKeys.CURRENT_USER_CHAT_HANDLE);
//     int? avatarId = SharedPrefs.getInt(SharedPrefsKeys.CURRENT_USER_AVATAR_ID);
//     if (chatHandle == null) {
//       showChatHandleDialog(context);
//     } else if (avatarId == null) {
//       showAvatarSelectionDialog(context);
//     } else {
//       bool isSenderBlocked =
//           await isUserBlocked(widget.userId, widget.receiverId);
//       bool isReceiverBlocked =
//           await isUserBlocked(widget.receiverId, widget.userId);

//       if (isSenderBlocked) {
//         // Show a snackbar message indicating that the sender has blocked the receiver
//         _showBlockedMessage("You blocked this user. Cannot send a message.");
//         return;
//       } else if (isReceiverBlocked) {
//         // Show a snackbar message indicating that the receiver has blocked the sender
//         _showBlockedMessage(
//             "This user has blocked you. Cannot send a message.");
//         return;
//       }

//       String messageText = _messageController.text.trim();
//       if (messageText.isNotEmpty) {
//         _messageController.clear();
//         var timestamp = DateTime.now().millisecondsSinceEpoch;

//         // Send the message to the receiver
//         _databaseReference
//             .child('messages')
//             .child(widget.userId)
//             .child(widget.receiverId)
//             .push()
//             .set({
//           'senderId': widget.userId,
//           'receiverId': widget.receiverId,
//           'message': messageText,
//           'timestamp': timestamp,
//         });

//         _databaseReference
//             .child('messages')
//             .child(widget.receiverId)
//             .child(widget.userId)
//             .push()
//             .set({
//           'senderId': widget.userId,
//           'receiverId': widget.receiverId,
//           'message': messageText,
//           'timestamp': timestamp,
//         });

//         // Update the chat list for the sender (widget.userId)
//         //   _updateChatList(widget.userId, widget.receiverId, messageText, timestamp);

//         // Update the chat list for the receiver (widget.receiverId)
//         _updateChatList(
//             widget.receiverId, widget.userId, messageText, timestamp);

//         final receiverFCMToken = await getFCMToken(widget.receiverId);
//         // Send notification to the receiver
//         await sendNotificationToReceiver(receiverFCMToken ?? '', widget.userId,
//             widget.receiverId, messageText);
//       }
//     }
//   }

//   void _updateChatList(String userId, String otherUserId, String lastMessage,
//       int timestamp) async {
//     try {
//       DataSnapshot snapshot = await _databaseReference
//           .child('chatList')
//           .child(userId)
//           .child(otherUserId)
//           .get();
//       if (snapshot.value != null) {
//         // Chat already exists, update last message and timestamp
//         await _databaseReference
//             .child('chatList')
//             .child(userId)
//             .child(otherUserId)
//             .update({
//           'lastMessage': lastMessage,
//           'timestamp': timestamp,
//           'newMessages': true,
//           // Set newMessages to true to indicate there are new messages
//         });
//       } else {
//         // Chat does not exist, create a new chat list entry
//         DataSnapshot userSnapshot =
//             await _databaseReference.child('users').child(otherUserId).get();
//         Map<dynamic, dynamic>? userData =
//             userSnapshot.value as Map<dynamic, dynamic>?;
//         String otherUserName = userData?['userName'] ?? 'Unknown User';
//         String otherUserImage = userData?['userImage'] ?? 'default_image_url';

//         await _databaseReference
//             .child('chatList')
//             .child(userId)
//             .child(otherUserId)
//             .set({
//           'userName': otherUserName,
//           'userImage': otherUserImage,
//           'receiverId': otherUserId,
//           'lastMessage': lastMessage,
//           'timestamp': timestamp,
//           'newMessages': true,
//         });
//       }
//     } catch (error) {
//       print('Error updating chat list: $error');
//     }
//   }

//   Future<void> _sendImage() async {
//     String? chatHandle =
//         SharedPrefs.getString(SharedPrefsKeys.CURRENT_USER_CHAT_HANDLE);
//     int? avatarId = SharedPrefs.getInt(SharedPrefsKeys.CURRENT_USER_AVATAR_ID);
//     if (chatHandle == null) {
//       showChatHandleDialog(context);
//     } else if (avatarId == null) {
//       showAvatarSelectionDialog(context);
//     } else {
//       bool isSenderBlocked =
//           await isUserBlocked(widget.userId, widget.receiverId);
//       bool isReceiverBlocked =
//           await isUserBlocked(widget.receiverId, widget.userId);

//       if (isSenderBlocked) {
//         // Show a snackbar message indicating that the sender has blocked the receiver
//         _showBlockedMessage("You blocked this user. Cannot send a message.");
//         return;
//       } else if (isReceiverBlocked) {
//         // Show a snackbar message indicating that the receiver has blocked the sender
//         _showBlockedMessage(
//             "This user has blocked you. Cannot send a message.");
//         return;
//       }
//       sendImageDialog(context, () => _openCamera(), () => _openGallery());
//     }
//   }

//   Future<void> _openCamera() async {
//     final ImagePicker _picker = ImagePicker();
//     XFile? pickedFile = await _picker.pickImage(
//       source: ImageSource
//           .camera, // Change this to ImageSource.camera for camera access
//     );

//     if (pickedFile != null) {
//       String fileName = DateTime.now().millisecondsSinceEpoch.toString();
//       Reference storageRef = FirebaseStorage.instance
//           .ref()
//           .child('privatechatdata')
//           .child(SharedPrefs.getString(SharedPrefsKeys.USER_ID)!)
//           .child(fileName);
//       UploadTask uploadTask = storageRef.putFile(File(pickedFile.path));

//       try {
//         TaskSnapshot taskSnapshot = await uploadTask;
//         String imageUrl = await taskSnapshot.ref.getDownloadURL();

//         var timestamp = DateTime.now().millisecondsSinceEpoch;

//         // Send the message to the receiver
//         _databaseReference
//             .child('messages')
//             .child(widget.userId)
//             .child(widget.receiverId)
//             .push()
//             .set({
//           'senderId': widget.userId,
//           'receiverId': widget.receiverId,
//           'message': imageUrl,
//           'timestamp': timestamp,
//         });

//         _databaseReference
//             .child('messages')
//             .child(widget.receiverId)
//             .child(widget.userId)
//             .push()
//             .set({
//           'senderId': widget.userId,
//           'receiverId': widget.receiverId,
//           'message': imageUrl,
//           'timestamp': timestamp,
//         });

//         // Update the chat list for the receiver (widget.receiverId)
//         _updateChatList(widget.receiverId, widget.userId, imageUrl, timestamp);
//       } catch (error) {
//         print('Error uploading image: $error');
//       }
//     }
//   }

//   Future<void> _openGallery() async {
//     final ImagePicker _picker = ImagePicker();

//     XFile? pickedFile = await _picker.pickImage(
//       source: ImageSource
//           .gallery, // Change this to ImageSource.camera for camera access
//     );

//     if (pickedFile != null) {
//       String fileName = DateTime.now().millisecondsSinceEpoch.toString();
//       Reference storageRef = FirebaseStorage.instance
//           .ref()
//           .child('privatechatdata')
//           .child(SharedPrefs.getString(SharedPrefsKeys.USER_ID)!)
//           .child(fileName);
//       UploadTask uploadTask = storageRef.putFile(File(pickedFile.path));

//       try {
//         TaskSnapshot taskSnapshot = await uploadTask;
//         String imageUrl = await taskSnapshot.ref.getDownloadURL();
//         var timestamp = DateTime.now().millisecondsSinceEpoch;

//         _databaseReference
//             .child('messages')
//             .child(widget.userId)
//             .child(widget.receiverId)
//             .push()
//             .set({
//           'senderId': widget.userId,
//           'receiverId': widget.receiverId,
//           'message': imageUrl,
//           'timestamp': timestamp,
//         });

//         _databaseReference
//             .child('messages')
//             .child(widget.receiverId)
//             .child(widget.userId)
//             .push()
//             .set({
//           'senderId': widget.userId,
//           'receiverId': widget.receiverId,
//           'message': imageUrl,
//           'timestamp': timestamp,
//         });

//         // Update the chat list for the sender (widget.userId)
//         // _updateChatList(widget.userId, widget.receiverId, imageUrl, timestamp);

//         // Update the chat list for the receiver (widget.receiverId)
//         _updateChatList(widget.receiverId, widget.userId, imageUrl, timestamp);
//       } catch (error) {
//         print('Error uploading image: $error');
//       }
//     }
//   }

//   void _showBlockedMessage(String message) {
//     showSnackBar(context, message);
//   }

//   void _showSuccessMessage(String message) {
//     showSnackBar(context, message);
//   }

//   void _showErrorMessage(String message) {
//     showErrorSnackBar(context, message);
//   }

//   void _blockUser(String currentUserID, String blockedUserID) {
//     // Add the blockedUserID to the currentUserID's blocked users list
//     _databaseReference
//         .child('blockedUsers')
//         .child(currentUserID)
//         .child(blockedUserID)
//         .set(true)
//         .then((_) {
//       // Successfully blocked the user, show a success message
//       _showSuccessMessage("User blocked successfully!");
//     }).catchError((error) {
//       // An error occurred while blocking the user, show an error message
//       _showErrorMessage("Failed to block user. Please try again.");
//     });

//     _loadBlockStatus();
//   }

//   void _unblockUser(String currentUserID, String blockedUserID) {
//     // Remove the blockedUserID from the currentUserID's blocked users list
//     _databaseReference
//         .child('blockedUsers')
//         .child(currentUserID)
//         .child(blockedUserID)
//         .remove()
//         .then((_) {
//       // Successfully unblocked the user, show a success message
//       _showSuccessMessage("User unblocked successfully!");
//     }).catchError((error) {
//       // An error occurred while unblocking the user, show an error message
//       _showErrorMessage("Failed to unblock user. Please try again.");
//     });

//     _loadBlockStatus();
//   }

//   void _showOptionsMenu(BuildContext context, bool isBlocked) {
//     String currentUserID = widget.userId;
//     String blockedUserID = widget.receiverId;

//     showBlockUserDialog(
//         context,
//         isBlocked,
//         () => {
//               if (isBlocked)
//                 {_unblockUser(currentUserID, blockedUserID)}
//               else
//                 {_blockUser(currentUserID, blockedUserID)}
//             });
//   }

//   Future<bool> isUserBlocked(String currentUserID, String targetUserID) async {
//     DatabaseEvent event = await _databaseReference
//         .child('blockedUsers')
//         .child(currentUserID)
//         .child(targetUserID)
//         .once();

//     DataSnapshot snapshot = event.snapshot;

//     // Check if the snapshot value exists and is not null
//     return snapshot.exists && snapshot.value != null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     _messages.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

//     Avatar? matchingAvatar = avatars.firstWhere(
//       (avatar) => avatar.id == int.tryParse(widget.receiverEmojiId),
//       orElse: () => Avatar(id: 0, imagePath: ''),
//     );

//     return Scaffold(
//       key: ChatScreen.chatScreenKey, // Assign the GlobalKey to the Scaffold

//       appBar: AppBar(
//         automaticallyImplyLeading: false, // Prevent the default back button
//         leadingWidth: kToolbarHeight + 32.0, // Adjust this value as needed
//         leading: Row(
//           children: [
//             IconButton(
//               icon: Icon(Icons.arrow_back),
//               onPressed: () {
//                 // Handle back button press here
//                 // setState(() {
//                 //   _isUserOnChatScreen = false;
//                 // });
//                 _updateNewMessage(false);

//                 Navigator.of(context).pop();
//               },
//             ),
//             // SizedBox(width: 8), // Adjust this value for spacing between arrow and image
//             SizedBox(
//               width:
//                   40, // Set the width of the image container equal to the height for a square image
//               height: kToolbarHeight,
//               child: Image.asset(
//                 matchingAvatar.imagePath,
//                 fit: BoxFit.contain, // Maintain the image's aspect ratio
//               ),
//             ),
//           ],
//         ),
//         title: Container(
//           alignment: Alignment.centerLeft,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.start,
//             children: [
//               // SizedBox(width: 8), // Adjust this value for spacing between image and title
//               Text(widget.receiverUserName),
//             ],
//           ),
//         ),
//         centerTitle: false, // Make sure centerTitle is set to false
//         actions: [
//           PopupMenuButton(
//             itemBuilder: (BuildContext context) {
//               return [
//                 PopupMenuItem(
//                   child: _isBlocked ? Text('Unblock user') : Text('Block user'),
//                   value: 'block this user',
//                 ),
//               ];
//             },
//             onSelected: (value) async {
//               // Perform action when a pop-up menu item is selected
//               switch (value) {
//                 case 'block this user':
//                   // Get the block status for the current user and receiver
//                   // You can use the isUserBlocked function to get the block status
//                   // Here, I'm assuming you have the function isUserBlocked implemented
//                   bool isBlocked =
//                       await isUserBlocked(widget.userId, widget.receiverId);

//                   _showOptionsMenu(context, isBlocked);

//                   break;
//               }
//             },
//           ),
//         ],
//       ),
//       body: WillPopScope(
//         // Set the onWillPop callback to get notified when the user attempts to pop the screen
//         onWillPop: () async {
//           // Update the flag when the user attempts to pop the ChatScreen
//           // setState(() {
//           //  // _isUserOnChatScreen = false;
//           // });
//           _updateNewMessage(false);

//           return true; // Return true to allow the screen to be popped
//         },

//         child: Column(
//           children: [
//             Expanded(
//               child: ListView.builder(
//                 reverse: true,
//                 itemCount: _messages.length,
//                 itemBuilder: (context, index) {
//                   Map<dynamic, dynamic> message = _messages[index];
//                   bool isSender = message['senderId'] == widget.userId;

//                   //testing start
//                   String messages = message['message'] ?? '';
//                   String imageUrl =
//                       messages.startsWith('https') ? messages : '';
//                   bool isImageMessage = imageUrl.isNotEmpty;

//                   int timestamp = message['timestamp'];

//                   String formattedDate = DateFormat('MMM d, yyyy').format(
//                     DateTime.fromMillisecondsSinceEpoch(timestamp),
//                   );
//                   DateTime messageDateTime =
//                       DateTime.fromMillisecondsSinceEpoch(timestamp);

//                   // Get the timestamp of the previous message (if available)
//                   int previousTimestamp = index + 1 < _messages.length
//                       ? _messages[index + 1]['timestamp']
//                       : 0;
//                   DateTime previousMessageDateTime =
//                       DateTime.fromMillisecondsSinceEpoch(previousTimestamp);

//                   // Check if the current message and the previous message belong to the same date
//                   bool showDateDivider =
//                       !isSameDate(messageDateTime, previousMessageDateTime);

//                   if (showDateDivider) {
//                     // Format the date to show only the date (MMM dd, yyyy)
//                     String formattedDate =
//                         DateFormat('MMM dd, yyyy').format(messageDateTime);

//                     return Column(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         ClipRRect(
//                           // Wrap with ClipRRect to make it circular
//                           borderRadius: BorderRadius.circular(8),
//                           child: Container(
//                             color: Colors.grey[200],
//                             padding: EdgeInsets.symmetric(
//                                 vertical: 8, horizontal: 16),
//                             child: Text(
//                               formattedDate,
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.grey),
//                             ),
//                           ),
//                         ),
//                         MessageBubble(
//                           message: messages,
//                           isCurrentUser: isSender,
//                           isImageMessage: isImageMessage,
//                           imageUrl: imageUrl,
//                           timestamp: timestamp,
//                         ),
//                       ],
//                     );
//                   } else {
//                     // If the current message and the previous message belong to the same date, don't show the date divider
//                     return MessageBubble(
//                       message: messages,
//                       isCurrentUser: isSender,
//                       isImageMessage: isImageMessage,
//                       imageUrl: imageUrl,
//                       timestamp: timestamp,
//                     );
//                   }
//                 },
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: Icon(Icons.mic),
//                     onPressed: () {
//                       _toggleListening();
//                     },
//                   ),
//                   Expanded(
//                     child: TextField(
//                       minLines: 1,
//                       maxLines: 7,
//                       controller: _messageController,
//                       decoration: InputDecoration(
//                         hintText: 'Type a message...',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(20),
//                           borderSide: BorderSide.none,
//                         ),
//                         filled: true,
//                         fillColor: Colors.grey[200],
//                         contentPadding:
//                             EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                       ),
//                     ),
//                   ),
//                   SizedBox(
//                       width:
//                           8), // Add some space between the text field and the send button
//                   IconButton(
//                     onPressed:
//                         _sendImage, // Call the function to open the gallery
//                     icon: Icon(
//                       Icons.image,
//                       color: Colors.blue[300],
//                     ), // You can use any other icon here
//                   ),
//                   GestureDetector(
//                     onTap: _sendMessage,
//                     child: Container(
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: Theme.of(context).primaryColor,
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Icon(
//                           Icons.send,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             // AdmobBanner(
//             //   adUnitId: AdHelper.bannerAdUnitId,
//             //   adSize: AdmobBannerSize.ADAPTIVE_BANNER(
//             //       width: MediaQuery.of(context).size.width.toInt()),
//             // )
//             CustomBannerAd(
//               key: UniqueKey(),
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   bool isSameDate(DateTime dateTime1, DateTime dateTime2) {
//     return dateTime1.year == dateTime2.year &&
//         dateTime1.month == dateTime2.month &&
//         dateTime1.day == dateTime2.day;
//   }

//   String getDateForIndex(int index) {
//     if (index >= 0 && index < _messages.length) {
//       int timestamp = _messages[index]['timestamp'];
//       return DateFormat('MM/dd/yyyy').format(
//         DateTime.fromMillisecondsSinceEpoch(timestamp),
//       );
//     }
//     return '';
//   }

//   void _toggleListening() {
//     _startListening();
//   }

//   void _startListening() async {
//     bool available = await _speechToText.initialize();
//     if (available) {
//       _speechToText.listen(
//         onResult: (result) {
//           setState(() {
//             _messageController.text = result.recognizedWords;
//             _typedText = result.recognizedWords;
//           });
//         },
//         listenMode: stt.ListenMode.dictation,
//         pauseFor: Duration(seconds: 2),
//       );
//       setState(() {
//         _isListening = true;
//       });
//     }
//   }

//   void _stopListening() {
//     _speechToText.stop();
//     setState(() {
//       _isListening = false;
//     });
//   }

//   Future<String?> getFCMToken(String receiverId) async {
//     DatabaseReference fcmTokenRef = FirebaseDatabase.instance
//         .ref()
//         .child('users')
//         .child(receiverId)
//         .child('fcmToken');

//     // Check if the token already exists in the database
//     DatabaseEvent event = await fcmTokenRef.once();
//     DataSnapshot dataSnapshot = event.snapshot;

//     String? token = dataSnapshot.value as String?;

//     if (token == null) {
//       // If the token doesn't exist in the database, generate a new token
//       FirebaseMessaging messaging = FirebaseMessaging.instance;
//       token = await messaging.getToken();

//       if (token != null) {
//         // Store the newly generated token in the database
//         fcmTokenRef.set(token);
//       }
//     }

//     return token;
//   }

//   Future<void> sendNotificationToReceiver(String receiverFCMToken,
//       String senderId, String receiverId, String message) async {
//     print('receiver token $receiverFCMToken');
//     // Replace 'YOUR_SERVER_KEY' with your FCM server key
//     String serverKey = MyFirebase.FIREBASE_CLOUD_MESSAGING_KEY_NOTIFICATION;
//     String url = MyFirebase.FIREBASE_NOTIFICATION_URL;

//     // Replace 'YOUR_NOTIFICATION_TITLE' and 'YOUR_NOTIFICATION_BODY' with your desired notification title and body
//     String notificationTitle = currentUserName ?? 'New Message';
//     String notificationBody = message;

//     try {
//       final response = await http.post(
//         Uri.parse(url),
//         headers: <String, String>{
//           'Content-Type': 'application/json',
//           'Authorization': 'key=$serverKey',
//         },
//         body: jsonEncode(<String, dynamic>{
//           'notification': <String, dynamic>{
//             'body': notificationBody,
//             'title': notificationTitle,
//             'sound': 'default',
//           },
//           // 'priority': 'high',
//           'data': <String, dynamic>{
//             'click_action': 'FLUTTER_NOTIFICATION_CLICK',
//             'type': 'private',
//             'senderUserId': currentUserId,
//             'receiverUserId': receiverId,
//           },
//           'to': receiverFCMToken,
//         }),
//       );

//       if (response.statusCode == 200) {
//         print('Notification sent successfully');
//       } else {
//         print(
//             'Failed to send notification. StatusCode: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Failed to send notification. Error: $e');
//     }
//   }
// }

// class DateDivider extends StatelessWidget {
//   final String formattedDate;

//   DateDivider(this.formattedDate);

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Container(
//         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         decoration: BoxDecoration(
//           color: Colors.grey[300],
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Text(
//           formattedDate,
//           style: TextStyle(
//             color: Colors.black54,
//             fontSize: 14,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class MessageBubble extends StatelessWidget {
//   final String message;
//   final bool isCurrentUser;
//   final bool isImageMessage;
//   final String imageUrl;
//   final int timestamp; // Add timestamp field to store the message timestamp

//   MessageBubble({
//     required this.message,
//     required this.isCurrentUser,
//     required this.isImageMessage,
//     required this.imageUrl,
//     required this.timestamp, // Accept the timestamp parameter in the constructor
//   });

//   @override
//   Widget build(BuildContext context) {
//     String formattedTime = DateFormat('hh:mm a')
//         .format(DateTime.fromMillisecondsSinceEpoch(timestamp));

//     return Align(
//       alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
//       child: GestureDetector(
//         onTap: () {
//           if (isImageMessage) {
//             _showFullImage(context, imageUrl);
//           }
//         },
//         child: Container(
//           padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//           margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//           decoration: BoxDecoration(
//             color: isCurrentUser ? Colors.blue[400] : Colors.blue[100],
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               isImageMessage
//                   ? Image.network(
//                       imageUrl,
//                       width: 200,
//                       height: 200,
//                       fit: BoxFit.cover,
//                     )
//                   : Text(
//                       message,
//                       style: TextStyle(
//                         color: isCurrentUser ? Colors.white : Colors.black,
//                       ),
//                     ),
//               SizedBox(height: 4),
//               Text(
//                 formattedTime, // Display the formatted timestamp
//                 style: TextStyle(
//                   color: isCurrentUser ? Colors.white70 : Colors.black54,
//                   fontSize: 12,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// void _showFullImage(BuildContext context, String imageUrl) {
//   Navigator.push(
//     context,
//     MaterialPageRoute(
//       builder: (context) => Scaffold(
//         backgroundColor: Colors.black, // Set background color to black
//         body: Stack(
//           children: [
//             Center(
//               child: PhotoView(
//                 imageProvider: NetworkImage(imageUrl),
//                 minScale: PhotoViewComputedScale.contained,
//                 maxScale: PhotoViewComputedScale.covered * 2.0,
//               ),
//             ),
//             Positioned(
//               top: 16,
//               right: 16,
//               child: IconButton(
//                 icon: Icon(
//                   Icons.close,
//                   color: Colors.white,
//                 ),
//                 onPressed: () {
//                   Navigator.pop(context); // Close the image viewer
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }

import 'dart:convert';
import 'dart:io';

import 'package:chat/utils/ads.dart';
import 'package:chat/utils/alert_dialog.dart';
import 'package:chat/utils/avatar.dart';
import 'package:chat/utils/constants.dart';
import 'package:chat/utils/shared_pref.dart';
import 'package:chat/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_video_player/cached_video_player.dart'
    as cachedVideoPlayer;

class ChatScreen extends StatefulWidget {
  final String userId;
  final String receiverId;
  final String receiverUserName;
  final String receiverEmojiId;

  static final chatScreenKey = GlobalKey<_ChatScreenState>();

  ChatScreen({
    required this.userId,
    required this.receiverId,
    required this.receiverUserName,
    required this.receiverEmojiId,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController _messageController = TextEditingController();
  DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  List<Map<dynamic, dynamic>> _messages = [];
  bool _isBlocked = false;
  String? currentUserName;
  stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  String _typedText = '';
  String? currentUserId;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  String? _currentDate;
  String? _lastDisplayedDate;
  double _uploadProgress = 0.0;
  bool _uploading = false; // Add this line to track the upload status

  @override
  void initState() {
    super.initState();

    //AdHelper().showInterstitialAd();
    // AdHelper.showInterstitialAd2TimesIn24Hours();

    SharedPrefs.setBool('isUserOnChatScreen', true);

    currentUserName =
        SharedPrefs.getString(SharedPrefsKeys.CURRENT_USER_CHAT_HANDLE);

    currentUserId = SharedPrefs.getString(SharedPrefsKeys.USER_ID).toString();

    _updateNewMessage(false);

    _loadMessages();

    _loadBlockStatus();
  }

  @override
  void dispose() {
    //  AdHelper().disposeInterstitialAd();

    SharedPrefs.setBool('isUserOnChatScreen', false);

    super.dispose();
  }

  void _loadBlockStatus() async {
    bool isBlocked = await isUserBlocked(widget.userId, widget.receiverId);
    setState(() {
      _isBlocked = isBlocked;
    });
  }

  void _updateNewMessage(bool newMessages) async {
    DataSnapshot snapshot = await _databaseReference
        .child('chatList')
        .child(widget.userId)
        .child(widget.receiverId)
        .get();
    if (snapshot.value != null) {
      DatabaseReference updateNewMessage = FirebaseDatabase.instance
          .ref()
          .child('chatList')
          .child(widget.userId)
          .child(widget.receiverId);

      updateNewMessage.update({'newMessages': newMessages});
    }
  }

  void _loadMessages() {
    _databaseReference
        .child('messages')
        .child(widget.userId)
        .child(widget.receiverId)
        .onValue
        .listen((event) {
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null && snapshot.value is Map) {
        Map<dynamic, dynamic>? messageMap =
            snapshot.value as Map<dynamic, dynamic>?;
        if (messageMap != null) {
          List<Map<dynamic, dynamic>> messagesList = [];

          // Convert the map of messages to a list of messages
          messageMap.forEach((key, value) {
            messagesList.add(value);
          });

          setState(() {
            _messages = messagesList;
          });
        }
      } else {
        setState(() {
          _messages = [];
        });
      }
    });
  }

  void _sendMessage() async {
    String? chatHandle =
        SharedPrefs.getString(SharedPrefsKeys.CURRENT_USER_CHAT_HANDLE);
    int? avatarId = SharedPrefs.getInt(SharedPrefsKeys.CURRENT_USER_AVATAR_ID);
    if (chatHandle == null) {
      showChatHandleDialog(context);
    } else if (avatarId == null) {
      showAvatarSelectionDialog(context);
    } else {
      bool isSenderBlocked =
          await isUserBlocked(widget.userId, widget.receiverId);
      bool isReceiverBlocked =
          await isUserBlocked(widget.receiverId, widget.userId);

      if (isSenderBlocked) {
        // Show a snackbar message indicating that the sender has blocked the receiver
        _showBlockedMessage("You blocked this user. Cannot send a message.");
        return;
      } else if (isReceiverBlocked) {
        // Show a snackbar message indicating that the receiver has blocked the sender
        _showBlockedMessage(
            "This user has blocked you. Cannot send a message.");
        return;
      }

      String messageText = _messageController.text.trim();
      if (messageText.isNotEmpty) {
        _messageController.clear();
        var timestamp = DateTime.now().millisecondsSinceEpoch;

        // Send the message to the receiver
        _databaseReference
            .child('messages')
            .child(widget.userId)
            .child(widget.receiverId)
            .push()
            .set({
          'senderId': widget.userId,
          'receiverId': widget.receiverId,
          'message': messageText,
          'timestamp': timestamp,
          'mediaType': 'text',
        });

        _databaseReference
            .child('messages')
            .child(widget.receiverId)
            .child(widget.userId)
            .push()
            .set({
          'senderId': widget.userId,
          'receiverId': widget.receiverId,
          'message': messageText,
          'timestamp': timestamp,
          'mediaType': 'text',
        });

        // Update the chat list for the sender (widget.userId)
        //   _updateChatList(widget.userId, widget.receiverId, messageText, timestamp);

        // Update the chat list for the receiver (widget.receiverId)
        _updateChatList(
            widget.receiverId, widget.userId, messageText, timestamp);

        final receiverFCMToken = await getFCMToken(widget.receiverId);
        // Send notification to the receiver
        await sendNotificationToReceiver(receiverFCMToken ?? '', widget.userId,
            widget.receiverId, messageText);
      }
    }
  }

  Future<void> _updateChatList(String userId, String otherUserId,
      String lastMessage, int timestamp) async {
    try {
      DataSnapshot snapshot = await _databaseReference
          .child('chatList')
          .child(userId)
          .child(otherUserId)
          .get();
      if (snapshot.value != null) {
        // Chat already exists, update last message and timestamp
        await _databaseReference
            .child('chatList')
            .child(userId)
            .child(otherUserId)
            .update({
          'lastMessage': lastMessage,
          'timestamp': timestamp,
          'newMessages': true,
          // Set newMessages to true to indicate there are new messages
        });
      } else {
        // Chat does not exist, create a new chat list entry
        DataSnapshot userSnapshot =
            await _databaseReference.child('users').child(otherUserId).get();
        Map<dynamic, dynamic>? userData =
            userSnapshot.value as Map<dynamic, dynamic>?;
        String otherUserName = userData?['userName'] ?? 'Unknown User';
        String otherUserImage = userData?['userImage'] ?? 'default_image_url';

        await _databaseReference
            .child('chatList')
            .child(userId)
            .child(otherUserId)
            .set({
          'userName': otherUserName,
          'userImage': otherUserImage,
          'receiverId': otherUserId,
          'lastMessage': lastMessage,
          'timestamp': timestamp,
          'newMessages': true,
        });
      }
    } catch (error) {
      print('Error updating chat list: $error');
    }
  }

  Future<void> _sendMedia() async {
    String? chatHandle =
        SharedPrefs.getString(SharedPrefsKeys.CURRENT_USER_CHAT_HANDLE);
    int? avatarId = SharedPrefs.getInt(SharedPrefsKeys.CURRENT_USER_AVATAR_ID);
    if (chatHandle == null) {
      showChatHandleDialog(context);
    } else if (avatarId == null) {
      showAvatarSelectionDialog(context);
    } else {
      bool isSenderBlocked =
          await isUserBlocked(widget.userId, widget.receiverId);
      bool isReceiverBlocked =
          await isUserBlocked(widget.receiverId, widget.userId);

      if (isSenderBlocked) {
        _showBlockedMessage("You blocked this user. Cannot send a message.");
        return;
      } else if (isReceiverBlocked) {
        _showBlockedMessage(
            "This user has blocked you. Cannot send a message.");
        return;
      }
      sendImageDialog(
          context,
          () => showPhotoOrVideoDialog(context, () => _openCameraWithImage(),
              () => _openCameraWithVideo()),
          () => _openGallery());
    }
  }

  Future<void> _openGallery() async {
    final ImagePicker _picker = ImagePicker();
    XFile? pickedFile = await _picker.pickMedia();

    if (pickedFile != null) {
      // Check if the picked file is a photo or a video
      if (pickedFile.path.endsWith('.jpg') ||
          pickedFile.path.endsWith('.png') ||
          pickedFile.path.endsWith('.jpeg') ||
          pickedFile.path.endsWith('.gif')) {
        // It's a photo
        print('Picked file is a photo');

        _uploadMedia(pickedFile, 'image');
      } else if (pickedFile.path.endsWith('.mp4') ||
          pickedFile.path.endsWith('.mov')) {
        // It's a video
        print('Picked file is a video');

        _uploadMedia(pickedFile, 'video');
      } else {
        // It's neither a photo nor a video
        print('Unsupported file type');

        _showErrorMessage('Unsupported file type. Pick Only Photo or Video');

        // Handle or display an error message
      }
    }
  }

  Future<void> _uploadMedia(XFile pickedFile, String mediaType) async {
    setState(() {
      _uploadProgress = 0.0;
      _uploading = true;
    });

    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('privatechatdata')
        .child(SharedPrefs.getString(SharedPrefsKeys.USER_ID)!)
        .child(fileName);
    UploadTask uploadTask = storageRef.putFile(File(pickedFile.path));

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      double progress = snapshot.bytesTransferred / snapshot.totalBytes;
      _updateUploadProgress(progress);
    });

    try {
      TaskSnapshot taskSnapshot = await uploadTask;
      String videoUrl = await taskSnapshot.ref.getDownloadURL();
      var timestamp = DateTime.now().millisecondsSinceEpoch;

      await _databaseReference
          .child('messages')
          .child(widget.userId)
          .child(widget.receiverId)
          .push()
          .set({
        'senderId': widget.userId,
        'receiverId': widget.receiverId,
        'message': videoUrl, // Store video URL
        'timestamp': timestamp,
        'mediaType': mediaType,
      });

      await _databaseReference
          .child('messages')
          .child(widget.receiverId)
          .child(widget.userId)
          .push()
          .set({
        'senderId': widget.userId,
        'receiverId': widget.receiverId,
        'message': videoUrl, // Store video URL
        'timestamp': timestamp,
        'mediaType': mediaType, // Add media type to differentiate videos
      });

      await _updateChatList(
          widget.receiverId, widget.userId, videoUrl, timestamp);

      await _updateUploadProgress(0.0);

      setState(() {
        _uploading = false;
      });
    } catch (error) {
      print('Error uploading video: $error');
      await _updateUploadProgress(0.0);
      setState(() {
        _uploading = false;
      });
    }
  }

  Future<void> _openCameraWithImage() async {
    final ImagePicker _picker = ImagePicker();
    XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );

    if (pickedFile != null) {
      setState(() {
        _uploadProgress = 0.0;
        _uploading = true;
      });

      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('privatechatdata')
          .child(SharedPrefs.getString(SharedPrefsKeys.USER_ID)!)
          .child(fileName);
      UploadTask uploadTask = storageRef.putFile(File(pickedFile.path));

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        _updateUploadProgress(progress);
      });

      try {
        TaskSnapshot taskSnapshot = await uploadTask;
        String imageUrl = await taskSnapshot.ref.getDownloadURL();

        var timestamp = DateTime.now().millisecondsSinceEpoch;

        // Send the message to the receiver
        await _databaseReference
            .child('messages')
            .child(widget.userId)
            .child(widget.receiverId)
            .push()
            .set({
          'senderId': widget.userId,
          'receiverId': widget.receiverId,
          'message': imageUrl,
          'timestamp': timestamp,
          'mediaType': 'image',
        });

        await _databaseReference
            .child('messages')
            .child(widget.receiverId)
            .child(widget.userId)
            .push()
            .set({
          'senderId': widget.userId,
          'receiverId': widget.receiverId,
          'message': imageUrl,
          'timestamp': timestamp,
          'mediaType': 'image',
        });

        // Update the chat list for the receiver (widget.receiverId)
        await _updateChatList(
            widget.receiverId, widget.userId, imageUrl, timestamp);

        await _updateUploadProgress(0.0);

        setState(() {
          _uploading = false;
        });
      } catch (error) {
        print('Error uploading image: $error');
        await _updateUploadProgress(0.0);

        setState(() {
          _uploading = false;
        });
      }
    }
  }

  Future<void> _openCameraWithVideo() async {
    final ImagePicker _picker = ImagePicker();
    XFile? pickedFile = await _picker.pickVideo(
      source: ImageSource.camera,
    );

    if (pickedFile != null) {
      setState(() {
        _uploadProgress = 0.0;
        _uploading = true;
      });

      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('privatechatdata')
          .child(SharedPrefs.getString(SharedPrefsKeys.USER_ID)!)
          .child(fileName);
      UploadTask uploadTask = storageRef.putFile(File(pickedFile.path));

         uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        _updateUploadProgress(progress);
      });

      try {
        TaskSnapshot taskSnapshot = await uploadTask;
        String imageUrl = await taskSnapshot.ref.getDownloadURL();

        var timestamp = DateTime.now().millisecondsSinceEpoch;

        // Send the message to the receiver
        await _databaseReference
            .child('messages')
            .child(widget.userId)
            .child(widget.receiverId)
            .push()
            .set({
          'senderId': widget.userId,
          'receiverId': widget.receiverId,
          'message': imageUrl,
          'timestamp': timestamp,
          'mediaType': 'video',
        });

        await _databaseReference
            .child('messages')
            .child(widget.receiverId)
            .child(widget.userId)
            .push()
            .set({
          'senderId': widget.userId,
          'receiverId': widget.receiverId,
          'message': imageUrl,
          'timestamp': timestamp,
          'mediaType': 'video',
        });

        // Update the chat list for the receiver (widget.receiverId)
        await _updateChatList(
            widget.receiverId, widget.userId, imageUrl, timestamp);

        await _updateUploadProgress(0.0);

        setState(() {
          _uploading = false;
        });
      } catch (error) {
        print('Error uploading image: $error');
        await _updateUploadProgress(0.0);

        setState(() {
          _uploading = false;
        });
      }
    }
  }

  Future<void> _updateUploadProgress(double progress) async {
    // Update your UI with the upload progress (e.g., set it in a progress bar)
    setState(() {
      _uploadProgress = progress;
    });
  }

  void _showBlockedMessage(String message) {
    showSnackBar(context, message);
  }

  void _showSuccessMessage(String message) {
    showSnackBar(context, message);
  }

  void _showErrorMessage(String message) {
    showErrorSnackBar(context, message);
  }

  void _blockUser(String currentUserID, String blockedUserID) {
    // Add the blockedUserID to the currentUserID's blocked users list
    _databaseReference
        .child('blockedUsers')
        .child(currentUserID)
        .child(blockedUserID)
        .set(true)
        .then((_) {
      // Successfully blocked the user, show a success message
      _showSuccessMessage("User blocked successfully!");
    }).catchError((error) {
      // An error occurred while blocking the user, show an error message
      _showErrorMessage("Failed to block user. Please try again.");
    });

    _loadBlockStatus();
  }

  void _unblockUser(String currentUserID, String blockedUserID) {
    // Remove the blockedUserID from the currentUserID's blocked users list
    _databaseReference
        .child('blockedUsers')
        .child(currentUserID)
        .child(blockedUserID)
        .remove()
        .then((_) {
      // Successfully unblocked the user, show a success message
      _showSuccessMessage("User unblocked successfully!");
    }).catchError((error) {
      // An error occurred while unblocking the user, show an error message
      _showErrorMessage("Failed to unblock user. Please try again.");
    });

    _loadBlockStatus();
  }

  void _showOptionsMenu(BuildContext context, bool isBlocked) {
    String currentUserID = widget.userId;
    String blockedUserID = widget.receiverId;

    showBlockUserDialog(
        context,
        isBlocked,
        () => {
              if (isBlocked)
                {_unblockUser(currentUserID, blockedUserID)}
              else
                {_blockUser(currentUserID, blockedUserID)}
            });
  }

  Future<bool> isUserBlocked(String currentUserID, String targetUserID) async {
    DatabaseEvent event = await _databaseReference
        .child('blockedUsers')
        .child(currentUserID)
        .child(targetUserID)
        .once();

    DataSnapshot snapshot = event.snapshot;

    // Check if the snapshot value exists and is not null
    return snapshot.exists && snapshot.value != null;
  }

  @override
  Widget build(BuildContext context) {
    _messages.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

    Avatar? matchingAvatar = avatars.firstWhere(
      (avatar) => avatar.id == int.tryParse(widget.receiverEmojiId),
      orElse: () => Avatar(id: 0, imagePath: ''),
    );

    return Scaffold(
      key: ChatScreen.chatScreenKey, // Assign the GlobalKey to the Scaffold

      appBar: AppBar(
        automaticallyImplyLeading: false, // Prevent the default back button
        leadingWidth: kToolbarHeight + 32.0, // Adjust this value as needed
        leading: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                // Handle back button press here
                // setState(() {
                //   _isUserOnChatScreen = false;
                // });
                _updateNewMessage(false);

                Navigator.of(context).pop();
              },
            ),
            // SizedBox(width: 8), // Adjust this value for spacing between arrow and image
            SizedBox(
              width:
                  40, // Set the width of the image container equal to the height for a square image
              height: kToolbarHeight,
              child: Image.asset(
                matchingAvatar.imagePath,
                fit: BoxFit.contain, // Maintain the image's aspect ratio
              ),
            ),
          ],
        ),
        title: Container(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // SizedBox(width: 8), // Adjust this value for spacing between image and title
              Text(widget.receiverUserName),
            ],
          ),
        ),
        centerTitle: false, // Make sure centerTitle is set to false
        actions: [
          PopupMenuButton(
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  child: _isBlocked ? Text('Unblock user') : Text('Block user'),
                  value: 'block this user',
                ),
              ];
            },
            onSelected: (value) async {
              // Perform action when a pop-up menu item is selected
              switch (value) {
                case 'block this user':
                  // Get the block status for the current user and receiver
                  // You can use the isUserBlocked function to get the block status
                  // Here, I'm assuming you have the function isUserBlocked implemented
                  bool isBlocked =
                      await isUserBlocked(widget.userId, widget.receiverId);

                  _showOptionsMenu(context, isBlocked);

                  break;
              }
            },
          ),
        ],
      ),
      body: WillPopScope(
        // Set the onWillPop callback to get notified when the user attempts to pop the screen
        onWillPop: () async {
          // Update the flag when the user attempts to pop the ChatScreen
          // setState(() {
          //  // _isUserOnChatScreen = false;
          // });
          _updateNewMessage(false);

          return true; // Return true to allow the screen to be popped
        },

        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      Map<dynamic, dynamic> message = _messages[index];
                      bool isSender = message['senderId'] == widget.userId;

                      //testing start
                      String messages = message['message'] ?? '';
                      String imageUrl =
                          messages.startsWith('https') ? messages : '';
                      bool isImageMessage = imageUrl.isNotEmpty;

                      int timestamp = message['timestamp'];
                      String mediaType = message['mediaType'] ?? 'none';

                      String formattedDate = DateFormat('MMM d, yyyy').format(
                        DateTime.fromMillisecondsSinceEpoch(timestamp),
                      );
                      DateTime messageDateTime =
                          DateTime.fromMillisecondsSinceEpoch(timestamp);

                      // Get the timestamp of the previous message (if available)
                      int previousTimestamp = index + 1 < _messages.length
                          ? _messages[index + 1]['timestamp']
                          : 0;
                      DateTime previousMessageDateTime =
                          DateTime.fromMillisecondsSinceEpoch(
                              previousTimestamp);

                      // Check if the current message and the previous message belong to the same date
                      bool showDateDivider =
                          !isSameDate(messageDateTime, previousMessageDateTime);

                      if (showDateDivider) {
                        // Format the date to show only the date (MMM dd, yyyy)
                        String formattedDate =
                            DateFormat('MMM dd, yyyy').format(messageDateTime);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              // Wrap with ClipRRect to make it circular
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                color: Colors.grey[200],
                                padding: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                child: Text(
                                  formattedDate,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey),
                                ),
                              ),
                            ),
                            MessageBubble(
                              message: messages,
                              isCurrentUser: isSender,
                              isImageMessage: isImageMessage,
                              imageUrl: imageUrl,
                              timestamp: timestamp,
                              mediaType: mediaType,
                            ),
                          ],
                        );
                      } else {
                        // If the current message and the previous message belong to the same date, don't show the date divider
                        return MessageBubble(
                          message: messages,
                          isCurrentUser: isSender,
                          isImageMessage: isImageMessage,
                          imageUrl: imageUrl,
                          timestamp: timestamp,
                          mediaType: mediaType,
                        );
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.mic),
                        onPressed: () {
                          _toggleListening();
                        },
                      ),
                      Expanded(
                        child: TextField(
                          minLines: 1,
                          maxLines: 7,
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                      SizedBox(
                          width:
                              8), // Add some space between the text field and the send button
                      IconButton(
                        onPressed:
                            _sendMedia, // Call the function to open the gallery
                        icon: Icon(
                          Icons.image,
                          color: Colors.blue[300],
                        ), // You can use any other icon here
                      ),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColor,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.send,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // AdmobBanner(
                //   adUnitId: AdHelper.bannerAdUnitId,
                //   adSize: AdmobBannerSize.ADAPTIVE_BANNER(
                //       width: MediaQuery.of(context).size.width.toInt()),
                // )
                CustomBannerAd(
                  key: UniqueKey(),
                )
              ],
            ),
            if (_uploading)
              Center(
                child: Container(
                  width: 200,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value:
                              _uploadProgress, // Use your upload progress variable here
                          backgroundColor: Colors.grey[300],
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                          strokeWidth: 10,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Uploading...',
                        style: TextStyle(fontSize: 18, color: Colors.blue[300]),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool isSameDate(DateTime dateTime1, DateTime dateTime2) {
    return dateTime1.year == dateTime2.year &&
        dateTime1.month == dateTime2.month &&
        dateTime1.day == dateTime2.day;
  }

  String getDateForIndex(int index) {
    if (index >= 0 && index < _messages.length) {
      int timestamp = _messages[index]['timestamp'];
      return DateFormat('MM/dd/yyyy').format(
        DateTime.fromMillisecondsSinceEpoch(timestamp),
      );
    }
    return '';
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
            _messageController.text = result.recognizedWords;
            _typedText = result.recognizedWords;
          });
        },
        listenMode: stt.ListenMode.dictation,
        pauseFor: Duration(seconds: 2),
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

  Future<void> sendNotificationToReceiver(String receiverFCMToken,
      String senderId, String receiverId, String message) async {
    print('receiver token $receiverFCMToken');
    // Replace 'YOUR_SERVER_KEY' with your FCM server key
    String serverKey = MyFirebase.FIREBASE_CLOUD_MESSAGING_KEY_NOTIFICATION;
    String url = MyFirebase.FIREBASE_NOTIFICATION_URL;

    // Replace 'YOUR_NOTIFICATION_TITLE' and 'YOUR_NOTIFICATION_BODY' with your desired notification title and body
    String notificationTitle = currentUserName ?? 'New Message';
    String notificationBody = message;

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
}

class DateDivider extends StatelessWidget {
  final String formattedDate;

  DateDivider(this.formattedDate);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          formattedDate,
          style: TextStyle(
            color: Colors.black54,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final bool isImageMessage;
  final String imageUrl;
  final int timestamp;
  final String mediaType; // Add a mediaType parameter

  MessageBubble({
    required this.message,
    required this.isCurrentUser,
    required this.isImageMessage,
    required this.imageUrl,
    required this.timestamp,
    required this.mediaType,
  });

  @override
  Widget build(BuildContext context) {
    String formattedTime = DateFormat('hh:mm a')
        .format(DateTime.fromMillisecondsSinceEpoch(timestamp));

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          if (mediaType == 'image') {
            _showFullImage(context, imageUrl);
          } else if (mediaType == 'video') {
            _playVideo(context, imageUrl);
          }
        },
        child: mediaType == 'none'
            ? Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: isCurrentUser ? Colors.blue[400] : Colors.blue[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isImageMessage)
                      Image.network(
                        imageUrl,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      )
                    else
                      Text(
                        message,
                        style: TextStyle(
                          color: isCurrentUser ? Colors.white : Colors.black,
                        ),
                      ),
                    SizedBox(height: 4),
                    Text(
                      formattedTime, // Display the formatted timestamp
                      style: TextStyle(
                        color: isCurrentUser ? Colors.white70 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: isCurrentUser ? Colors.blue[400] : Colors.blue[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (mediaType == 'image')
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            Image.asset('assets/placeholder.png'),
                      )
                    // Image.network(
                    //   imageUrl,
                    //   width: 200,
                    //   height: 200,
                    //   fit: BoxFit.cover,
                    // )
                    else if (mediaType == 'video')
                      Container(
                        width: 200,
                        height: 200,
                        child: VideoPlayerWidget(
                          videoUrl: imageUrl,
                          isCurrentUser: isCurrentUser,
                        ),
                      )
                    else if (mediaType == 'text')
                      Text(
                        message,
                        style: TextStyle(
                          color: isCurrentUser ? Colors.white : Colors.black,
                        ),
                      ),
                    SizedBox(height: 4),
                    Text(
                      formattedTime, // Display the formatted timestamp
                      style: TextStyle(
                        color: isCurrentUser ? Colors.white70 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

void _showFullImage(BuildContext context, String imageUrl) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black, // Set background color to black
        body: Stack(
          children: [
            Center(
              child: PhotoView(
                imageProvider: NetworkImage(imageUrl),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2.0,
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: Icon(
                  Icons.cancel,
                  color: Colors.white,
                  size: 35,
                ),
                onPressed: () {
                  Navigator.pop(context); // Close the image viewer
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _playVideo(BuildContext context, String videoUrl) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Scaffold(
        body: Stack(
          children: [
            Center(
              child: VideoApp(videoUrl: videoUrl),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: Icon(
                  Icons.cancel,
                  color: Colors.white,
                  size: 35,
                ),
                onPressed: () {
                  Navigator.pop(context); // Close the image viewer
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool isCurrentUser;

  VideoPlayerWidget({
    required this.videoUrl,
    required this.isCurrentUser,
  });

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late cachedVideoPlayer.CachedVideoPlayerController _controller;

  @override
  void initState() {
    _controller =
        cachedVideoPlayer.CachedVideoPlayerController.network(widget.videoUrl);
    _controller.initialize().then((value) {
      _controller.setVolume(0.0);
      _controller.play();
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return cachedVideoPlayer.CachedVideoPlayer(_controller);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}

class VideoApp extends StatefulWidget {
  final String videoUrl;

  VideoApp({required this.videoUrl});

  @override
  _VideoAppState createState() => _VideoAppState();
}

class _VideoAppState extends State<VideoApp> {
  late VideoPlayerController _controller;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
      });

    // Listen for video playback state changes
    _controller.addListener(() {
      if (_controller.value.isPlaying != isPlaying) {
        setState(() {
          isPlaying = _controller.value.isPlaying;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '',
      home: Scaffold(
        body: Center(
          child: _controller.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                )
              : CircularProgressIndicator(), // Show a loading indicator while initializing
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    // Rewind the video by a few seconds (e.g., 10 seconds)
                    final newPosition =
                        _controller.value.position - Duration(seconds: 10);
                    _controller.seekTo(newPosition);
                  },
                  icon: Icon(Icons.replay_10),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      isPlaying ? _controller.pause() : _controller.play();
                    });
                  },
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Fast forward the video by a few seconds (e.g., 10 seconds)
                    final newPosition =
                        _controller.value.position + Duration(seconds: 10);
                    _controller.seekTo(newPosition);
                  },
                  icon: Icon(Icons.forward_10),
                ),
              ],
            ),
            SizedBox(height: 16), // Add some spacing between buttons
            VideoProgressIndicator(
              _controller, // Display a progress indicator
              allowScrubbing: true, // Allow scrubbing through the video
              padding: EdgeInsets.all(8.0),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
