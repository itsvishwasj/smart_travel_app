import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // --- Registration Logic ---
  Future<User?> registerWithEmail(String name, String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 1. Collect user's name
      await userCredential.user?.updateDisplayName(name);

      // 2. Send email verification (OTP equivalent for new user)
      await userCredential.user?.sendEmailVerification();
      
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Return the error message to the UI
      return Future.error(e.message ?? 'An unknown error occurred during registration.');
    } catch (e) {
      return Future.error('Registration failed: $e');
    }
  }

  // --- Login Logic ---
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      return Future.error(e.message ?? 'An unknown error occurred during sign in.');
    } catch (e) {
      return Future.error('Sign in failed: $e');
    }
  }

  // --- Forgot Password Logic ---
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // This sends the reset link to the user's email (acts as OTP)
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      return Future.error(e.message ?? 'Failed to send password reset email.');
    } catch (e) {
      return Future.error('An unexpected error occurred: $e');
    }
  }

  // --- Sign Out Logic ---
  Future<void> signOut() async {
    await _auth.signOut();
  }
}