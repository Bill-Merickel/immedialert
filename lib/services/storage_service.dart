import 'dart:io';
import 'package:emergencycommunication/utilities/constants.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  Future<File> _compressImage(String imageId, File image) async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    File compressedImageFile = await FlutterImageCompress.compressAndGetFile(
      image.absolute.path,
      '$path/img_$imageId.jpg',
      quality: 70,
    );
    return compressedImageFile;
  }

  Future<String> _uploadImage(String path, String imageId, File image) async {
    StorageUploadTask uploadTask = storageRef.child(path).putFile(image);
    StorageTaskSnapshot storageSnap = await uploadTask.onComplete;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<String> uploadMessageImage(File imageFile, String groupId) async {
    String imageId = Uuid().v4();
    File image = await _compressImage(imageId, imageFile);
    String downloadUrl = await _uploadImage(
      '$groupId/images/messages/message_$imageId.jpg',
      imageId,
      image,
    );
    return downloadUrl;
  }
}
