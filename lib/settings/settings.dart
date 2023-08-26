import 'package:chat/settings/about.dart';
import 'package:chat/settings/messages.dart';
import 'package:chat/settings/notifcations_and_sound.dart';
import 'package:chat/settings/terms_of_services.dart';
import 'package:chat/utils/ads.dart';
import 'package:chat/utils/constants.dart';
import 'package:chat/utils/shared_pref.dart';
import 'package:flutter/material.dart';
import 'about.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    //AdHelper().showInterstitialAd();
  }

  @override
  void dispose() {
    // TODO: implement dispose

   // AdHelper().showInterstitialAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue, // Set the desired color here
        iconTheme: IconThemeData(
          color: Colors.white, // Set the color of the back arrow here
        ),
        title: Text(
          Constants.SETTINGS,
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: Text(Constants.MESSAGES),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MessagesScreen()),
                    );
                  },
                ),
                Divider(), // Add a divider after the first list item

                ListTile(
                  title: Text(Constants.NOTIFICATIONS_AND_SOUND),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NotificationsAndSoundScreen()),
                    );
                  },
                ),
                Divider(), // Add a divider after the first list item

                ListTile(
                  title: Text(Constants.ABOUT),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => About()),
                    );
                  },
                ),
                Divider(), // Add a divider after the first list item

                ListTile(
                  title: Text(Constants.TERMS_AND_CONDITIONS),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => TermsOfServiceScreen()),
                    );
                  },
                ),
                Divider(), // Add a divider after the first list item
                // AdmobBanner(
                //   adUnitId: AdHelper.bannerAdUnitId,
                //   adSize: AdmobBannerSize.ADAPTIVE_BANNER(
                //       width: MediaQuery.of(context).size.width.toInt()),
                // )
              ],
            ),
          ),
          //   AdmobBanner(
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
}
