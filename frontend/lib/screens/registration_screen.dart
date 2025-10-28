import 'package:flutter/material.dart';
import '../globals.dart';
import 'package:frontend/backend/server.dart';
import '../services/google_signin_service.dart';
import '../services/arri_client.rpc.dart';
import '../services/local_storage_service.dart';
import '../widgets/textbox.dart';
import '../widgets/button.dart';

class RegistrationScreen extends StatefulWidget {
  final VoidCallback? onAuthenticationSuccess;

  const RegistrationScreen({super.key, this.onAuthenticationSuccess});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();
  final _emailController =
      TextEditingController(); // used for "email or username" in sign-in and email in sign-up
  final _usernameController =
      TextEditingController(); // used in sign-up and for display name
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleSigningIn = false;
  bool _isAppleSigningIn = false; // new flag for apple
  String? _errorMessage;
  String? _successMessage;

  // controls which form is shown: true => Sign In, false => Sign Up
  bool _isSignIn = true;

  // Initialize Google Sign-In service
  final GoogleSignInService _googleSignInService = GoogleSignInService();

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- existing register / signin methods unchanged (kept as-is) ---
  Future<void> _registerUser() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_signUpFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final params = RegisterUserParams(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      final response = await server.auth.signup(params);

      if (response.success) {
        setState(() {
          _successMessage = response.message;
          _isLoading = false;
        });

        _emailController.clear();
        _usernameController.clear();
        _passwordController.clear();

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            widget.onAuthenticationSuccess?.call();
          }
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_signInFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final identifier = _emailController.text.trim();
      final isEmail = identifier.contains('@');

      final params = LoginUserParams(
        email: isEmail ? identifier : '',
        username: isEmail ? '' : identifier,
        password: _passwordController.text,
      );

      final response = await server.auth.signin(params);

      if (response.success) {
        final trimmedUsername = _usernameController.text.trim();
        final userNameToSave = isEmail
            ? (trimmedUsername.isNotEmpty
                  ? trimmedUsername
                  : (identifier.contains('@')
                        ? identifier.split('@').first
                        : identifier))
            : identifier;

        await LocalStorageService.saveUserData(
          userId: response.userId,
          userName: userNameToSave,
          userEmail: isEmail ? identifier : '',
          authToken: response.token,
        );

        setState(() {
          _successMessage = response.message;
          _isLoading = false;
        });

        _emailController.clear();
        _usernameController.clear();
        _passwordController.clear();

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            widget.onAuthenticationSuccess?.call();
          }
        });
      } else {
        // If backend indicates the account doesn't exist and needs a username,
        // switch to Sign Up and prefill fields so the user can complete registration.
        final needsUsername =
            response.message ==
            'Username is required for new user registration';

        if (needsUsername) {
          // Prefill username suggestion from identifier if possible
          final identifier = _emailController.text.trim();
          final suggestedUsername = identifier.contains('@')
              ? identifier.split('@').first
              : identifier;

          setState(() {
            _isSignIn = false; // show Sign Up form
            _usernameController.text = suggestedUsername;
            _errorMessage =
                'No account found for this email. Create a username to finish registration.';
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = response.message;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Sign in failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // --- Google sign-in (existing) ---
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _isGoogleSigningIn = true;
    });

    try {
      final result = await _googleSignInService.signIn();

      if (result.success && result.user != null) {
        setState(() {
          _successMessage =
              'Google Sign-In successful! Welcome ${result.user!.displayName ?? result.user!.email}';
          _isGoogleSigningIn = false;
        });

        _emailController.text = result.user!.email ?? '';
        _usernameController.text = result.user!.displayName ?? '';

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            widget.onAuthenticationSuccess?.call();
          }
        });
      } else {
        setState(() {
          _errorMessage = result.message;
          _isGoogleSigningIn = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google Sign-In failed: ${e.toString()}';
        _isGoogleSigningIn = false;
      });
    }
  }

  // --- Apple sign-in placeholder: replace with real Sign in with Apple integration ---
  Future<void> _handleAppleSignIn() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _isAppleSigningIn = true;
    });

    try {
      // TODO: Integrate 'sign_in_with_apple' or your Apple sign-in service here.
      // This is a placeholder to show UI state. Replace with actual sign-in flow.
      await Future.delayed(const Duration(milliseconds: 900));

      setState(() {
        _successMessage =
            'Apple Sign-In not configured — integrate Sign in with Apple SDK';
        _isAppleSigningIn = false;
      });

      // If you obtain user info, populate controllers similarly:
      // _emailController.text = appleEmail ?? '';
      // _usernameController.text = appleName ?? '';
      // widget.onAuthenticationSuccess?.call();
    } catch (e) {
      setState(() {
        _errorMessage = 'Apple Sign-In failed: ${e.toString()}';
        _isAppleSigningIn = false;
      });
    }
  }

  Widget _bottomButtonsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Button(
              text: 'Sign In',
              onPressed: () {
                if (_isSignIn) {
                  _handleSignIn();
                } else {
                  setState(() {
                    _isSignIn = true;
                    _errorMessage = null;
                    _successMessage = null;
                  });
                }
              },
              // isLoading: _isSignIn,
              isActive: _isSignIn,
              backgroundColor: Colors.black,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Button(
              text: 'Sign Up',
              onPressed: () {
                if (!_isSignIn) {
                  _registerUser();
                } else {
                  setState(() {
                    _isSignIn = false;
                    _errorMessage = null;
                    _successMessage = null;
                  });
                }
              },
              // isLoading: !_isSignIn,
              isActive: !_isSignIn,
              backgroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // Add this helper widget inside _RegistrationScreenState:
  Widget _orDivider({String label = 'or'}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
        ],
      ),
    );
  }

  // ---------- Google button ----------
  Widget _googleButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 8.0),
      child: GoogleSignInButton(
        onPressed: _handleGoogleSignIn,
        isLoading: _isGoogleSigningIn,
        text: _isGoogleSigningIn ? 'Signing in...' : 'Continue with Google',
      ),
    );
  }

  // ---------- Apple button ----------
  Widget _appleButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: AppleSignInButton(
        onPressed: _handleAppleSignIn,
        isLoading: _isAppleSigningIn,
        text: _isAppleSigningIn
            ? 'Signing in with Apple...'
            : 'Continue with Apple',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Top-right close icon

          // Form area (animated)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: _isSignIn ? _buildSignInForm() : _buildSignUpForm(),
          ),

          // Bottom buttons (two equal-sized buttons)
          _bottomButtonsRow(),

          _orDivider(),

          // Social buttons: Google then Apple
          _googleButton(),
          _appleButton(),
        ],
      ),
    );
  }

  Widget _buildSignInForm() {
    return SingleChildScrollView(
      primary: false,
      key: const ValueKey('signin'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Form(
        key: _signInFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  _successMessage!,
                  style: const TextStyle(color: Colors.green),
                ),
              ),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 4),

            // Email or Username Field (single field for sign-in)
            TextBox(
              controller: _emailController,
              labelText: 'Email or Username',
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email or username';
                }
                final v = value.trim();
                if (v.contains('@')) {
                  // basic email validation
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                    return 'Please enter a valid email';
                  }
                } else {
                  if (v.length < 3) {
                    return 'Username must be at least 3 characters';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password Field
            PasswordTextBox(
              controller: _passwordController,
              labelText: 'Password',
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Please enter your password';
                return null;
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpForm() {
    return SingleChildScrollView(
      primary: false,
      key: const ValueKey('signup'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Form(
        key: _signUpFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  _successMessage!,
                  style: const TextStyle(color: Colors.green),
                ),
              ),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 4),

            // Email Field (for sign-up)
            EmailTextBox(
              controller: _emailController,
              labelText: 'Email',
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Please enter your email';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                  return 'Please enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Username Field (only present in sign-up)
            UsernameTextBox(
              controller: _usernameController,
              labelText: 'Username',
            ),
            const SizedBox(height: 16),

            // Password Field
            PasswordTextBox(
              controller: _passwordController,
              labelText: 'Password',
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Please enter a password';
                if (value.length < 8)
                  return 'Password must be at least 8 characters';
                if (!RegExp(r'[A-Z]').hasMatch(value))
                  return 'Password must contain at least one uppercase letter';
                if (!RegExp(r'[a-z]').hasMatch(value))
                  return 'Password must contain at least one lowercase letter';
                if (!RegExp(r'\d').hasMatch(value))
                  return 'Password must contain at least one number';
                return null;
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Reusable dialog for registration/sign-in
Future<void> showRegistrationDialog(
  BuildContext context, {
  VoidCallback? onAuthenticated,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome'),
            const Spacer(),
            IconButton(
              constraints: BoxConstraints(minWidth: 30, minHeight: 30),
              style: IconButton.styleFrom(backgroundColor: Pallet.inside2),
              padding: EdgeInsets.all(5),
              icon: Icon(
                Icons.close,
                color: Pallet.font1,
                size: 16,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              tooltip: 'Close',
              splashRadius: 18,
            ),
          ],
        ),
        content: Align(
          alignment: Alignment.center,
          widthFactor: 1,
          heightFactor: 1,
          child: SizedBox(
            width: 400,
            child: RegistrationScreen(
              onAuthenticationSuccess: () async {
                onAuthenticated?.call();
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ),
        ),
      );
    },
  );
}
