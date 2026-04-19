import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../data/profile_data.dart';

final allTagsProvider = FutureProvider<List<TagModel>>((ref) async {
  final client = ref.read(apiClientProvider);
  final resp = await client.get<Map<String, dynamic>>('/tags');
  final data = resp['data'] as List<dynamic>;
  return data.map((e) => TagModel.fromJson(e as Map<String, dynamic>)).toList();
});

final myTagIdsProvider = FutureProvider<List<int>>((ref) async {
  final client = ref.read(apiClientProvider);
  final resp = await client.get<Map<String, dynamic>>('/users/me/tags');
  final data = resp['data'] as List<dynamic>;
  return data.map((e) => e['id'] as int).toList();
});

final myCareerProvider = FutureProvider<CareerModel?>((ref) async {
  final client = ref.read(apiClientProvider);
  try {
    final resp = await client.get<Map<String, dynamic>>('/users/me/career');
    final data = resp['data'];
    if (data == null) return null;
    return CareerModel.fromJson(data as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
});
