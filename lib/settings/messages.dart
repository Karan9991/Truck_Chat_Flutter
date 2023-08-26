import 'package:chat/utils/constants.dart';
import 'package:chat/utils/shared_pref.dart';
import 'package:flutter/material.dart';
import '/utils/avatar.dart';
import 'package:chat/utils/ads.dart';

class MessagesScreen extends StatelessWidget {
  final TextEditingController _chatHandleController = TextEditingController(
    text: SharedPrefs.getString(SharedPrefsKeys.CURRENT_USER_CHAT_HANDLE) ?? '',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Constants.MESSAGES),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Divider(), // Add a divider after the first list item

                _buildListTile(
                  Constants.CHAT_HANDLE,
                  Constants.PREPEND_YOUR_MESSAGES,
                  () => _showChatHandleDialog(context),
                ),
                Divider(), // Add a divider after the first list item

                _buildListTile(
                  Constants.CHOOSE_AVATAR,
                  Constants.AVATAR,
                  () {
                    showAvatarSelectionDialog(context);
                  },
                ),
                Divider(), // Add a divider after the first list item
              ],
            ),
          ),
          // AdmobBanner(
          //   adUnitId: AdHelper.bannerAdUnitId,
          //   adSize: AdmobBannerSize.ADAPTIVE_BANNER(
          //     width: MediaQuery.of(context).size.width.toInt(),
          //   ),
          // ),
          CustomBannerAd(key: UniqueKey(),)
        ],
      ),
    );
  }

  Widget _buildListTile(String title, String description, VoidCallback onTap) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      subtitle: Text(
        description,
        style: TextStyle(
          color: Colors.grey, // Replace with your desired text color
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showChatHandleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(DialogStrings.CHAT_HANDLE),
          content: TextField(
            controller: _chatHandleController,
            decoration:
                InputDecoration(hintText: DialogStrings.ENTER_CHAT_HANDLE),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                DialogStrings.CANCEL,
                style: TextStyle(
                    color:
                        Colors.blue), // Set the desired color for Cancel button
              ),
            ),
            TextButton(
              onPressed: () {
                String chatHandle = _chatHandleController.text;
                SharedPrefs.setString(
                    SharedPrefsKeys.CURRENT_USER_CHAT_HANDLE, chatHandle);

                print('Chat Handle: $chatHandle');
                Navigator.of(context).pop();
              },
              child: Text(
                DialogStrings.OK,
                style: TextStyle(
                    color:
                        Colors.blue), // Set the desired color for Cancel button
              ),
            ),
          ],
        );
      },
    );
  }
}
