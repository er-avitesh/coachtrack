// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../core/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _userCtrl   = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool  _obscure    = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok   = await auth.login(_userCtrl.text.trim(), _passCtrl.text);
    if (ok && mounted) {
      context.go(auth.isCoach ? '/coach' : '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Logo / Brand
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: const Color(AppConstants.primaryColor),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.fitness_center, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 24),
                const Text('Welcome back',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                      color: Color(AppConstants.textPrimary))),
                const SizedBox(height: 6),
                const Text('Sign in to CoachTrack',
                  style: TextStyle(fontSize: 15, color: Color(AppConstants.textSecondary))),

                const SizedBox(height: 36),

                if (auth.error != null) ErrorMessage(message: auth.error!),

                // Username
                TextFormField(
                  controller: _userCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 28),

                LoadingButton(
                  text: 'Sign In',
                  loading: auth.loading,
                  onPressed: _submit,
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ",
                      style: TextStyle(color: Color(AppConstants.textSecondary))),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Register'),
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
}
