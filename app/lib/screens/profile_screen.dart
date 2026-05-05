import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/app_toast.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  UserStats? _stats;
  UserSettings? _settings;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _hasError = false; });
    try {
      final results = await Future.wait([
        UserService.instance.getMe(),
        UserService.instance.getMyStats(),
        UserService.instance.getMySettings(),
      ]);
      setState(() {
        _profile = results[0] as UserProfile;
        _stats   = results[1] as UserStats;
        _settings = results[2] as UserSettings;
        _loading = false;
      });
    } catch (_) {
      setState(() { _loading = false; _hasError = true; });
      if (mounted) {
        showAppToast(context,
            variant: ToastVariant.error,
            title: 'Failed to load profile',
            subtitle: 'Check your connection and try again');
      }
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    // Optimistic update
    setState(() => _settings = _settings?.copyWith(notificationsEnabled: value));
    try {
      final updated = await UserService.instance.updateSettings(notificationsEnabled: value);
      setState(() => _settings = updated);
    } catch (_) {
      // Revert
      setState(() => _settings = _settings?.copyWith(notificationsEnabled: !value));
      if (mounted) {
        showAppToast(context,
            variant: ToastVariant.error,
            title: 'Could not save setting',
            subtitle: 'Try again in a moment');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.offWhite,
        body: Center(child: CircularProgressIndicator(color: AppColors.periwinkle)),
      );
    }

    if (_hasError || _profile == null) {
      return Scaffold(
        backgroundColor: AppColors.offWhite,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😕', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text('Could not load profile',
                  style: TextStyle(color: AppColors.ash, fontSize: 16)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _load,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: const BoxDecoration(
                      color: AppColors.periwinkle, borderRadius: AppRadius.pill),
                  child: const Text('Try again',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _profile!;
    final stats = _stats!;
    final settings = _settings!;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _ProfileHeader(
                name: profile.name,
                email: profile.email,
                role: profile.displayRole,
                initials: profile.initials,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StreakBanner(
                      streak: profile.streak,
                      best: profile.bestStreak,
                      weeklyActivity: stats.weeklyActivity,
                    ),
                    const SizedBox(height: 16),
                    _StatsGrid(
                      mastered: stats.masteredCount,
                      learning: stats.learningCount,
                      sessions: stats.sessionCount,
                      accuracy: stats.accuracyPercent,
                    ),
                    const SizedBox(height: 24),
                    _SettingsSection(
                      notificationsOn: settings.notificationsEnabled,
                      reminderTime: settings.displayReminderTime,
                      onNotificationsToggle: _toggleNotifications,
                    ),
                    const SizedBox(height: 16),
                    const _AccountSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.role,
    required this.initials,
  });

  final String name;
  final String email;
  final String role;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.sunnyYellow,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.sunnyYellow,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(name,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(email,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: const Color(0xFF7A5500), fontSize: 13)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: const BoxDecoration(
                color: AppColors.ink, borderRadius: AppRadius.pill),
            child: Text(role,
                style: const TextStyle(
                    color: AppColors.sunnyYellow,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Streak banner ─────────────────────────────────────────────────────────

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({
    required this.streak,
    required this.best,
    required this.weeklyActivity,
  });

  final int streak;
  final int best;
  final List<bool> weeklyActivity;

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
          color: AppColors.orange, borderRadius: AppRadius.cardBorderRadius),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current streak',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white.withOpacity(0.85))),
                const SizedBox(height: 4),
                Text('$streak days 🔥',
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge
                        ?.copyWith(color: Colors.white, fontSize: 32)),
                const SizedBox(height: 4),
                Text('Best: $best days',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white.withOpacity(0.7))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Row(
                children: List.generate(7, (i) {
                  final done = i < weeklyActivity.length && weeklyActivity[i];
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? Colors.white : Colors.white.withOpacity(0.3),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(7, (i) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: SizedBox(
                    width: 22,
                    child: Text(_days[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stats grid ────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.mastered,
    required this.learning,
    required this.sessions,
    required this.accuracy,
  });

  final int mastered;
  final int learning;
  final int sessions;
  final int accuracy;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatTile(label: 'Mastered', value: '$mastered', unit: 'cards',
            bg: const Color(0xFFE8F5EE), valueColor: AppColors.forestGreen),
        _StatTile(label: 'Learning', value: '$learning', unit: 'cards',
            bg: const Color(0xFFEEF3FE), valueColor: AppColors.periwinkle),
        _StatTile(label: 'Sessions', value: '$sessions', unit: 'total',
            bg: const Color(0xFFFEF9E8), valueColor: const Color(0xFF7A5500)),
        _StatTile(label: 'Accuracy', value: '$accuracy%', unit: 'avg',
            bg: const Color(0xFFFEF0F6), valueColor: AppColors.bubblegum),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.bg,
    required this.valueColor,
  });

  final String label;
  final String value;
  final String unit;
  final Color bg;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.cardBorderRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.ash, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .displayMedium
                      ?.copyWith(color: valueColor, fontSize: 26)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: valueColor.withOpacity(0.7), fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Settings ──────────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.notificationsOn,
    required this.reminderTime,
    required this.onNotificationsToggle,
  });

  final bool notificationsOn;
  final String reminderTime;
  final ValueChanged<bool> onNotificationsToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SETTINGS',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.fog,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
        const SizedBox(height: 10),
        Container(
          decoration: const BoxDecoration(
              color: Colors.white, borderRadius: AppRadius.cardBorderRadius),
          child: Column(
            children: [
              _SettingsRow(
                icon: Icons.person_outline_rounded,
                iconColor: AppColors.periwinkle,
                iconBg: const Color(0xFFEEF3FE),
                label: 'Edit profile',
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.fog, size: 20),
                onTap: () {},
              ),
              const _SettingsDivider(),
              _SettingsRow(
                icon: Icons.notifications_outlined,
                iconColor: AppColors.forestGreen,
                iconBg: const Color(0xFFE8F5EE),
                label: 'Notifications',
                trailing: Switch(
                  value: notificationsOn,
                  onChanged: onNotificationsToggle,
                  activeColor: AppColors.forestGreen,
                ),
                onTap: null,
              ),
              const _SettingsDivider(),
              _SettingsRow(
                icon: Icons.alarm_outlined,
                iconColor: AppColors.orange,
                iconBg: const Color(0xFFFEF3EC),
                label: 'Study reminder',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(reminderTime,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.ash)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.fog, size: 20),
                  ],
                ),
                onTap: () {},
              ),
              const _SettingsDivider(),
              _SettingsRow(
                icon: Icons.flag_outlined,
                iconColor: AppColors.bubblegum,
                iconBg: const Color(0xFFFEF0F6),
                label: 'Weak words',
                trailing: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chevron_right_rounded,
                        color: AppColors.fog, size: 20),
                  ],
                ),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardBorderRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style: Theme.of(context).textTheme.bodyLarge)),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 62),
      child: Divider(color: AppColors.border, height: 1),
    );
  }
}

// ── Account ───────────────────────────────────────────────────────────────

class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.cardBorderRadius,
        border: Border.all(color: AppColors.bubblegum, width: 1.5),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: AppRadius.cardBorderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, color: AppColors.bubblegum, size: 20),
              const SizedBox(width: 14),
              Text('Sign out',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                          color: AppColors.bubblegum,
                          fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
