// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../core/constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _userCtrl     = TextEditingController();
  final _passCtrl     = TextEditingController();
  String _role        = 'participant';
  bool   _obscure     = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      username: _userCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
      role:     _role,
    );
    if (ok && mounted) {
      context.go(auth.isCoach ? '/coach' : '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/login')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create Account',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                    color: Color(AppConstants.textPrimary))),
              const SizedBox(height: 6),
              const Text('Join CoachTrack today',
                style: TextStyle(color: Color(AppConstants.textSecondary))),
              const SizedBox(height: 28),

              if (auth.error != null) ErrorMessage(message: auth.error!),

              // Role selector
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: ['participant', 'coach'].map((r) {
                    final selected = _role == r;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _role = r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? const Color(AppConstants.primaryColor) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            r[0].toUpperCase() + r.substring(1),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected ? Colors.white : const Color(AppConstants.textSecondary),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              _field(_nameCtrl,  'Full Name',    Icons.badge_outlined,    TextInputAction.next),
              const SizedBox(height: 14),
              _field(_emailCtrl, 'Email',         Icons.email_outlined,    TextInputAction.next,
                  inputType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _field(_userCtrl,  'Username',     Icons.person_outline,    TextInputAction.next),
              const SizedBox(height: 14),

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
                validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
              ),

              const SizedBox(height: 28),
              LoadingButton(text: 'Create Account', loading: auth.loading, onPressed: _submit),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Already have an account? Sign in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl, String label, IconData icon,
    TextInputAction action, {TextInputType? inputType}
  ) {
    return TextFormField(
      controller: ctrl,
      keyboardType: inputType,
      textInputAction: action,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }
}
