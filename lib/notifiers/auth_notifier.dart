import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthNotifier extends ChangeNotifier {
  final AuthRepository _authRepository;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthNotifier(this._authRepository);

  /// Initialize by checking Supabase session and loading the user if present.
  Future<void> initialize() async {
    // Initialization step left intentionally minimal: session handling
    // is managed by the repository layer (custom auth). If you have
    // a cached user id, call `loadUser(cachedId)` here.
  }

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authRepository.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      _currentUser = user;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authRepository.login(
        email: email,
        password: password,
      );
      _currentUser = user;

      // Save session locally (basic implementation)
      // Session persistence is handled by repository / app storage.
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authRepository.getUser(userId);
      _currentUser = user;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  Future<void> changePassword(String newPassword) async {
    if (_currentUser == null) throw Exception('No user logged in');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.changePassword(
        userId: _currentUser!.id,
        newPassword: newPassword,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    Uint8List? avatarBytes,
    String? avatarFileName,
  }) async {
    if (_currentUser == null) throw Exception('No user logged in');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? newAvatarUrl = avatarUrl;

      if (avatarBytes != null && avatarFileName != null) {
        newAvatarUrl = await _authRepository.uploadAvatarAndUpdateProfile(
          userId: _currentUser!.id,
          fileBytes: avatarBytes,
          fileName: avatarFileName,
        );
      }

      // If avatar wasn't uploaded, update profile fields normally
      await _authRepository.updateProfile(
        userId: _currentUser!.id,
        displayName: displayName,
        bio: bio,
        avatarUrl: newAvatarUrl,
      );

      // Update current user
      _currentUser = _currentUser!.copyWith(
        displayName: displayName ?? _currentUser!.displayName,
        bio: bio ?? _currentUser!.bio,
        avatarUrl: newAvatarUrl ?? _currentUser!.avatarUrl,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
