import 'dart:html' as html;

Future<bool> openReportDownloadUrl(
  String url, {
  String? fileName,
}) async {
  if (url.isEmpty) {
    return false;
  }

  final anchor = html.AnchorElement(href: url)
    ..target = '_blank'
    ..rel = 'noopener noreferrer';

  if (fileName != null && fileName.isNotEmpty) {
    anchor.download = fileName;
  }

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  return true;
}
