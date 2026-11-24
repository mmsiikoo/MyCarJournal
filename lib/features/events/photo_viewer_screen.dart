import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../models/event_photo.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/base64_image.dart';

class PhotoViewerScreen extends ConsumerStatefulWidget {
  const PhotoViewerScreen({
    super.key,
    required this.eventId,
    this.initialIndex = 0,
  });

  final String eventId;
  final int initialIndex;

  @override
  ConsumerState<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends ConsumerState<PhotoViewerScreen> {
  late final PageController _controller;
  int _index = 0;
  bool _pendingInitialJump = true;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex < 0 ? 0 : widget.initialIndex;
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jumpTo(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      if (_controller.page?.round() != index) {
        _controller.jumpToPage(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(eventPhotosProvider(widget.eventId));
    final photos = photosAsync.value ?? const <EventPhoto>[];
    final safeIndex = photos.isEmpty ? 0 : _index.clamp(0, photos.length - 1);

    if (photos.isNotEmpty) {
      if (_pendingInitialJump) {
        _pendingInitialJump = false;
        _index = safeIndex;
        _jumpTo(safeIndex);
      } else if (_index != safeIndex) {
        _index = safeIndex;
        _jumpTo(safeIndex);
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          photos.isEmpty ? 'Фото' : '${safeIndex + 1} / ${photos.length}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: photosAsync.isLoading && photos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : photos.isEmpty
          ? const Center(
              child: Text(
                'Фото не знайдено',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: photos.length,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      return InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: Center(
                          child: Base64Image(photo.data, fit: BoxFit.contain),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.photo_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _details(photos[safeIndex]),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _details(EventPhoto photo) {
    final sizeKb = (photo.size / 1024).round();
    if (photo.width > 0 && photo.height > 0) {
      return '${photo.width}×${photo.height} • $sizeKb КБ';
    }
    return '$sizeKb КБ';
  }
}
