import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../data/user_detail_model.dart';

final userDetailProvider =
    FutureProvider.family<UserDetailModel, String>((ref, userId) async {
  final client = ref.read(apiClientProvider);

  final results = await Future.wait([
    client.get<Map<String, dynamic>>('/users/$userId'),
    client
        .get<Map<String, dynamic>>('/users/$userId/stats')
        .catchError((_) => <String, dynamic>{}),
    client
        .get<Map<String, dynamic>>('/users/$userId/career')
        .catchError((_) => <String, dynamic>{}),
  ]);

  final user    = results[0]['data'] as Map<String, dynamic>;
  final statsR  = results[1];
  final stats   = statsR.isNotEmpty ? statsR['data'] as Map<String, dynamic>? : null;
  final careerR = results[2];
  final career  = careerR.isNotEmpty ? careerR['data'] as Map<String, dynamic>? : null;

  return UserDetailModel.fromResponses(user: user, stats: stats, career: career);
});
