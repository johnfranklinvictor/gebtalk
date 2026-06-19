import 'dart:html' as html;
import 'dart:async';

Future<void> downloadFileImpl(String url, String fileName) async {
  // Convert view URL (/uploads/...) to download URL (/api/download/...) 
  // which sets Content-Disposition: attachment header
  String downloadUrl = url;
  if (url.contains('/uploads/')) {
    downloadUrl = url.replaceFirst('/uploads/', '/api/download/');
  }

  try {
    // Method 1: Use XHR to fetch as blob, then trigger download via blob URL
    final xhr = await html.HttpRequest.request(
      downloadUrl,
      method: 'GET',
      responseType: 'blob',
    );
    final blob = xhr.response as html.Blob;
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement(href: blobUrl)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
      
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    
    // Revoke the URL after download starts
    Future.delayed(const Duration(seconds: 10), () {
      html.Url.revokeObjectUrl(blobUrl);
    });
  } catch (e) {
    print("Blob download failed, falling back to direct link: $e");
    // Method 2: Fallback - use window.open to the download endpoint
    // This forces the browser to download via Content-Disposition: attachment
    html.window.open(downloadUrl, '_blank');
  }
}

void openFileInNewTabImpl(String url) {
  html.window.open(url, '_blank');
}
