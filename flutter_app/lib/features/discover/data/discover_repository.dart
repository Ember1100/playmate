import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'discover_model.dart';

class DiscoverRepository {
  DiscoverRepository(this._client);

  final ApiClient _client;

  Future<List<MatchCandidate>> getCandidates() async {
    final resp = await _client.get<Map<String, dynamic>>('/match/candidates');
    final data = resp['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => MatchCandidate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> respond({
    required String userId,
    required bool accept,
  }) async {
    await _client.post<dynamic>(
      '/match/respond',
      data: {
        'user_id': userId,
        'accept': accept,
      },
    );
  }
}

final discoverRepositoryProvider = Provider<DiscoverRepository>((ref) {
  return DiscoverRepository(ref.watch(apiClientProvider));
});
