import 'package:flutter/material.dart';
import 'package:emergencycommunication/services/auth_service.dart';
import 'package:emergencycommunication/services/database_service.dart';
import 'package:emergencycommunication/models/group_data.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  String _name, _email, _password;

  _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: <Widget>[
          _buildNameTF(),
          _buildEmailTF(),
          _buildPasswordTF(),
        ],
      ),
    );
  }

  _buildNameTF() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 30.0,
        vertical: 10.0,
      ),
      child: TextFormField(
        cursorColor: Theme.of(context).primaryColor,
        decoration: const InputDecoration(
          labelText: 'Name',
        ),
        validator: (input) =>
            input.trim().isEmpty ? 'Please enter a name' : null,
        // Refactor this
        onSaved: (input) => _name = input.trim(),
      ),
    );
  }

  _buildEmailTF() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 30.0,
        vertical: 10.0,
      ),
      child: TextFormField(
        cursorColor: Theme.of(context).primaryColor,
        decoration: const InputDecoration(
          labelText: 'Email',
        ),
        validator: (input) =>
            !input.contains('@') ? 'Please enter a valid email' : null,
        // Refactor this
        onSaved: (input) => _email = input,
      ),
    );
  }

  _buildPasswordTF() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 30.0,
        vertical: 10.0,
      ),
      child: TextFormField(
        cursorColor: Theme.of(context).primaryColor,
        decoration: const InputDecoration(
          labelText: 'Password',
        ),
        validator: (input) =>
            input.length < 6 ? 'Must be at least 6 characters' : null,
        // Refactor this
        onSaved: (input) => _password = input,
        obscureText: true,
      ),
    );
  }

  getGroupIdFromEmail(String email) async {
    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);
    List<String> groupIds = await databaseService.getAllGroupIds();
    List<String> groupAuthenticatedEmails;
    for (var groupId in groupIds) {
      groupAuthenticatedEmails =
          await databaseService.getGroupAuthenticatedEmails(groupId);
      for (var groupAuthenticatedEmail in groupAuthenticatedEmails) {
        if (email == groupAuthenticatedEmail) {
          Provider.of<GroupData>(context, listen: false).currentGroupId =
              groupId;
        }
      }
    }
  }

  _submit() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      if (_loginFormKey.currentState.validate()) {
        _loginFormKey.currentState.save();

        await getGroupIdFromEmail(_email);

        if (Provider.of<GroupData>(context, listen: false).currentGroupId !=
            null) {
          await authService.logIn(_name, _email, _password,
              Provider.of<GroupData>(context, listen: false).currentGroupId);
        } else {
          _showErrorDialog('You are not in bruh');
        }
      }
    } on PlatformException catch (err) {
      _showErrorDialog(err.message);
      // Create custom error messages
    }
  }

  _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(
            errorMessage,
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Emergency Communication',
              style: TextStyle(
                fontSize: 26.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(
              height: 40.0,
            ),
            _buildLoginForm(),
            const SizedBox(
              height: 20.0,
            ),
            Container(
              width: 180.0,
              child: FlatButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                color: Colors.blue,
                child: Text(
                  'Submit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                  ),
                ),
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
