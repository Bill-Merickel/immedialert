import 'package:auto_size_text/auto_size_text.dart';
import 'package:emergencycommunication/models/group_data.dart';
import 'package:emergencycommunication/services/auth_service.dart';
import 'package:emergencycommunication/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  String _name, _email, _password;
  int _selectedIndex = 0;

  _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: <Widget>[
          _buildEmailTF(),
          _buildPasswordTF(),
        ],
      ),
    );
  }

  _buildSignupForm() {
    return Form(
      key: _signupFormKey,
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
      child: Theme(
        data: ThemeData(
          primaryColor: Colors.white,
        ),
        child: TextFormField(
          cursorColor: Colors.white,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Montserrat',
          ),
          decoration: const InputDecoration(
            labelText: 'Name',
            labelStyle: TextStyle(
              color: Colors.white,
              fontFamily: 'Montserrat',
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          validator: (input) =>
              input.trim().isEmpty ? 'Please enter a name' : null,
          // Refactor this
          onSaved: (input) => _name = input.trim(),
        ),
      ),
    );
  }

  _buildEmailTF() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 30.0,
        vertical: 10.0,
      ),
      child: Theme(
        data: ThemeData(
          primaryColor: Colors.white,
        ),
        child: TextFormField(
          cursorColor: Colors.white,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Montserrat',
          ),
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            labelStyle: TextStyle(
              color: Colors.white,
              fontFamily: 'Montserrat',
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          validator: (input) =>
              !input.contains('@') ? 'Please enter a valid email' : null,
          // Refactor this
          onSaved: (input) => _email = input,
        ),
      ),
    );
  }

  _buildPasswordTF() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 30.0,
        vertical: 10.0,
      ),
      child: Theme(
        data: ThemeData(
          primaryColor: Colors.white,
        ),
        child: TextFormField(
          cursorColor: Colors.white,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Montserrat',
          ),
          decoration: const InputDecoration(
            labelText: 'Password',
            labelStyle: TextStyle(
              color: Colors.white,
              fontFamily: 'Montserrat',
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          validator: (input) =>
              input.length < 6 ? 'Must be at least 6 characters' : null,
          // Refactor this
          onSaved: (input) => _password = input,
          obscureText: true,
        ),
      ),
    );
  }

  Future<String> getGroupIdFromEmail(String email) async {
    String retrievedGroupId;
    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);
    List<String> groupIds = await databaseService.getAllGroupIds();
    List<String> groupAuthenticatedEmails;
    for (var groupId in groupIds) {
      groupAuthenticatedEmails =
          await databaseService.getGroupAuthenticatedEmails(groupId);
      for (var groupAuthenticatedEmail in groupAuthenticatedEmails) {
        if (email == groupAuthenticatedEmail) {
          retrievedGroupId = groupId;
        }
      }
    }
    return retrievedGroupId;
  }

  _submit() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      if (_selectedIndex == 0 && _signupFormKey.currentState.validate()) {
        _signupFormKey.currentState.save();
        Provider.of<GroupData>(context, listen: false).currentGroupId =
            await getGroupIdFromEmail(_email);

        if (Provider.of<GroupData>(context, listen: false).currentGroupId !=
            null) {
          await authService.signUp(_name, _email, _password,
              Provider.of<GroupData>(context, listen: false).currentGroupId);
        } else {
          _showErrorDialog('This email is not registered with a group.');
        }
      } else if (_selectedIndex == 1 && _loginFormKey.currentState.validate()) {
        _loginFormKey.currentState.save();

        Provider.of<GroupData>(context, listen: false).currentGroupId =
            await getGroupIdFromEmail(_email);

        if (Provider.of<GroupData>(context, listen: false).currentGroupId !=
            null) {
          await authService.logIn(_email, _password,
              Provider.of<GroupData>(context, listen: false).currentGroupId);
        } else {
          _showErrorDialog('This email is not registered with a group.');
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
        return PlatformAlertDialog(
          title: Text('Error'),
          content: Text(
            errorMessage,
          ),
          actions: <Widget>[
            PlatformDialogAction(
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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(10.0),
        child: AppBar(
          brightness: Brightness.dark,
        ),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                  ),
                  child: Text(
                    'You must be part of a group that has been registered with AppWiz to activate your account and use this application.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12.0,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(
                  height: 20.0,
                ),
                Container(
                  width: 274.0,
                  height: 80.0,
                  child: Image(
                    image: AssetImage('images/color_logo_with_background.png'),
                  ),
                ),
                SizedBox(
                  height: 20.0,
                ),
                AutoSizeText(
                  'Immedialert',
                  presetFontSizes: [32, 24, 18],
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Rounded-Elegance',
                    color: Colors.white,
                  ),
                ),
                SizedBox(
                  height: 20.0,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Container(
                      width: 150.0,
                      child: FlatButton(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            color: Colors.white,
                            fontSize: 22.0,
                            decoration: _selectedIndex == 0
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                        ),
                        onPressed: () => setState(() => _selectedIndex = 0),
                      ),
                    ),
                    Container(
                      width: 150.0,
                      child: FlatButton(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Text(
                          'Log In',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            color: Colors.white,
                            fontSize: 22.0,
                            decoration: _selectedIndex == 1
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                        ),
                        onPressed: () => setState(() => _selectedIndex = 1),
                      ),
                    ),
                  ],
                ),
                _selectedIndex == 0 ? _buildSignupForm() : _buildLoginForm(),
                const SizedBox(
                  height: 20.0,
                ),
                Container(
                  width: 180.0,
                  child: FlatButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    color: Colors.white,
                    child: Text(
                      'Submit',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                      ),
                    ),
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
