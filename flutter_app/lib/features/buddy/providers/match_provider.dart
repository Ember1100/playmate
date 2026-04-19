import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/match_repository.dart';

enum MatchStatus { idle, queued, matched, error }

class MatchState {
  const MatchState({
    this.status = MatchStatus.idle,
    this.result,
    this.errorMessage,
    this.activities = const [],
    this.mood = 0,
    this.genderPref = 0,
  });

  final MatchStatus    status;
  final MatchResult?   result;
  final String?        errorMessage;
  final List<String>   activities;
  final int            mood;
  final int            genderPref;

  MatchState copyWith({
    MatchStatus? status,
    MatchResult? result,
    String?      errorMessage,
    List<String>? activities,
    int?         mood,
    int?         genderPref,
  }) => MatchState(
    status:       status       ?? this.status,
    result:       result       ?? this.result,
    errorMessage: errorMessage ?? this.errorMessage,
    activities:   activities   ?? this.activities,
    mood:         mood         ?? this.mood,
    genderPref:   genderPref   ?? this.genderPref,
  );
}

class MatchNotifier extends Notifier<MatchState> {
  Timer? _pollTimer;

  @override
  MatchState build() {
    ref.onDispose(_stopPolling);
    return const MatchState();
  }

  MatchRepository get _repo => ref.read(matchRepositoryProvider);

  Future<void> join({
    required List<String> activities,
    required int mood,
    required int genderPref,
  }) async {
    _stopPolling();
    state = state.copyWith(
      status:     MatchStatus.queued,
      activities: activities,
      mood:       mood,
      genderPref: genderPref,
    );
    try {
      await _repo.joinMatch(activities: activities, mood: mood, genderPref: genderPref);
      _startPolling();
    } catch (e) {
      state = state.copyWith(status: MatchStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> leave() async {
    _stopPolling();
    try {
      await _repo.leaveMatch();
    } catch (_) {}
    state = const MatchState();
  }

  Future<void> next() async {
    _stopPolling();
    state = state.copyWith(status: MatchStatus.queued, result: null);
    try {
      await _repo.nextMatch(
        activities: state.activities,
        mood:       state.mood,
        genderPref: state.genderPref,
      );
      _startPolling();
    } catch (e) {
      state = state.copyWith(status: MatchStatus.error, errorMessage: e.toString());
    }
  }

  /// Called by WS listener when a `match_found` message arrives
  void onMatchFound(MatchResult result) {
    _stopPolling();
    state = state.copyWith(status: MatchStatus.matched, result: result);
  }

  void reset() {
    _stopPolling();
    state = const MatchState();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (state.status != MatchStatus.queued) {
        _stopPolling();
        return;
      }
      try {
        final result = await _repo.getResult();
        if (result.matched) {
          _stopPolling();
          state = state.copyWith(status: MatchStatus.matched, result: result);
        }
      } catch (_) {}
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }


}

final matchProvider = NotifierProvider<MatchNotifier, MatchState>(MatchNotifier.new);
