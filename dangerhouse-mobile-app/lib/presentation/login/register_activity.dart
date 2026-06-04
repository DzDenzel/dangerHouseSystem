import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/network_providers.dart';
import '../../data/models/auth_models.dart';
import '../../providers/auth_provider.dart';

class RegisterActivity extends ConsumerStatefulWidget {
  const RegisterActivity({super.key});

  @override
  ConsumerState<RegisterActivity> createState() => _RegisterActivityState();
}

class _RegisterActivityState extends ConsumerState<RegisterActivity> {
  static final RegExp _usernameRegex = RegExp(r'^[A-Za-z][A-Za-z0-9_]{3,19}$');
  static final RegExp _phoneRegex = RegExp(r'^1[3-9]\d{9}$');

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _usernameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();

  bool _checkingUsername = false;
  bool _checkingPhone = false;
  bool? _usernameAvailable;
  bool? _phoneAvailable;
  String? _usernameMessage;
  String? _phoneMessage;

  @override
  void initState() {
    super.initState();
    _usernameFocusNode.addListener(_handleUsernameFocusChange);
    _phoneFocusNode.addListener(_handlePhoneFocusChange);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameFocusNode
      ..removeListener(_handleUsernameFocusChange)
      ..dispose();
    _phoneFocusNode
      ..removeListener(_handlePhoneFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleUsernameFocusChange() {
    if (!_usernameFocusNode.hasFocus) {
      _checkUsernameAvailability();
    }
  }

  void _handlePhoneFocusChange() {
    if (!_phoneFocusNode.hasFocus) {
      _checkPhoneAvailability();
    }
  }

  String? _validateUsername(String? value) {
    final username = value?.trim() ?? '';
    if (username.isEmpty) {
      return '请输入用户名';
    }
    if (!_usernameRegex.hasMatch(username)) {
      return '用户名需以字母开头，可包含字母、数字、下划线，长度 4-20 位';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) {
      return '请输入手机号';
    }
    if (!_phoneRegex.hasMatch(phone)) {
      return '请输入正确的 11 位手机号';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) {
      return '请输入密码';
    }
    if (password.length < 6) {
      return '密码长度不能少于 6 位';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final confirmPassword = value?.trim() ?? '';
    if (confirmPassword.isEmpty) {
      return '请再次输入密码';
    }
    if (confirmPassword != _passwordController.text.trim()) {
      return '两次输入的密码不一致';
    }
    return null;
  }

  Future<bool> _checkUsernameAvailability({bool silent = false}) async {
    final validationError = _validateUsername(_usernameController.text);
    if (validationError != null) {
      if (!mounted) return false;
      setState(() {
        _usernameAvailable = null;
        _usernameMessage = silent ? null : validationError;
      });
      return false;
    }

    setState(() {
      _checkingUsername = true;
      _usernameMessage = null;
    });

    try {
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.checkUsername(_usernameController.text.trim());
      final available = response['data'] == true;

      if (!mounted) return available;
      setState(() {
        _usernameAvailable = available;
        _usernameMessage = available ? '用户名可用' : '用户名已存在，请更换';
      });
      return available;
    } catch (_) {
      if (!mounted) return false;
      setState(() {
        _usernameAvailable = null;
        _usernameMessage = '用户名校验失败，请稍后重试';
      });
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _checkingUsername = false;
        });
      }
    }
  }

  Future<bool> _checkPhoneAvailability({bool silent = false}) async {
    final validationError = _validatePhone(_phoneController.text);
    if (validationError != null) {
      if (!mounted) return false;
      setState(() {
        _phoneAvailable = null;
        _phoneMessage = silent ? null : validationError;
      });
      return false;
    }

    setState(() {
      _checkingPhone = true;
      _phoneMessage = null;
    });

    try {
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.checkPhone(_phoneController.text.trim());
      final available = response['data'] == true;

      if (!mounted) return available;
      setState(() {
        _phoneAvailable = available;
        _phoneMessage = available ? '手机号可以使用' : '该手机号已经注册过账户，请直接登录';
      });
      return available;
    } catch (_) {
      if (!mounted) return false;
      setState(() {
        _phoneAvailable = null;
        _phoneMessage = '手机号校验失败，请稍后重试';
      });
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _checkingPhone = false;
        });
      }
    }
  }

  Future<void> _handleRegister() async {
    final validForm = _formKey.currentState?.validate() ?? false;
    if (!validForm) return;

    final usernameAvailable = await _checkUsernameAvailability();
    final phoneAvailable = await _checkPhoneAvailability();

    if (!usernameAvailable || !phoneAvailable) {
      return;
    }

    final request = RegisterRequest(
      username: _usernameController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
      role: 'USER',
    );

    final success = await ref.read(authNotifierProvider.notifier).register(request);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('注册成功，请使用新账号登录')),
      );
      Navigator.pop(context);
      return;
    }

    final error = ref.read(authNotifierProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? '注册失败，请重试')),
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
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          _buildTitleSection(),
                          const SizedBox(height: 40),
                          _buildTextField(
                            controller: _usernameController,
                            focusNode: _usernameFocusNode,
                            hint: '请输入用户名',
                            helperText: '以字母开头，可包含字母、数字、下划线，长度 4-20 位',
                            message: _usernameMessage,
                            messageColor: _messageColor(_usernameAvailable, _checkingUsername),
                            trailing: _buildStatusIcon(_checkingUsername, _usernameAvailable),
                            icon: Icons.person_outline,
                            textInputAction: TextInputAction.next,
                            validator: _validateUsername,
                          ),
                          const SizedBox(height: 18),
                          _buildTextField(
                            controller: _phoneController,
                            focusNode: _phoneFocusNode,
                            hint: '请输入手机号',
                            helperText: '请填写本人常用手机号',
                            message: _phoneMessage,
                            messageColor: _messageColor(_phoneAvailable, _checkingPhone),
                            trailing: _buildStatusIcon(_checkingPhone, _phoneAvailable),
                            icon: Icons.phone_android_outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            validator: _validatePhone,
                          ),
                          const SizedBox(height: 18),
                          _buildTextField(
                            controller: _passwordController,
                            hint: '请设置登录密码',
                            helperText: '密码长度至少 6 位',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            textInputAction: TextInputAction.next,
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: 18),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            hint: '请再次输入密码',
                            icon: Icons.lock_reset_outlined,
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            validator: _validateConfirmPassword,
                            onFieldSubmitted: (_) {
                              _handleRegister();
                            },
                          ),
                          const SizedBox(height: 28),
                          _buildRegisterButton(authState.isLoading),
                          const SizedBox(height: 20),
                          _buildFooterText(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        const Icon(Icons.person_add_outlined, color: Colors.blueAccent, size: 60),
        const SizedBox(height: 16),
        const Text(
          '创建新账户',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'CREATE YOUR ACCOUNT',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    bool isPassword = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? helperText,
    String? message,
    Color? messageColor,
    Widget? trailing,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: isPassword,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: const TextStyle(color: Color(0xFF334155)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: Colors.blueAccent.withValues(alpha: 0.7)),
            suffixIcon: trailing,
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
          ),
          validator: validator,
          onChanged: (_) {
            if (controller == _usernameController) {
              setState(() {
                _usernameAvailable = null;
                _usernameMessage = null;
              });
            }
            if (controller == _phoneController) {
              setState(() {
                _phoneAvailable = null;
                _phoneMessage = null;
              });
            }
          },
          onFieldSubmitted: onFieldSubmitted,
        ),
        if (helperText != null || message != null) ...[
          const SizedBox(height: 6),
          Text(
            message ?? helperText ?? '',
            style: TextStyle(
              fontSize: 12,
              color: messageColor ?? const Color(0xFF64748B),
            ),
          ),
        ],
      ],
    );
  }

  Widget? _buildStatusIcon(bool checking, bool? available) {
    if (checking) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (available == null) {
      return null;
    }
    return Icon(
      available ? Icons.check_circle_outline : Icons.error_outline,
      color: available ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
    );
  }

  Color _messageColor(bool? available, bool checking) {
    if (checking) return const Color(0xFF2563EB);
    if (available == true) return const Color(0xFF16A34A);
    if (available == false) return const Color(0xFFDC2626);
    return const Color(0xFF64748B);
  }

  Widget _buildRegisterButton(bool isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : _handleRegister,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 54),
        backgroundColor: Colors.blueAccent,
        elevation: 2,
        shadowColor: Colors.blueAccent.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
              '注册',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildFooterText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('已有账号？', style: TextStyle(color: Colors.grey[600])),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            '立即登录',
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
