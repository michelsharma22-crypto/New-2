import 'package:flutter/material.dart';
import '../../domain/entities/video.dart';

class VideoOverlay extends StatelessWidget {
  final Video video;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final double coinsEarned;

  const VideoOverlay({
    super.key,
    required this.video,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    this.coinsEarned = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      icon: Icons.favorite,
                      count: video.likesCount,
                      onTap: onLike,
                      color: video.isLiked ? Colors.red : Colors.white,
                    ),
                    const SizedBox(height: 20),
                    _buildActionButton(
                      icon: Icons.comment,
                      count: video.commentsCount,
                      onTap: onComment,
                    ),
                    const SizedBox(height: 20),
                    _buildActionButton(
                      icon: Icons.share,
                      count: video.sharesCount,
                      onTap: onShare,
                    ),
                    const SizedBox(height: 30),
                    if (coinsEarned > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.black, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '+\$${coinsEarned.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: video.creatorAvatarUrl != null
                      ? NetworkImage(video.creatorAvatarUrl!)
                      : null,
                  child: video.creatorAvatarUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${video.creatorName ?? 'user'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        video.caption,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 35),
          const SizedBox(height: 4),
          Text(
            _formatCount(count),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
