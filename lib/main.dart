import 'package:awesome_loader/awesome_loader.dart';
import 'package:emergencycommunication/models/group_data.dart';
import 'package:emergencycommunication/models/user_data.dart';
import 'package:emergencycommunication/screens/home_screen.dart';
import 'package:emergencycommunication/screens/login_screen.dart';
import 'package:emergencycommunication/services/auth_service.dart';
import 'package:emergencycommunication/services/database_service.dart';
import 'package:emergencycommunication/services/storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Main method that executes the app
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserData(),
        ),
        ChangeNotifierProvider(
          create: (_) => GroupData(),
        ),
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<DatabaseService>(
          create: (_) => DatabaseService(),
        ),
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

// This class is the root of the application
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Immedialert',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.black,
        accentColor: Colors.white,
      ),
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<FirebaseUser>(
        stream: Provider.of<AuthService>(context, listen: false).user,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            // If there isn't a user currently logged in, go to the login screen
            if (snapshot.data == null) {
              return LoginScreen();
            }
            // Otherwise, save the id of the user and go to the home screen
            Provider.of<UserData>(context, listen: false).currentUserId =
                snapshot.data.uid;
            return HomeScreen();
          } else {
            // If the connection state isn't active, display a loading animation
            return Center(
              child: AwesomeLoader(
                loaderType: AwesomeLoader.AwesomeLoader4,
                color: Theme.of(context).accentColor,
              ),
            );
          }
        },
      ),
    );
  }
}
