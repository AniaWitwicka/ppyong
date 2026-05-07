class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.initials,
    required this.streak,
    required this.bestStreak,
    required this.lastActive,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String initials;
  final int streak;
  final int bestStreak;
  final DateTime lastActive;

  String get displayRole => role[0].toUpperCase() + role.substring(1);

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: j['id'] as String,
        name: j['name'] as String,
        email: j['email'] as String,
        role: j['role'] as String,
        initials: j['initials'] as String,
        streak: j['streak'] as int,
        bestStreak: j['best_streak'] as int,
        lastActive: DateTime.parse(j['last_active'] as String),
      );
}

class UserStats {
  const UserStats({
    required this.masteredCount,
    required this.learningCount,
    required this.sessionCount,
    required this.accuracyPercent,
    required this.weeklyActivity,
  });

  final int masteredCount;
  final int learningCount;
  final int sessionCount;
  final int accuracyPercent;
  final List<bool> weeklyActivity; // index 0 = Mon, 6 = Sun

  factory UserStats.fromJson(Map<String, dynamic> j) => UserStats(
        masteredCount: j['mastered_count'] as int,
        learningCount: j['learning_count'] as int,
        sessionCount: j['session_count'] as int,
        accuracyPercent: j['accuracy_percent'] as int,
        weeklyActivity: (j['weekly_activity'] as List).cast<bool>(),
      );
}

class UserSettings {
  const UserSettings({
    required this.notificationsEnabled,
    required this.studyReminderTime,
  });

  final bool notificationsEnabled;
  final String studyReminderTime; // "HH:MM" 24h

  String get displayReminderTime {
    final parts = studyReminderTime.split(':');
    final h = int.parse(parts[0]);
    final m = parts[1];
    final suffix = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $suffix';
  }

  UserSettings copyWith({bool? notificationsEnabled, String? studyReminderTime}) =>
      UserSettings(
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        studyReminderTime: studyReminderTime ?? this.studyReminderTime,
      );

  factory UserSettings.fromJson(Map<String, dynamic> j) => UserSettings(
        notificationsEnabled: j['notifications_enabled'] as bool,
        studyReminderTime: j['study_reminder_time'] as String,
      );
}

class UserSummary {
  const UserSummary({
    required this.id,
    required this.name,
    required this.initials,
    required this.role,
  });

  final String id;
  final String name;
  final String initials;
  final String role;

  factory UserSummary.fromJson(Map<String, dynamic> j) => UserSummary(
        id: j['id'] as String,
        name: j['name'] as String,
        initials: j['initials'] as String? ?? '',
        role: j['role'] as String,
      );
}
