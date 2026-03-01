import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/video.dart';
import '../../data/datasources/feed_remote_datasource.dart';
import '../../data/repositories/feed_repository_impl.dart';

part 'feed_provider.g.dart';

@riverpod
FeedRepositoryImpl feedRepository(FeedRepositoryRef ref) {
  return FeedRepositoryImpl(
    FeedRemoteDataSourceImpl(FirebaseFirestore.instance),
  );
}

@riverpod
class FeedController extends _$FeedController {
  @override
  Future<List<Video>> build() async {
    final repo = ref.read(feedRepositoryProvider);
    final result = await repo.getFeedVideos();
    return result.getOrElse(() => []);
  }

  Future<void> loadMore() async {
    final currentVideos = state.valueOrNull ?? [];
    if (currentVideos.isEmpty) return;
    
    final lastId = currentVideos.last.id;
    final repo = ref.read(feedRepositoryProvider);
    final result = await repo.getFeedVideos(lastVideoId: lastId);
    
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (videos) => state = AsyncValue.data([...currentVideos, ...videos]),
    );
  }
}

@riverpod
class CurrentVideoIndex extends _$CurrentVideoIndex {
  @override
  int build() => 0;
  
  void setIndex(int index) => state = index;
}
