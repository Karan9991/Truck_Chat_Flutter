import 'package:chat/home_screen.dart';
import 'package:chat/privateChat/pending_requests.dart';
import 'package:chat/privateChat/private_chat_homescreen.dart';
import 'package:flutter/material.dart';
import 'package:chat/utils/navigator_key.dart';

class GlobalNavigator {
  static showAlertDialog(String title, String content) {
    showDialog(
      barrierDismissible: false,
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(
                      initialTabIndex: 4,
                    ),
                  ),
                );
         
              },
              child: const Text('View Requests'),
            ),
          ],
        );
      },
    );
  }
}


