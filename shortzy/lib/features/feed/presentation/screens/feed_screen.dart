import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feed_provider.dart';
import '../widgets/video_player_item.dart';
import '../widgets/video_overlay.dart';
import '../../wallet/presentation/screens/wallet_screen.dart';
import '../../profile/presentation/screens/profile_screen.dart';
import '../../upload/presentation/screens/upload_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final PageController _pageController = PageController();
  final Map<int, double> _earnings = {};

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    ref.read(currentVideoIndexProvider.notifier).setIndex(index);
    
    if (_earnings.containsKey(index - 1)) {
      _showEarningAnimation(_earnings[index - 1]!);
    }
  }

  void _showEarningAnimation(double amount) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.monetization_on, color: Colors.amber),
            const SizedBox(width: 8),
            Text('Earned \$${amount.toStringAsFixed(2)}!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedControllerProvider);
    final currentIndex = ref.watch(currentVideoIndexProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: feedState.when(
        data: (videos) => PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          onPageChanged: _onPageChanged,
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            final isCurrentPage = index == currentIndex;
            
            return Stack(
              fit: StackFit.expand,
              children: [
                VideoPlayerItem(
                  videoUrl: video.videoUrl,
                  isCurrentPage: isCurrentPage,
                ),
                VideoOverlay(
                  video: video,
                  onLike: () {},
                  onComment: () {},
                  onShare: () {},
                  coinsEarned: _earnings[index] ?? 0,
                ),
              ],
            );
          },
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00F2EA)),
        ),
        error: (error, _) => Center(
          child: Text('Error: $error', style: const TextStyle(color: Colors.white)),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFF00F2EA),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Upload'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen()));
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
          } else if (index == 4) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }
        },
      ),
    );
  }
}
