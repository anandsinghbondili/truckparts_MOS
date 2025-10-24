import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/user.dart';
import '../models/auth_tokens_model.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens(AuthTokens tokens);
  Future<AuthTokens?> getTokens();
  Future<void> clearTokens();
  Future<void> saveUser(User user);
  Future<User?> getUser();
  Future<void> clearUser();
  Future<bool> isAuthenticated();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;
  final FlutterSecureStorage secureStorage;

  AuthLocalDataSourceImpl({
    required this.sharedPreferences,
    required this.secureStorage,
  });

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    final tokensModel = AuthTokensModel.fromEntity(tokens);
    final tokensJson = jsonEncode(tokensModel.toJson());
    await secureStorage.write(key: AppConstants.tokenKey, value: tokensJson);
  }

  @override
  Future<AuthTokens?> getTokens() async {
    try {
      final tokensJson = await secureStorage.read(key: AppConstants.tokenKey);
      if (tokensJson != null) {
        final tokensMap = jsonDecode(tokensJson) as Map<String, dynamic>;
        return AuthTokensModel.fromJson(tokensMap).toEntity();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearTokens() async {
    await secureStorage.delete(key: AppConstants.tokenKey);
    await secureStorage.delete(key: AppConstants.refreshTokenKey);
  }

  @override
  Future<void> saveUser(User user) async {
    final userModel = UserModel.fromEntity(user);
    final userJson = jsonEncode(userModel.toJson());
    await sharedPreferences.setString(AppConstants.userKey, userJson);
  }

  @override
  Future<User?> getUser() async {
    try {
      final userJson = sharedPreferences.getString(AppConstants.userKey);
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return UserModel.fromJson(userMap).toEntity();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearUser() async {
    await sharedPreferences.remove(AppConstants.userKey);
  }

  @override
  Future<bool> isAuthenticated() async {
    final tokens = await getTokens();
    return tokens != null;
  }
}
