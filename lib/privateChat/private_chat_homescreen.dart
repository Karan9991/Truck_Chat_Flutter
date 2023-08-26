import 'package:chat/privateChat/pending_requests.dart';
import 'package:chat/privateChat/chat.dart';
import 'package:chat/privateChat/chatlist.dart';
import 'package:chat/utils/constants.dart';
import 'package:chat/utils/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PrivateChatTab extends StatefulWidget {
  final Key key;

  PrivateChatTab({
    required this.key,
  });

  @override
  PrivateChatTabState createState() => PrivateChatTabState();
}

class PrivateChatTabState extends State<PrivateChatTab>
    with SingleTickerProviderStateMixin {
  // int _currentIndex = 0; // Store the current index here
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    bool? isPendingRequestScreenOpen =
        SharedPrefs.getBool('isPendingRequestScreenOpen') ?? false;

    if (isPendingRequestScreenOpen) {
      navigateToPendingRequestsTab();
      SharedPrefs.setBool('isPendingRequestScreenOpen', false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();

    // TODO: implement dispose
    super.dispose();
  }

  void navigateToPendingRequestsTab() {
    _tabController.animateTo(1); // Switch to the "Pending Requests" tab
  }


  @override
  Widget build(BuildContext context) {
    String? currentUserId = SharedPrefs.getString(SharedPrefsKeys.USER_ID);

    return DefaultTabController(
      // initialIndex: _currentIndex,
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            TabBar(
              controller: _tabController, // Add this line

              dividerColor: Colors.blue,
              labelColor: Colors.blue,
              tabs: [
                Tab(text: 'Chats'),
                Tab(text: 'Pending Requests'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController, // Add this line

                children: [
                  ChatListScreen(),
                  PendingRequestsScreen(currentUserId: currentUserId ?? '0'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
