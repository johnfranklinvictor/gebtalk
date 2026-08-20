import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// In-app Image Editor (crop, draw/doodle, add text caption) like WhatsApp
class ImageEditorScreen extends StatefulWidget {
  final String imagePath;
  final Uint8List? imageBytes;
  final Function(String caption) onSend;

  const ImageEditorScreen({
    super.key,
    required this.imagePath,
    this.imageBytes,
    required this.onSend,
  });

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  final TextEditingController _captionController = TextEditingController();
  final List<List<Offset>> _lines = [];
  List<Offset> _currentLine = [];
  Color _drawColor = Colors.redAccent;
  bool _isDrawing = false;

  final List<Color> _colors = [
    Colors.redAccent,
    Colors.yellowAccent,
    Colors.greenAccent,
    Colors.cyanAccent,
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.white,
    Colors.black,
  ];

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Toolbar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  // Draw Toggle Button
                  IconButton(
                    icon: Icon(
                      Icons.edit_rounded,
                      color: _isDrawing ? AppColors.primary : Colors.white70,
                    ),
                    onPressed: () => setState(() => _isDrawing = !_isDrawing),
                  ),
                  // Clear Drawings Button
                  if (_lines.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.undo_rounded, color: Colors.white70),
                      onPressed: () => setState(() => _lines.clear()),
                    ),
                ],
              ),
            ),

            // Color Palette Selector (when drawing mode active)
            if (_isDrawing)
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _colors.map((color) {
                    final isSelected = color == _drawColor;
                    return GestureDetector(
                      onTap: () => setState(() => _drawColor = color),
                      child: Container(
                        width: isSelected ? 28 : 22,
                        height: isSelected ? 28 : 22,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Main Canvas Image Area
            Expanded(
              child: GestureDetector(
                onPanStart: _isDrawing
                    ? (details) {
                        setState(() {
                          _currentLine = [details.localPosition];
                          _lines.add(_currentLine);
                        });
                      }
                    : null,
                onPanUpdate: _isDrawing
                    ? (details) {
                        setState(() {
                          _currentLine.add(details.localPosition);
                        });
                      }
                    : null,
                child: CustomPaint(
                  painter: _DrawingPainter(_lines, _drawColor),
                  child: Center(
                    child: widget.imageBytes != null
                        ? Image.memory(widget.imageBytes!, fit: BoxFit.contain)
                        : Image.network(widget.imagePath, fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image_rounded, color: Colors.white24, size: 80)),
                  ),
                ),
              ),
            ),

            // Bottom Caption & Send Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.surface,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _captionController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Add a caption...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.black),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onSend(_captionController.text.trim());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<List<Offset>> lines;
  final Color color;

  _DrawingPainter(this.lines, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (final line in lines) {
      for (int i = 0; i < line.length - 1; i++) {
        canvas.drawLine(line[i], line[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
