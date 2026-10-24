import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:task_master/src/providers/auth_provider.dart';
import 'package:task_master/src/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLogin = true;
  bool _isLoading = false;
  bool _showPassword = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _trySubmit() async {
    final isValid = _formKey.currentState?.validate();
    if (isValid != true) return;
    _formKey.currentState?.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (_isLogin) {
        await authProvider.signIn(_email, _password);
      } else {
        await authProvider.signUp(_email, _password);
        // After successful sign up, show a confirmation and switch to login mode
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Registration successful! Please log in.'),
              backgroundColor: AppColors.accentGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          setState(() {
            _isLogin = true;
          });
        }
      }
    } catch (error) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: AppColors.accentOrange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gradient Header
            Container(
              height: 240,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Stack(
                children: [
                  // Animated circles for decoration
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ).animate().scale(duration: 2000.ms, curve: Curves.easeInOut).then().scale(duration: 2000.ms, curve: Curves.easeInOut),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ).animate().scale(duration: 2500.ms, curve: Curves.easeInOut).then().scale(duration: 2500.ms, curve: Curves.easeInOut),
                  ),
                  // Header content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '✓',
                          style: GoogleFonts.poppins(
                            fontSize: 64,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ).animate().scale(delay: 200.ms, duration: 600.ms),
                        const SizedBox(height: 12),
                        Text(
                          'Task Master',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                        Text(
                          'Kelola tugas dengan mudah',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mode indicator
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isLogin = true;
                              });
                              _animationController.forward();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isLogin ? AppColors.primaryLight : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Login',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _isLogin ? Colors.white : AppColors.textLight,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isLogin = false;
                              });
                              _animationController.reverse();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isLogin ? AppColors.primaryLight : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Sign Up',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: !_isLogin ? Colors.white : AppColors.textLight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email field
                        TextFormField(
                          key: const ValueKey('email'),
                          validator: (value) => (value == null || !value.contains('@'))
                              ? 'Masukkan email yang valid'
                              : null,
                          onSaved: (value) => _email = value ?? '',
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: const Icon(Icons.email_outlined),
                            hintText: 'example@email.com',
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.3),
                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          key: const ValueKey('password'),
                          validator: (value) => (value == null || value.length < 6)
                              ? 'Password minimal 6 karakter'
                              : null,
                          onSaved: (value) => _password = value ?? '',
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showPassword = !_showPassword;
                                });
                              },
                            ),
                            hintText: '••••••••',
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.3),
                        const SizedBox(height: 28),

                        // Submit button
                        if (_isLoading)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                          ).animate().fadeIn()
                        else
                          Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryLight.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _trySubmit,
                              child: Text(
                                _isLogin ? 'Login' : 'Sign Up',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Footer text
                  Center(
                    child: Text.rich(
                      TextSpan(
                        text: _isLogin ? "Belum punya akun? " : "Sudah punya akun? ",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                        children: [
                          TextSpan(
                            text: _isLogin ? 'Sign Up' : 'Login',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryLight,
                            ),
                            recognizer: null,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}