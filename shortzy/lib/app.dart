import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/feed/presentation/screens/feed_screen.dart';

class ShortzyApp extends ConsumerWidget {
  const ShortzyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return MaterialApp(
      title: 'Shortzy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFF00F2EA),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F2EA),
          secondary: Color(0xFFFF0050),
        ),
      ),
      home: authState.when(
        data: (user) => user != null ? const FeedScreen() : const LoginScreen(),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const LoginScreen(),
      ),
    );
  }
}
