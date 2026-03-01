import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
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
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}

extension UserModelX on UserModel {
  User toEntity() => User(
        uid: uid,
        email: email,
        username: username,
        avatarUrl: avatarUrl,
        walletBalance: walletBalance,
        totalEarnings: totalEarnings,
        isCreator: isCreator,
        isVerified: isVerified,
        createdAt: createdAt,
        lastActiveAt: lastActiveAt,
      );
}
