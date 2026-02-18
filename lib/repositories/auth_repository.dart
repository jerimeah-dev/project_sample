import 'dart:typed_data';

import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthRepository {
  final AuthService authService;
  final StorageService? storageService;

  AuthRepository(this.authService, [this.storageService]);

  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    // Validation
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Invalid email');
    }
    if (password.isEmpty || password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    if (displayName.isEmpty) {
      throw Exception('Display name is required');
    }

    // Check if user already exists
    final existing = await authService.getUserByEmail(email);
    if (existing.isNotEmpty) {
      throw Exception('Email already registered');
    }

    // Create user
    const uuid = Uuid();
    final userId = uuid.v4();

    final response = await authService.register(
      id: userId,
      email: email,
      password: password,
      displayName: displayName,
    );

    return UserModel.fromJson(response);
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // Validation
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }

    final response = await authService.login(email: email, password: password);

    return UserModel.fromJson(response);
  }

  Future<UserModel> getUser(String userId) async {
    final response = await authService.getUserById(userId);
    return UserModel.fromJson(response);
  }

  Future<void> changePassword({
    required String userId,
    required String newPassword,
  }) async {
    if (newPassword.isEmpty || newPassword.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    await authService.updatePassword(userId: userId, newPassword: newPassword);
  }

  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    await authService.updateProfile(
      userId: userId,
      displayName: displayName,
      bio: bio,
      avatarUrl: avatarUrl,
    );
  }

  /// Uploads avatar binary (if storageService available) and updates profile.
  Future<String?> uploadAvatarAndUpdateProfile({
    required String userId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    if (storageService == null) {
      throw Exception('StorageService not available');
    }

    final publicUrl = await storageService!.uploadAvatarImage(
      userId,
      fileBytes,
      fileName,
    );

    await authService.updateProfile(userId: userId, avatarUrl: publicUrl);

    return publicUrl;
  }
}
