import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:emergencycommunication/services/auth_service.dart';
import 'package:emergencycommunication/screens/search_users_screen.dart';
import 'package:emergencycommunication/models/user_data.dart';
import 'package:emergencycommunication/utilities/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emergencycommunication/models/chat_model.dart';
import 'package:emergencycommunication/models/group_data.dart';
import 'package:emergencycommunication/screens/chat_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool hasLoadedGroupId = false;

  @override
  void initState() {
    super.initState();
    getGroupIdFromUserId(
        Provider.of<UserData>(context, listen: false).currentUserId);

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print('On message $message');
      },
      onResume: (Map<String, dynamic> message) async {
        print('On resume $message');
      },
      onLaunch: (Map<String, dynamic> message) async {
        print('On launch $message');
      },
    );
    _firebaseMessaging.requestNotificationPermissions(
      const IosNotificationSettings(
        sound: true,
        badge: true,
        alert: true,
      ),
    );
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      print('Settings registered: $settings');
    });
  }

  getGroupIdFromUserId(String userId) async {
    QuerySnapshot groupsSnap = await groupsRef.getDocuments();
    groupsSnap.documents.forEach((groupDoc) async {
      QuerySnapshot anotherSnapshot = await groupsRef
          .document(groupDoc.documentID)
          .collection('users')
          .getDocuments();
      anotherSnapshot.documents.forEach((userDoc) async {
        if (userDoc.documentID == userId) {
          Provider.of<GroupData>(context, listen: false).currentGroupId =
              groupDoc.documentID;
          setState(() {
            hasLoadedGroupId = true;
          });
        }
      });
    });
  }

  _buildChat(Chat chat, String currentUserId) {
    final bool isRead = chat.readStatus[currentUserId];
    final TextStyle readStyle = TextStyle(
      fontWeight: isRead ? FontWeight.w400 : FontWeight.bold,
    );
    return ListTile(
      title: Text(
        chat.name,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: chat.recentSender.isEmpty
          ? Text(
              'Chat Created',
              overflow: TextOverflow.ellipsis,
              style: readStyle,
            )
          : chat.recentMessage != null
              ? Text(
                  '${chat.memberInfo[chat.recentSender]['name']} : ${chat.recentMessage}',
                  overflow: TextOverflow.ellipsis,
                  style: readStyle,
                )
              : Text(
                  '${chat.memberInfo[chat.recentSender]['name']} sent an image',
                  overflow: TextOverflow.ellipsis,
                  style: readStyle,
                ),
      trailing: Text(
        timeFormat.format(
          chat.recentTimestamp.toDate(),
        ),
        style: readStyle,
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(chat),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId =
        Provider.of<UserData>(context, listen: false).currentUserId;
    String currentGroupId =
        Provider.of<GroupData>(context, listen: false).currentGroupId;
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: Text(
          'Chats',
          style: TextStyle(
            fontSize: 26.0,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.exit_to_app,
              size: 26.0,
            ),
            onPressed: () {
              Provider.of<AuthService>(context, listen: false)
                  .logOut(currentGroupId);
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
        ),
        child: hasLoadedGroupId
            ? StreamBuilder(
                stream: Firestore.instance
                    .collection('groups')
                    .document(currentGroupId)
                    .collection('chats')
                    .where('memberIds', arrayContains: currentUserId)
                    .orderBy('recentTimestamp', descending: true)
                    .snapshots(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.0,
                    ),
                    child: ListView.separated(
                      itemBuilder: (BuildContext context, int index) {
                        Chat chat =
                            Chat.fromDoc(snapshot.data.documents[index]);
                        return _buildChat(chat, currentUserId);
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return const Divider(
                          thickness: 1.0,
                        );
                      },
                      itemCount: snapshot.data.documents.length,
                    ),
                  );
                },
              )
            : Center(
                child: CircularProgressIndicator(),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchUsersScreen(),
          ),
        ),
        tooltip: 'Create New Chat',
        backgroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}
