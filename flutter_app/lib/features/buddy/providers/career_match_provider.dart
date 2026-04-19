import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/career_match_repository.dart';

// 复用线上匹配的状态枚举
enum CareerMatchStatus { idle, queued, matched, error }

class CareerMatchState {
  const CareerMatchState({
    this.status = CareerMatchStatus.idle,
    this.result,
    this.errorMessage,
    this.fields      = const [],
    this.goals       = const [],
    this.experience  = '1-3年',
  });

  final CareerMatchStatus  status;
  final CareerMatchResult? result;
  final String?            errorMessage;
  final List<String>       fields;
  final List<String>       goals;
  final String             experience;

  CareerMatchState copyWith({
    CareerMatchStatus?  status,
    CareerMatchResult?  result,
    String?             errorMessage,
    List<String>?       fields,
    List<String>?       goals,
    String?             experience,
  }) => CareerMatchState(
    status:       status       ?? this.status,
    result:       result       ?? this.result,
    errorMessage: errorMessage ?? this.errorMessage,
    fields:       fields       ?? this.fields,
    goals:        goals        ?? this.goals,
    experience:   experience   ?? this.experience,
  );
}

class CareerMatchNotifier extends Notifier<CareerMatchState> {
  Timer? _pollTimer;

  @override
  CareerMatchState build() {
    ref.onDispose(_stopPolling);
    return const CareerMatchState();
  }

  CareerMatchRepository get _repo => ref.read(careerMatchRepositoryProvider);

  Future<void> join({
    required List<String> fields,
    required List<String> goals,
    required String experience,
  }) async {
    _stopPolling();
    state = state.copyWith(
      status:     CareerMatchStatus.queued,
      fields:     fields,
      goals:      goals,
      experience: experience,
    );
    try {
      await _repo.joinMatch(fields: fields, goals: goals, experience: experience);
      _startPolling();
    } catch (e) {
      state = state.copyWith(
        status:       CareerMatchStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> leave() async {
    _stopPolling();
    try {
      await _repo.leaveMatch();
    } catch (_) {}
    state = const CareerMatchState();
  }

  Future<void> next() async {
    _stopPolling();
    state = state.copyWith(status: CareerMatchStatus.queued, result: null);
    try {
      await _repo.nextMatch(
        fields:     state.fields,
        goals:      state.goals,
        experience: state.experience,
      );
      _startPolling();
    } catch (e) {
      state = state.copyWith(
        status:       CareerMatchStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 由 WS 监听器调用（career_match_found 消息）
  void onMatchFound(CareerMatchResult result) {
    _stopPolling();
    state = state.copyWith(status: CareerMatchStatus.matched, result: result);
  }

  void reset() {
    _stopPolling();
    state = const CareerMatchState();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (state.status != CareerMatchStatus.queued) {
        _stopPolling();
        return;
      }
      try {
        final result = await _repo.getResult();
        if (result.matched) {
          _stopPolling();
          state = state.copyWith(
            status: CareerMatchStatus.matched,
            result: result,
          );
        }
      } catch (_) {}
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}

final careerMatchProvider =
    NotifierProvider<CareerMatchNotifier, CareerMatchState>(CareerMatchNotifier.new);
