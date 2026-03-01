import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/video.dart';

part 'video_model.freezed.dart';
part 'video_model.g.dart';

@freezed
class VideoModel with _$VideoModel {
  const factory VideoModel({
    required String id,
    required String videoUrl,
    required String thumbnailUrl,
    required String creatorId,
    String? creatorName,
    String? creatorAvatarUrl,
    required String caption,
    @Default([]) List<String> hashtags,
    @Default(0) int likesCount,
    @Default(0) int commentsCount,
    @Default(0) int sharesCount,
    @Default(0) int viewsCount,
    @Default(0.0) double earningsGenerated,
    DateTime? createdAt,
  }) = _VideoModel;

  factory VideoModel.fromJson(Map<String, dynamic> json) => _$VideoModelFromJson(json);
}

extension VideoModelX on VideoModel {
  Video toEntity() => Video(
        id: id,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        creatorId: creatorId,
        creatorName: creatorName,
        creatorAvatarUrl: creatorAvatarUrl,
        caption: caption,
        hashtags: hashtags,
        likesCount: likesCount,
        commentsCount: commentsCount,
        sharesCount: sharesCount,
        viewsCount: viewsCount,
        earningsGenerated: earningsGenerated,
        createdAt: createdAt,
      );
}
