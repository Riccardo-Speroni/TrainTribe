import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/utils/image_uploader.dart';
import 'package:image/image.dart' as img;

// This test simulates a web upload by providing an XFile-like path won't be used because we call the debug hook.
// We only validate that the debugUploadBytesHook receives resized bytes when kIsWeb path would be used.
// Since we can't flip kIsWeb in unit tests, we call the private resize indirectly by pretending through hook invocation on file path.
// (If needed, a platform interface abstraction could make true web path testable.)

void main() {
  group('ImageUploader fallback/bypass', () {
    test('debug hook short-circuits storage ref builder', () async {
      // Prepare square slightly larger image to trigger resize
      final original = img.Image(width: 400, height: 400);
      final bytes = img.encodeJpg(original);
      final temp = File('${Directory.systemTemp.path}/websim_${DateTime.now().microsecondsSinceEpoch}.jpg');
      await temp.writeAsBytes(bytes);
      int hookCalls = 0;
      ImageUploader.debugRefBuilder = () { fail('Should not build storage ref when hook set'); };
      ImageUploader.debugUploadBytesHook = (data, {required bool web}) async {
        hookCalls++;
        final decoded = img.decodeJpg(Uint8List.fromList(data));
        expect(decoded, isNotNull);
        expect(decoded!.width <= 300 && decoded.height <= 300, isTrue);
        return 'mock://url';
      };
      final url = await ImageUploader.uploadProfileImage(file: temp);
      expect(url, 'mock://url');
      expect(hookCalls, 1);
      ImageUploader.debugUploadBytesHook = null;
      ImageUploader.debugRefBuilder = null;
    });
  });
}
