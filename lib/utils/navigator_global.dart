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

  static showUpdateDialog() {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          title: Text(
            'Update Available',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'A new version of the app is available. Please update for the best experience.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to Play Store link
                // Example: launch('https://play.google.com/store/apps/details?id=com.example.app')
              },
              child: Text(
                'Update',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
