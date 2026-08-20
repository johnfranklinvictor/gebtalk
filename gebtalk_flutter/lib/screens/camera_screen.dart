import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/image_editor.dart';

/// Full-screen in-app camera like WhatsApp for instant photo/video capture
class CameraScreen extends StatefulWidget {
  final Function(String path, String caption) onMediaCaptured;

  const CameraScreen({
    super.key,
    required this.onMediaCaptured,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isFrontCamera = false;
  bool _isFlashOn = false;
  bool _isVideoMode = false;
  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Simulated Viewfinder Area
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey.shade900,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isVideoMode ? Icons.videocam_rounded : Icons.camera_alt_rounded,
                  color: Colors.white24,
                  size: 96,
                ),
                const SizedBox(height: 16),
                Text(
                  _isRecording ? 'Recording Video...' : 'Camera Viewfinder',
                  style: TextStyle(
                    color: _isRecording ? Colors.redAccent : Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Top Bar (Close, Flash, Switch Camera)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        color: _isFlashOn ? Colors.yellowAccent : Colors.white,
                        size: 24,
                      ),
                      onPressed: () => setState(() => _isFlashOn = !_isFlashOn),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white, size: 24),
                      onPressed: () => setState(() => _isFrontCamera = !_isFrontCamera),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Bar (Photo/Video Mode Switch & Capture Button)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mode Toggle (Photo vs Video)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isVideoMode = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: !_isVideoMode ? Colors.white24 : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'PHOTO',
                          style: TextStyle(
                            color: !_isVideoMode ? Colors.white : Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setState(() => _isVideoMode = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isVideoMode ? Colors.white24 : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'VIDEO',
                          style: TextStyle(
                            color: _isVideoMode ? Colors.white : Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Shutter Button
                GestureDetector(
                  onTap: _capturePhoto,
                  child: Container(
                    width: 76,
                    height: 76,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isVideoMode ? Colors.redAccent : Colors.white,
                        width: 4,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isVideoMode ? Colors.redAccent : Colors.white,
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

  void _capturePhoto() {
    // Open editor for captured image preview
    const sampleCapturedUrl = 'https://picsum.photos/800/1200';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageEditorScreen(
          imagePath: sampleCapturedUrl,
          onSend: (caption) {
            Navigator.pop(context); // close camera
            widget.onMediaCaptured(sampleCapturedUrl, caption);
          },
        ),
      ),
    );
  }
}
