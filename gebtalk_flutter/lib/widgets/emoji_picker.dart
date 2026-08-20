import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Full emoji picker widget with categories and instant selection
class EmojiPickerWidget extends StatefulWidget {
  final Function(String emoji) onEmojiSelected;

  const EmojiPickerWidget({
    super.key,
    required this.onEmojiSelected,
  });

  @override
  State<EmojiPickerWidget> createState() => _EmojiPickerWidgetState();
}

class _EmojiPickerWidgetState extends State<EmojiPickerWidget> {
  int _selectedCategory = 0;

  static const List<Map<String, dynamic>> _emojiCategories = [
    {
      'name': 'Smileys & People',
      'icon': Icons.sentiment_satisfied_alt_rounded,
      'emojis': [
        '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '🙃',
        '😉', '😊', '😇', '🥰', '😍', '🤩', '😘', '😗', '😚', '😙',
        '😋', '😛', '😜', '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔',
        '🤐', '🤨', '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '🤥',
        '😌', '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕', '🤢', '🤮',
        '🤧', '🥵', '🥶', '🥴', '😵', '🤯', '🤠', '🥳', '😎', '🤓',
      ],
    },
    {
      'name': 'Animals & Nature',
      'icon': Icons.pets_rounded,
      'emojis': [
        '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯',
        '🦁', '🐮', '🐷', '🐸', '🐵', '🙈', '🙉', '🙊', '🐒', '🐔',
        '🐧', '🐦', '🐤', '🐣', '🐥', '🦆', '🦅', '🦉', '🦇', '🐺',
        '🐗', '🐴', '🦄', '🐝', '🐛', '🦋', '🐌', '🐞', '🐜', '🦟',
      ],
    },
    {
      'name': 'Food & Drink',
      'icon': Icons.fastfood_rounded,
      'emojis': [
        '🍏', '🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🍈',
        '🍒', '🍑', '🥭', '🍍', '🥥', '🥝', '🍅', '🍆', '🥑', '🥦',
        '🍞', '🥐', '🥖', '🥨', '🥯', '🥞', '🧀', '🍖', '🍗', '🥩',
        '🍔', '🍟', '🍕', '🌭', '🥪', '🌮', '🌯', '🍳', '🥘', '🍲',
      ],
    },
    {
      'name': 'Activities',
      'icon': Icons.sports_soccer_rounded,
      'emojis': [
        '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉', '🥏', '🎱',
        '🏓', '🏸', '🏒', '🏑', '🥍', '🏏', '🎯', '⛳', '🏹', '🎣',
        '🥊', '🥋', '🎽', '🛹', '🛷', '⛸️', '🥌', '🎿', '⛷️', '🏂',
      ],
    },
    {
      'name': 'Objects & Symbols',
      'icon': Icons.lightbulb_rounded,
      'emojis': [
        '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '💔', '❣️', '💕',
        '💞', '💓', '💗', '💖', '💘', '💝', '💟', '☮️', '✝️', '☪️',
        '🔥', '💥', '✨', '🌟', '💫', '🎉', '🎊', '🎁', '🎈', '🏆',
        '💻', '📱', '☎️', '📞', '📟', '📠', '🔌', '🔋', '🖥️', '🖨️',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentCategory = _emojiCategories[_selectedCategory];
    final List<String> currentEmojis = currentCategory['emojis'];

    return Container(
      height: 260,
      color: AppColors.surface,
      child: Column(
        children: [
          // Category Icons Bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_emojiCategories.length, (index) {
                final cat = _emojiCategories[index];
                final isSelected = index == _selectedCategory;
                return IconButton(
                  icon: Icon(
                    cat['icon'] as IconData,
                    color: isSelected ? AppColors.primary : Colors.white38,
                    size: 22,
                  ),
                  onPressed: () => setState(() => _selectedCategory = index),
                );
              }),
            ),
          ),

          // Emoji Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: currentEmojis.length,
              itemBuilder: (context, index) {
                final emoji = currentEmojis[index];
                return InkWell(
                  onTap: () => widget.onEmojiSelected(emoji),
                  borderRadius: BorderRadius.circular(8),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
