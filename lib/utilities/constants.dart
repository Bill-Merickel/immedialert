import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

// Instance of Firestore
final Firestore _db = Firestore.instance;

// Reference of the 'groups' Firestore collection
final groupsRef = _db.collection('groups');

// Instance of FirebaseStorage
final FirebaseStorage _storage = FirebaseStorage.instance;

// Reference to the FirebaseStorage instance
final storageRef = _storage.ref();

// Format of the time that messages are sent
final DateFormat timeFormat = DateFormat('E, h:mm a');
