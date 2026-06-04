class ServiceErrorMessage {
  ServiceErrorMessage._();

  static String forDetection(String? rawMessage) {
    return _normalize(
      rawMessage,
      unavailableMessage: '检测图片已上传成功，当前识别服务暂不可用。请稍后在检测记录中点击“开始检测”或“重新检测”。',
      timeoutMessage: '检测图片已上传成功，但识别服务响应超时。请稍后在检测记录中继续检测。',
      fallbackMessage: '检测任务暂未完成，请稍后在检测记录中查看状态。',
    );
  }

  static String forReport(String? rawMessage) {
    return _normalize(
      rawMessage,
      unavailableMessage: '报告服务暂不可用，请稍后重试或稍后在报告页继续下载。',
      timeoutMessage: '报告处理超时，请稍后重试。',
      fallbackMessage: '报告处理失败，请稍后重试。',
    );
  }

  static String _normalize(
    String? rawMessage, {
    required String unavailableMessage,
    required String timeoutMessage,
    required String fallbackMessage,
  }) {
    final message = (rawMessage ?? '').replaceAll('Exception: ', '').trim();
    if (message.isEmpty) {
      return fallbackMessage;
    }

    final lower = message.toLowerCase();
    if (_looksLikeUnavailable(lower)) {
      return unavailableMessage;
    }
    if (_looksLikeTimeout(lower)) {
      return timeoutMessage;
    }
    if (_looksLikeInfrastructureMessage(lower)) {
      return fallbackMessage;
    }
    return message;
  }

  static bool _looksLikeUnavailable(String message) {
    return message.contains('connection refused') ||
        message.contains('actively refused') ||
        message.contains('failed to connect') ||
        message.contains('connection error') ||
        message.contains('service unavailable') ||
        message.contains('no route to host') ||
        message.contains('i/o error on post request') ||
        message.contains('socketexception') ||
        message.contains('connectexception');
  }

  static bool _looksLikeTimeout(String message) {
    return message.contains('timeout') ||
        message.contains('timed out') ||
        message.contains('deadline exceeded');
  }

  static bool _looksLikeInfrastructureMessage(String message) {
    return message.contains('127.0.0.1') ||
        message.contains('localhost') ||
        message.contains('/api/v1/') ||
        message.contains(':8000') ||
        message.contains(':8080') ||
        message.contains('detect_damage') ||
        message.contains('xmlhttprequest') ||
        message.contains('xhr');
  }
}
