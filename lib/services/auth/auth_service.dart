import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';

// ── Stream provider: listens to Firebase auth changes ────────────────────────
final authServiceProvider = StreamProvider<AuthState>((ref) {
  return FirebaseAuth.instance.authStateChanges().asyncMap((user) async {
    if (user == null) return const AuthState.unauthenticated();

    final idTokenResult = await user.getIdTokenResult();
    final role = AuthState.roleFromString(
      idTokenResult.claims?['role'] as String?,
    );

    return AuthState(
      status: AuthStatus.authenticated,
      firebaseUser: user,
      role: role,
    );
  });
});

// ── Actions provider ──────────────────────────────────────────────────────────
final authActionsProvider = Provider<AuthActions>((ref) => AuthActions());

class AuthActions {
  final _auth = FirebaseAuth.instance;

  /// Sign in with email and password
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Register new user with email and password
  Future<void> register(String email, String password, String name) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Update display name
    await credential.user?.updateDisplayName(name);
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get fresh Firebase ID token (auto-refreshes if expired)
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _auth.currentUser?.getIdToken(forceRefresh);
  }

  /// Get user role from token claims
  Future<UserRole> getUserRole() async {
    final result = await _auth.currentUser?.getIdTokenResult();
    return AuthState.roleFromString(result?.claims?['role'] as String?);
  }

  /// Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Current Firebase user
  User? get currentUser => _auth.currentUser;
}
