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
