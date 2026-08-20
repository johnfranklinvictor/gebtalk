import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';

/// Full-featured Sticker and GIF picker sheet like WhatsApp
class StickerPickerWidget extends StatefulWidget {
  final Function(String imageUrl) onStickerSelected;
  final Function(String gifUrl) onGifSelected;

  const StickerPickerWidget({
    super.key,
    required this.onStickerSelected,
    required this.onGifSelected,
  });

  @override
  State<StickerPickerWidget> createState() => _StickerPickerWidgetState();
}

class _StickerPickerWidgetState extends State<StickerPickerWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _gifSearchController = TextEditingController();

  List<Map<String, dynamic>> _stickers = [];
  List<Map<String, dynamic>> _gifs = [];
  bool _loadingStickers = true;
  bool _loadingGifs = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStickers();
    _searchGifs('');
  }

  Future<void> _loadStickers() async {
    final packs = await ApiService.getStickerPacks();
    if (packs.isNotEmpty) {
      final packId = packs.first['id'] ?? 'gebtalk_express';
      final stickers = await ApiService.getPackStickers(packId);
      if (mounted) {
        setState(() {
          _stickers = stickers;
          _loadingStickers = false;
        });
      }
    } else {
      if (mounted) setState(() => _loadingStickers = false);
    }
  }

  Future<void> _searchGifs(String query) async {
    setState(() => _loadingGifs = true);
    final gifs = await ApiService.searchGifs(query);
    if (mounted) {
      setState(() {
        _gifs = gifs;
        _loadingGifs = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _gifSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header Tab Bar (Stickers vs GIFs)
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white54,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(icon: Icon(Icons.sticky_note_2, size: 20), text: 'STICKERS'),
              Tab(icon: Icon(Icons.gif, size: 20), text: 'GIFS'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStickersTab(),
                _buildGifsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickersTab() {
    if (_loadingStickers) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_stickers.isEmpty) {
      return const Center(
        child: Text('No stickers found', style: TextStyle(color: Colors.white38)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: _stickers.length,
      itemBuilder: (context, index) {
        final sticker = _stickers[index];
        final url = sticker['image_url'] ?? '';
        return InkWell(
          onTap: () => widget.onStickerSelected(url),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  sticker['emoji'] ?? '😀',
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGifsTab() {
    return Column(
      children: [
        // GIF Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: _gifSearchController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search GIFs via GebTalk...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (val) => _searchGifs(val),
            ),
          ),
        ),

        // GIF Grid
        Expanded(
          child: _loadingGifs
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: _gifs.length,
                  itemBuilder: (context, index) {
                    final gif = _gifs[index];
                    final url = gif['url'] ?? '';
                    return InkWell(
                      onTap: () => widget.onGifSelected(url),
                      borderRadius: BorderRadius.circular(10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: Colors.white10,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.white10,
                            child: const Center(
                              child: Icon(Icons.gif_rounded, color: Colors.white38, size: 36),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
