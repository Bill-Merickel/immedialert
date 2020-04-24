import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emergencycommunication/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:emergencycommunication/models/group_data.dart';
import 'package:emergencycommunication/utilities/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging();

  Stream<FirebaseUser> get user => _auth.onAuthStateChanged;

  Future<void> logIn(
      String name, String email, String password, String groupId) async {
    try {
      AuthResult authResult = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (authResult.user != null) {
        String token = await _messaging.getToken();

        groupsRef
            .document(groupId)
            .collection('users')
            .document(authResult.user.uid)
            .setData({
          'name': name,
          'email': email,
          'token': token,
        });
      }
    } on PlatformException catch (err) {
      throw (err);
    }
  }

  Future<void> logOut(String groupId) async {
    await removeToken(groupId);
    Future.wait([
      _auth.signOut(),
    ]);
  }

  Future<void> removeToken(String groupId) async {
    final currentUser = await _auth.currentUser();
    await groupsRef
        .document(groupId)
        .collection('users')
        .document(currentUser.uid)
        .setData({'token': ''}, merge: true);
  }

  Future<void> updateToken(String groupId) async {
    final currentUser = await _auth.currentUser();
    final token = await _messaging.getToken();
    final userDoc = await groupsRef
        .document(groupId)
        .collection('users')
        .document(currentUser.uid)
        .get();
    if (userDoc.exists) {
      User user = User.fromDoc(userDoc);
      if (token != user.token) {
        groupsRef
            .document(groupId)
            .collection('users')
            .document(currentUser.uid)
            .setData({'token': token}, merge: true);
      }
    }
  }
}
