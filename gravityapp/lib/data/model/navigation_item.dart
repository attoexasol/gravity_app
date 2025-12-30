class NavigationItem {
  final int index;
  final String label;
  final String icon;
  final String route;

  const NavigationItem({
    required this.index,
    required this.label,
    required this.icon,
    required this.route,
  });

  /// Optional: for dynamic nav from API / config
  factory NavigationItem.fromJson(Map<String, dynamic> json) {
    return NavigationItem(
      index: json['index'],
      label: json['label'],
      icon: json['icon'],
      route: json['route'],
    );
  }
}
