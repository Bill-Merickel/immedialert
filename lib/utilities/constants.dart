import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

final Firestore _db = Firestore.instance;
final groupsRef = _db.collection('groups');

final FirebaseStorage _storage = FirebaseStorage.instance;
final storageRef = _storage.ref();

final DateFormat timeFormat = DateFormat('E, h:mm a');
