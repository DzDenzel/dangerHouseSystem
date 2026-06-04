import 'package:dangerhouse_app/presentation/login/register_activity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../home/home_activity.dart';

class LoginActivity extends ConsumerStatefulWidget {
  const LoginActivity({super.key});

  @override
  ConsumerState<LoginActivity> createState() => _LoginActivityState();
}

class _LoginActivityState extends ConsumerState<LoginActivity> {
  static const String _rememberMeKey = 'remember_me';
  static const String _rememberedAccountKey = 'remembered_account';
  static const String _legacyRememberedPasswordKey = 'remembered_password';

  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isAgreed = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _restoreRememberedCredentials();
  }

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _restoreRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    if (!rememberMe || !mounted) return;

    await prefs.remove(_legacyRememberedPasswordKey);

    setState(() {
      _rememberMe = true;
      _accountController.text = prefs.getString(_rememberedAccountKey) ?? '';
    });
  }

  Future<void> _persistRememberedCredentials({
    required String account,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await Future.wait([
        prefs.setBool(_rememberMeKey, true),
        prefs.setString(_rememberedAccountKey, account),
        prefs.remove(_legacyRememberedPasswordKey),
      ]);
      return;
    }

    await Future.wait([
      prefs.setBool(_rememberMeKey, false),
      prefs.remove(_rememberedAccountKey),
      prefs.remove(_legacyRememberedPasswordKey),
    ]);
  }

  Future<void> _handleLogin() async {
    if (ref.read(authNotifierProvider).isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_isAgreed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先阅读并同意《用户协议》和《隐私政策》')),
      );
      return;
    }

    final account = _accountController.text.trim();
    final password = _passwordController.text.trim();

    await ref.read(authNotifierProvider.notifier).login(
          account,
          password,
          rememberMe: _rememberMe,
        );

    final authState = ref.read(authNotifierProvider);
    if (!mounted) return;

    if (authState.data?.success == true) {
      await _persistRememberedCredentials(account: account);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeActivity()),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(authState.error ?? '登录失败，请重试')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE0F2FE),
                  Color(0xFFEFF6FF),
                  Colors.white,
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    _buildBrandSection(),
                    const SizedBox(height: 48),
                    _buildFormSection(),
                    const SizedBox(height: 32),
                    _buildActionSection(authState.isLoading),
                    const SizedBox(height: 40),
                    _buildFooterText(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandSection() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Column(
      children: [
        _buildTextField(
          controller: _accountController,
          hint: '用户名 / 手机号 / 邮箱',
          icon: Icons.person_outline,
          validator: (value) => (value == null || value.isEmpty) ? '账号不能为空' : null,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _passwordController,
          hint: '请输入密码',
          icon: Icons.lock_outline,
          isPassword: true,
          obscureText: _obscurePassword,
          onTogglePassword: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          validator: (value) => (value == null || value.isEmpty) ? '密码不能为空' : null,
        ),
        Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  _rememberMe = !_rememberMe;
                });
              },
              child: Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    activeColor: Colors.blueAccent,
                    visualDensity: VisualDensity.compact,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                  ),
                  const Text(
                    '记住我',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ],
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请联系系统管理员找回密码')),
                );
              },
              child: const Text(
                '忘记密码？',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Color(0xFF334155)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.blueAccent.withValues(alpha: 0.7)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[400],
                  size: 20,
                ),
                onPressed: onTogglePassword,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildActionSection(bool isLoading) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
            backgroundColor: Colors.blueAccent,
            elevation: 2,
            shadowColor: Colors.blueAccent.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  '登录',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _isAgreed,
                activeColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (value) {
                  setState(() {
                    _isAgreed = value ?? false;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isAgreed = !_isAgreed;
                });
              },
              child: RichText(
                text: TextSpan(
                  text: '我已阅读并同意',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  children: const [
                    TextSpan(
                      text: '《用户协议》',
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                    TextSpan(text: '和'),
                    TextSpan(
                      text: '《隐私政策》',
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('还没有账号？', style: TextStyle(color: Colors.grey[600])),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RegisterActivity()),
            );
          },
          child: const Text(
            '点击创建',
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
