import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branding_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _guestTokenController = TextEditingController();
  final _guestPinController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _guestMode = false;

  @override
  void initState() {
    super.initState();
    // Auto-login in debug mode (simulator) for screenshots
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoLoginForScreenshots();
      });
    }
  }

  Future<void> _autoLoginForScreenshots() async {
    try {
      // Wait a moment for the UI to render (for login screenshot)
      await Future.delayed(const Duration(seconds: 2));

      // Fill in demo credentials
      _emailController.text = 'review@verhuuragenda.nl';
      _passwordController.text = 'AppleReview2025!';

      // Wait another moment then login
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        // Try to login, but don't block if it fails
        await _handleLogin().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('Auto-login timeout - simulator may not have network access');
          },
        );
      }
    } catch (e) {
      debugPrint('Auto-login failed: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _guestTokenController.dispose();
    _guestPinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (_guestMode) {
      final ok = await ref.read(authStateProvider.notifier).loginGuest(
            _guestTokenController.text,
            _guestPinController.text,
          );
      if (ok && mounted) context.go('/guest');
      return;
    }

    final success = await ref.read(authStateProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                // Logo
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    size: 48,
                    color: Colors.white,
                  ),
                ),

                Text(
                  ref.watch(brandingProvider),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.loginTitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 48),

                // Error message
                if (authState.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            authState.error!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Mode toggle: Host / Guest
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _modeButton(
                          label: 'Verhuurder',
                          icon: Icons.home_work_outlined,
                          active: !_guestMode,
                          onTap: () => setState(() => _guestMode = false),
                        ),
                      ),
                      Expanded(
                        child: _modeButton(
                          label: 'Gast',
                          icon: Icons.person_outline,
                          active: _guestMode,
                          onTap: () => setState(() => _guestMode = true),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Host fields
                if (!_guestMode) ...[
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.email,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (_guestMode) return null;
                      if (value == null || value.isEmpty) {
                        return l10n.enterEmail;
                      }
                      if (!value.contains('@')) {
                        return l10n.enterValidEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (_guestMode) return null;
                      if (value == null || value.isEmpty) {
                        return l10n.enterPassword;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? true;
                          });
                        },
                      ),
                      Text(l10n.rememberMe),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go('/forgot-password'),
                        child: Text(l10n.forgotPassword),
                      ),
                    ],
                  ),
                ] else ...[
                  // Guest fields
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Gebruik de toegangscode en pincode uit de uitnodigingsmail van je verhuurder.',
                            style: TextStyle(color: Colors.blue[800], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextFormField(
                    controller: _guestTokenController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Toegangscode',
                      hintText: '64-tekens code uit je email',
                      prefixIcon: Icon(Icons.vpn_key_outlined),
                    ),
                    validator: (value) {
                      if (!_guestMode) return null;
                      if (value == null || value.trim().length < 10) {
                        return 'Vul je toegangscode in';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _guestPinController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    decoration: const InputDecoration(
                      labelText: 'Pincode',
                      hintText: '6 cijfers',
                      prefixIcon: Icon(Icons.password_outlined),
                    ),
                    validator: (value) {
                      if (!_guestMode) return null;
                      if (value == null || value.trim().length != 6) {
                        return 'Pincode is 6 cijfers';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 24),

                // Login button
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.login,
                          style: const TextStyle(fontSize: 16),
                        ),
                ),

                const SizedBox(height: 24),

                // Register link (host mode only)
                if (!_guestMode)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${l10n.noAccount} ',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text(l10n.freeRegister),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeButton({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: active ? AppTheme.primaryColor : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? AppTheme.primaryColor : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
