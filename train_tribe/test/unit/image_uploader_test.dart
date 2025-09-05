import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/utils/image_uploader.dart';

void main() {
  group('ImageUploader.uploadProfileImage', () {
    test('returns null when both inputs null', () async {
      final url = await ImageUploader.uploadProfileImage();
      expect(url, isNull);
    });

    test('returns null when file does not exist', () async {
      final f = File('non_existent_${DateTime.now().microsecondsSinceEpoch}.jpg');
      final url = await ImageUploader.uploadProfileImage(file: f);
      expect(url, isNull);
    });

    test('returns null when image cannot be decoded', () async {
      final temp = File('${Directory.systemTemp.path}/invalid_${DateTime.now().microsecondsSinceEpoch}.bin');
      await temp.writeAsBytes(List<int>.generate(32, (i) => i)); // not a valid image
      final url = await ImageUploader.uploadProfileImage(file: temp);
      expect(url, isNull);
      if (await temp.exists()) await temp.delete();
    });
  });
}
