import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'gather_model.dart';

class GatherRepository {
  GatherRepository(this._client);

  final ApiClient _client;

  /// 搭子局列表
  Future<List<Gather>> listGathers({String? category, int page = 1, int limit = 20}) async {
    final resp = await _client.get<Map<String, dynamic>>(
      '/buddy/gathers',
      params: {
        'page': page,
        'limit': limit,
        if (category != null) 'category': category,
      },
    );
    final pageData = resp['data'] as Map<String, dynamic>? ?? {};
    final items = pageData['items'] as List<dynamic>? ?? [];
    return items.map((e) => Gather.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 搭子局详情
  Future<Gather> getGather(String gatherId) async {
    final resp = await _client.get<Map<String, dynamic>>('/buddy/gathers/$gatherId');
    return Gather.fromJson(resp['data'] as Map<String, dynamic>);
  }

  /// 发起搭子局
  Future<Gather> createGather(CreateGatherRequest req) async {
    final resp = await _client.post<Map<String, dynamic>>(
      '/buddy/gathers',
      data: req.toJson(),
    );
    return Gather.fromJson(resp['data'] as Map<String, dynamic>);
  }

  /// 参加搭子局
  Future<Gather> joinGather(String gatherId) async {
    final resp = await _client.post<Map<String, dynamic>>('/buddy/gathers/$gatherId/join');
    return Gather.fromJson(resp['data'] as Map<String, dynamic>);
  }

  /// 退出搭子局
  Future<Gather> leaveGather(String gatherId) async {
    final resp = await _client.post<Map<String, dynamic>>('/buddy/gathers/$gatherId/leave');
    return Gather.fromJson(resp['data'] as Map<String, dynamic>);
  }

  /// 取消搭子局
  Future<void> cancelGather(String gatherId) async {
    await _client.post<dynamic>('/buddy/gathers/$gatherId/cancel');
  }
}

final gatherRepositoryProvider = Provider<GatherRepository>((ref) {
  return GatherRepository(ref.watch(apiClientProvider));
});
