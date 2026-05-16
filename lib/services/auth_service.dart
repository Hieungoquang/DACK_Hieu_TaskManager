import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import '../models/user_model.dart' as model;
import 'local_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern cho GoogleSignIn để tránh lỗi "Future already completed"
  static GoogleSignIn? _googleSignInInstance;
  GoogleSignIn get _googleSignIn {
    _googleSignInInstance ??= GoogleSignIn(
      clientId:
          '392134374842-roeo3k4h05r27k45uqpqth46lht6ieu9.apps.googleusercontent.com',
    );
    return _googleSignInInstance!;
  }

  Future<String?> forgotPassword(String email) async {
    try {
      await _auth
          .sendPasswordResetEmail(email: email)
          .timeout(const Duration(seconds: 15));
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found')
        return "Email không tồn tại trong hệ thống";
      return e.message;
    } on TimeoutException {
      return "Yêu cầu quá hạn. Vui lòng kiểm tra kết nối mạng.";
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    try {
      // 1. Tạo tài khoản Auth với timeout
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));

      if (userCredential.user != null) {
        // 2. Lưu vào Firestore với timeout nhanh hơn
        try {
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'email': email,
            'full_name': fullName ?? "",
            'username': email.split('@')[0],
            'phone_number': phone ?? "",
            'uid': userCredential.user!.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          }).timeout(const Duration(seconds: 10));
        } catch (e) {
          debugPrint("Lỗi Firestore (bỏ qua để tiếp tục): $e");
        }
      }

      await _setLoginStatus(true);
      return null;
    } on TimeoutException {
      return "Yêu cầu quá hạn. Vui lòng kiểm tra Internet.";
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return "Email này đã được sử dụng bởi tài khoản khác.";
        case 'invalid-email':
          return "Định dạng email không hợp lệ.";
        case 'weak-password':
          return "Mật khẩu quá yếu (tối thiểu 6 ký tự).";
        case 'network-request-failed':
          return "Lỗi kết nối mạng, vui lòng kiểm tra Internet.";
        default:
          return e.message ?? "Lỗi đăng ký không xác định.";
      }
    } catch (e) {
      return "Đã xảy ra lỗi: ${e.toString()}";
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 20));
      await _setLoginStatus(true);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        return "Tài khoản hoặc mật khẩu không đúng";
      }
      return "Lỗi đăng nhập: ${e.message}";
    } catch (e) {
      return "Đã xảy ra lỗi không xác định";
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return "Đã hủy đăng nhập";

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 20));
      User? user = userCredential.user;

      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email,
            'full_name': user.displayName ?? "",
            'username': user.email?.split('@')[0] ?? "user",
            'profile_picture': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      }
      await _setLoginStatus(true);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> _setLoginStatus(bool status) async {
    final box = await Hive.openBox('settingsBox');
    await box.put('isLoggedIn', status);
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await LocalService.clearAll();
    await _auth.signOut();
    await _setLoginStatus(false);
  }

  Future<String?> uploadAvatar(File imageFile) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return "Chưa đăng nhập";

      final storageRef = FirebaseStorage.instance.ref().child(
            'avatars/${user.uid}.jpg',
          );
      await storageRef.putFile(imageFile);
      String downloadUrl = await storageRef.getDownloadURL();

      await user.updatePhotoURL(downloadUrl);
      await _firestore.collection('users').doc(user.uid).update({
        'avatar_url': downloadUrl,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update local Hive
      final userBox = await Hive.openBox<model.User>('userBox');
      final localUser = userBox.get(user.uid);
      if (localUser != null) {
        localUser.avatar_url = downloadUrl;
        localUser.updated_at = DateTime.now();
        await localUser.save();
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateProfile({
    required String fullName,
    required String username,
    required String phoneNumber,
    required String email,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return "Chưa đăng nhập";

      // Email update is disabled as per user request

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'full_name': fullName,
        'username': username,
        'phone_number': phoneNumber,
        'email': email,
        'updated_at': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));

      // Update local Hive
      final userBox = await Hive.openBox<model.User>('userBox');
      final localUser = userBox.get(user.uid);
      if (localUser != null) {
        localUser.full_name = fullName;
        localUser.username = username;
        localUser.phone_number = phoneNumber;
        localUser.email = email;
        localUser.updated_at = DateTime.now();
        await localUser.save();
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
