import 'file_download_helper_stub.dart'
    if (dart.library.html) 'file_download_helper_web.dart';

Future<void> triggerFileDownload(String url, String fileName) async {
  await downloadFileImpl(url, fileName);
}

void triggerFileView(String url) {
  openFileInNewTabImpl(url);
}
