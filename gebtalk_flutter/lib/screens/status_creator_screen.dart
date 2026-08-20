import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/colors.dart';
import '../services/api_service.dart';

/// WhatsApp Text and Media Status Creator Screen
class StatusCreatorScreen extends StatefulWidget {
  final Function(String text, String? mediaUrl, String? bgColor, String? fontStyle) onStatusCreated;

  const StatusCreatorScreen({super.key, required this.onStatusCreated});

  @override
  State<StatusCreatorScreen> createState() => _StatusCreatorScreenState();
}

class _StatusCreatorScreenState extends State<StatusCreatorScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<Color> _backgroundColors = [
    const Color(0xFF1E88E5), // Blue
    const Color(0xFF43A047), // Green
    const Color(0xFFE53935), // Red
    const Color(0xFF8E24AA), // Purple
    const Color(0xFFFB8C00), // Orange
    const Color(0xFF00ACC1), // Cyan
    const Color(0xFF546E7A), // BlueGrey
    const Color(0xFFD81B60), // Pink
    const Color(0xFF3949AB), // Indigo
  ];

  final List<String> _fontStyles = [
    'Sans-Serif',
    'Serif',
    'Monospace',
    'Handwriting',
    'Bold Titan',
  ];

  int _colorIndex = 0;
  int _fontIndex = 0;
  String? _selectedMediaUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _cycleColor() {
    setState(() {
      _colorIndex = (_colorIndex + 1) % _backgroundColors.length;
    });
  }

  void _cycleFont() {
    setState(() {
      _fontIndex = (_fontIndex + 1) % _fontStyles.length;
    });
  }

  TextStyle _getCurrentTextStyle() {
    final styleName = _fontStyles[_fontIndex];
    switch (styleName) {
      case 'Serif':
        return const TextStyle(fontFamily: 'serif', fontSize: 28, color: Colors.white, fontWeight: FontWeight.normal);
      case 'Monospace':
        return const TextStyle(fontFamily: 'monospace', fontSize: 26, color: Colors.white, fontWeight: FontWeight.w600);
      case 'Handwriting':
        return const TextStyle(fontStyle: FontStyle.italic, fontSize: 30, color: Colors.white, fontWeight: FontWeight.w300);
      case 'Bold Titan':
        return const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.0);
      default:
        return const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold);
    }
  }

  void _submitStatus() {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedMediaUrl == null) return;

    final bgColorHex = '#${_backgroundColors[_colorIndex].value.toRadixString(16).padLeft(8, '0').substring(2)}';
    widget.onStatusCreated(
      text,
      _selectedMediaUrl,
      bgColorHex,
      _fontStyles[_fontIndex],
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _backgroundColors[_colorIndex];

    return Scaffold(
      backgroundColor: activeColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Center Editable Content Area
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  style: _getCurrentTextStyle(),
                  textAlign: TextAlign.center,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Type a status',
                    hintStyle: TextStyle(color: Colors.white60, fontSize: 28),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            // Top Control Bar
            Positioned(
              top: 12,
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
                        icon: const Icon(Icons.title_rounded, color: Colors.white, size: 26),
                        tooltip: 'Change font',
                        onPressed: _cycleFont,
                      ),
                      IconButton(
                        icon: const Icon(Icons.palette_rounded, color: Colors.white, size: 26),
                        tooltip: 'Change color',
                        onPressed: _cycleColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Send FAB
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton(
                backgroundColor: AppColors.primary,
                onPressed: _submitStatus,
                child: const Icon(Icons.send_rounded, color: Colors.black, size: 26),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
