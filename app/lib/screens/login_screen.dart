import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_input.dart';
import '../widgets/app_toast.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _HeroBand(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                children: [
                  _TogglePill(
                    isLogin: _isLogin,
                    onToggle: (v) => setState(() => _isLogin = v),
                  ),
                  const SizedBox(height: 28),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isLogin
                        ? const _LoginForm(key: ValueKey('login'))
                        : const _RegisterForm(key: ValueKey('register')),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin
                          ? "Don't have an account? Register"
                          : 'Already have an account? Log in',
                      style: const TextStyle(
                        color: AppColors.periwinkle,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero band ─────────────────────────────────────────────────────────────

class _HeroBand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.periwinkle,
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.forestGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: const Text(
              '뿅',
              style: TextStyle(
                fontSize: 38,
                color: Color(0xFFE8F5EE),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Ppyong',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Korean learning, together',
            style: TextStyle(
              color: Color(0xFFD0DFFA),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Toggle pill ───────────────────────────────────────────────────────────

class _TogglePill extends StatelessWidget {
  const _TogglePill({required this.isLogin, required this.onToggle});
  final bool isLogin;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDE8),
        borderRadius: AppRadius.pill,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _PillOption(label: 'Log in', active: isLogin, onTap: () => onToggle(true)),
          _PillOption(label: 'Register', active: !isLogin, onTap: () => onToggle(false)),
        ],
      ),
    );
  }
}

class _PillOption extends StatelessWidget {
  const _PillOption({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: AppRadius.pill,
            boxShadow: active
                ? [BoxShadow(color: AppColors.ink.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.ink : AppColors.fog,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Login form ────────────────────────────────────────────────────────────

class _LoginForm extends StatefulWidget {
  const _LoginForm({super.key});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _showPassword = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) return;

    setState(() => _loading = true);
    try {
      await AuthService.instance.login(email, password);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppToast(context,
          variant: ToastVariant.error,
          title: 'Login failed',
          subtitle: 'Check your email and password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppInput(
          hint: 'Email',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _passwordFocus.requestFocus(),
        ),
        const SizedBox(height: 12),
        _PasswordInput(
          hint: 'Password',
          controller: _passwordCtrl,
          focusNode: _passwordFocus,
          show: _showPassword,
          onToggle: () => setState(() => _showPassword = !_showPassword),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
            ),
            child: const Text(
              'Forgot password?',
              style: TextStyle(color: AppColors.periwinkle, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _OrangeCta(label: 'Log in', loading: _loading, onTap: _submit),
      ],
    );
  }
}

// ── Register form ─────────────────────────────────────────────────────────

class _RegisterForm extends StatefulWidget {
  const _RegisterForm({super.key});

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) return;
    if (password != confirm) {
      showAppToast(context, variant: ToastVariant.error, title: 'Passwords do not match');
      return;
    }
    if (password.length < 8) {
      showAppToast(context, variant: ToastVariant.error, title: 'Password must be at least 8 characters');
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.instance.register(name, email, password);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppToast(context,
          variant: ToastVariant.error,
          title: 'Registration failed',
          subtitle: 'Email may already be in use');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppInput(hint: 'Name', controller: _nameCtrl),
        const SizedBox(height: 12),
        AppInput(hint: 'Email', controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _PasswordInput(
          hint: 'Password',
          controller: _passwordCtrl,
          show: _showPassword,
          onToggle: () => setState(() => _showPassword = !_showPassword),
        ),
        const SizedBox(height: 12),
        _PasswordInput(
          hint: 'Confirm password',
          controller: _confirmCtrl,
          show: _showConfirm,
          onToggle: () => setState(() => _showConfirm = !_showConfirm),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF3FE),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            "You'll join as a Member. Your study group admin can update your role after you join.",
            style: TextStyle(color: AppColors.periwinkle, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 24),
        _OrangeCta(label: 'Create account', loading: _loading, onTap: _submit),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────

class _PasswordInput extends StatelessWidget {
  const _PasswordInput({
    required this.hint,
    required this.controller,
    required this.show,
    required this.onToggle,
    this.focusNode,
    this.onSubmitted,
  });
  final String hint;
  final TextEditingController controller;
  final bool show;
  final VoidCallback onToggle;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onSubmitted: onSubmitted,
      textInputAction: onSubmitted != null ? TextInputAction.done : null,
      obscureText: !show,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.fog, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(
            show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.fog,
            size: 20,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.periwinkle, width: 1.5),
        ),
      ),
    );
  }
}

class _OrangeCta extends StatelessWidget {
  const _OrangeCta({required this.label, required this.onTap, this.loading = false});
  final String label;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(color: AppColors.orange, borderRadius: AppRadius.pill),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
