import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:emergencycommunication/services/auth_service.dart';
import 'package:emergencycommunication/screens/search_users_screen.dart';
import 'package:emergencycommunication/models/user_data.dart';
import 'package:emergencycommunication/utilities/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emergencycommunication/models/chat_model.dart';
import 'package:emergencycommunication/screens/chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  @override
  void initState() {
    super.initState();
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) {
        print('On message $message');
      },
      onResume: (Map<String, dynamic> message) {
        print('On resume $message');
      },
      onLaunch: (Map<String, dynamic> message) {
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
    Provider.of<AuthService>(context, listen: false).updateToken();
  }

  _buildChat(Chat chat, String currentUserId) {
    final bool isRead = chat.readStatus[currentUserId];
    final TextStyle readStyle = TextStyle(
      fontWeight: isRead ? FontWeight.w400 : FontWeight.bold,
    );
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.white,
        radius: 28.0,
        backgroundImage: CachedNetworkImageProvider(chat.imageUrl),
      ),
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.exit_to_app),
          onPressed: Provider.of<AuthService>(context, listen: false).logOut,
        ),
        title: Text('Chats'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SearchUsersScreen(),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: Firestore.instance
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
          return ListView.separated(
            itemBuilder: (BuildContext context, int index) {
              Chat chat = Chat.fromDoc(snapshot.data.documents[index]);
              return _buildChat(chat, currentUserId);
            },
            separatorBuilder: (BuildContext context, int index) {
              return const Divider(
                thickness: 1.0,
              );
            },
            itemCount: snapshot.data.documents.length,
          );
        },
      ),
    );
  }
}