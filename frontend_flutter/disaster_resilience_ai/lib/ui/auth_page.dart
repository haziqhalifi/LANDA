import 'package:disaster_resilience_ai/services/api_service.dart';
import 'package:disaster_resilience_ai/ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  static const _tokenKey = 'auth_access_token';
  static const _emailKey = 'auth_email';
  static const _usernameKey = 'auth_username';

  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignIn = true;
  bool _loading = false;
  bool _restoring = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final result = _isSignIn
          ? await _api.signIn(email: email, password: password)
          : await _api.signUp(
              username: _usernameController.text.trim(),
              email: email,
              password: password,
            );

      await _saveSession(
        accessToken: result.accessToken,
        email: result.email,
        username: result.username,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomePage(
            accessToken: result.accessToken,
            email: result.email,
            username: result.username,
          ),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignIn = !_isSignIn;
      _error = null;
    });
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final email = prefs.getString(_emailKey);
      final username = prefs.getString(_usernameKey);

      if (token == null || email == null || username == null) {
        if (mounted) {
          setState(() => _restoring = false);
        }
        return;
      }

      await _api.me(token);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              HomePage(accessToken: token, email: email, username: username),
        ),
      );
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_emailKey);
      await prefs.remove(_usernameKey);
      if (mounted) {
        setState(() => _restoring = false);
      }
    }
  }

  Future<void> _saveSession({
    required String accessToken,
    required String email,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_usernameKey, username);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final muted = isDark ? const Color(0xFFA7B5A8) : Colors.grey;
    final heading = isDark ? const Color(0xFFE8F5E9) : const Color(0xFF1E293B);

    if (_restoring) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: const CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    }

    final title = _isSignIn ? 'Welcome Back' : 'Create Account';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Resilience AI',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF233124)
                          : const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isSignIn
                          ? Icons.lock_outline
                          : Icons.person_add_outlined,
                      size: 64,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: heading,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignIn
                        ? 'Sign in to monitor your community'
                        : 'Join us to stay resilient',
                    style: TextStyle(fontSize: 14, color: muted),
                  ),
                  const SizedBox(height: 32),
                  if (!_isSignIn)
                    TextFormField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: TextStyle(color: muted),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1E2720)
                            : Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        prefixIcon: Icon(Icons.person_outline, color: muted),
                      ),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                  if (!_isSignIn) const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: muted),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1E2720)
                          : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                      ),
                      prefixIcon: Icon(Icons.email_outlined, color: muted),
                    ),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (!text.contains('@')) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: muted),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1E2720)
                          : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                      ),
                      prefixIcon: Icon(Icons.lock_outline, color: muted),
                    ),
                    validator: (value) {
                      final text = value ?? '';
                      if (text.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3A2020)
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red[700], fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              _isSignIn ? 'SIGN IN' : 'CREATE ACCOUNT',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _loading ? null : _toggleMode,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF4CAF50),
                    ),
                    child: Text(
                      _isSignIn
                          ? 'Don\'t have an account? Sign up'
                          : 'Already have an account? Sign in',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
