import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final String name;
  final bool isMainChat;
  final String recentMessage;
  final String recentSender;
  final Timestamp recentTimestamp;
  final List<dynamic> memberIds;
  final dynamic memberInfo;
  final dynamic readStatus;

  // Constructor for Chat class
  Chat({
    this.id,
    this.name,
    this.isMainChat,
    this.recentMessage,
    this.recentSender,
    this.recentTimestamp,
    this.memberIds,
    this.memberInfo,
    this.readStatus,
  });

  // Factory for Chat class from a DocumentSnapshot
  factory Chat.fromDoc(DocumentSnapshot doc) {
    return Chat(
      id: doc.documentID,
      name: doc['name'],
      isMainChat: doc['isMainChat'],
      recentMessage: doc['recentMessage'],
      recentSender: doc['recentSender'],
      recentTimestamp: doc['recentTimestamp'],
      memberIds: doc['memberIds'],
      memberInfo: doc['memberInfo'],
      readStatus: doc['readStatus'],
    );
  }
}
