import 'package:flutter/material.dart';

import '../models/deck.dart';
import '../models/group.dart';
import '../models/teacher.dart';
import '../services/group_service.dart';
import '../services/teacher_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_error_body.dart';

Color _hexColor(String hex) {
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

class GroupDetailTeacherScreen extends StatefulWidget {
  const GroupDetailTeacherScreen({super.key, required this.groupId});
  final String groupId;

  @override
  State<GroupDetailTeacherScreen> createState() => _GroupDetailTeacherScreenState();
}

class _GroupDetailTeacherScreenState extends State<GroupDetailTeacherScreen> {
  GroupDetail? _group;
  List<StudentRosterItem> _students = [];
  List<ActivityEvent> _activity = [];
  bool _loading = true;
  bool _hasError = false;
  int _tab = 0; // 0=Students, 1=Decks, 2=Activity

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _hasError = false; });
    try {
      final results = await Future.wait([
        GroupService.instance.getGroup(widget.groupId),
        TeacherService.instance.getGroupStudents(widget.groupId),
        TeacherService.instance.getGroupActivity(widget.groupId),
      ]);
      if (mounted) {
        setState(() {
          _group = results[0] as GroupDetail;
          _students = results[1] as List<StudentRosterItem>;
          _activity = results[2] as List<ActivityEvent>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() { _loading = false; _hasError = true; });
        showAppToast(context, variant: ToastVariant.error, title: 'Failed to load group');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.forestGreen))
            : _hasError
                ? AppErrorBody(message: 'Could not load group', onRetry: _load)
                : Column(
                    children: [
                      _TeacherGroupHeader(
                        group: _group!,
                        tab: _tab,
                        onTabChange: (i) => setState(() => _tab = i),
                      ),
                      Expanded(child: _buildTabContent()),
                    ],
                  ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tab) {
      case 0:
        return _StudentsTab(students: _students);
      case 1:
        return _DecksTab(decks: _group!.sharedDecks);
      case 2:
        return _ActivityTab(events: _activity);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _TeacherGroupHeader extends StatelessWidget {
  const _TeacherGroupHeader({
    required this.group,
    required this.tab,
    required this.onTabChange,
  });

  final GroupDetail group;
  final int tab;
  final ValueChanged<int> onTabChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.forestGreen,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Text(group.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                    ),
                    Text(
                      '${group.memberCount} students · ${group.deckCount} decks',
                      style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Teacher view chip
              Container(
                padding: const EdgeInsets.fromLTRB(8, 3, 10, 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: AppRadius.pill,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_outlined, size: 11, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'TEACHER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Tab bar
          _TabBar(tab: tab, onTabChange: onTabChange),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.tab, required this.onTabChange});
  final int tab;
  final ValueChanged<int> onTabChange;

  @override
  Widget build(BuildContext context) {
    const labels = ['Students', 'Decks', 'Activity'];
    return Row(
      children: List.generate(labels.length, (i) {
        final active = tab == i;
        return GestureDetector(
          onTap: () => onTabChange(i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: active ? Colors.white : Colors.transparent,
                  width: 2.5,
                ),
              ),
            ),
            child: Text(
              labels[i],
              style: TextStyle(
                color: active ? Colors.white : Colors.white.withOpacity(0.55),
                fontSize: 14,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Students tab ──────────────────────────────────────────────────────────────

class _StudentsTab extends StatelessWidget {
  const _StudentsTab({required this.students});
  final List<StudentRosterItem> students;

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('👩‍🎓', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('No students yet', style: TextStyle(color: AppColors.ash, fontSize: 16)),
          ],
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(
            children: [
              Text('${students.length} students',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ash)),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Sort',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.periwinkle),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            itemCount: students.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _StudentCard(student: students[i]),
          ),
        ),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});
  final StudentRosterItem student;

  Color get _progressColor {
    if (student.progressPercent > 80) return AppColors.forestGreen;
    if (student.progressPercent > 60) return AppColors.periwinkle;
    return AppColors.bubblegum;
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = _hexColor(student.color);
    final progress = student.progressPercent / 100.0;
    final isWarn = student.streak == 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWarn ? const Color(0xFFFEF9E8) : Colors.white,
        borderRadius: AppRadius.cardBorderRadius,
        border: Border.all(color: isWarn ? AppColors.sunnyYellow : AppColors.border),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              student.initials,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        student.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                    ),
                    // Streak badge
                    if (student.streak > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.sunnyYellow,
                          borderRadius: AppRadius.pill,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department, size: 11, color: Color(0xFF7A5500)),
                            const SizedBox(width: 2),
                            Text(
                              '${student.streak}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF7A5500)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    // Due badge
                    if (student.dueCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.bubblegum.withOpacity(0.15),
                          borderRadius: AppRadius.pill,
                          border: Border.all(color: AppColors.bubblegum.withOpacity(0.6)),
                        ),
                        child: Text(
                          '${student.dueCount} due',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.bubblegum),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: AppRadius.pill,
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${student.progressPercent}%',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _progressColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Decks tab ─────────────────────────────────────────────────────────────────

class _DecksTab extends StatelessWidget {
  const _DecksTab({required this.decks});
  final List<DeckSummary> decks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: decks.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('📖', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('No decks shared yet', style: TextStyle(color: AppColors.ash, fontSize: 16)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: decks.map((d) => _DeckChip(deck: d)).toList(),
                  ),
                ),
        ),
        const _DeckActionRow(),
      ],
    );
  }
}

class _DeckChip extends StatelessWidget {
  const _DeckChip({required this.deck});
  final DeckSummary deck;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📖', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            deck.name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
          ),
          const SizedBox(width: 6),
          Text(
            '${deck.cardCount}',
            style: const TextStyle(fontSize: 11, color: AppColors.ash),
          ),
        ],
      ),
    );
  }
}

class _DeckActionRow extends StatelessWidget {
  const _DeckActionRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.pill,
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Message group',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: AppRadius.pill,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Assign deck',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Activity tab ──────────────────────────────────────────────────────────────

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({required this.events});
  final List<ActivityEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('💬', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('No activity yet', style: TextStyle(color: AppColors.ash, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: events.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        color: AppColors.border,
        indent: 52,
      ),
      itemBuilder: (context, i) => _ActivityRow(event: events[i]),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.event});
  final ActivityEvent event;

  IconData get _icon {
    switch (event.kind) {
      case 'mastered': return Icons.check_circle_outline;
      case 'streak': return Icons.local_fire_department_outlined;
      case 'quiz': return Icons.quiz_outlined;
      default: return Icons.trending_down_outlined;
    }
  }

  Color get _iconColor {
    switch (event.kind) {
      case 'mastered': return AppColors.forestGreen;
      case 'streak': return const Color(0xFFE6B547);
      case 'quiz': return AppColors.periwinkle;
      default: return AppColors.bubblegum;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, size: 16, color: _iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: AppColors.ink),
                    children: [
                      TextSpan(
                        text: event.userName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: ' ${_verb(event.kind)} '),
                      TextSpan(
                        text: event.subject,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ash),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _timeAgo(event.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.fog),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _verb(String kind) {
    switch (kind) {
      case 'mastered': return 'mastered';
      case 'streak': return 'hit a streak on';
      case 'quiz': return 'completed a quiz in';
      default: return 'is struggling with';
    }
  }
}

// ── Error body ────────────────────────────────────────────────────────────────

