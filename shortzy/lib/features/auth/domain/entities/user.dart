import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String uid,
    required String email,
    String? username,
    String? avatarUrl,
    @Default(0.0) double walletBalance,
    @Default(0.0) double totalEarnings,
    @Default(false) bool isCreator,
    @Default(false) bool isVerified,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
