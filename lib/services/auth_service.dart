import 'dart:async';
import '../models/user.dart';
import '../models/local_auth_user.dart';
import '../constants/app_constants.dart';
import '../extensions/string_extensions.dart'; // ✅ 追加
import 'password_hasher.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storageService;
  User? _currentUser;
  
  AuthService(this._storageService);
  
  User? get currentUser => _currentUser ?? _storageService.currentUser;
  
  Future<void> initialize() async {
    _currentUser = _storageService.currentUser;
  }
  
  Future<User> signup(
    String email,
    String firstName,
    String lastName,
    String nickname,
    String password,
    String confirmPassword,
  ) async {
    // ✅ String拡張メソッドを使用したバリデーション
    if (email.isBlank || firstName.isBlank || password.isBlank || confirmPassword.isBlank) {
      throw Exception(AppConstants.validationRequired);
    }
    
    if (password != confirmPassword) {
      throw Exception(AppConstants.validationPasswordMismatch);
    }
    
    if (password.length < AppConstants.passwordMinLength) {
      throw Exception(AppConstants.validationPasswordShort);
    }
    
    if (password.length > AppConstants.passwordMaxLength) {
      throw Exception(AppConstants.validationMaxLength);
    }
    
    // ✅ String拡張メソッドを使用したメールバリデーション
    if (!email.isValidEmail) {
      throw Exception(AppConstants.validationEmailInvalid);
    }
    
    final existingUser = _storageService.authUsers.any(
      (u) => u.email == email,
    );
    
    if (existingUser) {
      throw Exception('このメールアドレスは既に登録されています');
    }
    
    final salt = PasswordHasher.generateSalt();
    final passwordHash = PasswordHasher.hashPassword(password, salt);
    
    final userId = email;
    final now = DateTime.now();
    
    final authUser = LocalAuthUser(
      email: email,
      username: nickname.isNotBlank ? nickname : '$firstName $lastName',
      passwordHash: passwordHash,
      salt: salt,
      userId: userId,
      createdAt: now,
    );
    
    final user = User(
      id: userId,
      password: passwordHash,
      firstName: firstName,
      lastName: lastName,
      nickname: nickname,
      createdAt: now,
    );
    
    _storageService.authUsers.add(authUser);
    _storageService.users.add(user);
    _storageService.currentUser = user;
    _currentUser = user;
    
    await _storageService.save();
    
    return user;
  }
  
  Future<User> login(String email, String password) async {
    // ✅ String拡張メソッドを使用
    if (email.isBlank || password.isBlank) {
      throw Exception('メールアドレスとパスワードを入力してください');
    }
    
    final authUser = _storageService.authUsers.firstWhere(
      (u) => u.email == email,
      orElse: () => LocalAuthUser(
        email: '',
        username: '',
        passwordHash: '',
        salt: '',
        userId: '',
        createdAt: DateTime.now(),
      ),
    );
    
    // ✅ String拡張メソッドを使用
    if (authUser.email.isBlank) {
      throw Exception('メールアドレスまたはパスワードが正しくありません');
    }
    
    final isValid = PasswordHasher.verifyPassword(
      password,
      authUser.passwordHash,
      authUser.salt,
    );
    
    if (!isValid) {
      throw Exception('メールアドレスまたはパスワードが正しくありません');
    }
    
    final user = _storageService.users.firstWhere(
      (u) => u.id == email,
      orElse: () => User(
        id: email,
        firstName: 'Unknown',
        lastName: 'User',
        nickname: authUser.username,
      ),
    );
    
    _storageService.currentUser = user;
    _currentUser = user;
    
    await _storageService.save();
    
    return user;
  }
  
  Future<void> logout() async {
    _storageService.currentUser = null;
    _currentUser = null;
    await _storageService.save();
  }
  
  bool isLoggedIn() {
    return currentUser != null;
  }
}