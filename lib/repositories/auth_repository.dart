import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/app_exception.dart';

/// Result of a Google sign-in attempt.
class GoogleSignInResult {
  final User user;
  final bool isNewUser;
  GoogleSignInResult({required this.user, required this.isNewUser});
}

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _googleSignIn;

  static AuthRepository? _instance;
  static AuthRepository get instance => _instance ??= AuthRepository._(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );

  AuthRepository._(this._auth, this._db, [GoogleSignIn? googleSignIn])
    : _googleSignIn = googleSignIn ?? GoogleSignIn();

  AuthRepository(this._auth, this._db, [GoogleSignIn? googleSignIn])
    : _googleSignIn = googleSignIn ?? GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  String? get currentUid => _auth.currentUser?.uid;
  String? get currentEmail => _auth.currentUser?.email;
  String? get currentDisplayName => _auth.currentUser?.displayName;
  String? get currentPhotoURL => _auth.currentUser?.photoURL;

  Future<User> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      final name = displayName?.trim() ?? '';
      if (name.isNotEmpty) {
        await user.updateDisplayName(name);
      }
      await _createUserDocument(
        uid: user.uid,
        email: user.email!,
        displayName: name,
        photoURL: '',
        authProvider: 'password',
      );
      final profileId = await _createSelfProfile(
        uid: user.uid,
        displayName: name,
        email: user.email!,
      );
      await _initProfileController(uid: user.uid, profileId: profileId);
      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } catch (e) {
      throw AppException.unknown('Signup failed: $e');
    }
  }

  Future<User> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      final profileId = await _loadSelectedProfileId(uid: user.uid);
      await _initProfileController(uid: user.uid, profileId: profileId);
      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } catch (e) {
      throw AppException.unknown('Sign-in failed: $e');
    }
  }

  Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AppException.unknown('Google sign-in was cancelled');
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCred = await _auth.signInWithCredential(
        credential,
      );
      final user = userCred.user!;
      if (user.email == null) {
        throw AppException.unknown('Google account has no email');
      }
      final userDocRef = _db.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();
      bool isNewUser = !userDoc.exists;
      if (isNewUser) {
        await _createUserDocument(
          uid: user.uid,
          email: user.email!,
          displayName: user.displayName ?? '',
          photoURL: user.photoURL ?? '',
          authProvider: 'google.com',
        );
        final profileId = await _createSelfProfile(
          uid: user.uid,
          displayName: user.displayName ?? 'Me',
          email: user.email!,
        );
        await _initProfileController(uid: user.uid, profileId: profileId);
      } else {
        final profileId = await _loadSelectedProfileId(uid: user.uid);
        await _initProfileController(uid: user.uid, profileId: profileId);
      }
      return GoogleSignInResult(user: user, isNewUser: isNewUser);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.unknown('Google sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      try {
        await _auth.signOut();
      } catch (_) {}
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw AppException.unknown('Password reset failed: $e');
    }
  }

  Future<void> updateDisplayName({required String displayName}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw AppException.permission('Not signed in');
      await user.updateDisplayName(displayName.trim());
      await _db.collection('users').doc(user.uid).update({
        'displayName': displayName.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } catch (e) {
      throw AppException.unknown('Update failed: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw AppException.permission('Not signed in');
      final uid = user.uid;
      await _db.collection('users').doc(uid).delete();
      await user.delete();
      await _googleSignIn.signOut();
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } catch (e) {
      throw AppException.unknown('Account deletion failed: $e');
    }
  }

  Future<void> _createUserDocument({
    required String uid,
    required String email,
    required String displayName,
    required String photoURL,
    required String authProvider,
  }) async {
    final now = FieldValue.serverTimestamp();
    final timezone = DateTime.now().timeZoneName ?? 'UTC';

    await _db.collection('users').doc(uid).set({
      'email': email,
      'displayName': displayName,
      'timezone': timezone,
      'settings': {},
      'legalVersions': {'terms': '1.0', 'privacy': '1.0'},
      'aiConsentAt': null,
      'legal': {
        'termsVersion': '1.0',
        'privacyVersion': '1.0',
        'acceptedAt': now,
      },
      'selectedMemberId': null,
      'selectedDisplayName': null,
      'selectedProfileImageUrl': photoURL,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<String> _createSelfProfile({
    required String uid,
    required String displayName,
    required String email,
  }) async {
    final now = FieldValue.serverTimestamp();
    final timezone = DateTime.now().timeZoneName ?? 'UTC';
    final profileRef = _db.collection('profiles').doc();
    final profileId = profileRef.id;

    await profileRef.set({
      'ownerUid': uid,
      'kind': 'self',
      'name': displayName.isEmpty ? 'Me' : displayName,
      'timezone': timezone,
      'roles': {uid: 'owner'},
      'memberUids': [uid],
      'healthUids': [uid],
      'permissions': {},
      'dob': null,
      'relationship': null,
      'color': '#4F46E5',
      'missedAfterMin': 30,
      'conditions': <String>[],
      'archivedAt': null,
      'createdAt': now,
      'updatedAt': now,
    });

    await _db.collection('users').doc(uid).update({
      'selectedMemberId': profileId,
      'selectedDisplayName': displayName.isEmpty ? 'Me' : displayName,
      'updatedAt': now,
    });

    return profileId;
  }

  Future<String> _loadSelectedProfileId({required String uid}) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      final data = userDoc.data() ?? {};
      final selectedId = data['selectedMemberId'] as String?;
      if (selectedId != null && selectedId.isNotEmpty) return selectedId;

      final q = await _db
          .collection('profiles')
          .where('ownerUid', isEqualTo: uid)
          .where('kind', isEqualTo: 'self')
          .limit(1)
          .get();
      if (q.docs.isEmpty) {
        return await _createSelfProfile(
          uid: uid,
          displayName: _auth.currentUser?.displayName ?? 'Me',
          email: _auth.currentUser?.email ?? '',
        );
      }
      final fallbackId = q.docs.first.id;
      await _db.collection('users').doc(uid).update({
        'selectedMemberId': fallbackId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return fallbackId;
    } catch (e) {
      throw AppException.unknown('Could not load profile: $e');
    }
  }

  Future<void> _initProfileController({
    required String uid,
    required String profileId,
  }) async {
    try {
      // TODO: Replace with your actual ProfileController call.
      // Example: ProfileController.instance.initialize(uid: uid, profileId: profileId);
    } catch (_) {}
  }

  AppException _mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
      case 'email-already-in-use':
      case 'operation-not-allowed':
      case 'weak-password':
      case 'wrong-password':
      case 'invalid-credential':
        return AppException.validation(e.message ?? e.code);
      case 'user-not-found':
      case 'user-disabled':
      case 'account-exists-with-different-credential':
        return AppException.notFound(e.message ?? e.code);
      case 'network-request-failed':
      case 'too-many-requests':
        return AppException.network(e.message ?? e.code);
      case 'permission-denied':
        return AppException.permission(e.message ?? e.code);
      default:
        return AppException.unknown('${e.code}: ${e.message}');
    }
  }
}
