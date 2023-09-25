import 'package:chat/utils/ads.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Sponsors extends StatelessWidget {
  const Sponsors({super.key});

  void _openWebPage() async {
    String url =
        'https://smarttruckroute.com/'; // Replace with your desired URL
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Container(
  //     padding: const EdgeInsets.all(8.0),
  //     child: ListView.builder(
  //       itemCount: 10,
  //       itemBuilder: (BuildContext context, int index) {
  //         return Container(
  //           margin: const EdgeInsets.symmetric(
  //               horizontal: 16.0, vertical: 8.0), // Adjust the values as needed
  //           child: GestureDetector(
  //             onTap: _openWebPage,
  //             child: Card(
  //               elevation: 5.0,
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(20.0),
  //               ),
  //               child: Column(
  //                 children: <Widget>[
  //                   ClipRRect(
  //                     borderRadius:const BorderRadius.all(Radius.circular(20)),
  //                     child: Image.asset(
  //                       'assets/banner_sponsors.png',
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }


  @override
Widget build(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(8.0),
    child: ListView.builder(
      itemCount: 10,
      itemBuilder: (BuildContext context, int index) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 8.0),
              child: GestureDetector(
                onTap: _openWebPage,
                child: Card(
                  elevation: 5.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Column(
                    children: <Widget>[
                      ClipRRect(
                        borderRadius:const BorderRadius.all(Radius.circular(20)),
                        child: Image.asset(
                          'assets/banner_sponsors.png',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            CustomBannerAd(
              key: UniqueKey(),
            ),
          ],
        );
      },
    ),
  );
}

}
