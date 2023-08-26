class Request {
  final String senderId;
  final String receiverId;
  final String status;
  final String senderEmojiId;
  final String senderUserName;
  final String receiverEmojiId;
  final String receiverUserName;

  Request({
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.senderEmojiId,
    required this.senderUserName,
    required this.receiverEmojiId,
    required this.receiverUserName,
  });

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status,
      'senderEmojiId': senderEmojiId,
      'senderUserName': senderUserName,
      'receiverEmojiId': receiverEmojiId,
      'receiverUserName': receiverUserName,
    };
  }
}