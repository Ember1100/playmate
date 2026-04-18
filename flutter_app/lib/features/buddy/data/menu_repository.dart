import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'menu_model.dart';

class MenuRepository {
  MenuRepository(this._client);

  final ApiClient _client;

  Future<List<MenuItem>> getMenus({int type = 1}) async {
    final resp = await _client.get<Map<String, dynamic>>(
      '/buddy/menus',
      params: {'type': type},
    );
    final items = resp['data'] as List<dynamic>? ?? [];
    return items.map((e) => MenuItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository(ref.watch(apiClientProvider));
});
