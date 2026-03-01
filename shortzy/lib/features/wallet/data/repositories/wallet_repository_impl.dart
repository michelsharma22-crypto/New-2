import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/wallet_repository.dart';

abstract class WalletRepository {
  Future<Either<Failure, double>> getBalance(String userId);
  Future<Either<Failure, List<Transaction>>> getTransactions(String userId);
  Future<Either<Failure, void>> requestWithdrawal(String userId, double amount, Map<String, dynamic> bankDetails);
  Future<Either<Failure, void>> processWatchReward(String userId, String videoId, double watchDuration, double videoDuration);
}

class WalletRepositoryImpl implements WalletRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  WalletRepositoryImpl(this._firestore, this._functions);

  @override
  Future<Either<Failure, double>> getBalance(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return const Left(ServerFailure('User not found'));
      return Right((doc.data()?['wallet_balance'] ?? 0.0).toDouble());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Transaction>>> getTransactions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .get();
      
      return Right(snapshot.docs.map((doc) {
        final data = doc.data();
        return Transaction(
          id: doc.id,
          userId: data['userId'],
          amount: data['amount'].toDouble(),
          type: TransactionType.values.firstWhere(
            (e) => e.toString() == 'TransactionType.${data['type']}',
          ),
          status: TransactionStatus.values.firstWhere(
            (e) => e.toString() == 'TransactionStatus.${data['status']}',
          ),
          metadata: data['metadata'],
          createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
          completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
        );
      }).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> requestWithdrawal(String userId, double amount, Map<String, dynamic> bankDetails) async {
    try {
      final balanceResult = await getBalance(userId);
      final balance = balanceResult.getOrElse(() => 0.0);
      
      if (balance < amount) {
        return const Left(InsufficientBalanceFailure());
      }

      final batch = _firestore.batch();
      final withdrawalRef = _firestore.collection('withdrawals').doc();
      final transactionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc();

      batch.set(withdrawalRef, {
        'userId': userId,
        'amount': amount,
        'bankDetails': bankDetails,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(transactionRef, {
        'userId': userId,
        'amount': amount,
        'type': 'withdrawal_pending',
        'status': 'pending',
        'metadata': {'withdrawalId': withdrawalRef.id},
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.update(_firestore.collection('users').doc(userId), {
        'wallet_balance': FieldValue.increment(-amount),
      });

      await batch.commit();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> processWatchReward(String userId, String videoId, double watchDuration, double videoDuration) async {
    try {
      final callable = _functions.httpsCallable('processWatchReward');
      await callable.call({
        'videoId': videoId,
        'watchDuration': watchDuration,
        'videoDuration': videoDuration,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
