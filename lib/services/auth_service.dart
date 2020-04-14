import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:emergencycommunication/utilities/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging();

  Stream<FirebaseUser> get user => _auth.onAuthStateChanged;

  Future<void> signUp(String name, String email, String password) async {
    try {
      AuthResult authResult = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (authResult.user != null) {
        String token = await _messaging.getToken();
        usersRef.document(authResult.user.uid).setData({
          'name': name,
          'email': email,
          'token': token,
        });
      }
    } on PlatformException catch (err) {
      throw (err);
    }
  }

  Future<void> logIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on PlatformException catch (err) {
      throw (err);
    }
  }

  Future<void> logOut() {
    Future.wait([
      _auth.signOut(),
    ]);
  }
}
