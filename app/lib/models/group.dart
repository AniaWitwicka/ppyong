import 'deck.dart';

class MemberAvatar {
  const MemberAvatar({required this.initials, required this.color});
  final String initials;
  final String color;

  factory MemberAvatar.fromJson(Map<String, dynamic> j) => MemberAvatar(
        initials: j['initials'] as String,
        color: j['color'] as String,
      );
}

class GroupSummary {
  const GroupSummary({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.memberCount,
    required this.deckCount,
    required this.avatars,
    this.lastActive,
  });

  final String id;
  final String name;
  final String emoji;
  final String color;
  final int memberCount;
  final int deckCount;
  final DateTime? lastActive;
  final List<MemberAvatar> avatars;

  factory GroupSummary.fromJson(Map<String, dynamic> j) => GroupSummary(
        id: j['id'] as String,
        name: j['name'] as String,
        emoji: j['emoji'] as String,
        color: j['color'] as String,
        memberCount: j['member_count'] as int,
        deckCount: j['deck_count'] as int,
        lastActive: j['last_active'] != null
            ? DateTime.parse(j['last_active'] as String)
            : null,
        avatars: (j['avatars'] as List? ?? [])
            .map((e) => MemberAvatar.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class GroupMember {
  const GroupMember({
    required this.userId,
    required this.name,
    required this.initials,
    required this.role,
    required this.progress,
  });

  final String userId;
  final String name;
  final String initials;
  final String role; // "owner" | "member"
  final double progress;

  factory GroupMember.fromJson(Map<String, dynamic> j) => GroupMember(
        userId: j['user_id'] as String,
        name: j['name'] as String,
        initials: j['initials'] as String,
        role: j['role'] as String,
        progress: (j['progress'] as num).toDouble(),
      );
}

class GroupDetail {
  const GroupDetail({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.memberCount,
    required this.deckCount,
    required this.isOwner,
    required this.members,
    required this.sharedDecks,
  });

  final String id;
  final String name;
  final String emoji;
  final String color;
  final int memberCount;
  final int deckCount;
  final bool isOwner;
  final List<GroupMember> members;
  final List<DeckSummary> sharedDecks;

  factory GroupDetail.fromJson(Map<String, dynamic> j) => GroupDetail(
        id: j['id'] as String,
        name: j['name'] as String,
        emoji: j['emoji'] as String,
        color: j['color'] as String,
        memberCount: j['member_count'] as int,
        deckCount: j['deck_count'] as int,
        isOwner: j['is_owner'] as bool? ?? false,
        members: (j['members'] as List? ?? [])
            .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
            .toList(),
        sharedDecks: (j['shared_decks'] as List? ?? [])
            .map((e) => DeckSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
