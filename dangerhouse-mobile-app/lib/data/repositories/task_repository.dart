import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../core/errors/error_handler.dart';
import '../../core/utils/risk_level_util.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/detection_report.dart';
import '../models/detection_models.dart';

class TaskRepository {
  final DioClient _dioClient;

  TaskRepository(this._dioClient);

  Future<List<Task>> getTasks({
    int page = 1,
    int size = 20,
    String? status,
    String? riskLevel,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
        'sort': 'detectTime,desc',
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      if (riskLevel != null && riskLevel.isNotEmpty) {
        queryParams['riskLevel'] = riskLevel;
      }

      AppLogger.api('GET', ApiConstants.taskList, queryParams);

      return _dioClient.parseResponseList(
        await _dioClient.dio.get(ApiConstants.taskList, queryParameters: queryParams),
        Task.fromJson,
      );
    } catch (e) {
      AppLogger.e('获取任务列表失败', e);
      return [];
    }
  }

  Future<DetectionReport> getDetectionReport(int taskId) async {
    try {
      AppLogger.api('GET', '${ApiConstants.detection}/$taskId');

      final response = await _dioClient.dio.get('${ApiConstants.detection}/$taskId');

      final responseData = response.data;

      if (responseData is Map) {
        final code = responseData['code'];
        final message = responseData['message'];

        if (code != 200) {
          throw Exception(message ?? '检测任务不存在');
        }

        final data = responseData['data'];
        if (data != null) {
          final dto = DetectionResultDto.fromJson(data);
          return _convertDtoToReport(dto);
        }
      }

      throw Exception('检测报告数据为空');
    } on DioException catch (e) {
      final errorMsg = ErrorHandler.getErrorMessage(e, defaultMsg: '获取检测报告详情失败');
      AppLogger.e('获取检测报告详情失败', e);
      throw Exception(errorMsg);
    } catch (e) {
      AppLogger.e('获取检测报告详情失败', e);
      rethrow;
    }
  }

  Future<Map<String, int>?> generateReport({
    required int detectionId,
    String format = 'PDF',
  }) async {
    try {
      AppLogger.api('POST', ApiConstants.reportGenerate);

      final response = await _dioClient.dio.post(
        ApiConstants.reportGenerate,
        data: {
          'detectionId': detectionId,
          'format': format,
        },
      );

      if (_dioClient.isSuccessResponse(response)) {
        final data = response.data['data'];
        return {'reportId': data['reportId']};
      }
      return null;
    } catch (e) {
      AppLogger.e('生成报告失败', e);
      return null;
    }
  }

  Future<String?> downloadReport(int reportId) async {
    try {
      AppLogger.api('GET', '${ApiConstants.reports}/$reportId/download');

      final response = await _dioClient.dio.get(
        '${ApiConstants.reports}/$reportId/download',
      );

      if (_dioClient.isSuccessResponse(response)) {
        return response.data['data'] as String?;
      }
      return null;
    } catch (e) {
      AppLogger.e('下载报告失败', e);
      return null;
    }
  }

  DetectionReport _convertDtoToReport(DetectionResultDto dto) {
    final riskTitle = RiskLevelUtil.getTitle(dto.riskLevel);
    final riskDescription = RiskLevelUtil.getReportDescription(dto.riskLevel);

    List<String> imageUrls = [];
    if (dto.resultDetails != null && dto.resultDetails!.cracks != null) {
      for (var crack in dto.resultDetails!.cracks!) {
        if (crack.bbox != null && crack.bbox!.isNotEmpty) {
          imageUrls.add('https://picsum.photos/200/200?random=${crack.bbox![0].toInt()}');
        }
      }
    }

    List<RectificationSuggestion> suggestions = [];
    if (dto.riskLevel == 'C' || dto.riskLevel == 'D' ||
        dto.riskLevel == 'HIGH' || dto.riskLevel == 'CRITICAL') {
      suggestions.add(RectificationSuggestion(
        title: '设置警戒围栏',
        description: '围绕检测区域设置警戒范围，建议距离不少于5米。',
        iconType: 'fence',
      ));
      suggestions.add(RectificationSuggestion(
        title: '专业加固处理',
        description: '建议委托专业结构工程师进行鉴定并制定加固方案。',
        iconType: 'grouting',
      ));
    } else if (dto.riskLevel == 'B' || dto.riskLevel == 'MEDIUM') {
      suggestions.add(RectificationSuggestion(
        title: '加强监测',
        description: '建议定期复查，关注损伤发展趋势。',
        iconType: 'monitor',
      ));
    } else {
      suggestions.add(RectificationSuggestion(
        title: '常规维护',
        description: '保持现有维护状态，定期检查即可。',
        iconType: 'maintenance',
      ));
    }

    return DetectionReport(
      id: dto.id,
      taskId: dto.id,
      riskLevel: dto.riskLevel ?? 'UNKNOWN',
      riskTitle: riskTitle,
      riskDescription: riskDescription,
      maxWidth: dto.resultDetails?.maxWidth ?? 0.0,
      totalLength: (dto.resultDetails?.totalCracks ?? 0) * 10.0,
      morphology: _getMorphology(dto.riskLevel),
      images: imageUrls.isNotEmpty ? imageUrls : _getDefaultImages(),
      suggestions: suggestions,
    );
  }

  String _getMorphology(String? riskLevel) {
    switch (riskLevel?.toUpperCase()) {
      case 'D':
      case 'CRITICAL':
        return '贯穿性裂缝';
      case 'C':
      case 'HIGH':
        return '斜向裂缝';
      case 'B':
      case 'MEDIUM':
        return '细微裂缝';
      default:
        return '无明显裂缝';
    }
  }

  List<String> _getDefaultImages() {
    return [
      'https://picsum.photos/200/200?random=1',
      'https://picsum.photos/200/200?random=2',
      'https://picsum.photos/200/200?random=3',
    ];
  }
}
