import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/feed_model.dart';
import '../data/feed_repository.dart';

class FeedNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    return ref.read(feedRepositoryProvider).getPosts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(feedRepositoryProvider).getPosts(),
    );
  }

  Future<void> toggleLike(String postId) async {
    final current = state.valueOrNull ?? [];
    final index = current.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = current[index];
    // Optimistic update
    final updated = List<Post>.from(current);
    updated[index] = post.copyWith(
      isLiked: !post.isLiked,
      likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
    );
    state = AsyncData(updated);

    try {
      await ref.read(feedRepositoryProvider).toggleLike(postId);
    } catch (_) {
      // Revert on failure
      final revert = List<Post>.from(state.valueOrNull ?? []);
      final revertIndex = revert.indexWhere((p) => p.id == postId);
      if (revertIndex != -1) {
        revert[revertIndex] = post;
        state = AsyncData(revert);
      }
    }
  }

  void incrementCommentCount(String postId) {
    state.whenData((posts) {
      state = AsyncData(posts.map((p) {
        if (p.id != postId) return p;
        return p.copyWith(commentCount: p.commentCount + 1);
      }).toList());
    });
  }

  Future<void> createPost(String content) async {
    try {
      final newPost =
          await ref.read(feedRepositoryProvider).createPost(content);
      final current = state.valueOrNull ?? [];
      state = AsyncData([newPost, ...current]);
    } catch (e) {
      rethrow;
    }
  }
}

final feedProvider = AsyncNotifierProvider<FeedNotifier, List<Post>>(
  FeedNotifier.new,
);
