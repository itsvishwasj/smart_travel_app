// lib/login_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// LOGIN SCREEN
/// - Implements the modern UI from the provided images (box fields, custom colors).
/// - **The text fields now have a permanently visible light grey outline.**
/// - Includes Full Name and Confirm Password fields for the Register mode.
/// - Adds password visibility toggles (eye icon).
///
/// Backend contract for OTP (example):
/// 1) POST otpSendUrl with JSON: { "email": "user@example.com" }
///    -> backend sends OTP email and returns { "success": true }
/// 2) POST otpVerifyUrl with JSON: { "email":"...", "otp":"123456", "newPassword":"..." }
///    -> backend verifies OTP and (using Firebase Admin) sets the user's password, returning { "success": true }
///
/// NOTE: You must implement the backend endpoints to actually send email OTPs.
/// If you don't have a backend, keep both variables null to use the default password reset email.
const String? otpSendUrl = null; // e.g. 'https://us-central1-yourproject.cloudfunctions.net/sendOtp'
const String? otpVerifyUrl = null; // e.g. 'https://us-central1-yourproject.cloudfunctions.net/verifyOtp'

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _AuthMode { signIn, register }

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();

  bool _loading = false;
  _AuthMode _mode = _AuthMode.signIn;

  // State for password visibility
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _showMessage(String message, {Color? background}) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sendEmailVerificationTo(User user) async {
    try {
      await user.sendEmailVerification();
      await _showMessage('Verification email sent to ${user.email}. Check your inbox.');
    } catch (e) {
      await _showMessage('Failed to send verification email: $e', background: Colors.red);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      final user = cred.user;
      if (user != null) {
        // Optional: Update user display name if you decide to use the name field
        // await user.updateDisplayName(_nameCtrl.text.trim());

        await _sendEmailVerificationTo(user);
        await _auth.signOut();
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Verify your email'),
            content: Text(
              'A verification link has been sent to ${user.email}. '
              'Open that email and click the link, then sign in here.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? e.code;
      await _showMessage('Registration failed: $msg', background: Colors.red);
    } catch (e) {
      await _showMessage('Registration error: $e', background: Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      final user = cred.user;
      if (user == null) {
        await _showMessage('Sign-in failed: no user returned', background: Colors.red);
        await _auth.signOut();
        return;
      }

      await user.reload();
      final reloaded = _auth.currentUser;

      if (reloaded != null && reloaded.emailVerified) {
        await _showMessage('Signed in successfully. Welcome!');
      } else {
        await _auth.signOut();
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: const Text('Email not verified'),
              content: Text(
                'Your email (${user.email}) is not verified. '
                'Please check your inbox for the verification link.\n\n'
                'You can resend the verification email below.',
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _sendEmailVerificationTo(user);
                  },
                  child: const Text('Resend verification'),
                ),
              ],
            );
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? e.code;
      await _showMessage('Sign-in failed: $msg', background: Colors.red);
    } catch (e) {
      await _showMessage('Sign-in error: $e', background: Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Fallback password-reset (link) behavior (used when otpSendUrl is null)
  Future<void> _sendPasswordResetLink(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      await _showMessage('Password reset link sent to $email. Check your inbox.');
    } on FirebaseAuthException catch (e) {
      await _showMessage('Reset failed: ${e.message}', background: Colors.red);
    } catch (e) {
      await _showMessage('Reset error: $e', background: Colors.red);
    }
  }

  // ------------------------------
  // OTP flow (requires backend)
  // ------------------------------
  Future<bool> _requestOtp(String email) async {
    if (otpSendUrl == null) return false;
    try {
      final resp = await http.post(
        Uri.parse(otpSendUrl!),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 15));
      final body = jsonDecode(resp.body);
      return body['success'] == true;
    } catch (e) {
      // treat as failure
      return false;
    }
  }

  Future<bool> _verifyOtpAndSetPassword(String email, String otp, String newPassword) async {
    if (otpVerifyUrl == null) return false;
    try {
      final resp = await http.post(
        Uri.parse(otpVerifyUrl!),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp, 'newPassword': newPassword}),
      ).timeout(const Duration(seconds: 15));
      final body = jsonDecode(resp.body);
      return body['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Triggered by "Forgot password?"
  Future<void> _handleForgotPasswordButton() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      await _showMessage('Enter a valid email first (in the email field).', background: Colors.orange);
      return;
    }

    // If OTP endpoints configured -> OTP flow
    if (otpSendUrl != null && otpVerifyUrl != null) {
      setState(() => _loading = true);
      final ok = await _requestOtp(email);
      setState(() => _loading = false);
      if (!ok) {
        await _showMessage('Failed to send OTP. Try again or use password reset link.', background: Colors.red);
        return;
      }

      // OTP sent — show dialog to accept OTP + new password
      if (!mounted) return;
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => _OtpResetDialog(
          email: email,
          verifyCallback: (otp, newPassword) async {
            // returns true if password updated successfully
            return await _verifyOtpAndSetPassword(email, otp, newPassword);
          },
        ),
      );

      if (result == true) {
        await _showMessage('Password updated successfully. Sign in with the new password.');
      } else if (result == false) {
        await _showMessage('OTP verification failed or cancelled.', background: Colors.red);
      }
      return;
    }

    // Otherwise fallback to password reset email link
    await _sendPasswordResetLink(email);
  }

  // ------------------------------
  // UI (NEW DESIGN)
  // ------------------------------

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    List<String>? autofillHints,
    String? Function(String?)? validator,
    // For password visibility toggle
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityToggle,
    Key? key,
  }) {
    // Custom Input Field Styling to match the design (white fill, visible grey border)
    return TextFormField(
      key: key,
      controller: controller,
      keyboardType: keyboardType,
      // Apply visibility logic
      obscureText: isPassword ? !isVisible : obscureText,
      autofillHints: autofillHints,
      validator: validator,
      style: const TextStyle(color: Color(0xFF1E3A8A)), // Dark blue text
      decoration: InputDecoration(
        labelText: labelText,
        // The design shows the icon directly on the left of the label,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 15, right: 10),
          child: Icon(icon, color: const Color(0xFF1E3A8A), size: 20), // Dark blue icon
        ),
        // Suffix icon for password visibility
        suffixIcon: isPassword && onVisibilityToggle != null
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF1E3A8A).withOpacity(0.6), // Subtle eye icon
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        
        // --- START: MODIFIED FOR PERMANENT GREY BOX OUTLINE ---
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.0), // Default border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.0), // Visible grey border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4C6FFF), width: 1.5), // Primary color for focus
        ),
        // --- END: MODIFIED FOR PERMANENT GREY BOX OUTLINE ---
        
        labelStyle: const TextStyle(color: Color(0xFF1E3A8A)),
      ),
    );
  }

  List<Widget> _buildAuthFields() {
    final List<Widget> fields = [];
    final bool isRegister = _mode == _AuthMode.register;

    // 'Full Name' field only for Register mode
    if (isRegister) {
      fields.add(_buildTextField(
        controller: _nameCtrl,
        labelText: 'Full Name',
        icon: Icons.person_outline,
        autofillHints: const [AutofillHints.name],
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Name required';
          return null;
        },
      ));
      fields.add(const SizedBox(height: 16));
    }
    
    // Email field
    fields.add(_buildTextField(
      controller: _emailCtrl,
      labelText: 'Email',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Email required';
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return 'Enter valid email';
        return null;
      },
    ));
    fields.add(const SizedBox(height: 16));

    // Password field
    fields.add(_buildTextField(
      key: const ValueKey('password'), 
      controller: _passCtrl,
      labelText: 'Password',
      icon: Icons.lock_outline,
      isPassword: true,
      isVisible: _passwordVisible,
      onVisibilityToggle: () => setState(() => _passwordVisible = !_passwordVisible),
      autofillHints: isRegister ? null : const [AutofillHints.password],
      validator: (v) {
        if (v == null || v.isEmpty) return 'Password required';
        if (v.length < 6) return 'Minimum 6 characters';
        return null;
      },
    ));

    // Confirm Password field only for Register mode
    if (isRegister) {
      fields.add(const SizedBox(height: 16));
      fields.add(_buildTextField(
        key: const ValueKey('confirm_password'), 
        controller: _confirmPassCtrl,
        labelText: 'Confirm Password',
        icon: Icons.lock_outline,
        isPassword: true,
        isVisible: _confirmPasswordVisible,
        onVisibilityToggle: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Confirm Password required';
          if (v != _passCtrl.text) return 'Passwords do not match';
          return null;
        },
      ));
    }
    
    return fields;
  }

  @override
  Widget build(BuildContext context) {
    // Determine the text content based on the current mode
    final isSignIn = _mode == _AuthMode.signIn;
    final title = isSignIn ? 'Sign In' : 'Create Account';
    final header = isSignIn ? 'Welcome Back!' : 'Join the Journey';
    final actionText = isSignIn ? 'Sign In' : 'Register';
    final toggleText = isSignIn ? "Don't have an account? Register" : "Already have an account? Sign In";

    return Scaffold(
      // Light background color from the images
      backgroundColor: const Color(0xFFF0F0FF), 
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Text (matches the top part of the image)
            Padding(
              padding: const EdgeInsets.only(top: 40.0, left: 25.0, bottom: 20),
              child: Text(
                header,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A), // Dark blue
                ),
              ),
            ),
            
            // Content Card
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                child: Center(
                  child: Card(
                    // Lighter card background (closer to white)
                    color: Colors.white, 
                    elevation: 10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A), // Dark blue
                              ),
                            ),
                            const SizedBox(height: 25),

                            // Fields
                            ..._buildAuthFields(),
                            
                            // Forgot Password (only in Sign In mode)
                            if (isSignIn)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _loading ? null : _handleForgotPasswordButton,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF4C6FFF))), // Primary color
                                ),
                              ),

                            SizedBox(height: isSignIn ? 20 : 30),

                            // Primary action button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading
                                    ? null
                                    : () async {
                                        HapticFeedback.selectionClick();
                                        if (isSignIn) {
                                          await _handleSignIn();
                                        } else {
                                          await _handleRegister();
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4C6FFF), // Primary dark blue/purple
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 5,
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text(
                                        actionText,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 25),
                            
                            // Mode toggle text
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _mode = isSignIn ? _AuthMode.register : _AuthMode.signIn;
                                  _formKey.currentState?.reset(); // Clear form when switching mode
                                  // Reset visibility toggles when switching modes
                                  _passwordVisible = false; 
                                  _confirmPasswordVisible = false;
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                toggleText,
                                style: const TextStyle(
                                  color: Color(0xFF1E3A8A), // Dark blue
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            
                            // The original app required email verification, keeping this note.
                            if (!isSignIn) 
                              const Padding(
                                padding: EdgeInsets.only(top: 12.0),
                                child: Text(
                                  'New users will receive a verification email.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog widget for entering OTP + new password (used in OTP flow)
class _OtpResetDialog extends StatefulWidget {
  final String email;
  final Future<bool> Function(String otp, String newPassword) verifyCallback;

  const _OtpResetDialog({required this.email, required this.verifyCallback});

  @override
  State<_OtpResetDialog> createState() => _OtpResetDialogState();
}

class _OtpResetDialogState extends State<_OtpResetDialog> {
  final _otpCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _loading = false;
  // State for password visibility within the dialog
  bool _newPasswordVisible = false; 

  @override
  void dispose() {
    _otpCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final otp = _otpCtrl.text.trim();
    final newPass = _newPassCtrl.text;
    if (otp.isEmpty || newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter OTP and new password (min 6 chars)'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _loading = true);
    final ok = await widget.verifyCallback(otp, newPass);
    setState(() => _loading = false);
    if (ok) {
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('OTP verification failed.'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keeping the OTP dialog simple/functional, but applying the new primary color
    return AlertDialog(
      title: const Text('Enter OTP & New Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('A one-time code was sent to ${widget.email}. Enter it below and choose a new password.'),
          const SizedBox(height: 12),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'OTP', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _newPassCtrl,
            // Apply visibility logic
            obscureText: !_newPasswordVisible,
            decoration: InputDecoration(
              labelText: 'New password',
              border: const OutlineInputBorder(),
              // Add visibility toggle to the dialog password field
              suffixIcon: IconButton(
                icon: Icon(
                  _newPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  setState(() {
                    _newPasswordVisible = !_newPasswordVisible;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false), 
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF1E3A8A))), // Dark Blue
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4C6FFF)), // Primary color
          child: _loading 
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
              : const Text('Submit'),
        ),
      ],
    );
  }
}