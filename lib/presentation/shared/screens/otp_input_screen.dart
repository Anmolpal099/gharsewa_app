import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/auth/auth_state.dart';

class OtpInputScreen extends ConsumerStatefulWidget {
  final String email;
  final String type; // 'email_verification' or 'password_reset'

  const OtpInputScreen({
    super.key,
    required this.email,
    this.type = 'email_verification',
  });

  @override
  ConsumerState<OtpInputScreen> createState() => _OtpInputScreenState();
}

class _OtpInputScreenState extends ConsumerState<OtpInputScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _canResend = false;
  int _resendCountdown = 60;
  Timer? _timer;
  int _expiryCountdown = 600; // 10 minutes
  Timer? _expiryTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _startExpiryTimer();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    _expiryTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  void _startExpiryTimer() {
    _expiryCountdown = 600;
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_expiryCountdown > 0) {
        setState(() => _expiryCountdown--);
      } else {
        timer.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP has expired. Please request a new one.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  String get _expiryDisplay {
    final minutes = _expiryCountdown ~/ 60;
    final seconds = _expiryCountdown % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);

    try {
      final actions = ref.read(authActionsProvider);
      
      if (widget.type == 'password_reset') {
        await actions.sendPasswordResetOtp(widget.email);
      } else {
        // For email verification, we need to call the send endpoint
        // This would require adding a method to auth service
        // For now, user can request new OTP from registration
        throw Exception('Please register again to get a new OTP');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _startResendTimer();
        _startExpiryTimer();
        // Clear existing OTP
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all 6 digits'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final actions = ref.read(authActionsProvider);

      if (widget.type == 'password_reset') {
        // For password reset, just verify OTP and navigate to new password screen
        // The actual verification will happen when setting new password
        context.push('/new-password', extra: {'email': widget.email, 'otp': otp});
      } else {
        // Email verification - this will log the user in
        await actions.verifyEmail(widget.email, otp);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
          
          // Pop all routes and let the router redirect based on auth state
          // The router will automatically redirect to the correct dashboard
          if (mounted) {
            // Go to splash, which will trigger redirect to correct dashboard
            context.go('/splash');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.type == 'password_reset' ? 'Reset Password' : 'Verify Email',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Icon(
                    widget.type == 'password_reset'
                        ? Icons.lock_reset
                        : Icons.mark_email_read,
                    size: 72,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Enter OTP',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    'We sent a 6-digit code to\n${widget.email}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Expiry timer
                  Text(
                    'Code expires in $_expiryDisplay',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _expiryCountdown < 60 ? Colors.red : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 32),

                  // OTP input boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 50,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                            // Auto-verify when all 6 digits entered
                            if (index == 5 && value.isNotEmpty) {
                              _verifyOtp();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // Verify button
                  FilledButton(
                    onPressed: _isLoading ? null : _verifyOtp,
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
                        : const Text(
                            'Verify OTP',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Resend OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Didn't receive the code? "),
                      TextButton(
                        onPressed: _canResend && !_isLoading ? _resendOtp : null,
                        child: Text(
                          _canResend
                              ? 'Resend'
                              : 'Resend in ${_resendCountdown}s',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
