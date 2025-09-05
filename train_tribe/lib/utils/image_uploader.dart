import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

/// Provides static helpers to resize and upload profile images to Firebase Storage.
class ImageUploader {
  /// Test hook to inject a custom storage reference (e.g., mock or fake implementation).
  static Reference Function()? debugRefBuilder;
  /// Test hook to bypass Firebase completely: receives the finalized JPEG bytes and returns a URL.
  static Future<String?> Function(List<int> bytes, {required bool web})? debugUploadBytesHook;
  /// Resize (max 300px on longest side) and upload an XFile or File.
  /// Returns the download URL or null on failure.
  static Future<String?> uploadProfileImage({XFile? xfile, File? file}) async {
    try {
      if (xfile == null && file == null) return null;
      if (kIsWeb && xfile != null) {
        final bytes = await xfile.readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded == null) return null;
        final resized = _resize(decoded);
        final data = img.encodeJpg(resized, quality: 85);
        if (debugUploadBytesHook != null) {
          return await debugUploadBytesHook!(data, web: true);
        }
        final ref = _ref();
        final task = await ref.putData(data, SettableMetadata(contentType: 'image/jpeg'));
        return await task.ref.getDownloadURL();
      }
      final f = file ?? File(xfile!.path);
      if (!await f.exists()) return null;
      final original = await f.readAsBytes();
      final decoded = img.decodeImage(original);
      if (decoded == null) return null;
      final resized = _resize(decoded);
      final jpg = img.encodeJpg(resized, quality: 85);
      final tmp = File('${Directory.systemTemp.path}/pp_${DateTime.now().microsecondsSinceEpoch}.jpg');
      await tmp.writeAsBytes(jpg);
      try {
        if (debugUploadBytesHook != null) {
          return await debugUploadBytesHook!(jpg, web: false);
        }
        final ref = debugRefBuilder != null ? debugRefBuilder!() : _ref();
        final task = await ref.putFile(tmp, SettableMetadata(contentType: 'image/jpeg'));
        return await task.ref.getDownloadURL();
      } finally {
        if (await tmp.exists()) { try { await tmp.delete(); } catch (_) {} }
      }
    } catch (e) {
      // ignore or log
      return null;
    }
  }

  static img.Image _resize(img.Image input) {
    const int target = 300;
    if (input.width <= target && input.height <= target) return input;
    return img.copyResize(input, width: input.width >= input.height ? target : null, height: input.height > input.width ? target : null);
  }

  static Reference _ref() => FirebaseStorage.instance.ref().child('profile_pictures/${DateTime.now().millisecondsSinceEpoch}.jpg');
}
