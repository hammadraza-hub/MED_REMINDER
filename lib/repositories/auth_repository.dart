import 'package:firebase_auth/firebase_auth.dart';

import '../core/app_exception.dart';

/// ============================================================
/// AUTH REPOSITORY
/// ============================================================
/// Wraps firebase_auth with consistent error handling.
///
/// All methods throw [AppException] on failure — never raw
/// FirebaseAuthException. This keeps screens / business logic
/// free of Firebase-specific error codes.
///
/// Usage:
///   final user = await AuthRepository.instance.signInWithEmailPassword(
///     email: '...',
///     password: '...',
///   );
/// ============================================================
class AuthRepository {
  // Singleton — single source of truth for auth state across the app.
  static final AuthRepository instance = AuthRepository._();
  AuthRepository._();

  // Internal FirebaseAuth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ───────────────────────────────────────────────────────────
  // Current User & State
  // ───────────────────────────────────────────────────────────

  /// The current authenticated user, or null if not signed in.
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes.
  /// Emits null when user signs out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Stream of user changes (display name, photo URL, email verified, etc.)
  Stream<User?> get userChanges => _auth.userChanges();

  /// Whether a user is currently signed in.
  bool get isSignedIn => _auth.currentUser != null;

  /// The current user's UID, or null if not signed in.
  String? get currentUid => _auth.currentUser?.uid;

  /// The current user's email, or null if not signed in.
  String? get currentEmail => _auth.currentUser?.email;

  // ───────────────────────────────────────────────────────────
  // Email / Password Auth
  // ───────────────────────────────────────────────────────────

  /// Creates a new user account with email and password.
  ///
  /// On success, the user is automatically signed in.
  /// Throws [AppException] with type=validation for:
  ///   - invalid-email
  ///   - weak-password
  ///   - email-already-in-use
  Future<User> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw AppException.fromAuthException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.unknown(e.toString(), originalError: e);
    }
  }

  /// Signs in an existing user with email and password.
  ///
  /// Throws [AppException] with type=validation for:
  ///   - wrong-password
  ///   - user-not-found
  ///   - user-disabled
  ///   - invalid-credential
  Future<User> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw AppException.fromAuthException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.unknown(e.toString(), originalError: e);
    }
  }

  // ───────────────────────────────────────────────────────────
  // Sign Out
  // ───────────────────────────────────────────────────────────

  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AppException.unknown(e.toString(), originalError: e);
    }
  }

  // ───────────────────────────────────────────────────────────
  // Password Reset
  // ───────────────────────────────────────────────────────────

  /// Sends a password reset email to the given address.
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AppException.fromAuthException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.unknown(e.toString(), originalError: e);
    }
  }

  // ───────────────────────────────────────────────────────────
  // Profile Updates
  // ───────────────────────────────────────────────────────────

  /// Updates the current user's display name.
  Future<void> updateDisplayName({required String displayName}) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
    } on FirebaseAuthException catch (e) {
      throw AppException.fromAuthException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.unknown(e.toString(), originalError: e);
    }
  }

  /// Updates the current user's email address.
  ///
  /// Note: firebase_auth v7.0.0+ deprecated `updateEmail` in favor of
  /// `verifyBeforeUpdateEmail` — this sends a verification email to the
  /// new address before actually updating it (more secure, prevents typos).
  ///
  /// User must click the verification link in the email before the
  /// email is actually changed.
  Future<void> updateEmail({required String newEmail}) async {
    try {
      await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      throw AppException.fromAuthException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.unknown(e.toString(), originalError: e);
    }
  }

  /// Updates the current user's password.
  /// Note: May require recent login (reauthenticate first).
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AppException.fromAuthException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.unknown(e.toString(), originalError: e);
    }
  }

  // ───────────────────────────────────────────────────────────
  // Account Deletion
  // ───────────────────────────────────────────────────────────

  /// Deletes the current user's account.
  /// Note: For sensitive operations, Firebase may require recent login.
  /// Use reauthenticateWithEmailPassword() first if needed.
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw AppException.fromAuthException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.unknown(e.toString(), originalError: e);
    }
  }

  // ───────────────────────────────────────────────────────────
  // Re-authentication (for sensitive operations)
  // ───────────────────────────────────────────────────────────

  /// Re-authenticates the current user with email + password.
  /// Required before sensitive operations (delete, password change,
  /// email change) if user hasn't signed in recently.
  Future<void> reauthenticateWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await _auth.currentUser?.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AppException.fromAuthException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.unknown(e.toString(), originalError: e);
    }
  }

  // ───────────────────────────────────────────────────────────
  // Email Verification
  // ───────────────────────────────────────────────────────────

  /// Sends a verification email to the current user.
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AppException.fromAuthException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.unknown(e.toString(), originalError: e);
    }
  }

  /// Whether the current user's email is verified.
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Reloads the current user's profile (refreshes emailVerified, etc.)
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } on FirebaseAuthException catch (e) {
      throw AppException.fromAuthException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.unknown(e.toString(), originalError: e);
    }
  }
}
