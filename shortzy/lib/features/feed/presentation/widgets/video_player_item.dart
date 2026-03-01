import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../core/utils/video_cache_manager.dart';

class VideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  final bool isCurrentPage;

  const VideoPlayerItem({
    super.key,
    required this.videoUrl,
    required this.isCurrentPage,
  });

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final cachedPath = await VideoCacheManager.getVideoPath(widget.videoUrl);
      _controller = VideoPlayerController.networkUrl(Uri.parse(cachedPath));
      
      await _controller!.initialize();
      await _controller!.setLooping(true);
      
      if (mounted) {
        setState(() => _isInitialized = true);
        if (widget.isCurrentPage && _isVisible) {
          _controller!.play();
        }
      }
    } catch (e) {
      debugPrint('Video initialization error: $e');
    }
  }

  @override
  void didUpdateWidget(VideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentPage != oldWidget.isCurrentPage) {
      _handlePlayState();
    }
  }

  void _handlePlayState() {
    if (!_isInitialized || _controller == null) return;
    
    if (widget.isCurrentPage && _isVisible) {
      _controller!.play();
    } else {
      _controller!.pause();
      _controller!.seekTo(Duration.zero);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.videoUrl),
      onVisibilityChanged: (info) {
        _isVisible = info.visibleFraction > 0.5;
        _handlePlayState();
      },
      child: Container(
        color: Colors.black,
        child: _isInitialized && _controller != null
            ? AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              )
            : const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00F2EA),
                ),
              ),
      ),
    );
  }
}
