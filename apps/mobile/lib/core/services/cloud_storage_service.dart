import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cloud_storage_service.g.dart';

class CloudStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Compress an image and upload to Firebase Storage, returning the URL and file size bytes.
  Future<(String, int)?> compressAndUploadImage({
    required String uid,
    required String imagePath,
    required String diaryId,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      // Generate a unique filename based on timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = '${tempDir.path}/compress_${timestamp}.jpg';

      // Compress
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        quality: 80,
        minWidth: 1080,
        minHeight: 1080,
        format: CompressFormat.jpeg,
      );

      if (compressedFile == null) return null;

      final fileBytes = await compressedFile.length();
      final file = File(compressedFile.path);

      // Upload to Storage
      final ref = _storage.ref().child('users/$uid/diaries/$diaryId/$timestamp.jpg');
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Clean up temp file
      if (await file.exists()) {
        await file.delete();
      }

      return (downloadUrl, fileBytes);
    } catch (e) {
      print('Cloud storage upload error: $e');
      return null;
    }
  }

  /// Delete folder/files for a diary
  Future<void> deleteDiaryImages(String uid, String diaryId) async {
    try {
      final ref = _storage.ref().child('users/$uid/diaries/$diaryId');
      final listResult = await ref.listAll();
      for (var item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      print('Cloud storage delete error: $e');
    }
  }
}

@riverpod
CloudStorageService cloudStorageService(CloudStorageServiceRef ref) {
  return CloudStorageService();
}
