import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/colors.dart';
import '../models/chat_models.dart';

class InteractiveCustomerCard extends StatefulWidget {
  final Contact contact;
  final VoidCallback onTap;

  const InteractiveCustomerCard({Key? key, required this.contact, required this.onTap}) : super(key: key);

  @override
  State<InteractiveCustomerCard> createState() => _InteractiveCustomerCardState();
}

class _InteractiveCustomerCardState extends State<InteractiveCustomerCard> {
  bool _isHovered = false;
  Offset _mousePosition = Offset.zero;

  Widget _buildStatusCheckmark(String status) {
    if (status == 'sent') {
      return const Icon(Icons.check, size: 13, color: AppColors.textMuted);
    } else if (status == 'delivered') {
      return const Icon(Icons.done_all_rounded, size: 14, color: AppColors.textMuted);
    } else if (status == 'read') {
      return const Icon(Icons.done_all_rounded, size: 14, color: AppColors.primary);
    }
    return const SizedBox.shrink();
  }

  Widget _buildLastMessagePreview() {
    final msg = widget.contact.lastMessage;
    if (msg == null) {
      return Text(
        widget.contact.phone,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    String prefix = '';
    String content = '';
    IconData? icon;
    Color iconColor = AppColors.primary;

    if (msg.isAudio) {
      prefix = 'Voice Note';
      content = msg.duration != null ? ' • ${msg.duration}' : '';
      icon = Icons.mic_rounded;
    } else if (msg.isFile) {
      final name = msg.fileName ?? 'File';
      final isImg = name.toLowerCase().endsWith('.png') ||
          name.toLowerCase().endsWith('.jpg') ||
          name.toLowerCase().endsWith('.jpeg') ||
          name.toLowerCase().endsWith('.gif');
      if (isImg) {
        prefix = 'Photo';
        content = '';
        icon = Icons.image_rounded;
      } else if (name.toLowerCase().endsWith('.pdf')) {
        prefix = 'Document';
        content = ' • $name';
        icon = Icons.picture_as_pdf_rounded;
        iconColor = AppColors.secondary;
      } else {
        prefix = 'File';
        content = ' • $name';
        icon = Icons.insert_drive_file_rounded;
      }
    } else {
      prefix = msg.text;
      content = '';
    }

    return Row(
      children: [
        if (msg.isUser) ...[
          _buildStatusCheckmark(msg.status),
          const SizedBox(width: 4),
        ],
        if (icon != null) ...[
          Icon(icon, size: 13, color: iconColor.withOpacity(0.85)),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontFamily: 'Product Sans',
              ),
              children: [
                TextSpan(
                  text: prefix,
                  style: TextStyle(
                    color: msg.isAudio || msg.isFile ? Colors.white.withOpacity(0.85) : AppColors.textMuted,
                    fontWeight: msg.isAudio || msg.isFile ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                TextSpan(text: content),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Generate a mock activity score
    int activityScore = (widget.contact.name.length * 7) % 100;

    return MouseRegion(
      onEnter: (_) { if (mounted) setState(() => _isHovered = true); },
      onExit: (_) { if (mounted) setState(() {
        _isHovered = false;
        _mousePosition = Offset.zero;
      }); },
      onHover: (details) {
        if (_isHovered && mounted) {
          setState(() {
            _mousePosition = details.localPosition;
          });
        }
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate tilt based on mouse position relative to center of the card
            double x = 0;
            double y = 0;
            if (_isHovered) {
              double centerX = constraints.maxWidth / 2;
              final centerY = 45.0; // Approx half height
              // Max rotation of 10 degrees (0.17 radians)
              if (centerX > 0 && centerX.isFinite && centerY > 0) {
                x = ((_mousePosition.dy - centerY) / centerY) * -0.15;
                y = ((_mousePosition.dx - centerX) / centerX) * 0.15;
              }
            }

            return TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: _isHovered ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              builder: (context, double hoverValue, child) {
                final transform = Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // perspective
                  ..rotateX(x * hoverValue)
                  ..rotateY(y * hoverValue)
                  ..scale(1.0 + (0.02 * hoverValue));

                return Transform(
                  transform: transform,
                  alignment: FractionalOffset.center,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isHovered ? AppColors.primary : AppColors.glassBorder,
                        width: _isHovered ? 2 : 1,
                      ),
                      boxShadow: [
                        if (_isHovered)
                          BoxShadow(color: AppColors.primary.withOpacity(0.3 * hoverValue), blurRadius: 20, spreadRadius: 2),
                        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: widget.contact.tags.any((t) => t.name.toLowerCase() == 'high priority' || t.name.toLowerCase() == 'vip') ? AppColors.secondary : AppColors.primary, width: 2),
                              image: widget.contact.avatar.isNotEmpty
                                  ? DecorationImage(image: NetworkImage(widget.contact.avatar), fit: BoxFit.cover)
                                  : null,
                              boxShadow: [
                                if (widget.contact.tags.any((t) => t.name.toLowerCase() == 'high priority' || t.name.toLowerCase() == 'vip'))
                                  BoxShadow(color: AppColors.secondary.withOpacity(0.5), blurRadius: 8)
                                else
                                  BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 8)
                              ],
                            ),
                            child: widget.contact.avatar.isEmpty
                                ? Icon(Icons.person, color: widget.contact.tags.any((t) => t.name.toLowerCase() == 'high priority' || t.name.toLowerCase() == 'vip') ? AppColors.secondary : AppColors.primary)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          
                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              widget.contact.name.toUpperCase(),
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (widget.contact.tags.any((t) => t.name.toLowerCase() == 'high priority' || t.name.toLowerCase() == 'vip')) ...[
                                            const SizedBox(width: 6),
                                            const Icon(Icons.star, color: AppColors.secondary, size: 13)
                                                .animate()
                                                .shimmer(duration: 1.seconds),
                                          ]
                                        ],
                                      ),
                                    ),
                                    if (widget.contact.lastMessage != null) ...[
                                      Text(
                                        widget.contact.lastMessage!.time,
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 10,
                                          fontFamily: 'Product Sans',
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                _buildLastMessagePreview(),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.local_fire_department, color: AppColors.orangeGlow, size: 12),
                                    const SizedBox(width: 4),
                                    Text("Activity: $activityScore/100", style: const TextStyle(color: AppColors.orangeGlow, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                )
                              ],
                            ),
                          ),
                          
                          // Tags
                          if (widget.contact.tags.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.deepIndigo,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                              ),
                              child: Text(
                                widget.contact.tags.first.name.toUpperCase(),
                                style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            
                          if (widget.contact.unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Center(
                                child: Text(
                                  '${widget.contact.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Product Sans',
                                  ),
                                ),
                              ),
                            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                             .scale(end: const Offset(1.15, 1.15), duration: 1200.ms, curve: Curves.easeInOut),
                          ],
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 15),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
