import 'package:awesome_loader/awesome_loader.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emergencycommunication/models/chat_model.dart';
import 'package:emergencycommunication/models/group_data.dart';
import 'package:emergencycommunication/models/user_data.dart';
import 'package:emergencycommunication/screens/chat_screen.dart';
import 'package:emergencycommunication/screens/search_users_screen.dart';
import 'package:emergencycommunication/services/auth_service.dart';
import 'package:emergencycommunication/services/database_service.dart';
import 'package:emergencycommunication/utilities/constants.dart';
import 'package:emergencycommunication/widgets/main_stream.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool hasLoadedGroupId = false;
  bool mainChatSelected = true;
  bool mainChatLoaded = false;
  String groupName;
  Chat mainChat;

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
            getGroupName(groupDoc.documentID);
            loadMainChat(context, groupDoc.documentID);
          });
        }
      });
    });
  }

  getGroupName(String groupId) async {
    DocumentSnapshot groupDoc = await groupsRef.document(groupId).get();
    setState(() {
      groupName = groupDoc['name'];
    });
  }

  _buildChat(Chat chat, String currentUserId) {
    final bool isRead = chat.readStatus[currentUserId];
    final TextStyle readStyle = TextStyle(
      fontWeight: isRead ? FontWeight.w400 : FontWeight.bold,
      fontFamily: 'Montserrat',
    );
    return Dismissible(
      key: Key(
        UniqueKey().toString(),
      ),
      onDismissed: (direction) {
        Provider.of<DatabaseService>(context, listen: false).deleteChat(
            Provider.of<GroupData>(context, listen: false).currentGroupId,
            chat);
      },
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.all(
            Radius.circular(30.0),
          ),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.0),
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: ListTile(
        title: Text(
          chat.name,
          overflow: TextOverflow.ellipsis,
          style: readStyle,
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
      ),
    );
  }

  loadMainChat(BuildContext context, String groupId) async {
    String currentUserId =
        Provider.of<UserData>(context, listen: false).currentUserId;
    bool mainChatExists = false;
    QuerySnapshot chatQuery =
        await groupsRef.document(groupId).collection('chats').getDocuments();

    chatQuery.documents.forEach((doc) {
      if (doc['isMainChat']) {
        mainChat = Chat.fromDoc(doc);
        mainChatExists = true;
        var memberIds = doc['memberIds'];
        if (!memberIds.contains(currentUserId)) {
          Provider.of<DatabaseService>(context, listen: false)
              .addUserToChat(groupId, Chat.fromDoc(doc), currentUserId);
        }
        setState(() {
          mainChatLoaded = true;
        });
      }
    });

    if (!mainChatExists) {
      mainChat = await Provider.of<DatabaseService>(context, listen: false)
          .createMainChat(
              context, 'Main Stream', [currentUserId], true, groupId);

      setState(() {
        mainChatLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId =
        Provider.of<UserData>(context, listen: false).currentUserId;
    String currentGroupId =
        Provider.of<GroupData>(context, listen: false).currentGroupId;

    loadHomeScreenContent(bool mainChatSelected) {
      if (!mainChatLoaded) {
        return Center(
          child: AwesomeLoader(
            loaderType: AwesomeLoader.AwesomeLoader4,
            color: Colors.white,
          ),
        );
      } else {
        if (mainChatSelected) {
          if (mainChatLoaded && mainChat != null) {
            return MainStream(mainChat);
          } else {
            return Center(
              child: AwesomeLoader(
                loaderType: AwesomeLoader.AwesomeLoader4,
                color: Colors.white,
              ),
            );
          }
        } else {
          return StreamBuilder(
            stream: Firestore.instance
                .collection('groups')
                .document(currentGroupId)
                .collection('chats')
                .where('memberIds', arrayContains: currentUserId)
                .orderBy('recentTimestamp', descending: true)
                .snapshots(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (!snapshot.hasData) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(
                      Radius.circular(30.0),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'No chats available.',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                );
              }
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(
                    Radius.circular(30.0),
                  ),
                ),
                child: ListView.separated(
                  itemBuilder: (BuildContext context, int index) {
                    Chat chat = Chat.fromDoc(snapshot.data.documents[index]);
                    if (!chat.isMainChat) {
                      return _buildChat(chat, currentUserId);
                    } else {
                      return null;
                    }
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    if (index == snapshot.data.documents.length - 2) {
                      return Visibility(
                        visible: false,
                        child: const Divider(
                          thickness: 1.0,
                        ),
                      );
                    }
                    return const Divider(
                      thickness: 1.0,
                    );
                  },
                  itemCount: snapshot.data.documents.length,
                ),
              );
            },
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        brightness: Brightness.dark,
        title: Text(
          (groupName != null) ? groupName : '',
          style: TextStyle(
            fontSize: 24.0,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.exit_to_app,
              size: 26.0,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) {
                  return PlatformAlertDialog(
                    title: Text('Are you sure you want to sign out?'),
                    content: Text(
                        'You\'ll have to sign back in and you won\'t receive background notifications.'),
                    actions: <Widget>[
                      PlatformDialogAction(
                        child: Text('No'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      PlatformDialogAction(
                        child: Text('Yes'),
                        onPressed: () {
                          Navigator.pop(context);
                          Provider.of<GroupData>(context, listen: false)
                              .currentGroupId = null;
                          Provider.of<AuthService>(context, listen: false)
                              .logOut(currentGroupId);
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            color: Theme.of(context).primaryColor,
            height: 60.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                FlatButton(
                  onPressed: () {
                    setState(() {
                      mainChatSelected = true;
                    });
                  },
                  child: Text(
                    'Main Stream',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                      fontSize: 20.0,
                      decoration: mainChatSelected
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                  ),
                ),
                FlatButton(
                  onPressed: () {
                    setState(() {
                      mainChatSelected = false;
                    });
                  },
                  child: Text(
                    'Chats',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                      fontSize: 20.0,
                      decoration: !mainChatSelected
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
              ),
              child: hasLoadedGroupId
                  ? loadHomeScreenContent(mainChatSelected)
                  : Center(
                      child: AwesomeLoader(
                        loaderType: AwesomeLoader.AwesomeLoader4,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: mainChatSelected
          ? null
          : FloatingActionButton(
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
