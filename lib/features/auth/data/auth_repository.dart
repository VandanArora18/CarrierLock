import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Authentication repository — Firebase Auth + Firestore user profile.
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email/password and create Firestore user document.
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? fleetId,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = UserModel(
      uid: credential.user!.uid,
      name: name,
      email: email,
      phone: phone,
      role: role,
      fleetId: fleetId,
      isOnline: true,
    );

    await _firestore
        .collection('users')
        .doc(credential.user!.uid)
        .set(user.toFirestore());

    // If driver, add to fleet
    if (role == 'driver' && fleetId != null) {
      await _firestore.collection('fleets').doc(fleetId).update({
        'driverIds': FieldValue.arrayUnion([credential.user!.uid]),
      });
    }

    // If admin, add to fleet
    if (role == 'admin' && fleetId != null) {
      await _firestore.collection('fleets').doc(fleetId).update({
        'adminIds': FieldValue.arrayUnion([credential.user!.uid]),
      });
    }

    return user;
  }

  /// Sign in with email/password.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update last login
    await _firestore.collection('users').doc(credential.user!.uid).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
      'isOnline': true,
    });

    return getUserProfile(credential.user!.uid);
  }

  /// Sign in with Google
  Future<UserModel> signInWithGoogle({String role = 'driver'}) async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('Google sign in cancelled');
    
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;
    
    // Check if user exists, if not create basic profile
    DocumentSnapshot doc;
    try {
      doc = await _firestore.collection('users').doc(user.uid).get();
    } catch (e) {
      throw Exception('Failed to get user doc: $e');
    }

    if (!doc.exists) {
      final newUser = UserModel(
        uid: user.uid,
        name: user.displayName ?? 'Google User',
        email: user.email ?? '',
        role: role,
        isOnline: true,
      );
      try {
        await _firestore.collection('users').doc(user.uid).set(newUser.toFirestore());
      } catch (e) {
        throw Exception('Failed to set user doc: $e');
      }
    } else {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'isOnline': true,
          'role': role,
        });
      } catch (e) {
        throw Exception('Failed to update user doc: $e');
      }
    }
    
    try {
      return await getUserProfile(user.uid);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Sign in with Phone Number
  Future<void> signInWithPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  /// Get user profile from Firestore.
  Future<UserModel> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('User profile not found');
    return UserModel.fromFirestore(doc);
  }

  /// Stream of user profile changes.
  Stream<UserModel> userProfileStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => UserModel.fromFirestore(doc));
  }

  /// Update FCM token.
  Future<void> updateFcmToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).update({
      'fcmToken': token,
    });
  }

  /// Update user location.
  Future<void> updateLocation(
    String uid, {
    required double lat,
    required double lng,
    String? placeName,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'currentLocation': {
        'lat': lat,
        'lng': lng,
        'placeName': placeName,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    });
  }

  /// Sign out.
  Future<void> signOut() async {
    final uid = currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': false,
      });
    }
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  /// Update user profile fields.
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }
}

/// Provider for AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
