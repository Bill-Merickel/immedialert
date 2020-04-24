import 'package:emergencycommunication/models/group_data.dart';
import 'package:emergencycommunication/models/user_data.dart';
import 'package:emergencycommunication/models/user_model.dart';
import 'package:emergencycommunication/screens/home_screen.dart';
import 'package:emergencycommunication/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CreateChatScreen extends StatefulWidget {
  final List<User> selectedUsers;

  const CreateChatScreen({this.selectedUsers});

  @override
  _CreateChatScreenState createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  final _nameFormKey = GlobalKey<FormFieldState>();
  String _name = '';
  bool _isLoading = false;

  _submit() async {
    if (_nameFormKey.currentState.validate() && !_isLoading) {
      _nameFormKey.currentState.save();
      setState(() => _isLoading = true);
      List<String> userIds =
          widget.selectedUsers.map((user) => user.id).toList();
      userIds.add(
        Provider.of<UserData>(context, listen: false).currentUserId,
      );
      final currentGroupId =
          Provider.of<GroupData>(context, listen: false).currentGroupId;
      Provider.of<DatabaseService>(context, listen: false)
          .createChat(context, _name, userIds, currentGroupId)
          .then((success) {
        if (success) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(),
            ),
            (Route<dynamic> route) => false,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Chat'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _isLoading
                ? LinearProgressIndicator(
                    backgroundColor: Colors.blue[200],
                    valueColor: const AlwaysStoppedAnimation(
                      Colors.blue,
                    ),
                  )
                : const SizedBox.shrink(),
            const SizedBox(height: 30.0),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextFormField(
                key: _nameFormKey,
                decoration: InputDecoration(labelText: 'Chat Name'),
                validator: (input) =>
                    input.trim().isEmpty ? 'Please enter a chat name' : null,
                onSaved: (input) => _name = input,
              ),
            ),
            const SizedBox(height: 20.0),
            Container(
              width: 180.0,
              child: FlatButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                color: Colors.blue,
                child: Text(
                  'Create',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                  ),
                ),
                onPressed: _submit,
              ),
            )
          ],
        ),
      ),
    );
  }
}
