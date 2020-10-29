import 'package:awesome_loader/awesome_loader.dart';
import 'package:emergencycommunication/models/group_data.dart';
import 'package:emergencycommunication/models/user_data.dart';
import 'package:emergencycommunication/models/user_model.dart';
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
          .createChat(context, _name, userIds, false, currentGroupId)
          .then((success) {
        if (success) {
          Navigator.popUntil(context, ModalRoute.withName('/'));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Chat',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                _isLoading
                    ? AwesomeLoader(
                        loaderType: AwesomeLoader.AwesomeLoader4,
                        color: Theme.of(context).primaryColor,
                      )
                    : AwesomeLoader(
                        loaderType: AwesomeLoader.AwesomeLoader4,
                        color: Colors.white,
                      ),
                const SizedBox(height: 30.0),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: TextFormField(
                    key: _nameFormKey,
                    cursorColor: Theme.of(context).primaryColor,
                    decoration: InputDecoration(
                      labelText: 'Chat Name',
                      labelStyle: TextStyle(
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                    ),
                    validator: (input) => input.trim().isEmpty
                        ? 'Please enter a chat name'
                        : null,
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
                    color: Theme.of(context).primaryColor,
                    child: Text(
                      'Create',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                      ),
                    ),
                    onPressed: _submit,
                  ),
                ),
                const SizedBox(
                  height: 80.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
