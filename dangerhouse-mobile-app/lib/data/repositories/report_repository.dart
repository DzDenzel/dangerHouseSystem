import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/error_handler.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/common_utils.dart';
import '../models/report_models.dart';

class ReportRepository {
  final DioClient _dioClient;

  ReportRepository(this._dioClient);

  Future<ReportGenerateResponse?> generateReport({
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

      return _dioClient.parseResponseData(response, ReportGenerateResponse.fromJson);
    } on DioException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e, defaultMsg: '鎶ュ憡鐢熸垚澶辫触'));
    } catch (e) {
      throw Exception('鎶ュ憡鐢熸垚澶辫触: $e');
    }
  }

  Future<ReportDto?> getReport(int reportId) async {
    try {
      AppLogger.api('GET', '${ApiConstants.reports}/$reportId');

      final response = await _dioClient.dio.get('${ApiConstants.reports}/$reportId');

      return _dioClient.parseResponseData(response, ReportDto.fromJson);
    } on DioException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e, defaultMsg: '鑾峰彇鎶ュ憡璇︽儏澶辫触'));
    } catch (e) {
      throw Exception('鑾峰彇鎶ュ憡璇︽儏澶辫触: $e');
    }
  }

  Future<String?> getDownloadUrl(int reportId) async {
    try {
      AppLogger.api('GET', '${ApiConstants.reports}/$reportId/download');

      final response = await _dioClient.dio.get(
        '${ApiConstants.reports}/$reportId/download',
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('data')) {
          final dataMap = data['data'] as Map<String, dynamic>;
          return dataMap['downloadUrl'] as String?;
        }
        return data['downloadUrl'] as String?;
      }
      return null;
    } on DioException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e, defaultMsg: '鑾峰彇涓嬭浇閾炬帴澶辫触'));
    } catch (e) {
      throw Exception('鑾峰彇涓嬭浇閾炬帴澶辫触: $e');
    }
  }

  Future<Uint8List?> downloadReport(
    int reportId, {
    String? downloadUrl,
    Function(int received, int total)? onProgress,
  }) async {
    try {
      AppLogger.api('GET', '${ApiConstants.reports}/$reportId/download');

      final response = await _dioClient.dio.get(
        '${ApiConstants.reports}/$reportId/download',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': 'application/pdf, application/json'},
        ),
        onReceiveProgress: onProgress,
      );

      final responseBytes = _toBytes(response.data);
      final contentType = response.headers.value(Headers.contentTypeHeader) ?? '';

      if (_isJsonPayload(contentType, responseBytes)) {
        final resolvedDownloadUrl = _extractDownloadUrlFromBytes(responseBytes);
        final fullDownloadUrl = ImageUtils.getFullFileUrl(resolvedDownloadUrl);
        if (fullDownloadUrl != null) {
          AppLogger.api('GET', fullDownloadUrl);
          return await _downloadFileFromUrl(
            fullDownloadUrl,
            onProgress: onProgress,
          );
        }
      }

      if (responseBytes != null && responseBytes.isNotEmpty) {
        return responseBytes;
      }

      final directDownloadUrl = ImageUtils.getFullFileUrl(downloadUrl);
      if (directDownloadUrl != null) {
        AppLogger.api('GET', directDownloadUrl);
        return await _downloadFileFromUrl(
          directDownloadUrl,
          onProgress: onProgress,
        );
      }

      return responseBytes;
    } on DioException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e, defaultMsg: '涓嬭浇鎶ュ憡澶辫触'));
    } catch (e) {
      throw Exception('涓嬭浇鎶ュ憡澶辫触: $e');
    }
  }

  Future<Uint8List?> _downloadFileFromUrl(
    String url, {
    Function(int received, int total)? onProgress,
  }) async {
    final response = await _dioClient.dio.get(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Accept': 'application/pdf, application/octet-stream'},
      ),
      onReceiveProgress: onProgress,
    );

    return _toBytes(response.data);
  }

  Uint8List? _toBytes(dynamic data) {
    if (data is Uint8List) {
      return data;
    }
    if (data is List<int>) {
      return Uint8List.fromList(data);
    }
    if (data is String) {
      return Uint8List.fromList(utf8.encode(data));
    }
    return null;
  }

  bool _isJsonPayload(String contentType, Uint8List? bytes) {
    if (contentType.contains('application/json') || contentType.contains('text/json')) {
      return true;
    }
    if (bytes == null || bytes.isEmpty) {
      return false;
    }

    final firstChar = String.fromCharCode(bytes.first).trim();
    return firstChar == '{' || firstChar == '[';
  }

  String? _extractDownloadUrlFromBytes(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(utf8.decode(bytes)) as Object?;
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final directUrl = decoded['downloadUrl'];
    if (directUrl is String && directUrl.isNotEmpty) {
      return directUrl;
    }

    final nestedData = decoded['data'];
    if (nestedData is Map<String, dynamic>) {
      final nestedDownloadUrl = nestedData['downloadUrl'];
      if (nestedDownloadUrl is String && nestedDownloadUrl.isNotEmpty) {
        return nestedDownloadUrl;
      }
    }

    return null;
  }

  Future<List<ReportDto>> getReports({
    int page = 0,
    int size = 20,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      AppLogger.api('GET', ApiConstants.reports, queryParams);

      return _dioClient.parseResponseList(
        await _dioClient.dio.get(ApiConstants.reports, queryParameters: queryParams),
        ReportDto.fromJson,
      );
    } on DioException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e, defaultMsg: '鑾峰彇鎶ュ憡鍒楄〃澶辫触'));
    } catch (e) {
      throw Exception('鑾峰彇鎶ュ憡鍒楄〃澶辫触: $e');
    }
  }
}
