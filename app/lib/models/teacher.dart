class MemberAvatar {
  const MemberAvatar({required this.initials, required this.color});
  final String initials;
  final String color; // hex e.g. "#99B7F5"

  factory MemberAvatar.fromJson(Map<String, dynamic> j) => MemberAvatar(
        initials: j['initials'] as String,
        color: j['color'] as String,
      );
}

class AttentionItem {
  const AttentionItem({
    required this.userId,
    required this.name,
    required this.initials,
    required this.color,
    required this.groupId,
    required this.groupName,
    required this.reason,
    required this.severity,
  });

  final String userId;
  final String name;
  final String initials;
  final String color;
  final String groupId;
  final String groupName;
  final String reason;
  final String severity; // 'urgent' | 'warn'

  factory AttentionItem.fromJson(Map<String, dynamic> j) => AttentionItem(
        userId: j['user_id'] as String,
        name: j['name'] as String,
        initials: j['initials'] as String,
        color: j['color'] as String,
        groupId: j['group_id'] as String,
        groupName: j['group_name'] as String,
        reason: j['reason'] as String,
        severity: j['severity'] as String,
      );
}

class TeacherGroupSummary {
  const TeacherGroupSummary({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.memberCount,
    required this.deckCount,
    this.lastActive,
    required this.classAvg,
    required this.avatars,
  });

  final String id;
  final String name;
  final String emoji;
  final String color;
  final int memberCount;
  final int deckCount;
  final DateTime? lastActive;
  final int classAvg;
  final List<MemberAvatar> avatars;

  factory TeacherGroupSummary.fromJson(Map<String, dynamic> j) =>
      TeacherGroupSummary(
        id: j['id'] as String,
        name: j['name'] as String,
        emoji: j['emoji'] as String,
        color: j['color'] as String,
        memberCount: j['member_count'] as int,
        deckCount: j['deck_count'] as int,
        lastActive: j['last_active'] != null
            ? DateTime.parse(j['last_active'] as String)
            : null,
        classAvg: j['class_avg'] as int,
        avatars: (j['avatars'] as List)
            .map((a) => MemberAvatar.fromJson(a as Map<String, dynamic>))
            .toList(),
      );
}

class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.userName,
    required this.initials,
    required this.kind,
    required this.subject,
    required this.target,
    required this.createdAt,
  });

  final String id;
  final String userName;
  final String initials;
  final String kind; // 'mastered' | 'streak' | 'quiz' | 'weak'
  final String subject;
  final String target;
  final DateTime createdAt;

  factory ActivityEvent.fromJson(Map<String, dynamic> j) => ActivityEvent(
        id: j['id'] as String,
        userName: j['user_name'] as String,
        initials: j['initials'] as String,
        kind: j['kind'] as String,
        subject: j['subject'] as String,
        target: j['target'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class StudentRosterItem {
  const StudentRosterItem({
    required this.userId,
    required this.name,
    required this.initials,
    required this.color,
    required this.streak,
    required this.dueCount,
    required this.progressPercent,
  });

  final String userId;
  final String name;
  final String initials;
  final String color;
  final int streak;
  final int dueCount;
  final int progressPercent;

  factory StudentRosterItem.fromJson(Map<String, dynamic> j) => StudentRosterItem(
        userId: j['user_id'] as String,
        name: j['name'] as String,
        initials: j['initials'] as String,
        color: j['color'] as String,
        streak: j['streak'] as int,
        dueCount: j['due_count'] as int,
        progressPercent: j['progress_percent'] as int,
      );
}

class TeacherDashboard {
  const TeacherDashboard({
    required this.activeToday,
    required this.totalStudents,
    required this.avgAccuracy,
    required this.decksAssigned,
    required this.attention,
    required this.groups,
    required this.recentActivity,
  });

  final int activeToday;
  final int totalStudents;
  final int avgAccuracy;
  final int decksAssigned;
  final List<AttentionItem> attention;
  final List<TeacherGroupSummary> groups;
  final List<ActivityEvent> recentActivity;

  factory TeacherDashboard.fromJson(Map<String, dynamic> j) => TeacherDashboard(
        activeToday: j['active_today'] as int,
        totalStudents: j['total_students'] as int,
        avgAccuracy: j['avg_accuracy'] as int,
        decksAssigned: j['decks_assigned'] as int,
        attention: (j['attention'] as List)
            .map((a) => AttentionItem.fromJson(a as Map<String, dynamic>))
            .toList(),
        groups: (j['groups'] as List)
            .map((g) =>
                TeacherGroupSummary.fromJson(g as Map<String, dynamic>))
            .toList(),
        recentActivity: (j['recent_activity'] as List)
            .map((e) => ActivityEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
