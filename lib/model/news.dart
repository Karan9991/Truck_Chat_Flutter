
import 'package:chat/utils/constants.dart';

class NewsItem {
  final String title;
  final String postedDate;
  final String link;

  NewsItem({required this.title, required this.postedDate, required this.link});

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      title: json[API.TITLE],
      postedDate: json[API.POSTED_DATE],
      link: json[API.LINK],
    );
  }
}