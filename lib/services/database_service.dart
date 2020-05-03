import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emergencycommunication/models/chat_model.dart';
import 'package:emergencycommunication/models/message_model.dart';
import 'package:emergencycommunication/models/user_data.dart';
import 'package:emergencycommunication/models/user_model.dart';
import 'package:emergencycommunication/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DatabaseService {
  Future<User> getUser(String userId, String groupId) async {
    DocumentSnapshot userDoc = await groupsRef
        .document(groupId)
        .collection('users')
        .document(userId)
        .get();
    return User.fromDoc(userDoc);
  }

  Future<List<User>> searchUsers(
      String currentUserId, String currentGroupId, String name) async {
    QuerySnapshot usersSnap = await groupsRef
        .document(currentGroupId)
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: name)
        .getDocuments();
    List<User> users = [];
    usersSnap.documents.forEach((doc) {
      User user = User.fromDoc(doc);
      if (user.id != currentUserId) {
        users.add(user);
      }
    });
    return users;
  }

  Future<List<String>> getAllGroupIds() async {
    QuerySnapshot groupsSnap = await groupsRef.getDocuments();
    List<String> groupNames = [];
    groupsSnap.documents.forEach((doc) {
      groupNames.add(doc.documentID);
    });
    return groupNames;
  }

  Future<List<String>> getGroupAuthenticatedEmails(String groupId) async {
    List<String> groupAuthenticatedEmails = [];
    QuerySnapshot eventsQuery = await groupsRef.getDocuments();
    eventsQuery.documents.forEach((doc) {
      if (doc.documentID == groupId) {
        for (int i = 0; i < doc['authenticatedEmails'].length; i++) {
          String authenticatedEmail = doc['authenticatedEmails'][i].toString();
          groupAuthenticatedEmails.add(authenticatedEmail);
        }
      }
    });
    return groupAuthenticatedEmails;
  }

  Future<bool> createChat(BuildContext context, String name, List<String> users,
      bool isMainChat, String groupId) async {
    List<String> memberIds = [];
    Map<String, dynamic> memberInfo = {};
    Map<String, dynamic> readStatus = {};
    for (String userId in users) {
      memberIds.add(userId);

      User user = await getUser(userId, groupId);
      Map<String, dynamic> userMap = {
        'name': user.name,
        'email': user.email,
        'token': user.token,
      };
      memberInfo[userId] = userMap;

      readStatus[userId] = false;
    }
    await groupsRef.document(groupId).collection('chats').add({
      'name': name,
      'isMainChat': isMainChat,
      'recentMessage': 'Chat created',
      'recentSender': '',
      'recentTimestamp': Timestamp.now(),
      'memberIds': memberIds,
      'memberInfo': memberInfo,
      'readStatus': readStatus,
    });
    return true;
  }

  Future<Chat> createMainChat(BuildContext context, String name,
      List<String> users, bool isMainChat, String groupId) async {
    List<String> memberIds = [];
    Map<String, dynamic> memberInfo = {};
    Map<String, dynamic> readStatus = {};
    for (String userId in users) {
      memberIds.add(userId);

      User user = await getUser(userId, groupId);
      Map<String, dynamic> userMap = {
        'name': user.name,
        'email': user.email,
        'token': user.token,
      };
      memberInfo[userId] = userMap;

      readStatus[userId] = false;
    }
    await groupsRef.document(groupId).collection('chats').add({
      'name': name,
      'isMainChat': isMainChat,
      'recentMessage': 'Chat created',
      'recentSender': '',
      'recentTimestamp': Timestamp.now(),
      'memberIds': memberIds,
      'memberInfo': memberInfo,
      'readStatus': readStatus,
    });

    QuerySnapshot querySnapshot =
        await groupsRef.document(groupId).collection('chats').getDocuments();
    Chat chat;
    querySnapshot.documents.forEach((doc) {
      if (doc['isMainChat'] == true) {
        chat = Chat.fromDoc(doc);
      }
    });

    return chat;
  }

  Future<bool> addUserToChat(String groupId, Chat chat, String userId) async {
    List<dynamic> membersIds = [];
    DocumentSnapshot chatSnapshot = await groupsRef
        .document(groupId)
        .collection('chats')
        .document(chat.id)
        .get();

    for (var memberId in chatSnapshot['memberIds']) {
      membersIds.add(memberId);
    }

    if (!membersIds.contains(userId)) {
      Map<String, dynamic> memberInfo = {};
      Map<String, dynamic> readStatus = {};

      membersIds.add(userId);

      User user = await getUser(userId, groupId);
      Map<String, dynamic> userMap = {
        'name': user.name,
        'email': user.email,
        'token': user.token,
      };
      memberInfo[userId] = userMap;
      readStatus[userId] = false;

      await groupsRef
          .document(groupId)
          .collection('chats')
          .document(chat.id)
          .setData({
        'memberIds': membersIds,
        'memberInfo': memberInfo,
        'readStatus': readStatus,
      }, merge: true);
      return true;
    } else {
      return false;
    }
  }

  void deleteChat(String groupId, Chat chat) async {
    DocumentSnapshot chatSnapshot = await groupsRef
        .document(groupId)
        .collection('chats')
        .document(chat.id)
        .get();
    chatSnapshot.reference
        .collection('messages')
        .getDocuments()
        .then((snapshot) {
      for (DocumentSnapshot ds in snapshot.documents) {
        ds.reference.delete();
      }
    });
    chatSnapshot.reference.delete();
  }

  void sendChatMessage(String groupId, Chat chat, Message message) {
    groupsRef
        .document(groupId)
        .collection('chats')
        .document(chat.id)
        .collection('messages')
        .add({
      'senderId': message.senderId,
      'text': message.text,
      'imageUrl': message.imageUrl,
      'timestamp': message.timestamp,
    });
  }

  void setChatRead(
      BuildContext context, String groupId, Chat chat, bool read) async {
    String currentUserId =
        Provider.of<UserData>(context, listen: false).currentUserId;
    groupsRef
        .document(groupId)
        .collection('chats')
        .document(chat.id)
        .updateData({
      'readStatus.$currentUserId': read,
    });
  }
}
