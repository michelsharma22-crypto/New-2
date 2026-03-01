import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../domain/entities/transaction.dart';
import '../../data/repositories/wallet_repository_impl.dart';

part 'wallet_provider.g.dart';

@riverpod
WalletRepositoryImpl walletRepository(WalletRepositoryRef ref) {
  return WalletRepositoryImpl(
    FirebaseFirestore.instance,
    FirebaseFunctions.instance,
  );
}

@riverpod
Future<double> userBalance(UserBalanceRef ref, String userId) async {
  final repo = ref.watch(walletRepositoryProvider);
  final result = await repo.getBalance(userId);
  return result.getOrElse(() => 0.0);
}

@riverpod
Future<List<Transaction>> userTransactions(UserTransactionsRef ref, String userId) async {
  final repo = ref.watch(walletRepositoryProvider);
  final result = await repo.getTransactions(userId);
  return result.getOrElse(() => []);
}

@riverpod
class WalletController extends _$WalletController {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> requestWithdrawal(String userId, double amount, Map<String, dynamic> bankDetails) async {
    state = const AsyncValue.loading();
    final repo = ref.read(walletRepositoryProvider);
    final result = await repo.requestWithdrawal(userId, amount, bankDetails);
    
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }
}
