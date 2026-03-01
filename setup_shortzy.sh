[#!/bin/bash

set -e

echo "🚀 Shortzy - Complete Watch-to-Earn App Setup"
echo "=============================================="

PROJECT_NAME="shortzy"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${YELLOW}Installing Flutter...${NC}"
    git clone https://github.com/flutter/flutter.git -b stable $HOME/flutter
    export PATH="$PATH:$HOME/flutter/bin"
    echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
fi

echo -e "${GREEN}✓ Flutter found${NC}"

# Create Project
echo -e "${YELLOW}Creating Flutter Project...${NC}"
rm -rf $PROJECT_NAME 2>/dev/null || true
flutter create $PROJECT_NAME --platforms web,android,ios --org com.shortzy
cd $PROJECT_NAME

# Create folder structure
echo -e "${YELLOW}Creating Folder Structure...${NC}"
mkdir -p lib/{core/{errors,utils,usecases,network},config/{routes,theme,constants},providers,services}
mkdir -p lib/features/auth/{data/{models,datasources,repositories},domain/{entities,repositories,usecases},presentation/{providers,screens,widgets}}
mkdir -p lib/features/feed/{data/{models,datasources,repositories},domain/{entities,repositories,usecases},presentation/{providers,screens,widgets}}
mkdir -p lib/features/upload/{data/{datasources,repositories},domain/{repositories,usecases},presentation/{providers,screens}}
mkdir -p lib/features/wallet/{data/{models,datasources,repositories},domain/{entities,repositories,usecases},presentation/{providers,screens,widgets}}
mkdir -p lib/features/profile/{data,domain,presentation}
mkdir -p {assets/{animations,icons,images},web/icons}

echo -e "${GREEN}✓ Folders created${NC}"

# ============================================
# 1. PUBSPEC.YAML
# ============================================
cat > pubspec.yaml << 'EOF'
name: shortzy
description: Production-grade Watch-to-Earn Short Video Platform
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_storage: ^11.6.0
  firebase_analytics: ^10.8.0
  firebase_crashlytics: ^3.4.9
  cloud_functions: ^4.6.0
  
  # State Management
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
  
  # Video & Media
  video_player: ^2.8.1
  chewie: ^1.7.1
  flutter_cache_manager: ^3.3.1
  cached_video_player_plus: ^3.0.1
  ffmpeg_kit_flutter: ^6.0.3
  video_compress: ^3.1.2
  visibility_detector: ^0.4.0+2
  image_picker: ^1.0.7
  camera: ^0.10.5+9
  
  # Auth
  google_sign_in: ^6.2.1
  sign_in_with_apple: ^5.0.1
  
  # UI
  flutter_screenutil: ^5.9.0
  shimmer: ^3.0.0
  lottie: ^3.0.0
  flutter_animate: ^4.3.0
  smooth_page_indicator: ^1.1.0
  
  # Navigation
  auto_route: ^7.8.4
  
  # Data
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  
  # Security
  flutter_secure_storage: ^9.0.0
  local_auth: ^2.2.0
  crypto: ^3.0.3
  
  # Network
  dio: ^5.4.0
  connectivity_plus: ^5.0.2
  
  # Utils
  equatable: ^2.0.5
  dartz: ^0.10.1
  uuid: ^4.3.3
  intl: ^0.19.0
  path_provider: ^2.1.1
  permission_handler: ^11.2.0
  share_plus: ^7.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.7
  freezed: ^2.4.6
  json_serializable: ^6.7.1
  riverpod_generator: ^2.3.9
  auto_route_generator: ^7.3.2

flutter:
  uses-material-design: true
  assets:
    - assets/animations/
    - assets/icons/
    - assets/images/
EOF

echo -e "${GREEN}✓ pubspec.yaml created${NC}"

# ============================================
# 2. CORE FILES
# ============================================

cat > lib/main.dart << 'EOF'
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: ShortzyApp()));
}
EOF

cat > lib/app.dart << 'EOF'
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
EOF

cat > lib/core/errors/failures.dart << 'EOF'
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);
  
  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class InsufficientBalanceFailure extends Failure {
  const InsufficientBalanceFailure() : super('Insufficient balance');
}
EOF

cat > lib/core/usecases/usecase.dart << 'EOF'
import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {
  const NoParams();
}
EOF

cat > lib/core/utils/video_cache_manager.dart << 'EOF'
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class VideoCacheManager {
  static const key = 'videoCache';
  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 50,
    ),
  );
  
  static Future<String> getVideoPath(String url) async {
    final file = await instance.getFileFromCache(url);
    if (file != null) return file.file.path;
    final newFile = await instance.downloadFile(url);
    return newFile.file.path;
  }
  
  static Future<void> preCacheVideo(String url) async {
    await instance.downloadFile(url);
  }
}
EOF

echo -e "${GREEN}✓ Core files created${NC}"

# ============================================
# 3. AUTH FEATURE
# ============================================

cat > lib/features/auth/domain/entities/user.dart << 'EOF'
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
EOF

cat > lib/features/auth/domain/repositories/auth_repository.dart << 'EOF'
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  Future<Either<Failure, User>> signInWithGoogle();
  Future<Either<Failure, User>> signInWithEmail(String email, String password);
  Future<Either<Failure, User>> signUp(String email, String password, String username);
  Future<Either<Failure, void>> signOut();
}
EOF

cat > lib/features/auth/data/models/user_model.dart << 'EOF'
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
EOF

cat > lib/features/auth/data/datasources/auth_remote_datasource.dart << 'EOF'
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithGoogle();
  Future<UserModel> signInWithEmail(String email, String password);
  Future<UserModel> signUpWithEmail(String email, String password, String username);
  Future<void> signOut();
  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    required firebase_auth.FirebaseAuth auth,
    required GoogleSignIn googleSignIn,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _googleSignIn = googleSignIn,
        _firestore = firestore;

  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return _getUserFromFirestore(firebaseUser.uid);
    });
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Sign in aborted');

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = firebase_auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final firebaseUser = userCredential.user!;
    
    final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
    
    if (!userDoc.exists) {
      final newUser = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email!,
        username: googleUser.displayName ?? 'User_${firebaseUser.uid.substring(0, 6)}',
        avatarUrl: googleUser.photoUrl,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toJson());
      return newUser;
    }
    
    return UserModel.fromJson(userDoc.data()!);
  }

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _getUserFromFirestore(credential.user!.uid);
  }

  @override
  Future<UserModel> signUpWithEmail(String email, String password, String username) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final newUser = UserModel(
      uid: credential.user!.uid,
      email: email,
      username: username,
      createdAt: DateTime.now(),
    );
    
    await _firestore.collection('users').doc(credential.user!.uid).set(newUser.toJson());
    return newUser;
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<UserModel> _getUserFromFirestore(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('User not found');
    return UserModel.fromJson(doc.data()!);
  }
}
EOF

cat > lib/features/auth/data/repositories/auth_repository_impl.dart << 'EOF'
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Stream<User?> get authStateChanges => _remoteDataSource.authStateChanges;

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      final user = await _remoteDataSource.signInWithGoogle();
      return Right(user.toEntity());
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithEmail(String email, String password) async {
    try {
      final user = await _remoteDataSource.signInWithEmail(email, password);
      return Right(user.toEntity());
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signUp(String email, String password, String username) async {
    try {
      final user = await _remoteDataSource.signUpWithEmail(email, password, username);
      return Right(user.toEntity());
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
EOF

cat > lib/features/auth/presentation/providers/auth_provider.dart << 'EOF'
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';

part 'auth_provider.g.dart';

@riverpod
AuthRepositoryImpl authRepository(AuthRepositoryRef ref) {
  return AuthRepositoryImpl(
    AuthRemoteDataSourceImpl(
      auth: firebase_auth.FirebaseAuth.instance,
      googleSignIn: GoogleSignIn(),
      firestore: FirebaseFirestore.instance,
    ),
  );
}

@riverpod
Stream<User?> authState(AuthStateRef ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}

@riverpod
User? currentUser(CurrentUserRef ref) {
  return ref.watch(authStateProvider).valueOrNull;
}

@riverpod
class AuthController extends _$AuthController {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.signInWithGoogle();
    
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.signInWithEmail(email, password);
    
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }

  Future<void> signUp(String email, String password, String username) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.signUp(email, password, username);
    
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.signOut();
    
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }
}
EOF

cat > lib/features/auth/presentation/screens/login_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    
    ref.listen(authControllerProvider, (_, next) {
      next.whenOrNull(
        error: (error, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        ),
      );
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Color(0xFF1a1a2e)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_circle_fill,
                  size: 100,
                  color: Color(0xFF00F2EA),
                ),
                const SizedBox(height: 20),
                Text(
                  'Shortzy',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: authState.isLoading
                        ? null
                        : () {
                            if (_isSignUp) {
                              ref.read(authControllerProvider.notifier).signUp(
                                    _emailController.text,
                                    _passwordController.text,
                                    'user_${DateTime.now().millisecondsSinceEpoch}',
                                  );
                            } else {
                              ref.read(authControllerProvider.notifier).signInWithEmail(
                                    _emailController.text,
                                    _passwordController.text,
                                  );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF0050),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: authState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp ? 'Already have an account? Sign In' : 'Create Account',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.grey),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
                    icon: const Icon(Icons.g_mobiledata, size: 30),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
EOF

echo -e "${GREEN}✓ Auth feature created${NC}"

# ============================================
# 4. FEED FEATURE
# ============================================

cat > lib/features/feed/domain/entities/video.dart << 'EOF'
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
EOF

cat > lib/features/feed/data/models/video_model.dart << 'EOF'
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
EOF

cat > lib/features/feed/data/datasources/feed_remote_datasource.dart << 'EOF'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video_model.dart';

abstract class FeedRemoteDataSource {
  Future<List<VideoModel>> getFeedVideos({String? lastVideoId, int limit = 10});
  Future<void> likeVideo(String videoId, String userId);
  Future<void> incrementViews(String videoId);
}

class FeedRemoteDataSourceImpl implements FeedRemoteDataSource {
  final FirebaseFirestore _firestore;

  FeedRemoteDataSourceImpl(this._firestore);

  @override
  Future<List<VideoModel>> getFeedVideos({String? lastVideoId, int limit = 10}) async {
    Query query = _firestore
        .collection('videos')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastVideoId != null) {
      final lastDoc = await _firestore.collection('videos').doc(lastVideoId).get();
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return VideoModel.fromJson({...data, 'id': doc.id});
    }).toList();
  }

  @override
  Future<void> likeVideo(String videoId, String userId) async {
    final batch = _firestore.batch();
    
    batch.update(_firestore.collection('videos').doc(videoId), {
      'likesCount': FieldValue.increment(1),
    });
    
    batch.set(
      _firestore.collection('videos').doc(videoId).collection('likes').doc(userId),
      {'timestamp': FieldValue.serverTimestamp()},
    );
    
    await batch.commit();
  }

  @override
  Future<void> incrementViews(String videoId) async {
    await _firestore.collection('videos').doc(videoId).update({
      'viewsCount': FieldValue.increment(1),
    });
  }
}
EOF

cat > lib/features/feed/data/repositories/feed_repository_impl.dart << 'EOF'
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
EOF

cat > lib/features/feed/presentation/providers/feed_provider.dart << 'EOF'
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
EOF

cat > lib/features/feed/presentation/widgets/video_player_item.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../core/utils/video_cache_manager.dart';

class VideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  final bool isCurrentPage;

  const VideoPlayerItem({
    super.key,
    required this.videoUrl,
    required this.isCurrentPage,
  });

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final cachedPath = await VideoCacheManager.getVideoPath(widget.videoUrl);
      _controller = VideoPlayerController.networkUrl(Uri.parse(cachedPath));
      
      await _controller!.initialize();
      await _controller!.setLooping(true);
      
      if (mounted) {
        setState(() => _isInitialized = true);
        if (widget.isCurrentPage && _isVisible) {
          _controller!.play();
        }
      }
    } catch (e) {
      debugPrint('Video initialization error: $e');
    }
  }

  @override
  void didUpdateWidget(VideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentPage != oldWidget.isCurrentPage) {
      _handlePlayState();
    }
  }

  void _handlePlayState() {
    if (!_isInitialized || _controller == null) return;
    
    if (widget.isCurrentPage && _isVisible) {
      _controller!.play();
    } else {
      _controller!.pause();
      _controller!.seekTo(Duration.zero);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.videoUrl),
      onVisibilityChanged: (info) {
        _isVisible = info.visibleFraction > 0.5;
        _handlePlayState();
      },
      child: Container(
        color: Colors.black,
        child: _isInitialized && _controller != null
            ? AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              )
            : const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00F2EA),
                ),
              ),
      ),
    );
  }
}
EOF

cat > lib/features/feed/presentation/widgets/video_overlay.dart << 'EOF'
import 'package:flutter/material.dart';
import '../../domain/entities/video.dart';

class VideoOverlay extends StatelessWidget {
  final Video video;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final double coinsEarned;

  const VideoOverlay({
    super.key,
    required this.video,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    this.coinsEarned = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      icon: Icons.favorite,
                      count: video.likesCount,
                      onTap: onLike,
                      color: video.isLiked ? Colors.red : Colors.white,
                    ),
                    const SizedBox(height: 20),
                    _buildActionButton(
                      icon: Icons.comment,
                      count: video.commentsCount,
                      onTap: onComment,
                    ),
                    const SizedBox(height: 20),
                    _buildActionButton(
                      icon: Icons.share,
                      count: video.sharesCount,
                      onTap: onShare,
                    ),
                    const SizedBox(height: 30),
                    if (coinsEarned > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.black, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '+\$${coinsEarned.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: video.creatorAvatarUrl != null
                      ? NetworkImage(video.creatorAvatarUrl!)
                      : null,
                  child: video.creatorAvatarUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${video.creatorName ?? 'user'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        video.caption,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 35),
          const SizedBox(height: 4),
          Text(
            _formatCount(count),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
EOF

cat > lib/features/feed/presentation/screens/feed_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feed_provider.dart';
import '../widgets/video_player_item.dart';
import '../widgets/video_overlay.dart';
import '../../wallet/presentation/screens/wallet_screen.dart';
import '../../profile/presentation/screens/profile_screen.dart';
import '../../upload/presentation/screens/upload_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final PageController _pageController = PageController();
  final Map<int, double> _earnings = {};

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    ref.read(currentVideoIndexProvider.notifier).setIndex(index);
    
    if (_earnings.containsKey(index - 1)) {
      _showEarningAnimation(_earnings[index - 1]!);
    }
  }

  void _showEarningAnimation(double amount) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.monetization_on, color: Colors.amber),
            const SizedBox(width: 8),
            Text('Earned \$${amount.toStringAsFixed(2)}!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedControllerProvider);
    final currentIndex = ref.watch(currentVideoIndexProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: feedState.when(
        data: (videos) => PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          onPageChanged: _onPageChanged,
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            final isCurrentPage = index == currentIndex;
            
            return Stack(
              fit: StackFit.expand,
              children: [
                VideoPlayerItem(
                  videoUrl: video.videoUrl,
                  isCurrentPage: isCurrentPage,
                ),
                VideoOverlay(
                  video: video,
                  onLike: () {},
                  onComment: () {},
                  onShare: () {},
                  coinsEarned: _earnings[index] ?? 0,
                ),
              ],
            );
          },
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00F2EA)),
        ),
        error: (error, _) => Center(
          child: Text('Error: $error', style: const TextStyle(color: Colors.white)),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFF00F2EA),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Upload'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen()));
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
          } else if (index == 4) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }
        },
      ),
    );
  }
}
EOF

echo -e "${GREEN}✓ Feed feature created${NC}"

# ============================================
# 5. WALLET FEATURE
# ============================================

cat > lib/features/wallet/domain/entities/transaction.dart << 'EOF'
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
EOF

cat > lib/features/wallet/data/repositories/wallet_repository_impl.dart << 'EOF'
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
EOF

cat > lib/features/wallet/presentation/providers/wallet_provider.dart << 'EOF'
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
EOF

cat > lib/features/wallet/presentation/screens/wallet_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/wallet_provider.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final balanceAsync = ref.watch(userBalanceProvider(user.uid));
    final transactionsAsync = ref.watch(userTransactionsProvider(user.uid));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Wallet'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00F2EA), Color(0xFF00D4AA)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Balance',
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  balanceAsync.when(
                    data: (balance) => Text(
                      '\$${balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Error loading balance'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showWithdrawalDialog(context, ref, user.uid),
                    icon: const Icon(Icons.account_balance),
                    label: const Text('Withdraw'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: const Color(0xFF00F2EA),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildStatCard('Total Earnings', '\$${user.totalEarnings.toStringAsFixed(2)}'),
                const SizedBox(width: 16),
                _buildStatCard('Videos Watched', '124'),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Recent Transactions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            transactionsAsync.when(
              data: (transactions) => ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  return _buildTransactionItem(tx);
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error loading transactions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(dynamic tx) {
    final bool isEarn = tx.type.toString().contains('earn');
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEarn ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isEarn ? Icons.add : Icons.remove,
          color: isEarn ? Colors.green : Colors.orange,
        ),
      ),
      title: Text(
        tx.type.toString().split('.').last,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        tx.createdAt?.toString() ?? '',
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: Text(
        '${isEarn ? '+' : '-'}\$${tx.amount.toStringAsFixed(2)}',
        style: TextStyle(
          color: isEarn ? Colors.green : Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showWithdrawalDialog(BuildContext context, WidgetRef ref, String userId) {
    final amountController = TextEditingController();
    final accountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('Withdraw Funds', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Amount',
                labelStyle: TextStyle(color: Colors.grey),
                prefixText: '\$ ',
                prefixStyle: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: accountController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Bank Account / PayPal',
                labelStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              ref.read(walletControllerProvider.notifier).requestWithdrawal(
                    userId,
                    amount,
                    {'account': accountController.text},
                  );
              Navigator.pop(context);
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }
}
EOF

echo -e "${GREEN}✓ Wallet feature created${NC}"

# ============================================
# 6. UPLOAD FEATURE
# ============================================

cat > lib/features/upload/presentation/screens/upload_screen.dart << 'EOF'
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  File? _videoFile;
  final _captionController = TextEditingController();
  bool _isUploading = false;
  double _uploadProgress = 0;

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _videoFile = File(picked.path));
    }
  }

  Future<void> _uploadVideo() async {
    if (_videoFile == null) return;
    
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      final info = await VideoCompress.compressVideo(
        _videoFile!.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
      );

      final compressedFile = File(info!.path!);

      final ref = FirebaseStorage.instance
          .ref()
          .child('videos')
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.mp4');

      final uploadTask = ref.putFile(
        compressedFile,
        SettableMetadata(contentType: 'video/mp4'),
      );

      uploadTask.snapshotEvents.listen((event) {
        setState(() {
          _uploadProgress = event.bytesTransferred / event.totalBytes;
        });
      });

      final snapshot = await uploadTask;
      final videoUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('videos').add({
        'videoUrl': videoUrl,
        'thumbnailUrl': '',
        'creatorId': user.uid,
        'creatorName': user.username,
        'creatorAvatarUrl': user.avatarUrl,
        'caption': _captionController.text,
        'hashtags': [],
        'likesCount': 0,
        'commentsCount': 0,
        'sharesCount': 0,
        'viewsCount': 0,
        'earningsGenerated': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video uploaded successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Upload Video'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _isUploading ? null : _pickVideo,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey),
                ),
                child: _videoFile != null
                    ? const Center(
                        child: Icon(Icons.video_file, size: 80, color: Color(0xFF00F2EA)),
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Tap to select video', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Add a caption...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            if (_isUploading) ...[
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF00F2EA)),
              ),
              const SizedBox(height: 16),
              Text(
                '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _videoFile != null ? _uploadVideo : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0050),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Upload', style: TextStyle(fontSize: 18)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
EOF

echo -e "${GREEN}✓ Upload feature created${NC}"

# ============================================
# 7. PROFILE FEATURE
# ============================================

cat > lib/features/profile/presentation/screens/profile_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null ? const Icon(Icons.person, size: 50) : null,
            ),
            const SizedBox(height: 16),
            Text(
              '@${user.username ?? 'user'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.email,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat('Videos', '0'),
                _buildStat('Followers', '0'),
                _buildStat('Following', '0'),
                _buildStat('Likes', '0'),
              ],
            ),
            const SizedBox(height: 32),
            if (!user.isCreator)
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.verified),
                label: const Text('Become a Creator'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F2EA),
                  foregroundColor: Colors.black,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
EOF

echo -e "${GREEN}✓ Profile feature created${NC}"

# ============================================
# 8. WEB & FIREBASE CONFIG
# ============================================

cat > web/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="Shortzy - Watch to Earn Short Video Platform">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="Shortzy">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  <link rel="icon" type="image/png" href="favicon.png"/>
  <title>Shortzy</title>
  <link rel="manifest" href="manifest.json">
  <script>
    const serviceWorkerVersion = null;
  </script>
  <script src="flutter.js" defer></script>
</head>
<body>
  <script>
    window.addEventListener('load', function(ev) {
      _flutter.loader.loadEntrypoint({
        serviceWorker: {
          serviceWorkerVersion: serviceWorkerVersion,
        },
        onEntrypointLoaded: function(engineInitializer) {
          engineInitializer.initializeEngine().then(function(appRunner) {
            appRunner.runApp();
          });
        }
      });
    });
  </script>
</body>
</html>
EOF

cat > lib/firebase_options.dart << 'EOF'
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_AUTH_DOMAIN',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'YOUR_BUNDLE_ID',
  );
}
EOF

echo -e "${GREEN}✓ Web & Firebase config created${NC}"

# ============================================
# 9. FINAL COMMANDS
# ============================================

echo ""
echo -e "${YELLOW}Running Flutter commands...${NC}"

flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

echo ""
echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}✅ SHORTZY SETUP COMPLETE!${NC}"
echo -e "${GREEN}==============================================${NC}"
echo ""
echo "Next steps:"
echo "1. Configure Firebase: flutterfire configure"
echo "2. Run: flutter run -d web-server --web-port 8080"
echo "3. Or: flutter build web"
echo ""
echo -e "${YELLOW}Happy coding! 🚀${NC}"]
