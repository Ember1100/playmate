import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/menu_model.dart';
import '../data/menu_repository.dart';

final menusProvider = FutureProvider<List<MenuItem>>((ref) {
  return ref.watch(menuRepositoryProvider).getMenus(type: 1);
});
