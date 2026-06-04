import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/entities/task.dart';
import 'camera_grid_painter.dart';

class CaptureActivity extends ConsumerStatefulWidget {
  final Task? task;

  const CaptureActivity({super.key, this.task});

  @override
  ConsumerState<CaptureActivity> createState() => _CaptureActivityState();
}

class _CaptureActivityState extends ConsumerState<CaptureActivity> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  FlashMode _flashMode = FlashMode.off;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 处理应用生命周期变化，释放/重新初始化相机
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    // 请求相机权限
    var status = await Permission.camera.request();
    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要相机权限来进行拍照')),
        );
      }
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // 默认选择第一个后置摄像头
        final camera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );
        
        _controller = CameraController(
          camera,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: defaultTargetPlatform == TargetPlatform.android 
              ? ImageFormatGroup.jpeg 
              : ImageFormatGroup.bgra8888,
        );

        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('相机初始化失败: $e')),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _controller == null || _controller!.value.isTakingPicture) {
      return;
    }

    try {
      final XFile file = await _controller!.takePicture();
      _handleImage(file);
    } catch (e) {
      debugPrint('拍照失败: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        _handleImage(image);
      }
    } catch (e) {
      debugPrint('相册选择失败: $e');
    }
  }

  // 移除 _showUploadConfirmDialog 和 _uploadAndDetect 方法，改为仅返回文件
  void _handleImage(XFile imageFile) async {
    final shouldReturn = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认图片'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<Uint8List>(
              future: imageFile.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Image.memory(snapshot.data!, height: 200, fit: BoxFit.cover);
                }
                return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
              },
            ),
            const SizedBox(height: 16),
            const Text('是否使用此照片？'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('重拍'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('使用'),
          ),
        ],
      ),
    );

    if (shouldReturn == true && mounted) {
      Navigator.pop(context, imageFile);
    }
  }

  void _toggleFlash() {
    if (_controller != null) {
      setState(() {
        _flashMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
      });
      _controller!.setFlashMode(_flashMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. 相机预览层
            Center(
              child: CameraPreview(_controller!),
            ),
            
            // 2. 网格辅助线层
            Positioned.fill(
              child: CustomPaint(
                painter: CameraGridPainter(),
              ),
            ),

            // 3. 顶部操作栏
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 关闭按钮
                  _buildCircleButton(
                    icon: Icons.close,
                    onTap: () => Navigator.pop(context),
                  ),
                  // 闪光灯按钮
                  _buildCircleButton(
                    icon: _flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
                    color: _flashMode == FlashMode.off ? Colors.white : Colors.yellow,
                    onTap: _toggleFlash,
                  ),
                ],
              ),
            ),

            // 4. 底部提示文字
            Positioned(
              bottom: 160,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fullscreen, color: Colors.blueAccent, size: 16),
                      SizedBox(width: 8),
                      Text(
                        '长按拍照',
                        style: TextStyle(color: Colors.blueAccent, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 5. 底部操作区 (快门与相册)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 相册入口
                  GestureDetector(
                    onTap: _pickImage,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 4),
                        const Text('相册上传', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ],
                    ),
                  ),

                  // 快门按钮
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 80,
                      height: 80,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                  // 占位 (保持居中)
                  const SizedBox(width: 60), 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
