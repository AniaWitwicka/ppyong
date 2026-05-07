class Invite {
  const Invite({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.groupEmoji,
    required this.groupColor,
    required this.inviterName,
    required this.inviteeEmail,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String groupName;
  final String groupEmoji;
  final String groupColor;
  final String inviterName;
  final String inviteeEmail;
  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;

  factory Invite.fromJson(Map<String, dynamic> j) => Invite(
        id: j['id'] as String,
        groupId: j['group_id'] as String,
        groupName: j['group_name'] as String,
        groupEmoji: j['group_emoji'] as String,
        groupColor: j['group_color'] as String,
        inviterName: j['inviter_name'] as String,
        inviteeEmail: j['invitee_email'] as String,
        status: j['status'] as String,
        expiresAt: DateTime.parse(j['expires_at'] as String),
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class InviteList {
  const InviteList({required this.incoming, required this.sent});
  final List<Invite> incoming;
  final List<Invite> sent;

  factory InviteList.fromJson(Map<String, dynamic> j) => InviteList(
        incoming: (j['incoming'] as List? ?? [])
            .map((e) => Invite.fromJson(e as Map<String, dynamic>))
            .toList(),
        sent: (j['sent'] as List? ?? [])
            .map((e) => Invite.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
