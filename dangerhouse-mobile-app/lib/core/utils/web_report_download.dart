import 'web_report_download_stub.dart'
    if (dart.library.html) 'web_report_download_web.dart' as impl;

Future<bool> openReportDownloadUrl(
  String url, {
  String? fileName,
}) {
  return impl.openReportDownloadUrl(url, fileName: fileName);
}
