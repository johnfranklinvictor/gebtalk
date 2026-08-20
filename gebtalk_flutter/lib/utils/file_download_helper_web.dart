import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'dart:async';
import 'dart:js_interop';

Future<void> downloadFileImpl(String url, String fileName) async {
  // Convert view URL (/uploads/...) to download URL (/api/download/...) 
  // which sets Content-Disposition: attachment header
  String downloadUrl = url;
  if (url.contains('/uploads/')) {
    downloadUrl = url.replaceFirst('/uploads/', '/api/download/');
  }

  try {
    // Method 1: Use XMLHttpRequest to fetch as blob, then trigger download via blob URL
    final xhr = web.XMLHttpRequest();
    xhr.open('GET', downloadUrl);
    xhr.responseType = 'blob';
    
    final completer = Completer<void>();
    xhr.onload = ((web.Event e) {
      completer.complete();
    }).toJS;
    xhr.onerror = ((web.Event e) {
      completer.completeError('XHR failed');
    }).toJS;
    xhr.send();
    await completer.future;
    
    final blob = xhr.response as web.Blob;
    final blobUrl = web.URL.createObjectURL(blob);
    
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = blobUrl;
    anchor.setAttribute('download', fileName);
    anchor.style.display = 'none';
      
    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
    
    // Revoke the URL after download starts
    Future.delayed(const Duration(seconds: 10), () {
      web.URL.revokeObjectURL(blobUrl);
    });
  } catch (e) {
    debugPrint("Blob download failed, falling back to direct link: $e");
    // Method 2: Fallback - use window.open to the download endpoint
    // This forces the browser to download via Content-Disposition: attachment
    web.window.open(downloadUrl, '_blank');
  }
}

void openFileInNewTabImpl(String url) {
  web.window.open(url, '_blank');
}
