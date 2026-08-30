import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../domain/user_model.dart';
import '../../../../core/services/notification_service.dart';

/// Auth state — tracks current user profile.
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Auth state notifier — manages sign up, sign in, sign out.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState());

  /// Check if user is already logged in.
  Future<void> checkAuthState() async {
    state = state.copyWith(isLoading: true);
    try {
      final firebaseUser = _repo.currentUser;
      if (firebaseUser != null) {
        final user = await _repo.getUserProfile(firebaseUser.uid);
        state = AuthState(user: user, isLoading: false);
        // Initialize push notifications
        NotificationService().init(firebaseUser.uid);
      } else {
        state = const AuthState(isLoading: false);
      }
    } catch (e) {
      state = AuthState(isLoading: false, error: e.toString());
    }
  }

  /// Sign up.
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? fleetId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.signUp(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
        fleetId: fleetId,
      );
      state = AuthState(user: user, isLoading: false);
      NotificationService().init(user.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapAuthError(e.code));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Sign in.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.signIn(email: email, password: password);
      state = AuthState(user: user, isLoading: false);
      NotificationService().init(user.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapAuthError(e.code));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Sign in with Google.
  Future<bool> signInWithGoogle({String role = 'driver'}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.signInWithGoogle(role: role);
      state = AuthState(user: user, isLoading: false);
      NotificationService().init(user.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapAuthError(e.code));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    if (state.user != null) {
      await NotificationService().removeToken(state.user!.uid);
    }
    await _repo.signOut();
    state = const AuthState();
  }

  /// Clear error.
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Map Firebase Auth error codes to user-friendly messages.
  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'user-disabled':
        return 'This account has been disabled';
      default:
        return 'Authentication failed. Please try again';
    }
  }

  /// Reload current user profile after phone auth
  Future<void> reloadUser() async {
    final firebaseUser = _repo.currentUser;
    if (firebaseUser == null) return;
    try {
      final user = await _repo.getUserProfile(firebaseUser.uid);
      state = AuthState(user: user, isLoading: false);
    } catch (_) {}
  }
}

/// Provider for auth state.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return AuthNotifier(repo);
});

/// Provider for current user (convenience).
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});
