import 'package:train_tribe/repositories/user_repository.dart';

class FakeUserRepository implements IUserRepository {
  bool nextIsUnique = true;
  Map<String, Map<String, dynamic>> saved = {};
  bool throwOnSave = false;

  @override
  Future<bool> isUsernameUnique(String username) async => nextIsUnique;

  @override
  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    if (throwOnSave) {
      throw Exception('save error');
    }
    saved[uid] = Map<String, dynamic>.from(data);
  }
}
