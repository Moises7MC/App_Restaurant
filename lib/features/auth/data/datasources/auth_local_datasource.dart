import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'dart:convert';
import '../../../../services/api_service.dart';

abstract class AuthLocalDataSource {
  Future<UserModel> login(String username, String password);
  Future<void> logout();
  Future<UserModel?> getCachedUser();
  Future<void> cacheUser(UserModel user);
  Future<String?> getWaiterFullName();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String cachedUserKey = 'CACHED_USER';
  static const String waiterNameKey = 'WAITER_FULL_NAME';

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<UserModel> login(String username, String password) async {
    final waiterData = await ApiService.loginWaiter(username, password);

    final fullName = '${waiterData['firstName']} ${waiterData['lastName']}'
        .trim();

    final user = UserModel(
      id: waiterData['id'].toString(),
      email: username,
      name: fullName,
      photoUrl: null,
      username: waiterData['username'],
      firstName: waiterData['firstName'],
      lastName: waiterData['lastName'],
      gender: waiterData['gender'],
    );

    await cacheUser(user);
    await sharedPreferences.setString(waiterNameKey, fullName);
    return user;
  }

  @override
  Future<void> logout() async {
    await sharedPreferences.remove(cachedUserKey);
    await sharedPreferences.remove(waiterNameKey);
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final jsonString = sharedPreferences.getString(cachedUserKey);
    if (jsonString != null) {
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return UserModel.fromJson(jsonMap);
    }
    return null;
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    final jsonString = json.encode(user.toJson());
    await sharedPreferences.setString(cachedUserKey, jsonString);
  }

  @override
  Future<String?> getWaiterFullName() async {
    return sharedPreferences.getString(waiterNameKey);
  }
}
