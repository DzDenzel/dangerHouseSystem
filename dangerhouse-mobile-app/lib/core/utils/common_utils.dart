import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

export 'app_logger.dart';

class DateUtils {
  static final DateFormat _displayFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _monthDayFormat = DateFormat('MM-dd HH:mm');
  static final DateFormat _fullFormat = DateFormat('yyyy年MM月dd日 HH:mm');

  static DateTime? _parseDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return null;
    try {
      return DateTime.parse(dateTimeStr);
    } catch (e) {
      return null;
    }
  }

  static String formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '-';
    try {
      final dateTime = _parseDateTime(dateTimeStr);
      if (dateTime == null) return dateTimeStr;
      return _displayFormat.format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  static String formatDate(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '-';
    try {
      final dateTime = _parseDateTime(dateTimeStr);
      if (dateTime == null) return dateTimeStr;
      return _dateFormat.format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  static String formatFriendly(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '-';
    try {
      final dateTime = _parseDateTime(dateTimeStr);
      if (dateTime == null) return dateTimeStr;

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return '刚刚';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}分钟前';
      } else if (difference.inHours < 24 && dateTime.day == now.day) {
        return '今天 ${_timeFormat.format(dateTime)}';
      } else {
        final yesterday = now.subtract(const Duration(days: 1));
        if (dateTime.year == yesterday.year &&
            dateTime.month == yesterday.month &&
            dateTime.day == yesterday.day) {
          return '昨天 ${_timeFormat.format(dateTime)}';
        } else if (dateTime.year == now.year) {
          return _monthDayFormat.format(dateTime);
        } else {
          return _displayFormat.format(dateTime);
        }
      }
    } catch (e) {
      return dateTimeStr;
    }
  }

  static String formatFull(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '-';
    try {
      final dateTime = _parseDateTime(dateTimeStr);
      if (dateTime == null) return dateTimeStr;
      return _fullFormat.format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  static DateTime? tryParse(String? dateTimeStr) {
    return _parseDateTime(dateTimeStr);
  }

  static bool isToday(String? dateTimeStr) {
    final dateTime = _parseDateTime(dateTimeStr);
    if (dateTime == null) return false;
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  static bool isYesterday(String? dateTimeStr) {
    final dateTime = _parseDateTime(dateTimeStr);
    if (dateTime == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day;
  }

  static bool isThisMonth(String? dateTimeStr) {
    final dateTime = _parseDateTime(dateTimeStr);
    if (dateTime == null) return false;
    final now = DateTime.now();
    return dateTime.year == now.year && dateTime.month == now.month;
  }

  static bool isWithinDays(String? dateTimeStr, int days) {
    final dateTime = _parseDateTime(dateTimeStr);
    if (dateTime == null) return false;
    final now = DateTime.now();
    final difference = now.difference(dateTime).inDays;
    return difference >= 0 && difference <= days;
  }

  static String getCurrentDate() {
    return _dateFormat.format(DateTime.now());
  }

  static String getCurrentDateTime() {
    return _displayFormat.format(DateTime.now());
  }

  static int compareDateTime(String? a, String? b, {bool descending = true}) {
    final timeA = _parseDateTime(a);
    final timeB = _parseDateTime(b);
    if (timeA == null && timeB == null) return 0;
    if (timeA == null) return descending ? 1 : -1;
    if (timeB == null) return descending ? -1 : 1;
    return descending ? timeB.compareTo(timeA) : timeA.compareTo(timeB);
  }
}

class StringUtils {
  static bool isEmpty(String? str) {
    return str == null || str.trim().isEmpty;
  }

  static bool isNotEmpty(String? str) {
    return !isEmpty(str);
  }

  static String truncate(String str, int length) {
    if (str.length <= length) return str;
    return '${str.substring(0, length)}...';
  }

  static String orDefault(String? str, String defaultValue) {
    return isEmpty(str) ? defaultValue : str!;
  }
}

class NetworkErrorUtils {
  static String getErrorMessage(DioException e, {String defaultMsg = '操作失败，请重试'}) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return '网络连接超时，请检查网络后重试';
    } else if (e.type == DioExceptionType.connectionError) {
      return '网络连接失败，请检查网络或服务器是否正常运行';
    } else if (e.type == DioExceptionType.badResponse) {
      if (e.response?.data is Map) {
        final message = e.response?.data['message'];
        if (message != null) return message.toString();
      }

      final statusCode = e.response?.statusCode;
      if (statusCode == 401) {
        return '身份验证失败，请重新登录';
      } else if (statusCode == 403) {
        return '没有权限执行此操作';
      } else if (statusCode == 404) {
        return '请求的资源不存在';
      } else if (statusCode != null && statusCode >= 500) {
        return '服务器内部错误，请稍后重试';
      }
      return '服务器错误，请稍后重试';
    } else if (e.type == DioExceptionType.cancel) {
      return '请求已取消';
    } else if (e.message != null && e.message!.contains('XMLHttpRequest')) {
      return '网络请求失败，请检查服务器是否正常运行';
    }

    return defaultMsg;
  }

  static String getFriendlyErrorMessage(dynamic error, {String defaultMsg = '操作失败，请重试'}) {
    if (error is DioException) {
      return getErrorMessage(error, defaultMsg: defaultMsg);
    }
    return error.toString().replaceAll('Exception: ', '');
  }
}

class FormValidators {
  static final RegExp _mobilePhoneRegex = RegExp(r'^1[3-9]\d{9}$');
  static final RegExp _landlineRegex = RegExp(r'^0\d{2,3}-?\d{7,8}$');

  static String? validatePhone(String? value, {bool required = false, String label = '联系电话'}) {
    if (value == null || value.trim().isEmpty) {
      if (required) return '请输入$label';
      return null;
    }

    final phone = value.trim();
    if (!_mobilePhoneRegex.hasMatch(phone) && !_landlineRegex.hasMatch(phone)) {
      return '请输入正确的手机号或座机号';
    }
    return null;
  }

  static String? validateMobilePhone(String? value, {bool required = false, String label = '手机号码'}) {
    if (value == null || value.trim().isEmpty) {
      if (required) return '请输入$label';
      return null;
    }

    final phone = value.trim();
    if (!_mobilePhoneRegex.hasMatch(phone)) {
      return '请输入正确的11位手机号';
    }
    return null;
  }

  static String? validateYear(
    String? value, {
    bool required = false,
    String label = '年份',
    int minYear = 1800,
    int? maxYear,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (required) return '请输入$label';
      return null;
    }

    final year = int.tryParse(value.trim());
    if (year == null) {
      return '请输入有效的年份';
    }

    final currentYear = DateTime.now().year;
    final effectiveMaxYear = maxYear ?? currentYear;

    if (year < minYear || year > effectiveMaxYear) {
      return '$label应在$minYear-$effectiveMaxYear之间';
    }
    return null;
  }

  static String? validateBuildYear(String? value, {bool required = false}) {
    return validateYear(value, required: required, label: '建造年份', minYear: 1800);
  }

  static String? validatePositiveNumber(
    String? value, {
    bool required = false,
    String label = '数值',
    double? minValue,
    double? maxValue,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (required) return '请输入$label';
      return null;
    }

    final number = double.tryParse(value.trim());
    if (number == null) {
      return '请输入有效的数值';
    }

    if (number <= 0) {
      return '$label必须大于0';
    }

    if (minValue != null && number < minValue) {
      return '$label不能小于$minValue';
    }

    if (maxValue != null && number > maxValue) {
      return '$label不能大于$maxValue';
    }

    return null;
  }

  static String? validatePositiveInteger(
    String? value, {
    bool required = false,
    String label = '数值',
    int? minValue,
    int? maxValue,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (required) return '请输入$label';
      return null;
    }

    final number = int.tryParse(value.trim());
    if (number == null) {
      return '请输入有效的整数';
    }

    if (number <= 0) {
      return '$label必须大于0';
    }

    if (minValue != null && number < minValue) {
      return '$label不能小于$minValue';
    }

    if (maxValue != null && number > maxValue) {
      return '$label不能大于$maxValue';
    }

    return null;
  }

  static String? validateFloorCount(String? value, {bool required = false}) {
    return validatePositiveInteger(value, required: required, label: '建筑层数', minValue: 1, maxValue: 200);
  }

  static String? validateArea(String? value, {bool required = false}) {
    return validatePositiveNumber(value, required: required, label: '建筑面积', minValue: 0.1);
  }

  static String? validateEmail(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      if (required) return '请输入邮箱';
      return null;
    }

    if (!RegExp(r"^\S+@\S+\.\S+$").hasMatch(value.trim())) {
      return '请输入有效的邮箱地址';
    }
    return null;
  }

  static String? validateRequired(String? value, {String label = '此项'}) {
    if (value == null || value.trim().isEmpty) {
      return '请输入$label';
    }
    return null;
  }
}

class ImageUtils {
  static String? getFullImageUrl(String? imagePath) {
    return getFullFileUrl(imagePath);
  }

  static String? getFullFileUrl(String? filePath) {
    if (filePath == null) return null;

    final trimmedPath = filePath.trim();
    if (trimmedPath.isEmpty) return null;

    return trimmedPath;
  }

  static bool isNetworkImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return false;
    return imagePath.startsWith('http://') ||
        imagePath.startsWith('https://') ||
        imagePath.startsWith('//');
  }

  static String? getThumbnailUrl(String? imagePath, {int width = 200, int height = 200}) {
    final fullUrl = getFullImageUrl(imagePath);
    if (fullUrl == null) return null;

    return fullUrl;
  }
}
