import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emergencycommunication/models/chat_model.dart';
import 'package:emergencycommunication/models/group_data.dart';
import 'package:emergencycommunication/models/message_model.dart';
import 'package:emergencycommunication/models/user_data.dart';
import 'package:emergencycommunication/services/database_service.dart';
import 'package:emergencycommunication/services/storage_service.dart';
import 'package:emergencycommunication/utilities/constants.dart';
import 'package:emergencycommunication/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen(this.chat);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isComposingMessage = false;
  DatabaseService _databaseService;
  String currentGroupId;

  @override
  void initState() {
    super.initState();
    currentGroupId =
        Provider.of<GroupData>(context, listen: false).currentGroupId;
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
    _databaseService.setChatReadStatus(
        context, currentGroupId, widget.chat, true);
  }

  _buildMessageTF() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: <Widget>[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: IconButton(
              icon: Icon(
                Icons.photo,
                color: Colors.white,
              ),
              onPressed: () async {
                File imageFile = await ImagePicker.pickImage(
                  source: ImageSource.gallery,
                );
                if (imageFile != null) {
                  String imageUrl = await Provider.of<StorageService>(
                    context,
                    listen: false,
                  ).uploadMessageImage(imageFile, currentGroupId);
                  _sendMessage(null, imageUrl);
                }
              },
            ),
          ),
          Expanded(
            child: TextField(
              cursorColor: Colors.white,
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              enableSuggestions: true,
              minLines: 1,
              maxLines: 8,
              onChanged: (messageText) {
                setState(() => _isComposingMessage = messageText.isNotEmpty);
              },
              style: TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
              decoration: InputDecoration.collapsed(
                hintText: 'Send a message',
                hintStyle: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 4.0,
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_upward,
                color: Colors.white,
              ),
              onPressed: _isComposingMessage
                  ? () => _sendMessage(
                        _messageController.text,
                        null,
                      )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  _sendMessage(String text, String imageUrl) async {
    if ((text != null && text.trim().isNotEmpty) || imageUrl != null) {
      if (imageUrl == null) {
        // Text Message
        _messageController.clear();
        setState(() => _isComposingMessage = false);
      }
      Message message = Message(
        senderId: Provider.of<UserData>(context, listen: false).currentUserId,
        text: text,
        imageUrl: imageUrl,
        timestamp: Timestamp.now(),
      );
      _databaseService.sendChatMessage(currentGroupId, widget.chat, message);
    }
  }

  _buildMessagesStream() {
    return StreamBuilder(
      stream: groupsRef
          .document(currentGroupId)
          .collection('chats')
          .document(widget.chat.id)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }
        return Expanded(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            onPanDown: (_) {
              FocusScope.of(context).requestFocus(FocusNode());
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(
                  Radius.circular(30.0),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 20.0,
                ),
                physics: AlwaysScrollableScrollPhysics(),
                reverse: true,
                children: _buildMessageBubbles(snapshot),
              ),
            ),
          ),
        );
      },
    );
  }

  List<MessageBubble> _buildMessageBubbles(
      AsyncSnapshot<QuerySnapshot> messages) {
    List<MessageBubble> messageBubbles = [];
    messages.data.documents.forEach((doc) {
      Message message = Message.fromDoc(doc);
      MessageBubble messageBubble = MessageBubble(widget.chat, message);
      messageBubbles.add(messageBubble);
    });
    return messageBubbles;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        _databaseService.setChatReadStatus(
            context, currentGroupId, widget.chat, true);
        return Future.value(true);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        appBar: AppBar(
          title: Text(
            widget.chat.name,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildMessagesStream(),
              _buildMessageTF(),
            ],
          ),
        ),
      ),
    );
  }
}
