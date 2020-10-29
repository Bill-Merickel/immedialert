import 'package:auto_size_text/auto_size_text.dart';
import 'package:email_validator/email_validator.dart';
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
  // GlobalKeys for the login and signup form
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // Strings that hold the name, email, and password values
  String _name, _email, _password;

  // Index = 0 if signup is selected, 1 if login is selected
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

  _buildTF(String name, FormFieldValidator validator, bool obscureText) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 30.0,
        vertical: 10.0,
      ),
      child: Theme(
        data: ThemeData(
          primaryColor: Theme.of(context).accentColor,
        ),
        child: TextFormField(
          cursorColor: Theme.of(context).accentColor,
          style: TextStyle(
            color: Theme.of(context).accentColor,
            fontFamily: 'Montserrat',
          ),
          decoration: InputDecoration(
            labelText: name,
            labelStyle: TextStyle(
              color: Theme.of(context).accentColor,
              fontFamily: 'Montserrat',
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).accentColor),
            ),
          ),
          validator: validator,
          // Refactor this
          onSaved: (input) {
            if (name == "Name") {
              _name = input.trim();
            } else if (name == "Email") {
              _email = input;
            } else if (name == "Password") {
              _password = input;
            }
          },
          obscureText: obscureText,
        ),
      ),
    );
  }

  _buildNameTF() {
    return _buildTF(
      "Name",
      (input) => input.trim().isEmpty ? 'Please enter a name' : null,
      false,
    );
  }

  _buildEmailTF() {
    return _buildTF(
      "Email",
      (input) =>
          EmailValidator.validate(input) ? null : 'Please enter a valid email',
      false,
    );
  }

  _buildPasswordTF() {
    return _buildTF(
      "Password",
      (input) => input.length < 6 ? 'Must be at least 6 characters' : null,
      true,
    );
  }

  _submit() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);
    try {
      if (_selectedIndex == 0 && _signupFormKey.currentState.validate()) {
        _signupFormKey.currentState.save();
        Provider.of<GroupData>(context, listen: false).currentGroupId =
            await databaseService.getGroupIdFromEmail(_email);

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
            await databaseService.getGroupIdFromEmail(_email);

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
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.0,
                  ),
                  child: Text(
                    'You must be part of a group that has been registered with AppWiz to activate your account and use this application.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12.0,
                      color: Theme.of(context).accentColor,
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
                    color: Theme.of(context).accentColor,
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
                            color: Theme.of(context).accentColor,
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
                            color: Theme.of(context).accentColor,
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
                SizedBox(
                  height: 20.0,
                ),
                Container(
                  width: 180.0,
                  child: FlatButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    color: Theme.of(context).accentColor,
                    child: Text(
                      'Submit',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: Theme.of(context).primaryColor,
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
