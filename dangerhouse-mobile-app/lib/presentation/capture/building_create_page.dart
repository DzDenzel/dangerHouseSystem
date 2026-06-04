import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../core/providers/network_providers.dart';
import '../../core/utils/common_utils.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/building_models.dart';

class BuildingCreatePage extends ConsumerStatefulWidget {
  const BuildingCreatePage({super.key});

  @override
  ConsumerState<BuildingCreatePage> createState() => _BuildingCreatePageState();
}

class _BuildingCreatePageState extends ConsumerState<BuildingCreatePage> {
  final _formKey = GlobalKey<FormState>();
  
  // 表单控制器
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _areaController = TextEditingController();
  final _buildYearController = TextEditingController();
  final _floorCountController = TextEditingController();
  final _descController = TextEditingController();

  // 下拉选择值
  String _structureType = '砖混结构';
  String _initialRiskLevel = '待评定（默认）';

  // 图片相关
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  bool _isSaving = false;
  bool _isSaved = false;

  final List<String> _structureTypes = [
    '砖混结构',
    '钢筋混凝土',
    '钢结构',
    '砖木结构',
    '其他',
  ];

  final List<String> _riskLevels = [
    '待评定（默认）',
    'A级 - 无危险点',
    'B级 - 有危险点',
    'C级 - 局部危房',
    'D级 - 整幢危房',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _areaController.dispose();
    _buildYearController.dispose();
    _floorCountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _selectedImage = image;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '选择建筑图片',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: '拍照',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildImageSourceOption(
                    icon: Icons.photo_library,
                    label: '相册',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF2F80ED).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: const Color(0xFF2F80ED)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Future<String?> _uploadImage(int buildingId) async {
    if (_selectedImage == null) return null;

    try {
      final dioClient = ref.read(dioClientProvider);
      final dio = dioClient.dio;
      final bytes = await _selectedImage!.readAsBytes();
      final fileName = _selectedImage!.name;

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final response = await dio.post(
        '${ApiConstants.buildings}/$buildingId/image',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final code = data['code'] as int?;
        if (code == null || code == 0 || code == 200) {
          final imagePath = data['data'];
          if (imagePath is String && imagePath.isNotEmpty) {
            return imagePath;
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(buildingRepositoryProvider);

      String structureTypeCode = Building.structureTypeReverseMap[_structureType] ?? 'OTHER';

      final newBuilding = await repository.createBuilding(CreateBuildingRequest(
        name: _nameController.text,
        address: _addressController.text,
        structureType: structureTypeCode,
        buildYear: int.tryParse(_buildYearController.text),
        floorCount: int.tryParse(_floorCountController.text),
        area: double.tryParse(_areaController.text),
        ownerName: _ownerNameController.text.isEmpty ? null : _ownerNameController.text,
        ownerPhone: _ownerPhoneController.text.isEmpty ? null : _ownerPhoneController.text,
        description: _descController.text.isEmpty ? null : _descController.text,
        imagePath: null,
      ));

      Building? finalBuilding = newBuilding;
      if (newBuilding != null && _selectedImage != null) {
        final imagePath = await _uploadImage(newBuilding.id);
        if (imagePath == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('建筑已创建，但图片上传失败，请稍后重试')),
          );
        } else {
          finalBuilding =
              await repository.getBuildingById(newBuilding.id) ??
              newBuilding.copyWith(imagePath: imagePath);
        }
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSaved = finalBuilding != null;
        });

        if (finalBuilding != null) {
          // 延迟返回，让用户看到成功动画
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) Navigator.pop(context, finalBuilding);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('创建失败，请重试')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发生错误: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '新增建筑档案',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildSection(
                    title: '基本信息',
                    children: [
                      _buildImagePicker(),
                      _buildTextField(
                        controller: _nameController,
                        label: '建筑名称',
                        hint: '例如：朝阳区花园小区3号楼',
                        isRequired: true,
                      ),
                      _buildTextField(
                        controller: _addressController,
                        label: '详细地址',
                        hint: '省市区 + 详细门牌号',
                        isRequired: true,
                        suffixIcon: Icons.location_on_outlined,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: '结构类型',
                              value: _structureType,
                              items: _structureTypes,
                              onChanged: (val) => setState(() => _structureType = val!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _buildYearController,
                              label: '建造年份',
                              hint: 'YYYY',
                              keyboardType: TextInputType.number,
                              validator: FormValidators.validateBuildYear,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _floorCountController,
                              label: '建筑层数',
                              hint: '如：6',
                              keyboardType: TextInputType.number,
                              validator: FormValidators.validateFloorCount,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Spacer(),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: '产权信息',
                    children: [
                      _buildTextField(
                        controller: _ownerNameController,
                        label: '产权人/单位',
                        hint: '姓名或单位全称',
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _ownerPhoneController,
                              label: '联系电话',
                              hint: '手机或座机',
                              keyboardType: TextInputType.phone,
                              validator: FormValidators.validatePhone,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _areaController,
                              label: '建筑面积',
                              hint: '㎡',
                              keyboardType: TextInputType.number,
                              suffixText: '㎡',
                              validator: FormValidators.validateArea,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: '检测设置',
                    children: [
                      _buildDropdown(
                        label: '初始危险评级',
                        value: _initialRiskLevel,
                        items: _riskLevels,
                        onChanged: (val) => setState(() => _initialRiskLevel = val!),
                      ),
                      _buildTextField(
                        controller: _descController,
                        label: '备注说明',
                        hint: '可补充建筑现状、历史检测情况、特殊注意事项等...',
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F80ED).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2F80ED).withValues(alpha: 0.15)),
                    ),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), height: 1.5),
                        children: [
                          TextSpan(
                            text: '提示：',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2F80ED)),
                          ),
                          TextSpan(text: '档案创建后可在建筑列表中对此建筑发起 AI 检测，检测结果将自动关联至该档案。'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFFF5F7FA),
                    const Color(0xFFF5F7FA).withValues(alpha: 0.95),
                    const Color(0xFFF5F7FA).withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: (_isSaving || _isSaved) ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSaved ? const Color(0xFF27AE60) : const Color(0xFF2F80ED),
                    foregroundColor: Colors.white,
                    elevation: _isSaved ? 0 : 4,
                    shadowColor: const Color(0xFF2F80ED).withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSaved) ...[
                        const Icon(Icons.check_circle, size: 20),
                        const SizedBox(width: 8),
                        const Text('档案已创建', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ] else ...[
                        if (_isSaving)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        else
                          const Icon(Icons.save, size: 20),
                        const SizedBox(width: 8),
                        Text(_isSaving ? '保存中...' : '保存建筑档案',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F80ED),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children.expand((child) => [child, const SizedBox(height: 12)]).take(children.length * 2 - 1),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    IconData? suffixIcon,
    String? suffixText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7280),
              ),
            ),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Color(0xFFFF4D4F), fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
          validator: validator ?? (isRequired ? (val) => FormValidators.validateRequired(val, label: label) : null),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFF2F80ED).withValues(alpha: 0.3), width: 2),
            ),
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, size: 16, color: const Color(0xFF2F80ED))
                : null,
            suffixText: suffixText,
            suffixStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '建筑图片',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedImage != null 
                    ? const Color(0xFF2F80ED).withValues(alpha: 0.3)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: _selectedImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: kIsWeb
                            ? FutureBuilder(
                                future: _selectedImage!.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Image.memory(
                                      snapshot.data!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                },
                              )
                            : Image.file(
                                File(_selectedImage!.path),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImage = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 32,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '点击上传建筑图片',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              focusColor: Colors.transparent, // 去除焦点背景色
              icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF6B7280)),
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
              onChanged: onChanged,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
