class API {
  static const String BASE_URL = 'https://smarttruckroute.com/';
  static const String VERSION = 'bb/v1';

  static const String DEVICE_REGISTER = BASE_URL + VERSION + '/device_register';
  static const String NEW_CONVERSATION = BASE_URL + VERSION + '/device_message';
  static const String CONVERSATION_LIST =
      BASE_URL + VERSION + '/get_previous_messages';
  static const String CHAT = BASE_URL + VERSION + '/get_all_reply_message';
  static const String SEND_MESSAGE =
      BASE_URL + VERSION + '/device_post_message';
  static const String NEWS = BASE_URL + VERSION + '/get_news';
  static const String REPORT_ABUSE = BASE_URL + VERSION + '/add_user_flags';
  static const String IGNORE_USER = BASE_URL + VERSION + '/update_user_ignored';

  static const String VISIT_WEBSITE = 'https://truckchatapp.com';
  static const String CONTACT = 'https://truckchatapp.com/index.html#Contact';
  static const String SPONSORS = 'https://truckchatapp.com/sponsors.html';
  static const String REVIEWS = 'https://truckchatapp.com/reviews/mobile';
  static const String HELP = 'https://truckchatapp.com/index.html#FAQ';
  static const String CONTENT_TYPE = 'Content-Type';
  static const String APPLICATION_JSON = 'application/json';
  static const String SERVER_MSG_ID = 'server_msg_id';
  static const String SERVER_MESSAGE_ID = 'server_message_id';
  static const String STATUS = 'status';
  static const String MESSAGE = 'message';
  static const String COUNTS = 'counts';
  static const String ORIGINAL = 'original';
  static const String TIMESTAMP = 'timestamp';
  static const String USER_ID = 'user_id';
  static const String MESSAGE_REPLY_LIST = 'messsage_reply_list';
  static const String SERVER_MSG_REPLY_ID = 'server_msg_reply_id';
  static const String REPLY_MSG = 'reply_msg';
  static const String EMOJI_ID = 'emoji_id';
  static const String DEVICE_ID = 'device_id';
  static const String DEVICE_GCM_ID = 'device_gcm_id';
  static const String MESSAGE_DEVICE_TYPE = 'message_device_type';
  static const String MESSAGE_LATITUDE = 'message_latitude';
  static const String MESSAGE_LONGITUDE = 'message_longitude';
  static const String DEVICE_TYPE = 'device_type';
  static const String LATITUDE = 'latitude';
  static const String LONGITUDE = 'longitude';
  static const String NEWS_LIST = 'news_list';
  static const String TITLE = 'title';
  static const String POSTED_DATE = 'posted_date';
  static const String LINK = 'link';
}

class MyFirebase {
  static const String FIREBASE_CLOUD_MESSAGING_KEY_NOTIFICATION =
      'AAAAeR6Pnuo:APA91bHiasD4BKzgcY04ZiQ8oNi0L3HdOBeLBtUrxPfemCHHlxY0SGRP9VQ4kowDqRtOacdN8HUjmDTTMOgV1IzActxqGbKCT2W6dRm3Om5baCfJjDlBWnOm5vNqO-goLJRJV0UG1XgL';

  // static const String FIREBASE_CLOUD_MESSAGING_KEY_NOTIFICATION =
  //     'AAAA51Dk8wU:APA91bH16JrFM6yg3w014AeQ77SmXCjaTCiT8XlRy3CKPhv79XZx7xVV1_SpzLMsGaG1Zal9Cjr9gBhdMVDwz7Ka4-nnKMRyCLx2hWwoec3VahSQ5aEWxDJkqPbLkebovTWdCgkdSFTB';

  static const String FIREBASE_NOTIFICATION_URL =
      'https://fcm.googleapis.com/fcm/send';
}

class DialogStrings {
  static const String STAR_CHAT = 'Star this chat';
  static const String CHATS_THAT_ARE_STARRED_WILL =
      'Chats that are starred will not be removed after 1 day of inactivity.';
  static const String MARK_CHAT_UNREAD =
      'Unread chats will appear in bold with a "New Message" icon.';
  static const String MESSAGE_ICON_WILL =
      'The "New Message" icon will be removed.';
  static const String MARK_CHAT_READ = 'Mark this chat as read';
  static const String MARK_CHAT_THIS_UNREAD = 'Mark this chat as unread';

  static const String MARK_AS_READ = 'Mark as read';
  static const String THE_NEW_MESSAGE_ICON =
      'The "New Message" icon will be removed for all current chats.';
  static const String THE_NEW_MESSAGE_ICON_WILL =
      'The "New Message" icon will be removed.';
  static const String THIS_APP_IS_PROVIDED_I_AGREED =
      'This app is provided as a free service for trucking professionals.\n\nWe want the commercial truck driving community to have a pleasant and useful experience using the free TruckChat app, so that means no posting of explicit or offensive content. More specifically: no porn, no racism, no homophobia, no threats, no abuse, no bullying, no profanity, no sexual advances, no solicitation or personal services. No advertising of your business (unless you are a paying Sponsor of the app with written permission from the developer).\n\nIf we feel you are violating these terms, we can remove your content and/or delete your profile without question. We encourage checking with drivers about weather, traffic, parking, company reviews, delivery discussions between drivers and dispatchers.\n\nBy pressing the "I Agree" button you agree to these terms.';

  static const String MARK_AS_UNREAD = 'Mark as unread';
  static const String UNREAD_CHATS_WILL =
      'Unread chats will appear in bold with a "New Message" icon.';
  static const String CANCEL = 'Cancel';
  static const String REPORT_ABUSE = 'Report Abuse';
  static const String TO_REPORT_ABUSE =
      'To report abuse or inappropriate content, tap on a message inside a chat conversation and select an option from the popup.';
  static const String GOT_IT = 'Got It!';
  static const String TERMS_OF_SERVICE = 'Terms of Service';
  static const String THIS_APP_IS_PROVIDED =
      'This app is provided as a free service for trucking professionals.\n\nWe want the commercial truck driving community to have a pleasant and useful experience using the free TruckChat app, so that means no posting of explicit or offensive content. More specifically: no porn, no racism, no homophobia, no threats, no abuse, no bullying, no profanity, no sexual advances, no solicitation or personal services. No advertising of your business (unless you are a paying Sponsor of the app with written permission from the developer).\n\nIf we feel you are violating these terms, we can remove your content and/or delete your profile without question. We encourage checking with drivers about weather, traffic, parking, company reviews, delivery discussions between drivers and dispatchers.';
  static const String CHAT_HANDLE = 'Chat Handle';
  static const String PREPEND_YOUR_MESSAGES =
      'Prepend your messages with a handle (Handles are not unique for each other)';
  static const String CHOOSE_AVATAR = 'Choose Avatar';
  static const String AVATAR = 'Avatar';
  static const String ENTER_CHAT_HANDLE = 'Enter your chat handle';
  static const String OK = 'OK';
  static const String I_AGREE = 'I Agree';
  static const String EXIT = 'Exit';
  static const String ALERT = 'ALERT';
  static const String DELETE_THIS_CHAT = 'Delete this chat';

  static const String DO_YOU_WANT_EXIT_CONVERSATION =
      'Do you want to exit from this conversation?';

  static const String ARE_YOU_SURE = 'Are you sure you want to exit the app?';
  static const String PRIVATE_CHAT_ENABLED = 'Private Chat Enabled';
  static const String PRIVATE_CHAT_DISABLED = 'Private Chat Disabled';
  static const String PRIVATE_CHAT_YOU_REQUESTED =
      'You have requested for private chat now any person in group will able to chat with you privately. A green indicator to show user is ready for private chat.';
  static const String PRIVATE_CHAT_YOU_NO_LONGER =
      'You no longer receiving private chat requests.';

  static const String IGNORE_USER = 'Ignore User';
  static const String SEND_PRIVATE_CHAT_REQUEST = 'Send Private Chat Request';
  static const String CAMERA = 'Camera';
  static const String GALLERY = 'Galley';
  static const String DELETE = 'Delete';

  static const String CHOOSE_AN_OPTION = 'Choose an option';
  static const String DELETE_CHAT = 'Delete this chat';
  static const String CHAT_WILL_BE_DELETED =
      'This chat will be deleted. You will no longer receive messages & notifications from this chat.';
  static const String ARE_YOU_SURE_DELETE_CHAT =
      'Are you sure you want to delete this chat?';
}

class SharedPrefsKeys {
  static const String SERIAL_NUMBER = 'serialNumber';
  static const String CURRENT_USER_AVATAR_ID = 'currentUserAvatarId';
  static const String USER_ID = 'userId';
  static const String CURRENT_USER_CHAT_HANDLE = 'currentUserChatHandle';
  static const String CURRENT_USER_AVATAR_IMAGE_PATH =
      'currentUserAvatarImagePath';
  static const String CONVERSATIONS = 'conversations';
  static const String STORE_STARRED_CONVERSATIONS = 'starredConversations';

  static const String TERMS_AGREED = 'termsAgreed';
  static const String SELECTED_AVATAR_ID = 'selectedAvatarId';
  static const String CHAT_HANDLE = 'chatHandle';
  static const String LATITUDE = 'latitude';
  static const String LONGITUDE = 'longitude';

  static const String CHAT_TONES = 'chatTones';
  static const String NOTIFICATIONS = 'notifications';
  static const String NOTIFICATIONS_TONE = 'notificationsTone';
  static const String VIBRATE = 'vibrate';
  static const String PRIVATE_CHAT = 'privateChat';
}

class Constants {
  static const String CONVERSATION = 'New Conversation';
  static const String COMPOSE_CONVERSATION = 'Compose a new conversation';
  static const String COMPOSE_MESSAGE = 'Compose message';

  static const String NO_CONVERSATION_FOUND = 'No conversations found';
  static const String REPLIES = 'Replies: ';
  static const String LAST_ACTIVE = 'Last Active: ';
  static const String ERROR = 'Error occurred';
  static const String LATITUDE = 'latitude';
  static const String LONGITUDE = 'longitude';
  static const String SETTINGS = 'Settings';
  static const String TELL_A_FRIEND = 'Tell a Friend';
  static const String HELP = 'Help';
  static const String REPORT_ABUSE = 'Report Abuse';
  static const String STARRED_CHAT = 'Starred Chats';

  static const String EXIT = 'Exit';
  static const String REFRESH = 'Refresh';
  static const String CHECK_OUT_TRUCKCHAT = 'Check out TruckChat';
  static const String I_AM_USING_TRUCKCHAT =
      'I am using TruckChat right now, check it out at:\n\nhttps://play.google.com/store/apps/details?id=com.teletype.truckchat\n\nhttp://truckchatapp.com';
  static const String CONVERSATION_ID = 'conversationId';
  static const String REPLY_COUNT = 'replyCount';
  static const String IS_READ = 'isRead';
  static const String ABOUT = 'About';
  static const String LIVE_CHAT_WITH =
      '“LIVE CHAT WITH FELLOW COMMERCIAL DRIVERS IN YOUR AREA.\nIT\'S LIKE HAVING A DIGITAL CB AT NO COST.”';
  static const String TOTALLY_FREE_APP =
      'Totally FREE app, no hidden fees.\nPlease support our Sponsors.';
  static const String ALL_RIGHTS_RESERVED =
      '© TeleType Co. All Rights Reserved';
  static const String VISIT_THE_WEBSITE = 'Visit the website';
  static const String CONTACT_US = 'Contact us';
  static const String VERSION = 'Version 68.6.0.0';
  static const String TERMS_OF_SERVICE = 'Terms of Service';
  static const String MESSAGES = 'Messages';
  static const String NOTIFICATIONS_AND_SOUND = 'Notifications and Sound';
  static const String CHAT_TONES = 'Chat tones';
  static const String PLAY_A_SOUND =
      'Plays a sound for incoming and outgoing messages';
  static const String NOTIFICATIONS = 'Notifications';
  static const String NOTIFICATIONS_ARE_SHOWN =
      'Notifications are shown for new messages when app is not running';
  static const String NOTIFICATION_TONE = 'Notification tone';
  static const String NOTIFICATION_MESSAGES_WILL_PLAY =
      'Notification messages will play the default system notifications sound.';
  static const String VIBRATE = 'Vibrate';
  static const String NOTIFICATION_MESSAGES_WILL_VIBRATE =
      'Notifications messages will vibrate the device.';
  static const String PRIVATE_CHAT = 'Private Chat';
  static const String NOTIFICATIONS_SOUND = 'Notifications & Sound';
  static const String TERMS_AND_CONDITIONS = 'Terms and Conditions';
  static const String THIS_APP_IS_PROVIDED =
      'This app is provided as a free service for trucking professionals.\n\nWe want the commercial truck driving community to have a pleasant and useful experience using the free TruckChat app, so that means no posting of explicit or offensive content. More specifically: no porn, no racism, no homophobia, no threats, no abuse, no bullying, no profanity, no sexual advances, no solicitation or personal services. No advertising of your business (unless you are a paying Sponsor of the app with written permission from the developer).\n\nIf we feel you are violating these terms, we can remove your content and/or delete your profile without question. We encourage checking with drivers about weather, traffic, parking, company reviews, delivery discussions between drivers and dispatchers.';

  static const String ANDROID = 'Android';
  static const String IOS = 'iPhone';
  static const String APP_BAR_TITLE = 'TruckChat';
  static const String CHAT_HANDLE = 'Chat Handle';
  static const String PREPEND_YOUR_MESSAGES =
      'Prepend your messages with a handle (Handles are not unique for each other)';
  static const String CHOOSE_AVATAR = 'Choose Avatar';
  static const String AVATAR = 'Avatar';
  static const String ALLOW_USERS_TO =
      'Allow users to send invitations for private chat enabled.';

  static const String NEWS = 'News';
  static const String CHATS = 'Chats';
  static const String SPONSORS = 'Sponsors';
  static const String REVIEWS = 'Reviews';
  static const String SMART_TRUCK = 'SmartTruck';
  static const String PRIVATE = 'Private';

  static const String FCM_NOTIFICATION_TITLE = 'There are new messages!';
  static const String FCM_NOTIFICATION_BODY = 'Tap here to open TruckChat';
}
