class SubMenuItem {
  const SubMenuItem({
    required this.id,
    required this.name,
    required this.sort,
  });

  final int id;
  final String name;
  final int sort;

  factory SubMenuItem.fromJson(Map<String, dynamic> json) => SubMenuItem(
        id:   json['id'] as int,
        name: json['name'] as String,
        sort: json['sort'] as int? ?? 0,
      );
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.sort,
    required this.children,
  });

  final int id;
  final String name;
  final int sort;
  final List<SubMenuItem> children;

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id:       json['id'] as int,
        name:     json['name'] as String,
        sort:     json['sort'] as int? ?? 0,
        children: (json['children'] as List<dynamic>? ?? [])
            .map((e) => SubMenuItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
