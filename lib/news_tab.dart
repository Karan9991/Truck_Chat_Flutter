import 'dart:convert';
import 'package:chat/model/news.dart';
import 'package:chat/utils/ads.dart';
import 'package:chat/utils/constants.dart';
import 'package:chat/utils/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class NewsTab extends StatefulWidget {
  final Key key;

  NewsTab({
    required this.key,
  });

  @override
  _NewsTabState createState() => _NewsTabState();
}

class _NewsTabState extends State<NewsTab> with AutomaticKeepAliveClientMixin {
  List<NewsItem> _newsItems = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();

    fetchDataFromServer();
    // InterstitialAdManager.initialize();
  }

  @override
  void dispose() {
    super.dispose();
    //  InterstitialAdManager.dispose();
  }

  Future<void> fetchDataFromServer() async {
    final url = API.NEWS;
    final headers = {API.CONTENT_TYPE: API.APPLICATION_JSON};
    final body = {};

    final response = await http.post(Uri.parse(url),
        headers: headers, body: json.encode(body));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      print('---------------News---------------');
      print('News response body $jsonData');
      print('------------------------------');

      if (jsonData[API.STATUS] == 200) {
        final newsList = jsonData[API.NEWS_LIST] as List<dynamic>;

        setState(() {
          _newsItems = newsList.map((item) => NewsItem.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        print('Error: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      print('Error: ${response.statusCode}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      // Center the circular progress indicator
      child: SingleChildScrollView(
        child: _isLoading
            ? Center(
                // Display circular progress indicator when loading
                child: CircularProgressIndicator(),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _newsItems.length + (_newsItems.length ~/ 4),
                itemBuilder: (context, index) {
                  if (index % 5 == 4) {
                    // Check if it's the ad banner index
                    // The ad banner should be shown after every 5 items (0-based index)
                    //  return Container();
                    return CustomBannerAd(
                      key: UniqueKey(),
                    );

                    // return AdBannerWidget();
                  } else {
                    // Calculate the actual index in the news list
                    final newsIndex = index - (index ~/ 5);

                    final newsItem = _newsItems[newsIndex];

                    // final newsItem = _newsItems[index];
                    DateTime postedDate = DateTime.parse(newsItem.postedDate);
                    String formattedDate =
                        DateFormat('yyyy/MM/dd').format(postedDate);

                    return Card(
                      color: Colors.blue,
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: InkWell(
                        onTap: () {
                          // InterstitialAdManager.showInterstitialAd();

                          navigateToURL(newsItem.link);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/news.png',
                                    width: 24,
                                    height: 24,
                                    color: Colors.black,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    // Wrap the Text widget with Expanded
                                    child: Text(
                                      newsItem.title,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Padding(
                                padding: EdgeInsets.only(
                                    left: 32), // Adjust the left padding

                                child: Text(
                                  'Posted on ${formattedDate}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
      ),
    );
  }

  void navigateToURL(String url) async {
    launchUrl(Uri.parse(url));
  }

  Future<void> launchInBrowser(url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }
}

