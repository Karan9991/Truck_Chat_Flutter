import 'dart:io';

import 'package:chat/utils/constants.dart';
import 'package:chat/utils/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:chat/utils/ads.dart';
import 'package:app_settings/app_settings.dart';

class NotificationsAndSoundScreen extends StatefulWidget {
  @override
  _NotificationsAndSoundScreenState createState() =>
      _NotificationsAndSoundScreenState();
}

class _NotificationsAndSoundScreenState
    extends State<NotificationsAndSoundScreen> {
  bool? chatTonesEnabled;
  bool? notificationsEnabled;
  bool? notificationToneEnabled;
  bool? vibrateEnabled;
  bool? privateChatEnabled;

  @override
  void initState() {
    super.initState();

    // Retrieve the initial values from SharedPreferences
    chatTonesEnabled = SharedPrefs.getBool(SharedPrefsKeys.CHAT_TONES);
    notificationsEnabled = SharedPrefs.getBool(SharedPrefsKeys.NOTIFICATIONS);
    notificationToneEnabled =
        SharedPrefs.getBool(SharedPrefsKeys.NOTIFICATIONS_TONE);
    vibrateEnabled = SharedPrefs.getBool(SharedPrefsKeys.VIBRATE);
    privateChatEnabled = SharedPrefs.getBool(SharedPrefsKeys.PRIVATE_CHAT);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Constants.NOTIFICATIONS_AND_SOUND),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(0.0, 16.0, 0.0, 16.0),
              children: [
                Divider(),
                _buildListTile(
                  Constants.CHAT_TONES,
                  Constants.PLAY_A_SOUND,
                  SharedPrefsKeys.CHAT_TONES,
                  chatTonesEnabled,
                  (bool? value) {
                    setState(() {
                      chatTonesEnabled = value;
                    });
                    SharedPrefs.setBool(SharedPrefsKeys.CHAT_TONES, value!);
                  },
                ),
                Divider(),
                _buildListTile(
                  Constants.NOTIFICATIONS,
                  Constants.NOTIFICATIONS_ARE_SHOWN,
                  SharedPrefsKeys.NOTIFICATIONS,
                  notificationsEnabled,
                  (bool? value) {
                    setState(() {
                      notificationsEnabled = value;
                    });
                    SharedPrefs.setBool(SharedPrefsKeys.NOTIFICATIONS, value!);
                  },
                ),
                Divider(),
                _buildListTile(
                  Constants.NOTIFICATION_TONE,
                  Constants.NOTIFICATION_MESSAGES_WILL_PLAY,
                  SharedPrefsKeys.NOTIFICATIONS_TONE,
                  notificationToneEnabled,
                  (bool? value) {
                    setState(() {
                      notificationToneEnabled = value;
                    });
                    if (Platform.isIOS) {
                      AppSettings.openAppSettings(
                          type: AppSettingsType.notification);
                    } else {
                      SharedPrefs.setBool(
                          SharedPrefsKeys.NOTIFICATIONS_TONE, value!);
                    }
                  },
                ),
                Divider(),
                _buildListTile(
                  Constants.VIBRATE,
                  Constants.NOTIFICATION_MESSAGES_WILL_VIBRATE,
                  SharedPrefsKeys.VIBRATE,
                  vibrateEnabled,
                  (bool? value) {
                    setState(() {
                      vibrateEnabled = value;
                    });
                    if (Platform.isIOS) {
                      AppSettings.openAppSettings(
                          type: AppSettingsType.notification);
                    } else {
                      SharedPrefs.setBool(SharedPrefsKeys.VIBRATE, value!);
                    }
                  },
                ),
                Divider(),
                _buildListTile(
                  Constants.PRIVATE_CHAT,
                  Constants.ALLOW_USERS_TO,
                  SharedPrefsKeys.PRIVATE_CHAT,
                  privateChatEnabled,
                  (bool? value) {
                    setState(() {
                      privateChatEnabled = value;
                    });
                    SharedPrefs.setBool(SharedPrefsKeys.PRIVATE_CHAT, value!);
                  },
                ),
                Divider(),
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

  Widget _buildListTile(
    String title,
    String description,
    String key,
    bool? value,
    ValueChanged<bool?> onChanged,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          value = !(value ?? false);
        });
        onChanged(value);
        print('actual value $value');
        SharedPrefs.setBool(key, value!);
        print('gesture click $key ${SharedPrefs.getBool(key)}');
      },
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            color: Colors.grey,
            // fontWeight: FontWeight.bold,
          ),
        ),
        trailing:Platform.isIOS &&  (key == SharedPrefsKeys.NOTIFICATIONS_TONE ||
                key == SharedPrefsKeys.VIBRATE)
            ? Icon(
                Icons.arrow_circle_right_outlined,
                color: Colors.blue,
                size: 30,
              )
            : Checkbox(
                value: value ?? false,
                onChanged: (newValue) {
                  setState(() {
                    value = newValue;
                  });
                  onChanged(value);
                  SharedPrefs.setBool(key, value!);
                  print('check box $key ${SharedPrefs.getBool(key)}');
                },
                activeColor: Colors.blue,
              ),
      ),
    );
  }
}
