import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/utils/image_uploader.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

Uint8List? capturedBytes;

void main() {
  group('ImageUploader success path', () {
    test('uploads resized image and returns URL', () async {
      final imgObj = img.Image(width: 800, height: 200); // wide image triggers resize width=300
      final bytes = img.encodeJpg(imgObj);
      final temp = File('${Directory.systemTemp.path}/valid_${DateTime.now().microsecondsSinceEpoch}.jpg');
      await temp.writeAsBytes(bytes);
      ImageUploader.debugUploadBytesHook = (b, {required bool web}) async {
        capturedBytes = Uint8List.fromList(b);
        return 'https://example.com/fake.jpg';
      };
      final url = await ImageUploader.uploadProfileImage(file: temp);
      expect(url, 'https://example.com/fake.jpg');
      expect(capturedBytes, isNotEmpty);
      // Ensure resized dimension <=300
  final decoded = img.decodeJpg(capturedBytes!);
  expect(decoded, isNotNull);
  expect(decoded!.width <= 300 && decoded.height <= 300, isTrue);
      ImageUploader.debugUploadBytesHook = null;
    });
  });
}
