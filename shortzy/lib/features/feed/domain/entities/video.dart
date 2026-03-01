import 'package:freezed_annotation/freezed_annotation.dart';

part 'video.freezed.dart';
part 'video.g.dart';

@freezed
class Video with _$Video {
  const factory Video({
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
    @Default(false) bool isLiked,
    @Default(false) bool isWatched,
  }) = _Video;

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);
}
