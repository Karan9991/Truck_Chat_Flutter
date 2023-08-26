import 'package:chat/utils/constants.dart';
import 'package:chat/utils/shared_pref.dart';
import 'package:flutter/material.dart';

class ChatHandle {
  static void showChatHandle(BuildContext context) {
    TextEditingController _textEditingController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(DialogStrings.CHAT_HANDLE),
          content: TextField(
            controller: _textEditingController,
            decoration: InputDecoration(hintText: DialogStrings.ENTER_CHAT_HANDLE),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(DialogStrings.CANCEL),
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () async {
                String chatHandle = _textEditingController.text;
                await SharedPrefs.setString(SharedPrefsKeys.CHAT_HANDLE, chatHandle);
                Navigator.pop(context); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
}
