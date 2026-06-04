import 'package:flutter/material.dart';
import '../../data/models/detection_models.dart';
import 'dart:ui' as ui;

class DetectionPainter extends CustomPainter {
  final List<CrackDto> cracks;
  final ui.Image image; // 传入原始图片用于计算比例

  DetectionPainter({
    required this.cracks,
    required this.image,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 计算缩放比例：Canvas Size / Image Size
    // 假设图片是 fitWidth 或者 fitHeight，这里需要根据实际的显示方式来计算
    // 简单的 fit: BoxFit.contain 逻辑
    double scaleX = size.width / image.width;
    double scaleY = size.height / image.height;
    
    // 如果是 BoxFit.contain，取较小的 scale
    double scale = scaleX < scaleY ? scaleX : scaleY;

    // 计算偏移量，使图片居中
    double offsetX = (size.width - image.width * scale) / 2;
    double offsetY = (size.height - image.height * scale) / 2;

    // 保存画布状态
    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    for (var crack in cracks) {
      // 假设 bbox 格式为 [x1, y1, x2, y2]
      if (crack.bbox != null && crack.bbox!.length >= 4) {
        final rect = Rect.fromLTRB(
          crack.bbox![0],
          crack.bbox![1],
          crack.bbox![2],
          crack.bbox![3],
        );
        canvas.drawRect(rect, paint);

        // 绘制置信度
        if (crack.confidence != null) {
          textPainter.text = TextSpan(
            text: '${(crack.confidence! * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              backgroundColor: Colors.red,
            ),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(rect.left, rect.top - 16));
        }
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
