import 'dart:typed_data';
import 'package:dangerhouse_app/data/models/auth_models.dart';
import 'package:dangerhouse_app/providers/auth_provider.dart';
import 'package:dangerhouse_app/core/providers/network_providers.dart';
import 'package:dangerhouse_app/core/utils/common_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class UserInfoEditPage extends ConsumerStatefulWidget {
  final LoginResponse user;

  const UserInfoEditPage({super.key, required this.user});

  @override
  ConsumerState<UserInfoEditPage> createState() => _UserInfoEditPageState();
}

class _UserInfoEditPageState extends ConsumerState<UserInfoEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController _nicknameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  String? _avatarUrl;
  XFile? _selectedAvatar;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.user.nickname ?? '');
    _phoneController = TextEditingController(text: widget.user.phone);
    _emailController = TextEditingController(text: widget.user.email);
    _avatarUrl = widget.user.avatar;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).refreshUserInfo().then((_) {
        if (mounted) {
          final newUser = ref.read(authNotifierProvider).data;
          if (newUser != null) {
            setState(() {
              _nicknameController.text = newUser.nickname ?? '';
              _phoneController.text = newUser.phone ?? '';
              _emailController.text = newUser.email ?? '';
              _avatarUrl = newUser.avatar;
            });
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedAvatar = image;
        _isUploadingAvatar = true;
      });

      final authRepository = ref.read(authRepositoryProvider);
      final bytes = await image.readAsBytes();
      final fileName = image.name;
      final avatarUrl = await authRepository.uploadAvatar(bytes, fileName);

      if (mounted) {
        if (avatarUrl != null) {
          setState(() {
            _avatarUrl = avatarUrl;
            _isUploadingAvatar = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('头像上传成功'),
              backgroundColor: Color(0xFF27AE60),
            ),
          );
        } else {
          setState(() {
            _selectedAvatar = null;
            _isUploadingAvatar = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('头像上传失败，请重试'),
              backgroundColor: Color(0xFFFF4D4F),
            ),
          );
        }
      }
    }
  }

  void _handleSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      final request = UpdateUserRequest(
        nickname: _nicknameController.text,
        username: widget.user.username,
        phone: _phoneController.text,
        email: _emailController.text,
        avatar: _avatarUrl,
      );

      final success = await ref.read(authNotifierProvider.notifier).updateProfile(request);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('个人信息修改成功'),
              backgroundColor: Color(0xFF27AE60),
            ),
          );
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        } else {
          final error = ref.read(authNotifierProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? '修改失败，请重试'),
              backgroundColor: const Color(0xFFFF4D4F),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildAvatarSection(),
                  const SizedBox(height: 24),
                  _buildFormCard(),
                  const SizedBox(height: 20),
                  _buildVerificationAlert(),
                ],
              ),
            ),
          ),
          _buildSaveButton(isLoading),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => Navigator.pop(context),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                ),
                icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF374151)),
              ),
              const Expanded(
                child: Text(
                  '编辑个人信息',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    final displayName = _nicknameController.text.isNotEmpty ? _nicknameController.text : (widget.user.username ?? '用户');

    return Column(
      children: [
        GestureDetector(
          onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _isUploadingAvatar
                      ? Container(
                          color: Colors.blueGrey.shade100,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _selectedAvatar != null
                          ? FutureBuilder<Uint8List>(
                              future: _selectedAvatar!.readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Image.memory(snapshot.data!, fit: BoxFit.cover);
                                }
                                return Container(
                                  color: Colors.blueGrey.shade100,
                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                );
                              },
                            )
                          : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                              ? Image.network(
                                  ImageUtils.getFullImageUrl(_avatarUrl!) ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(displayName),
                                )
                              : _buildAvatarPlaceholder(displayName),
                ),
              ),
              Positioned(
                right: -8,
                bottom: -8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F80ED),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2F80ED).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _isUploadingAvatar ? '上传中...' : '点击修改头像',
          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder(String displayName) {
    return Container(
      color: Colors.blueGrey.shade100,
      child: Center(
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 28,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF9FAFB)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildReadOnlyField(
              value: widget.user.username ?? '',
              label: '用户名',
              icon: Icons.account_circle_outlined,
            ),
            const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 52, endIndent: 20),
            _buildInputField(
              controller: _nicknameController,
              label: '昵称',
              icon: Icons.person_outline,
            ),
            const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 52, endIndent: 20),
            _buildInputField(
              controller: _phoneController,
              label: '手机号码',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 52, endIndent: 20),
            _buildInputField(
              controller: _emailController,
              label: '电子邮箱',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value.isEmpty ? '-' : value,
                  style: TextStyle(
                    fontSize: 13,
                    color: value.isEmpty ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
                  decoration: InputDecoration(
                    hintText: '请输入$label',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  validator: (value) {
                    if (label == '手机号码') {
                      if (value == null || value.isEmpty) {
                        return '请输入手机号';
                      }
                      if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
                        return '请输入正确的11位手机号';
                      }
                    }
                    if (label == '电子邮箱') {
                      if (value == null || value.isEmpty) {
                        return '请输入邮箱';
                      }
                      if (!RegExp(r"^\S+@\S+\.\S+$").hasMatch(value)) {
                        return '请输入有效的邮箱地址';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationAlert() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF27AE60).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF27AE60).withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF27AE60)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '您的账号已通过政府专员实名认证，修改信息可能需要重新审核。',
              style: TextStyle(
                fontSize: 11,
                color: const Color(0xFF27AE60).withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isLoading) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: isLoading ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2F80ED),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF2F80ED).withValues(alpha: 0.7),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            shadowColor: const Color(0xFF2F80ED).withValues(alpha: 0.3),
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
                  '保存修改',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
