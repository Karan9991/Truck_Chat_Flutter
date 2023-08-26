import 'dart:io';

import 'package:chat/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:device_info/device_info.dart';
import 'package:chat/utils/ads.dart';

class About extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(Constants.ABOUT),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/ic_logo.png',
                      width: 200,
                    ),
                    Text(
                      Constants.LIVE_CHAT_WITH,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      Constants.TOTALLY_FREE_APP,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      Constants.ALL_RIGHTS_RESERVED,
                      style: TextStyle(
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 16.0),
                    Divider(height: 2.0),
                    SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () => _launchURL(Uri.parse(API.VISIT_WEBSITE)),
                          child: Text(
                            Constants.VISIT_THE_WEBSITE,
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 16.0,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _launchURL(Uri.parse(
                              API.CONTACT)), // Replace with your contact URL
                          child: Text(
                            Constants.CONTACT_US,
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 16.0,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),
                    GestureDetector(
                      onTap: () {
                        String email = Uri.encodeComponent("");
                        String subject =
                            Uri.encodeComponent(Constants.CHECK_OUT_TRUCKCHAT);
                        String body =
                            Uri.encodeComponent(Constants.I_AM_USING_TRUCKCHAT);
                        print(subject);
                        Uri mail = Uri.parse(
                            "mailto:$email?subject=$subject&body=$body");
                        launchUrl(mail);
                      },
                      child: Text(
                        Constants.TELL_A_FRIEND,
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 16.0,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.blue,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    Text(Constants.VERSION),
                    
                    Text(
                      'Serial# ',
                      style: TextStyle(fontSize: 16),
                    ),
                    FutureBuilder<String>(
                      future: getPaddedSerialNumber(),
                      builder: (BuildContext context,
                          AsyncSnapshot<String> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          return Text(snapshot.data ?? 'Unknown');
                        }
                      },
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () => showTermsOfServiceDialog(
                              context), // Replace with your terms of service URL
                          child: Text(
                            Constants.TERMS_OF_SERVICE,
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 16.0,
                              fontStyle: FontStyle.italic,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
        ));
  }

  Future<void> _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void showTermsOfServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(DialogStrings.TERMS_OF_SERVICE),
        content: SingleChildScrollView(child:  Text(
          DialogStrings.THIS_APP_IS_PROVIDED,
        ),),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(DialogStrings.GOT_IT),
          ),
        ],
      ),
    );
  }

  Future<String> getPaddedSerialNumber() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    String? serial;

    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo =
            await deviceInfoPlugin.androidInfo;
        serial = androidInfo.androidId;
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
        serial = iosInfo.identifierForVendor;
      }
    } on PlatformException {
      serial = '';
    }

    final int padding = 4;
    if ((serial!.length % padding) == 0) {
      final StringBuffer stringBuffer = StringBuffer();

      for (int i = 0; i < serial.length; i += padding) {
        if (stringBuffer.isNotEmpty) {
          stringBuffer.write("-");
        }

        stringBuffer.write(serial.substring(i, i + padding));
      }

      return stringBuffer.toString();
    }

    return serial;
  }
}
