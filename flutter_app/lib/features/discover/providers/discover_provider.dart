import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/discover_model.dart';
import '../data/discover_repository.dart';

class CandidatesNotifier extends AsyncNotifier<List<MatchCandidate>> {
  @override
  Future<List<MatchCandidate>> build() async {
    return ref.read(discoverRepositoryProvider).getCandidates();
  }

  Future<void> skip(String userId) async {
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((c) => c.id != userId).toList());
  }

  Future<void> like(String userId) async {
    try {
      await ref.read(discoverRepositoryProvider).respond(
            userId: userId,
            accept: true,
          );
    } catch (_) {
      // Ignore errors, still remove from list
    }
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((c) => c.id != userId).toList());
  }
}

final candidatesProvider =
    AsyncNotifierProvider<CandidatesNotifier, List<MatchCandidate>>(
  CandidatesNotifier.new,
);
