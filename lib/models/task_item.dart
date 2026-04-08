class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.link,
    required this.rewardCoins,
    required this.isActive,
  });

  final String id;
  final String title;
  final String link;
  final int rewardCoins;
  final bool isActive;

  factory TaskItem.fromMap(String id, Map<String, dynamic> map) {
    return TaskItem(
      id: id,
      title: (map['title'] ?? '') as String,
      link: (map['link'] ?? '') as String,
      rewardCoins: (map['rewardCoins'] ?? 0) as int,
      isActive: (map['isActive'] ?? true) as bool,
    );
  }
}
