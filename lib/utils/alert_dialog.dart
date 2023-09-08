import 'package:chat/home_screen.dart';
import 'package:chat/utils/constants.dart';
import 'package:chat/utils/register_user.dart';
import 'package:chat/utils/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:chat/chat/chat_list.dart';
import 'package:chat/chat/conversation_data.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:app_settings/app_settings.dart';

void showMarkAsReadUnreadDialog(BuildContext context) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogOption(
                DialogStrings.MARK_AS_READ, DialogStrings.THE_NEW_MESSAGE_ICON,
                () async {
              print('Mark as read');

              await markAllRead();

              Navigator.of(context).pop();

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(
                    initialTabIndex: 1,
                  ),
                ),
              );
            }),
            _buildDialogOption(
                DialogStrings.MARK_AS_UNREAD, DialogStrings.UNREAD_CHATS_WILL,
                () async {
              print('Mark as unread');

              await markAllUnread();

              Navigator.of(context).pop(); // Close the dialog if needed
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(
                    initialTabIndex: 1,
                  ),
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            child: Text(
              DialogStrings.CANCEL,
              style: TextStyle(
                fontSize: 18, // Adjust the font size as needed
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

void showMarkAsReadUnreadStarDialog(BuildContext context) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogOption(DialogStrings.STAR_CHAT,
                DialogStrings.CHATS_THAT_ARE_STARRED_WILL, () async {
              print('Chat Starred');

              // await markAllRead();

              Navigator.of(context).pop();
            }),
            _buildDialogOption(DialogStrings.MARK_CHAT_READ,
                DialogStrings.THE_NEW_MESSAGE_ICON_WILL, () async {
              print('Chat Read');

              // await markAllUnread();

              Navigator.of(context).pop(); // Close the dialog if needed
            }),
          ],
        ),
        actions: [
          TextButton(
            child: Text(
              DialogStrings.CANCEL,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
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

Future<void> markAllRead() async {
  List<Conversation> storedConversations = await getStoredConversations();

  // Mark all conversations as read
  for (var conversation in storedConversations) {
    conversation.isRead = true;
  }

  // Store the updated conversations
  await storeConversations(storedConversations);
}

Future<void> markAllUnread() async {
  List<Conversation> storedConversations = await getStoredConversations();

  // Mark all conversations as unread
  for (var conversation in storedConversations) {
    conversation.isRead = false;
  }

  // Store the updated conversations
  await storeConversations(storedConversations);
}

GlobalKey<_TermsOfServiceDialogState> dialogKey = GlobalKey();

class TermsOfServiceDialog extends StatefulWidget {
  final Key key;

  TermsOfServiceDialog({required this.key}) : super(key: key);

  @override
  _TermsOfServiceDialogState createState() => _TermsOfServiceDialogState();
}

class _TermsOfServiceDialogState extends State<TermsOfServiceDialog> {
  bool _isButtonEnabled = true; // Add this variable

  void _handleAgreeButton() {
    if (_isButtonEnabled) {
      setState(() {
        _isButtonEnabled = false; // Disable the button
      });

      SharedPrefs.setBool(SharedPrefsKeys.TERMS_AGREED, true);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(DialogStrings.TERMS_OF_SERVICE),
      content: SingleChildScrollView(
        child: Text(
          DialogStrings.THIS_APP_IS_PROVIDED_I_AGREED,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Perform action for "Exit"
            // Use exit(0) for platforms other than iOS
            if (Platform.isIOS) {
              // Handle iOS-specific exit behavior (e.g., display an alert)
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(DialogStrings.EXIT),
                  content: Text(DialogStrings.ARE_YOU_SURE),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(DialogStrings.CANCEL),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(DialogStrings.EXIT),
                    ),
                  ],
                ),
              ).then((exitConfirmed) {
                if (exitConfirmed ?? false) {
                  exit(0); // Exit the app
                }
              });
            } else {
              exit(0); // Exit the app directly for platforms other than iOS
            }
          },
          child: Text(DialogStrings.EXIT),
        ),
        TextButton(
          onPressed: () {
            // Perform action for "I Agree"
            SharedPrefs.setBool(SharedPrefsKeys.TERMS_AGREED, true);
            print('Terms Agreed');
            Navigator.of(context).pop();
            //  showLocationAccessDialog(context, () => null);
          },
          child: Text(DialogStrings.I_AGREE),
        ),
        // Rest of your code...
      ],
    );
  }
}

Future<void> showTermsOfServiceDialog(BuildContext context) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => TermsOfServiceDialog(key: dialogKey),
  );
}

void showExitConversationDialog(BuildContext context) async {
  bool exitConfirmed = await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(DialogStrings.ALERT),
      content: Text(DialogStrings.DO_YOU_WANT_EXIT_CONVERSATION),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true); // Exit button pressed, return true
          },
          child: Text(DialogStrings.EXIT),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context)
                .pop(false); // Cancel button pressed, return false
          },
          child: Text(DialogStrings.CANCEL),
        ),
      ],
    ),
  );

  if (exitConfirmed == true) {
    // Perform the exit action or navigate to the previous screen
    Navigator.of(context).pop(); // Go back to the previous screen
  }
}

void showLocationAccessDialog(BuildContext context, Function() onOk) {
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Location Access'),
        content: Text(
          'This app collects location data to provide city and province information related to chat messages, '
          'while you are using it. This '
          'data is not used for any other purposes and is not shared with third '
          'parties.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog

              onOk();
            },
            child: Text('Next'),
          ),
        ],
      );
    },
  );
}

void showLocationAccessDialogGlobalKey(
    GlobalKey<NavigatorState> navigatorKey, Function() onOk) {
  showDialog(
    barrierDismissible: false,
    context: navigatorKey.currentContext!,
    builder: (context) {
      return AlertDialog(
        title: Text('Location Access'),
        content: Text(
          'This app collects location data to provide city and province information related to chat messages, '
          'while you are using it. This '
          'data is not used for any other purposes and is not shared with third '
          'parties.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog

              onOk();
            },
            child: Text(DialogStrings.OK),
          ),
        ],
      );
    },
  );
}

void showPrivateChatDialog(
    BuildContext context, bool isPrivateChatEnabled, Function() onOk) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(isPrivateChatEnabled
            ? DialogStrings.PRIVATE_CHAT_ENABLED
            : DialogStrings.PRIVATE_CHAT_DISABLED),
        content: Text(isPrivateChatEnabled
            ? DialogStrings.PRIVATE_CHAT_YOU_REQUESTED
            : DialogStrings.PRIVATE_CHAT_YOU_NO_LONGER),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog

              onOk();
            },
            child: Text(DialogStrings.GOT_IT),
          ),
        ],
      );
    },
  );
}

void messageLongPressDialog(BuildContext context, Function() onReportAbuse,
    Function() onIgnoreUser, Function() onStartPrivateChat) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                onReportAbuse(); // Call the callback for Report Abuse action
              },
              child: Text(DialogStrings.REPORT_ABUSE),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                onIgnoreUser(); // Call the callback for Ignore User action
              },
              child: Text(DialogStrings.IGNORE_USER),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                onStartPrivateChat(); // Call the callback for Start Private Chat action
              },
              child: Text(DialogStrings.SEND_PRIVATE_CHAT_REQUEST),
            ),
          ],
        ),
      );
    },
  );
}

void messageLongPressDialogWithoutPrivateChat(
    BuildContext context, Function() onReportAbuse, Function() onIgnoreUser) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                onReportAbuse(); // Call the callback for Report Abuse action
              },
              child: Text(DialogStrings.REPORT_ABUSE),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                onIgnoreUser(); // Call the callback for Ignore User action
              },
              child: Text(DialogStrings.IGNORE_USER),
            ),
          ],
        ),
      );
    },
  );
}

void deletePrivateChatDialog(
    BuildContext context, Function() onDelete, Function() onCancel) {
  showDialog(
    barrierDismissible: false, // Set barrierDismissible to false

    context: context,
    builder: (context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                onDelete(); // Call the callback for Report Abuse action
              },
              child: Text(DialogStrings.DELETE_THIS_CHAT),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                onCancel();
              },
              child: Text(DialogStrings.CANCEL),
            ),
          ],
        ),
      );
    },
  );
}

void showBlockUserDialog(
    BuildContext context, bool isBlocked, Function() onBlockUnblock) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.block,
                color: Colors.red,
              ),
              title: Text(isBlocked ? 'Unblock this user' : 'Block this user'),
              onTap: () {
                Navigator.pop(context); // Close the options menu
                onBlockUnblock();
              },
            ),
          ],
        ),
      );
    },
  );
}

void showDeleteChatDialog(BuildContext context, Function() onDeleteChat) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(DialogStrings.DELETE_CHAT),
        content: Text(DialogStrings.ARE_YOU_SURE_DELETE_CHAT),
        actions: [
          TextButton(
            child: Text(DialogStrings.CANCEL),
            onPressed: () {
              Navigator.of(context).pop(); // Close the confirmation dialog
            },
          ),
          TextButton(
            child: Text(DialogStrings.DELETE),
            onPressed: () async {
              Navigator.of(context).pop();
              onDeleteChat();
            },
          ),
        ],
      );
    },
  );
}

void showIgnoreUserSuccessDialog(BuildContext context, String title) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}

Future<void> showReportDialog(
    BuildContext context, VoidCallback onReport) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Report Abuse'),
        content: Text('Are you sure you want to report abuse?'),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
          TextButton(
            child: Text('Report'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              onReport(); // Call the provided callback function
            },
          ),
        ],
      );
    },
  );
}

Future<void> showIgnoreUserDialog(
    BuildContext context, VoidCallback onIgnore) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Ignore User'),
        content: Text('Are you sure you want to Ignore this user?'),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
          TextButton(
            child: Text('Ignore'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              onIgnore(); // Call the provided callback function
            },
          ),
        ],
      );
    },
  );
}

void sendPrivateChatRequest(
    BuildContext context, String title, String subtitle) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(subtitle),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}

void sendImageDialog(
  BuildContext context,
  Function() onCamera,
  Function() onGallery,
) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center, // Center the options
            children: [
              SizedBox(height: 10),
              Text(
                DialogStrings.CHOOSE_AN_OPTION,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  onGallery();
                },
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center the icon and text
                  children: [
                    Icon(Icons.image),
                    SizedBox(width: 16),
                    Text(
                      'Gallery',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  onCamera();
                },
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center the icon and text
                  children: [
                    SizedBox(width: 10),
                    Icon(Icons.camera_alt),
                    SizedBox(width: 16),
                    Text(
                      'Camera',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

void showPhotoOrVideoDialog(
  BuildContext context,
  Function() onPhoto,
  Function() onVideo,
) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center, // Center the options
            children: [
              SizedBox(height: 10),
              // Text(
              //   DialogStrings.CHOOSE_AN_OPTION,
              //   style: TextStyle(
              //     fontWeight: FontWeight.bold,
              //     fontSize: 18,
              //   ),
              // ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onPhoto();
                },
                icon: Icon(Icons.photo),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.cyan[400],
                       shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        20), ),
                ),
                label: Text('Photo'),
              ),
      
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onVideo();
                },
                icon: Icon(Icons.videocam),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        20), 
                  ),
                ),
                label: Text('Video'),
              ),
           
              SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

void showChatHandleDialog(BuildContext context) {
  final TextEditingController _chatHandleController = TextEditingController();

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

void showLocationPermissionDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Location Permission Required'),
        content:
            Text('Please enable location permission in your device settings.'),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Open Settings'),
            onPressed: () {
              Navigator.of(context).pop();
              _openAppSettings();
            },
          ),
        ],
      );
    },
  );
}

Future<void> _openAppSettings() async {
  await AppSettings.openAppSettings(type: AppSettingsType.location);
}
