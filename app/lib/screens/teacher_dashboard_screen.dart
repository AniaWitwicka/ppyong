import 'package:flutter/material.dart';

import '../models/teacher.dart';
import '../models/user.dart';
import '../services/teacher_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import 'assign_deck_sheet.dart';
import 'group_detail_teacher_screen.dart';
import 'import_deck_screen.dart';

Color _hex(String hex) {
  final clean = hex.replaceFirst('#', '');
  return Color(int.parse('FF$clean', radix: 16));
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key, required this.onSwitchView});
  final VoidCallback onSwitchView;

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  TeacherDashboard? _data;
  bool _loading = true;
  String _teacherName = '';
  String _initials = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Show cached data instantly if available, refresh in background
    final cached = TeacherService.instance.cachedDashboard;
    final cachedProfile = UserService.instance.cachedProfile;
    if (cached != null && cachedProfile != null) {
      if (mounted) {
        setState(() {
          _data = cached;
          _teacherName = cachedProfile.name.split(' ').first;
          _initials = cachedProfile.initials;
          _loading = false;
        });
      }
      _refreshInBackground();
      return;
    }
    try {
      final results = await Future.wait([
        TeacherService.instance.getDashboard(refresh: true),
        UserService.instance.getMe(refresh: true),
      ]);
      final dashboard = results[0] as TeacherDashboard;
      final user = results[1] as UserProfile;
      if (mounted) {
        setState(() {
          _data = dashboard;
          _teacherName = user.name.split(' ').first;
          _initials = user.initials;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      final results = await Future.wait([
        TeacherService.instance.getDashboard(refresh: true),
        UserService.instance.getMe(refresh: true),
      ]);
      final dashboard = results[0] as TeacherDashboard;
      final user = results[1] as UserProfile;
      if (mounted) {
        setState(() {
          _data = dashboard;
          _teacherName = user.name.split(' ').first;
          _initials = user.initials;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SafeArea(
        child: Center(child: CircularProgressIndicator(color: AppColors.forestGreen)),
      );
    }
    if (_data == null) {
      return const SafeArea(
        child: Center(child: Text('Failed to load dashboard')),
      );
    }
    final d = _data!;

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Column(
            children: [
              _TeacherHeader(
                teacherName: _teacherName,
                initials: _initials,
                data: d,
                onSwitchView: widget.onSwitchView,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (d.attention.isNotEmpty) ...[
                        _AttentionSection(items: d.attention),
                        const SizedBox(height: 24),
                      ],
                      _GroupsSection(groups: d.groups),
                      const SizedBox(height: 24),
                      _ActivitySection(events: d.recentActivity),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ImportFab(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportDeckScreen()))),
                const SizedBox(height: 10),
                _AssignFab(onTap: () => showAssignDeckSheet(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _TeacherHeader extends StatelessWidget {
  const _TeacherHeader({
    required this.teacherName,
    required this.initials,
    required this.data,
    required this.onSwitchView,
  });

  final String teacherName;
  final String initials;
  final TeacherDashboard data;
  final VoidCallback onSwitchView;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.forestGreen,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative circle — bleeds outside the header top-right
          const Positioned(
            right: -24,
            top: -36,
            child: SizedBox(
              width: 140,
              height: 140,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0x1FFFFFFF), // white 12%
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '안녕하세요,',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Nunito',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            teacherName.isEmpty ? '선생님' : '$teacherName 선생님',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontSize: 22,
                                ),
                          ),
                          const SizedBox(height: 8),
                          _RoleChip(
                            label: 'TEACHER VIEW',
                            onTap: onSwitchView,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.sunnyYellow,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Color(0xFF7A5500),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _TeacherStatRow(data: data),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 3, 10, 3),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: AppRadius.pill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.sunnyYellow,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.chevron_right, color: Colors.white, size: 12),
          ],
        ),
      ),
    );
  }
}

// ── Stat row ─────────────────────────────────────────────────────────────────

class _TeacherStatRow extends StatelessWidget {
  const _TeacherStatRow({required this.data});
  final TeacherDashboard data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Active today',
            value: '${data.activeToday}',
            total: '${data.totalStudents}',
            bgColor: AppColors.sunnyYellow,
            borderColor: const Color(0xFFE6B547),
            textColor: const Color(0xFF7A5500),
            icon: Icons.local_fire_department,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: 'Avg accuracy',
            value: '${data.avgAccuracy}%',
            bgColor: const Color(0xFFE8F5EE),
            borderColor: AppColors.forestGreen,
            textColor: const Color(0xFF16563A),
            icon: Icons.trending_up,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: 'Decks live',
            value: '${data.decksAssigned}',
            bgColor: AppColors.periwinkle,
            borderColor: const Color(0xFF7B9CE5),
            textColor: const Color(0xFF1A3A7A),
            icon: Icons.layers_outlined,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.total,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.icon,
  });

  final String label;
  final String value;
  final String? total;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Stack(
        children: [
          // Icon box top-right
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.55),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 13, color: textColor),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      height: 1.1,
                    ),
                  ),
                  if (total != null) ...[
                    const SizedBox(width: 1),
                    Text(
                      '/$total',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: textColor.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Needs attention ───────────────────────────────────────────────────────────

class _AttentionSection extends StatelessWidget {
  const _AttentionSection({required this.items});
  final List<AttentionItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Needs attention',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: const BoxDecoration(
                color: AppColors.bubblegum,
                borderRadius: AppRadius.pill,
              ),
              child: Text(
                '${items.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            Text(
              'See all',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.ash,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _AttentionCard(item: item)),
      ],
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.item});
  final AttentionItem item;

  @override
  Widget build(BuildContext context) {
    final isUrgent = item.severity == 'urgent';
    final bgColor =
        isUrgent ? const Color(0xFFFEF0F6) : const Color(0xFFFEF9E8);
    final borderColor =
        isUrgent ? AppColors.bubblegum : AppColors.sunnyYellow;
    final avatarColor = _hex(item.color);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GroupDetailTeacherScreen(groupId: item.groupId)),
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: avatarColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                item.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Nunito',
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.fog.withOpacity(0.25),
                        borderRadius: AppRadius.pill,
                      ),
                      child: Text(
                        item.groupName,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.ash,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.reason,
                  style: const TextStyle(fontSize: 12, color: AppColors.ash),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.fog, size: 18),
        ],
      ),
    ),
    );
  }
}

// ── My groups ─────────────────────────────────────────────────────────────────

class _GroupsSection extends StatelessWidget {
  const _GroupsSection({required this.groups});
  final List<TeacherGroupSummary> groups;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('My groups',
                style: Theme.of(context).textTheme.headlineMedium),
            const Spacer(),
            Text(
              'Manage',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.periwinkle,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (groups.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No groups yet',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.ash),
            ),
          )
        else
          ...groups.map((g) => _GroupCard(group: g)),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});
  final TeacherGroupSummary group;

  @override
  Widget build(BuildContext context) {
    final borderColor = _hex(group.color);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(group.emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Nunito',
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${group.memberCount} students · ${group.deckCount} decks',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.ash),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.fog,
                    size: 18),
              ],
            ),
          ),
          // Divider + avatars + class avg
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: AppColors.border.withOpacity(0.6), width: 1),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                // Overlapping avatars
                if (group.avatars.isNotEmpty)
                  SizedBox(
                    width: 22 + (group.avatars.length - 1) * 16.0,
                    height: 22,
                    child: Stack(
                      children: group.avatars.asMap().entries.map((e) {
                        return Positioned(
                          left: e.key * 16.0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _hex(e.value.color),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                e.value.initials.isNotEmpty
                                    ? e.value.initials[0]
                                    : '?',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(width: 8),
                const Text(
                  'class avg',
                  style: TextStyle(fontSize: 10, color: AppColors.ash),
                ),
                const Spacer(),
                Text(
                  '${group.classAvg}%',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: ClipRRect(
              borderRadius: AppRadius.pill,
              child: LinearProgressIndicator(
                value: group.classAvg / 100,
                minHeight: 5,
                backgroundColor: borderColor.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(borderColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent activity ───────────────────────────────────────────────────────────

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.events});
  final List<ActivityEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Recent activity',
                style: Theme.of(context).textTheme.headlineMedium),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.periwinkle.withOpacity(0.12),
                borderRadius: AppRadius.pill,
                border: Border.all(color: AppColors.periwinkle.withOpacity(0.4)),
              ),
              child: const Text(
                'Today',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.periwinkle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No activity yet',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.ash),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.cardBorderRadius,
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: events.asMap().entries.map((e) {
                return _ActivityItem(
                  event: e.value,
                  isLast: e.key == events.length - 1,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.event, required this.isLast});
  final ActivityEvent event;
  final bool isLast;

  (Color, Color, IconData) get _style {
    switch (event.kind) {
      case 'mastered':
        return (const Color(0xFFE8F5EE), AppColors.forestGreen, Icons.check);
      case 'streak':
        return (const Color(0xFFFFF8E7), const Color(0xFF7A5500),
            Icons.local_fire_department);
      case 'quiz':
        return (const Color(0xFFEEF3FE), AppColors.periwinkle,
            Icons.track_changes);
      case 'weak':
        return (
          const Color(0xFFFEF0F6),
          AppColors.bubblegum,
          Icons.auto_awesome
        );
      default:
        return (const Color(0xFFEEF3FE), AppColors.periwinkle, Icons.info);
    }
  }

  String get _verb {
    switch (event.kind) {
      case 'mastered':
        return ' mastered ';
      case 'streak':
        return ' is on a streak — ';
      case 'quiz':
        return ' quizzed ';
      case 'weak':
        return ' struggled with ';
      default:
        return ' ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bgColor, iconColor, icon) = _style;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: event.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppColors.ink,
                        ),
                      ),
                      TextSpan(
                        text: _verb,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.ash),
                      ),
                      TextSpan(
                        text: event.subject,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _timeAgo(event.createdAt),
                style: const TextStyle(fontSize: 10, color: AppColors.fog),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, color: AppColors.border.withOpacity(0.8)),
      ],
    );
  }
}

// ── FABs ──────────────────────────────────────────────────────────────────────

class _ImportFab extends StatelessWidget {
  const _ImportFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.upload_outlined, color: AppColors.forestGreen, size: 22),
      ),
    );
  }
}

class _AssignFab extends StatelessWidget {
  const _AssignFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: AppColors.orange,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0xFFD85F22),
              offset: Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
    );
  }
}
