class ReplyMsg {
  final int rid;
  final int uid;
  final String replyMsg;
  final int timestamp;
  final String emojiId;
  final String topic;
  final String driverName;
  final String privateChat;

  ReplyMsg(this.rid, this.uid, this.replyMsg, this.timestamp, this.emojiId,
      this.topic, this.driverName, this.privateChat);
}

class ReplyMsgg {
  final String rid;
  final int uid;
  final String replyMsg;
  final int timestamp;
  ReplyMsgg(this.rid, this.uid, this.replyMsg, this.timestamp);
}
