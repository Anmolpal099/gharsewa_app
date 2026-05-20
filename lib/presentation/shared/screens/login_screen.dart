import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_constants.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/auth/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isRegisterMode = false;
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Validation ────────────────────────────────────────────────
  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? _validateName(String? v) {
    if (v == null || v.isEmpty) return 'Name is required';
    if (v.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  // ── Submit ────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final actions = ref.read(authActionsProvider);

      if (_isRegisterMode) {
        await actions.register(
          _emailCtrl.text,
          _passwordCtrl.text,
          _nameCtrl.text,
        );
      } else {
        await actions.signIn(_emailCtrl.text, _passwordCtrl.text);
      }

      // Navigate based on role after auth state updates
      if (mounted) {
        final authState = ref.read(authServiceProvider).value;
        _navigateByRole(authState?.role);
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_parseError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateByRole(UserRole? role) {
    switch (role) {
      case UserRole.serviceProvider:
        context.go(RouteConstants.providerDashboard);
      case UserRole.admin:
        context.go(RouteConstants.adminDashboard);
      default:
        context.go(RouteConstants.customerHome);
    }
  }

  String _parseError(String error) {
    if (error.contains('user-not-found')) return 'No account found with this email';
    if (error.contains('wrong-password')) return 'Incorrect password';
    if (error.contains('email-already-in-use')) return 'Email already registered';
    if (error.contains('weak-password')) return 'Password is too weak';
    if (error.contains('network-request-failed')) return 'No internet connection';
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state — auto-navigate if already logged in
    ref.listen(authServiceProvider, (_, next) {
      next.whenData((auth) {
        if (auth.isAuthenticated) _navigateByRole(auth.role);
      });
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Logo ──────────────────────────────────────
                    const Icon(
                      Icons.home_repair_service,
                      size: 72,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Gharsewa',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isRegisterMode ? 'Create your account' : 'Welcome back',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 32),

                    // ── Name (register only) ──────────────────────
                    if (_isRegisterMode) ...[
                      TextFormField(
                        controller: _nameCtrl,
                        validator: _validateName,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Email ─────────────────────────────────────
                    TextFormField(
                      controller: _emailCtrl,
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Password ──────────────────────────────────
                    TextFormField(
                      controller: _passwordCtrl,
                      validator: _validatePassword,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Submit button ─────────────────────────────
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isRegisterMode ? 'Create Account' : 'Sign In',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // ── Toggle login/register ─────────────────────
                    TextButton(
                      onPressed: () => setState(() {
                        _isRegisterMode = !_isRegisterMode;
                        _formKey.currentState?.reset();
                      }),
                      child: Text(
                        _isRegisterMode
                            ? 'Already have an account? Sign In'
                            : "Don't have an account? Register",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
