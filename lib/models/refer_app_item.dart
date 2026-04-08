class ReferAppItem {
  const ReferAppItem({
    required this.id,
    required this.name,
    required this.link,
    required this.commissionCoins,
    required this.isActive,
  });

  final String id;
  final String name;
  final String link;
  final int commissionCoins;
  final bool isActive;

  factory ReferAppItem.fromMap(String id, Map<String, dynamic> map) {
    return ReferAppItem(
      id: id,
      name: (map['name'] ?? 'App') as String,
      link: (map['link'] ?? '') as String,
      commissionCoins: (map['commissionCoins'] ?? 0) as int,
      isActive: (map['isActive'] ?? true) as bool,
    );
  }
}
