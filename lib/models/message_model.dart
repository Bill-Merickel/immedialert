import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String text;
  final String imageUrl;
  final Timestamp timestamp;

  // Constructor for Message class
  Message({
    this.id,
    this.senderId,
    this.text,
    this.imageUrl,
    this.timestamp,
  });

  // Factory for Message class from a DocumentSnapshot
  factory Message.fromDoc(DocumentSnapshot doc) {
    return Message(
      id: doc.documentID,
      senderId: doc['senderId'],
      text: doc['text'],
      imageUrl: doc['imageUrl'],
      timestamp: doc['timestamp'],
    );
  }
}
