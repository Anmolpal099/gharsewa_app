import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';

final authServiceProvider = StreamProvider<AuthState>((ref) {
  return FirebaseAuth.instance.authStateChanges().asyncMap((user) async {
    if (user == null) return const AuthState.unauthenticated();

    // Get custom claims (role) from Firebase token
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

final authActionsProvider = Provider<AuthActions>((ref) => AuthActions());

class AuthActions {
  final _auth = FirebaseAuth.instance;

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> registerWithEmail(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _auth.currentUser?.getIdToken(forceRefresh);
  }
}
