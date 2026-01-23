import 'dart:async';
import '../models/user.dart';
import '../models/local_auth_user.dart';
import '../constants/app_constants.dart';
import '../extensions/string_extensions.dart';
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
    if (email.isBlank ||
        firstName.isBlank ||
        password.isBlank ||
        confirmPassword.isBlank) {
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

    // 🔥 ここで deletedAt をチェック
    final user = _storageService.users.firstWhere(
      (u) => u.id == email,
      orElse: () => throw Exception('ユーザー情報が存在しません'),
    );

    if (user.deletedAt != null) {
      throw Exception('このアカウントは削除されています');
    }

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

  Future<void> deleteAccount(String email) async {
    final now = DateTime.now();

    final index = _storageService.users.indexWhere((u) => u.id == email);
    if (index == -1) {
      throw Exception('ユーザーが存在しません');
    }

    final user = _storageService.users[index];

    // 🔥 すでに削除されていたら弾く
    if (user.deletedAt != null) {
      throw Exception('このアカウントは既に削除されています');
    }

    _storageService.users[index] = User(
      id: user.id,
      password: user.password,
      firstName: user.firstName,
      lastName: user.lastName,
      nickname: user.nickname,
      phoneNumber: user.phoneNumber,
      rate: user.rate,
      premium: user.premium,
      roomCount: user.roomCount,
      createdAt: user.createdAt,
      lastUpdatedPremium: user.lastUpdatedPremium,
      deletedAt: now,
    );

    _storageService.currentUser = null;
    _currentUser = null;

    await _storageService.save();
  }
}
