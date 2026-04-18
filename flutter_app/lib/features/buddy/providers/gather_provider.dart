import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/gather_model.dart';
import '../data/gather_repository.dart';

// ── 按分类的搭子局列表 Provider ───────────────────────────────────────────────

class GatherListNotifier extends FamilyAsyncNotifier<List<Gather>, String?> {
  @override
  Future<List<Gather>> build(String? category) async {
    return ref.read(gatherRepositoryProvider).listGathers(category: category);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(gatherRepositoryProvider).listGathers(category: arg),
    );
  }

  /// 参加搭子局（乐观更新）
  Future<void> join(String gatherId) async {
    final current = state.valueOrNull ?? [];
    final index = current.indexWhere((g) => g.id == gatherId);
    if (index == -1) return;

    final original = current[index];
    // Optimistic update
    final updated = List<Gather>.from(current);
    updated[index] = original.copyWith(
      isJoined: true,
      joinedCount: original.joinedCount + 1,
    );
    state = AsyncData(updated);

    try {
      final newGather = await ref.read(gatherRepositoryProvider).joinGather(gatherId);
      final reverted = List<Gather>.from(state.valueOrNull ?? []);
      final i = reverted.indexWhere((g) => g.id == gatherId);
      if (i != -1) {
        reverted[i] = newGather;
        state = AsyncData(reverted);
      }
    } catch (e) {
      // Revert
      final reverted = List<Gather>.from(state.valueOrNull ?? []);
      final i = reverted.indexWhere((g) => g.id == gatherId);
      if (i != -1) {
        reverted[i] = original;
        state = AsyncData(reverted);
      }
      rethrow;
    }
  }

  /// 退出搭子局（乐观更新）
  Future<void> leave(String gatherId) async {
    final current = state.valueOrNull ?? [];
    final index = current.indexWhere((g) => g.id == gatherId);
    if (index == -1) return;

    final original = current[index];
    final updated = List<Gather>.from(current);
    updated[index] = original.copyWith(
      isJoined: false,
      joinedCount: (original.joinedCount - 1).clamp(0, original.capacity),
    );
    state = AsyncData(updated);

    try {
      final newGather = await ref.read(gatherRepositoryProvider).leaveGather(gatherId);
      final reverted = List<Gather>.from(state.valueOrNull ?? []);
      final i = reverted.indexWhere((g) => g.id == gatherId);
      if (i != -1) {
        reverted[i] = newGather;
        state = AsyncData(reverted);
      }
    } catch (e) {
      final reverted = List<Gather>.from(state.valueOrNull ?? []);
      final i = reverted.indexWhere((g) => g.id == gatherId);
      if (i != -1) {
        reverted[i] = original;
        state = AsyncData(reverted);
      }
      rethrow;
    }
  }

  /// 发布成功后在列表头部插入新搭子局
  void prepend(Gather gather) {
    final current = state.valueOrNull ?? [];
    state = AsyncData([gather, ...current]);
  }
}

final gatherListProvider =
    AsyncNotifierProviderFamily<GatherListNotifier, List<Gather>, String?>(
  GatherListNotifier.new,
);
