import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/providers/network_providers.dart';
import '../../core/utils/common_utils.dart' as app_utils;
import '../../core/utils/risk_level_util.dart';
import '../../core/utils/service_error_message.dart';
import '../../core/utils/web_report_download.dart';
import '../../data/models/building_models.dart';
import '../../data/models/detection_models.dart';
import '../../domain/entities/task.dart';
import '../../providers/refresh_notifier.dart';
import '../capture/ai_detection_page.dart';

class ReportDetailPage extends ConsumerStatefulWidget {
  final Task? task;
  final int? detectionId;

  const ReportDetailPage({
    super.key,
    this.task,
    this.detectionId,
  });

  @override
  ConsumerState<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends ConsumerState<ReportDetailPage> {
  final PageController _imagePageController = PageController();

  DetectionResultDto? _detail;
  Building? _building;
  bool _isLoading = true;
  bool _isExporting = false;
  bool _isStartingDetection = false;
  bool _isLoadingImages = false;
  double _downloadProgress = 0;
  String? _errorMessage;

  int _activeImageIndex = 0;
  List<Uint8List> _imageFrames = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final id = widget.detectionId ?? widget.task?.id;
      if (id == null) {
        throw Exception('无效的检测记录');
      }

      final repo = ref.read(detectionRepositoryProvider);
      final detail = await repo.getDetectionDetail(id);
      if (detail == null) {
        throw Exception('未找到检测记录');
      }

      Building? building;
      if (detail.buildingId != null) {
        final buildingRepo = ref.read(buildingRepositoryProvider);
        building = await buildingRepo.getBuildingById(detail.buildingId!);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _detail = detail;
        _building = building;
        _isLoading = false;
      });

      await _loadImages(detail);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = ServiceErrorMessage.forDetection(e.toString());
      });
    }
  }

  Future<void> _loadImages(DetectionResultDto detail) async {
    final candidates = detail.resolvedImages
        .where((image) =>
            (image.fullResultImagePath?.isNotEmpty ?? false) ||
            (image.fullImagePath?.isNotEmpty ?? false))
        .toList();
    if (candidates.isEmpty) {
      return;
    }

    setState(() => _isLoadingImages = true);

    try {
      final dio = ref.read(dioClientProvider).dio;
      final frames = <Uint8List>[];
      for (final image in candidates) {
        final url = image.fullResultImagePath ?? image.fullImagePath;
        if (url == null || url.isEmpty) {
          continue;
        }
        final response = await dio.get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        final data = response.data;
        if (data != null && data.isNotEmpty) {
          frames.add(Uint8List.fromList(data));
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _imageFrames = frames;
        _activeImageIndex = 0;
        _isLoadingImages = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingImages = false);
      }
    }
  }

  Future<void> _handleExportPDF() async {
    final detail = _detail;
    if (detail == null || _isExporting) {
      return;
    }

    setState(() {
      _isExporting = true;
      _downloadProgress = 0;
    });

    try {
      final reportRepo = ref.read(reportRepositoryProvider);
      final existingReport = detail.report;
      final generateResponse = existingReport?.id != null
          ? null
          : await reportRepo.generateReport(
              detectionId: detail.id,
              format: 'PDF',
            );

      final reportId = existingReport?.id ?? generateResponse?.reportId;
      final reportNo = existingReport?.reportNo ??
          generateResponse?.reportNo ??
          'RPT_${detail.id}';
      final directDownloadUrl = app_utils.ImageUtils.getFullFileUrl(
            existingReport?.filePath ?? generateResponse?.downloadUrl,
          ) ??
          (reportId != null ? await reportRepo.getDownloadUrl(reportId) : null);

      if (reportId == null) {
        throw Exception('报告生成失败');
      }

      setState(() => _downloadProgress = 0.1);

      if (kIsWeb) {
        if (directDownloadUrl == null || directDownloadUrl.isEmpty) {
          throw Exception('未获取到可用的报告下载地址');
        }

        final opened = await openReportDownloadUrl(
          directDownloadUrl,
          fileName: '$reportNo.pdf',
        );

        if (!opened) {
          throw Exception('浏览器未能打开报告下载链接');
        }

        if (!mounted) {
          return;
        }

        setState(() {
          _isExporting = false;
          _downloadProgress = 1;
        });

        ref.read(refreshNotifierProvider.notifier).notifyDetectionUpdated(
              detectionId: detail.id,
            );
        ref.read(refreshNotifierProvider.notifier).notifyRefreshAll();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF 报告已在浏览器中打开，请继续下载')),
        );
        return;
      }

      final bytes = await reportRepo.downloadReport(
        reportId,
        downloadUrl: directDownloadUrl,
        onProgress: (received, total) {
          if (!mounted || total <= 0) {
            return;
          }
          setState(() {
            _downloadProgress = 0.1 + (received / total) * 0.8;
          });
        },
      );

      if (bytes == null || bytes.isEmpty) {
        throw Exception('报告下载失败');
      }

      final path = await _savePdfToFile(bytes, reportNo);
      if (!mounted) {
        return;
      }

      setState(() {
        _isExporting = false;
        _downloadProgress = 1;
      });

      ref.read(refreshNotifierProvider.notifier).notifyDetectionUpdated(
            detectionId: detail.id,
          );
      ref.read(refreshNotifierProvider.notifier).notifyRefreshAll();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF 报告已保存至: $path')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ServiceErrorMessage.forReport(e.toString()))),
      );
    }
  }

  Future<void> _handleStartDetection() async {
    final detail = _detail;
    if (detail == null || _isStartingDetection) {
      return;
    }

    setState(() {
      _isStartingDetection = true;
      _isLoading = true;
    });

    try {
      final latest =
          await ref.read(detectionRepositoryProvider).startDetection(detail.id);
      if (latest == null) {
        throw Exception('检测任务启动失败，请稍后重试');
      }

      if (!mounted) {
        return;
      }

      setState(() => _detail = latest);
      await _loadData();
      if (!mounted) {
        return;
      }

      ref.read(refreshNotifierProvider.notifier).notifyDetectionUpdated(
            detectionId: detail.id,
          );
      ref.read(refreshNotifierProvider.notifier).notifyRefreshAll();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('检测任务已提交，请稍后手动刷新状态')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ServiceErrorMessage.forDetection(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() => _isStartingDetection = false);
      }
    }
  }

  Future<String> _savePdfToFile(Uint8List bytes, String reportNo) async {
    final fileName =
        'Report_${reportNo}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    if (Platform.isAndroid) {
      const publicBaseDir = '/storage/emulated/0/Download';
      final publicReportsDir = Directory('$publicBaseDir/DangerHouseReports');

      try {
        await Permission.storage.request();
        await Permission.manageExternalStorage.request();
        if (!await publicReportsDir.exists()) {
          await publicReportsDir.create(recursive: true);
        }
        final publicFile = File('${publicReportsDir.path}/$fileName');
        await publicFile.writeAsBytes(bytes, flush: true);
        return publicFile.path;
      } catch (_) {
        final appDir = await getApplicationDocumentsDirectory();
        final fallbackDir = Directory('${appDir.path}/DangerHouseReports');
        if (!await fallbackDir.exists()) {
          await fallbackDir.create(recursive: true);
        }
        final fallbackFile = File('${fallbackDir.path}/$fileName');
        await fallbackFile.writeAsBytes(bytes, flush: true);
        return fallbackFile.path;
      }
    }

    final appDir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory('${appDir.path}/DangerHouseReports');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    final file = File('${reportsDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('加载中...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('检测报告')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Color(0xFFEF4444)),
              const SizedBox(height: 16),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    final detail = _detail!;
    final riskColor = RiskLevelUtil.getColor(detail.resolvedRiskLevel);
    final riskLabel = RiskLevelUtil.getLabel(detail.resolvedRiskLevel);
    final buildingName = detail.buildingName ?? '未知建筑';
    final buildingAddress = detail.buildingAddress ?? '';
    final location =
        buildingAddress.isNotEmpty ? '$buildingName / $buildingAddress' : buildingName;
    final detector =
        detail.username?.isNotEmpty == true ? detail.username! : '系统自动检测';
    final suggestions = _buildSuggestions(detail.resolvedRiskLevel);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: 12,
            ),
            child: Row(
              children: [
                IconButton(
                  icon:
                      const Icon(Icons.arrow_back, color: Color(0xFF374151)),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        '建筑损伤检测报告',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '检测编号: ${detail.id}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share,
                      size: 20, color: Color(0xFF6B7280)),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildImageHeader(riskColor),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    color: riskColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI 危险等级评定',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              riskLabel,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                detail.status ?? 'COMPLETED',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          detail.resolvedAnalysis ??
                              RiskLevelUtil.getReportDescription(
                                  detail.resolvedRiskLevel),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildDataCell(
                                '裂缝数量',
                                '${detail.resolvedCrackCount}',
                                '条',
                                riskColor,
                              ),
                              Container(width: 1, height: 40, color: const Color(0xFFF3F4F6)),
                              _buildDataCell(
                                '损伤比例',
                                detail.resolvedDamageRatio.toStringAsFixed(2),
                                '%',
                                const Color(0xFF374151),
                              ),
                              Container(width: 1, height: 40, color: const Color(0xFFF3F4F6)),
                              _buildDataCell(
                                'AI置信度',
                                detail.resolvedConfidence.toStringAsFixed(2),
                                '%',
                                const Color(0xFF27AE60),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
                          ),
                          Row(
                            children: [
                              _buildDataCell(
                                '裂缝最大宽度',
                                detail.resolvedMaxWidth.toStringAsFixed(1),
                                'mm',
                                riskColor,
                              ),
                              Container(width: 1, height: 40, color: const Color(0xFFF3F4F6)),
                              _buildDataCell(
                                '延伸总长',
                                (detail.resolvedTotalCracks * 10).toStringAsFixed(0),
                                'cm',
                                const Color(0xFF374151),
                              ),
                              Container(width: 1, height: 40, color: const Color(0xFFF3F4F6)),
                              _buildDataCell(
                                '结果图片',
                                '${detail.resolvedImages.length}',
                                '张',
                                const Color(0xFF2F80ED),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.place_outlined, '检测地点', location),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.access_time_outlined,
                            '检测时间',
                            app_utils.DateUtils.formatDateTime(
                              detail.detectTime ?? detail.updatedAt,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.person_outline, '检测人员', detector),
                          if (detail.description?.isNotEmpty == true) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.notes_outlined,
                              '检测备注',
                              detail.description!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            Icons.link_outlined,
                            '绑定用户',
                            _building?.ownerUserId?.toString() ?? '-',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.badge_outlined,
                            '创建角色',
                            _building?.createdByRoleName ??
                                _building?.createdByRole?.toString() ??
                                '-',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.manage_accounts_outlined,
                            '跟进检测员',
                            _building?.assignedInspectorId?.toString() ?? '-',
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(
                            riskColor,
                            'AI 整改建议方案',
                            '${suggestions.length} 项处置建议',
                          ),
                          const SizedBox(height: 14),
                          ...suggestions.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(top: 6),
                                    decoration: BoxDecoration(
                                      color: riskColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF4B5563),
                                        height: 1.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if ((detail.resultDetails?.cracks?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              riskColor,
                              '裂缝明细',
                              '${detail.resultDetails!.cracks!.length} 处识别结果',
                            ),
                            const SizedBox(height: 14),
                            ...detail.resultDetails!.cracks!.map(
                              (crack) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 30,
                                        height: 30,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: riskColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${crack.id ?? '-'}',
                                          style: TextStyle(
                                            color: riskColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '${crack.typeName ?? crack.type ?? '裂缝'} | 框 ${_formatBbox(crack.bbox)} | 中心 ${_formatCenter(crack.center)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF374151),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isExporting) ...[
                  LinearProgressIndicator(value: _downloadProgress.clamp(0.0, 1.0)),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _resolvePrimaryAction(),
                    icon: (_isExporting || _isStartingDetection)
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(_resolvePrimaryIcon()),
                    label: Text(_resolvePrimaryActionText()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _resolvePrimaryActionColor(riskColor),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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

  VoidCallback? _resolvePrimaryAction() {
    final status = _detail?.status?.toUpperCase() ?? '';
    final hasUploadedImages = _detail?.resolvedImages.isNotEmpty == true;

    if (status == 'CREATED' && !hasUploadedImages) {
      return _goToUploadImage;
    }
    if (status == 'READY' && hasUploadedImages) {
      return _isStartingDetection ? null : _handleStartDetection;
    }
    if (status == 'FAILED') {
      return _isStartingDetection ? null : _handleStartDetection;
    }
    return _isExporting ? null : _handleExportPDF;
  }

  String _resolvePrimaryActionText() {
    final status = _detail?.status?.toUpperCase() ?? '';
    final hasUploadedImages = _detail?.resolvedImages.isNotEmpty == true;
    final hasReport = _detail?.report?.id != null;

    if (status == 'CREATED' && !hasUploadedImages) {
      return '上传图片检测';
    }
    if (status == 'READY' && hasUploadedImages) {
      return _isStartingDetection ? '正在启动检测...' : '开始检测';
    }
    if (status == 'FAILED') {
      return _isStartingDetection ? '正在重新提交...' : '重新检测';
    }
    if (status == 'COMPLETED') {
      if (_isExporting) {
        return hasReport ? '正在下载报告...' : '正在生成并下载...';
      }
      return hasReport ? '下载 PDF 正式报告' : '生成并下载 PDF 报告';
    }
    return _isExporting ? '正在下载报告...' : '导出 PDF 正式报告';
  }

  IconData _resolvePrimaryIcon() {
    final status = _detail?.status?.toUpperCase() ?? '';
    final hasUploadedImages = _detail?.resolvedImages.isNotEmpty == true;
    final hasReport = _detail?.report?.id != null;

    if (status == 'CREATED' && !hasUploadedImages) {
      return Icons.add_a_photo;
    }
    if (status == 'READY' && hasUploadedImages) {
      return Icons.play_arrow;
    }
    if (status == 'FAILED') {
      return Icons.refresh;
    }
    if (status == 'COMPLETED') {
      return hasReport ? Icons.download : Icons.description;
    }
    return Icons.download;
  }

  Color _resolvePrimaryActionColor(Color riskColor) {
    final status = _detail?.status?.toUpperCase() ?? '';
    if (status == 'FAILED') {
      return const Color(0xFFE67E22);
    }
    return riskColor;
  }

  Widget _buildImageHeader(Color riskColor) {
    final status = _detail?.status?.toUpperCase() ?? '';
    final hasUploadedImages = _detail?.resolvedImages.isNotEmpty == true;
    final needsUpload = !hasUploadedImages && status == 'CREATED';

    return Container(
      width: double.infinity,
      color: Colors.black,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_isLoadingImages)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white54),
                  )
                else if (_imageFrames.isNotEmpty)
                  PageView.builder(
                    controller: _imagePageController,
                    itemCount: _imageFrames.length,
                    onPageChanged: (index) {
                      setState(() => _activeImageIndex = index);
                    },
                    itemBuilder: (_, index) =>
                        Image.memory(_imageFrames[index], fit: BoxFit.cover),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.image_not_supported,
                          color: Colors.white54,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '暂无检测图片',
                          style: TextStyle(color: Colors.white54),
                        ),
                        if (needsUpload) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _goToUploadImage,
                            icon: const Icon(Icons.add_a_photo),
                            label: const Text('上传图片检测'),
                          ),
                        ],
                      ],
                    ),
                  ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: riskColor, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          _imageFrames.isNotEmpty
                              ? '检测完成 ${_activeImageIndex + 1}/${_imageFrames.length}'
                              : (_detail?.status == 'COMPLETED'
                                  ? '检测完成'
                                  : (_detail?.status ?? '已归档')),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_imageFrames.length > 1)
            Container(
              height: 84,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: const Color(0xFF111827),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _imageFrames.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final active = index == _activeImageIndex;
                  return GestureDetector(
                    onTap: () {
                      _imagePageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active ? const Color(0xFF2F80ED) : Colors.white24,
                          width: active ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.memory(_imageFrames[index], fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataCell(String label, String value, String unit, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: valueColor,
                  ),
                ),
                TextSpan(
                  text: unit,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(Color accentColor, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
        ),
      ],
    );
  }

  Future<void> _goToUploadImage() async {
    if (_detail == null) {
      return;
    }

    final preSelectedBuilding = _detail!.buildingId != null
        ? Building(
            id: _detail!.buildingId!,
            name: _detail!.buildingName ?? '未命名建筑',
            address: _detail!.buildingAddress ?? '',
            structureType: 'OTHER',
            initialRiskLevel: _detail!.resolvedRiskLevel,
          )
        : null;

    final result = await Navigator.push<DetectionResultDto>(
      context,
      MaterialPageRoute(
        builder: (_) => AIDetectionPage(
          preSelectedBuilding: preSelectedBuilding,
          existingDetectionId: _detail!.id,
          returnResultOnSuccess: true,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() => _detail = result);
      await _loadImages(result);
      ref.read(refreshNotifierProvider.notifier).notifyDetectionUpdated(
            detectionId: result.id,
          );
      ref.read(refreshNotifierProvider.notifier).notifyRefreshAll();
    }
  }

  String _formatBbox(List<double>? bbox) {
    if (bbox == null || bbox.length < 4) {
      return '-';
    }
    return '[${bbox[0].toStringAsFixed(0)}, ${bbox[1].toStringAsFixed(0)}, ${bbox[2].toStringAsFixed(0)}, ${bbox[3].toStringAsFixed(0)}]';
  }

  String _formatCenter(List<double>? center) {
    if (center == null || center.length < 2) {
      return '-';
    }
    return '(${center[0].toStringAsFixed(0)}, ${center[1].toStringAsFixed(0)})';
  }

  List<String> _buildSuggestions(String? riskLevel) {
    final level = (riskLevel ?? '').toUpperCase();
    if (level == 'D' || level == 'CRITICAL') {
      return const [
        '立即停止相关区域使用，并设置警戒线或隔离区。',
        '尽快委托专业结构鉴定机构开展现场复核与安全评估。',
        '根据鉴定意见实施紧急加固、卸载或拆除处置。',
      ];
    }
    if (level == 'C' || level == 'HIGH') {
      return const [
        '限制高风险区域使用，尽快安排专项复检。',
        '结合裂缝位置与发展趋势制定局部加固方案。',
        '加密巡检频率，重点跟踪裂缝扩展情况。',
      ];
    }
    if (level == 'B' || level == 'MEDIUM') {
      return const [
        '纳入定期巡检台账，持续跟踪裂缝变化。',
        '必要时开展表层修补、防水或防腐处理。',
        '结合使用年限和环境条件安排阶段性复检。',
      ];
    }
    return const [
      '当前风险总体可控，建议保持常规巡检。',
      '继续做好日常维护和隐患记录。',
      '如发现裂缝扩展或渗漏等异常，应及时复检。',
    ];
  }
}
