import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

enum TransactionType {
  earnWatch,
  earnUpload,
  withdrawalPending,
  withdrawalCompleted,
  withdrawalRejected,
  referralBonus,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  rejected,
}

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String userId,
    required double amount,
    required TransactionType type,
    required TransactionStatus status,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? completedAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);
}
