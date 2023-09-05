import 'dart:io';
import 'package:chat/home_screen.dart';
import 'package:chat/utils/alert_dialog.dart';
import 'package:chat/utils/constants.dart';
import 'package:chat/utils/device_type.dart';
import 'package:chat/utils/register_user.dart';
import 'package:chat/utils/shared_pref.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chat/utils/lat_lng.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:chat/utils/ads.dart';
import 'package:flutter/services.dart'; // Import SystemChrome
import 'package:geolocator/geolocator.dart';

class NewConversationScreen extends StatefulWidget {
  @override
  _NewConversationScreenState createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends State<NewConversationScreen> {
  String status_message = '';
  int status_code = 0;
  int conversation_id = 0;
  TextEditingController _textEditingController = TextEditingController();
  String? emojiId;
  bool _isSending = false;

  stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  String _typedText = '';
  String deviceType = getDeviceType();

  double _keyboardPadding = 0.0; // Initialize padding

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    // Restore all available screen orientations
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(Constants.CONVERSATION),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              // Wrap this section with SingleChildScrollView
              child: Container(
                padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.mic),
                      onPressed: () {
                        _toggleListening();
                      },
                    ),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: TextField(
                        controller: _textEditingController,
                        onChanged: (value) {
                          _typedText = value;
                        },
                        maxLines: 4, // Increase the number of lines to show
                        decoration: InputDecoration(
                          hintText: Constants.COMPOSE_CONVERSATION,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide(
                              color: Colors
                                  .green, // Change the selected border color here
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 16.0,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.0),
                    Material(
                      borderRadius: BorderRadius.circular(24.0),
                      color: Colors.blue,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24.0),
                        onTap: () async {
                          String newConversation =
                              _textEditingController.text.trim();
                          if (!newConversation.isEmpty) {
                            await _sendConversation();
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(12.0),
                          child: _isSending
                              ? CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                )
                              : Icon(
                                  Icons.send,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // AdmobBanner(
          //   adUnitId: AdHelper.bannerAdUnitId,
          //   adSize: AdmobBannerSize.ADAPTIVE_BANNER(
          //     width: MediaQuery.of(context).size.width.toInt(),
          //   ),
          // ),
          CustomBannerAd(
            key: UniqueKey(),
          ),
        ],
      ),
    );
  }

  Future<bool> send() async {
    String newConversation = _textEditingController.text;
    String? serialNumber = SharedPrefs.getString(SharedPrefsKeys.SERIAL_NUMBER);
    Map<String, double> locationData = await getLocation();
    double latitude = locationData[Constants.LATITUDE]!;
    double longitude = locationData[Constants.LONGITUDE]!;
    String? userId = SharedPrefs.getString(SharedPrefsKeys.USER_ID) ?? '';
    bool? privateChat =
        SharedPrefs.getBool(SharedPrefsKeys.PRIVATE_CHAT) ?? false;
    String? chatHandle =
        SharedPrefs.getString(SharedPrefsKeys.CURRENT_USER_CHAT_HANDLE) ?? '';

    String privateChatStatus = privateChat ? '1' : '0';

    if (SharedPrefs.getInt(SharedPrefsKeys.CURRENT_USER_AVATAR_ID) != null) {
      emojiId =
          SharedPrefs.getInt(SharedPrefsKeys.CURRENT_USER_AVATAR_ID).toString();
      // print('new conversation emoji id $emojiId');
    } else {
      emojiId = '0';
      // print('new conversation emoji id $emojiId');
    }

    final Uri url = Uri.parse(API.NEW_CONVERSATION);

    try {
      Map<String, dynamic> entity = {
        API.DEVICE_ID: serialNumber,
        API.MESSAGE_DEVICE_TYPE: deviceType,
        API.MESSAGE: newConversation,
        API.MESSAGE_LATITUDE: latitude.toString(),
        API.MESSAGE_LONGITUDE: longitude.toString(),
        API.EMOJI_ID: emojiId,
        // "device_package": "com.teletype.truckchat2.android",
        // "user_id": userId,
        // "private_chat": privateChatStatus,
        // "driver_name": chatHandle,
      };

      http.Response response = await http.post(
        url,
        body: json.encode(entity),
        headers: {API.CONTENT_TYPE: API.APPLICATION_JSON},
      );

      if (response.statusCode == 200) {
        String result = response.body;
        print('---------------New Conversation Response---------------');

        print(result);
        // print('[REPLY] $result');

        Map<String, dynamic> jsonResult = json.decode(result);
        status_code = jsonResult[API.STATUS];
        //  print('new conversation status_code $status_code');

        if (jsonResult.containsKey(API.MESSAGE)) {
          status_message = jsonResult[API.MESSAGE];
          // print('new conversation status_message $status_message');
        } else {
          status_message = '';
        }

        if (jsonResult.containsKey(API.SERVER_MESSAGE_ID)) {
          conversation_id = jsonResult[API.SERVER_MESSAGE_ID];
          //  print('new conversation id $conversation_id');
        }

        return true;
      } else {
        status_message = 'Connection Error';
      }
    } catch (e) {
      // print('new conversation catch $e');
      status_message = e.toString();
    }

    return false;
  }

  Future<void> _sendConversation() async {
    print('send conversation');
    // Location location = Location();
    // PermissionStatus _permissionGranted;
    final _locationPermission = await Geolocator.checkPermission();

    // _permissionGranted = await location.hasPermission();

    // if (_locationPermission == LocationPermission.denied ||
    //     _locationPermission == LocationPermission.deniedForever) {
    //   showLocationPermissionDialog(context);
    // } else {
    String? userId = SharedPrefs.getString(SharedPrefsKeys.USER_ID);

    if (userId == null) {
      print('4');
      setState(() {
        _isSending = true;
      });
      await registerDevice();

      bool sent = await send();

      setState(() {
        _isSending = false;
      });

      if (sent) {
        print('5');
        await sendFCMNotification('all', 'message');

        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => HomeScreen(
                    initialTabIndex: 1,
                  )),
        );
      }
    } else {
      print('6');

      setState(() {
        _isSending = true;
      });

      bool sent = await send();

      setState(() {
        _isSending = false;
      });

      if (sent) {
        print('7');
        await sendFCMNotification('all', 'message');

        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => HomeScreen(
                    initialTabIndex: 1,
                  )),
        );
      }
    }
    // }
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
            _textEditingController.text = result.recognizedWords;
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

  Future<void> sendFCMNotification(String topic, String message) async {
    String? userId = SharedPrefs.getString(SharedPrefsKeys.USER_ID);

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
        'type': 'newchat',
        'senderUserId': userId, // Include the senderId in the data payload
      },
    };

    try {
      final response =
          await http.post(url, headers: headers, body: jsonEncode(body));
      if (response.statusCode == 200) {
        print('FCM notification sent successfully');
      } else {
        print('Failed to send FCM notification');
      }
    } catch (e) {
      print('Error sending FCM notification: $e');
    }
  }
}
