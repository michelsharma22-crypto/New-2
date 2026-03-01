import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/video.dart';
import '../datasources/feed_remote_datasource.dart';

abstract class FeedRepository {
  Future<Either<Failure, List<Video>>> getFeedVideos({String? lastVideoId});
  Future<Either<Failure, void>> likeVideo(String videoId, String userId);
}

class FeedRepositoryImpl implements FeedRepository {
  final FeedRemoteDataSource _remoteDataSource;

  FeedRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<Video>>> getFeedVideos({String? lastVideoId}) async {
    try {
      final videos = await _remoteDataSource.getFeedVideos(lastVideoId: lastVideoId);
      return Right(videos.map((v) => v.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> likeVideo(String videoId, String userId) async {
    try {
      await _remoteDataSource.likeVideo(videoId, userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
