import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:train_tribe/utils/image_uploader.dart';

void main() {
	group('ImageUploader.uploadProfileImage', () {
		setUp(() {
			// Reset hooks before each test
			ImageUploader.debugRefBuilder = null;
			ImageUploader.debugUploadBytesHook = null;
		});

		test('returns null when both xfile and file are null', () async {
			final result = await ImageUploader.uploadProfileImage();
			expect(result, isNull);
		});

		test('resizes large image and uses debugUploadBytesHook returning URL', () async {
			// Create a large dummy image 800x400 (solid content not required for resize assertion)
			final original = img.Image(width: 800, height: 400);
			final jpg = img.encodeJpg(original, quality: 95);
			final tempFile = File('${Directory.systemTemp.path}/test_upload_${DateTime.now().microsecondsSinceEpoch}.jpg');
			await tempFile.writeAsBytes(jpg);

			late List<int> receivedBytes;
			ImageUploader.debugUploadBytesHook = (bytes, {required bool web}) async {
				receivedBytes = bytes;
				return 'mock://uploaded/profile.jpg';
			};

			final url = await ImageUploader.uploadProfileImage(file: tempFile);
			expect(url, 'mock://uploaded/profile.jpg');

			final decoded = img.decodeJpg(Uint8List.fromList(receivedBytes));
			expect(decoded, isNotNull);
			final d = decoded!;
			expect(d.width <= 300 || d.height <= 300, isTrue, reason: 'Image should be resized so longest side <= 300');
			expect(d.width <= 300, isTrue);
			expect(d.height <= 300, isTrue);

			if (await tempFile.exists()) {
				await tempFile.delete();
			}
		});

		test('returns null for non-existent file path', () async {
			final bogus = File('${Directory.systemTemp.path}/does_not_exist_${DateTime.now().microsecondsSinceEpoch}.jpg');
			final r = await ImageUploader.uploadProfileImage(file: bogus);
			expect(r, isNull);
		});
	});
}

