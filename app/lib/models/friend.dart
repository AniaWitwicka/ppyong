class Friend {
  const Friend({
    required this.friendshipId,
    required this.userId,
    required this.name,
    required this.initials,
    required this.role,
    required this.streak,
    required this.wordCount,
    required this.dueCount,
  });

  final String friendshipId;
  final String userId;
  final String name;
  final String initials;
  final String role;
  final int streak;
  final int wordCount;
  final int dueCount;

  factory Friend.fromJson(Map<String, dynamic> j) => Friend(
        friendshipId: j['friendship_id'] as String,
        userId: j['user_id'] as String,
        name: j['name'] as String,
        initials: j['initials'] as String,
        role: j['role'] as String,
        streak: j['streak'] as int,
        wordCount: j['word_count'] as int,
        dueCount: j['due_count'] as int,
      );
}
