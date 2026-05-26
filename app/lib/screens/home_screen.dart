import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/collection.dart';
import '../models/user.dart';
import '../services/collection_service.dart';
import '../services/teacher_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import 'collection_detail_screen.dart';
import 'flashcard_study_screen.dart';
import 'learn_screen.dart';
import '../services/invite_service.dart';
import 'groups_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import 'teacher_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  int _homeRefreshKey = 0;
  int _groupsBadge = 0;
  String _userRole = '';
  String _activeRole = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadGroupsBadge();
    _loadUserRole();
  }

  Future<void> _loadGroupsBadge() async {
    try {
      final count = await InviteService.instance.pendingCount();
      if (mounted) setState(() => _groupsBadge = count);
    } catch (_) {}
  }

  Future<void> _loadUserRole() async {
    try {
      final user = await UserService.instance.getMe();
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('activeRole_${user.id}');
      final defaultRole =
          (user.role == 'teacher' || user.role == 'admin') ? 'teacher' : 'learner';
      setState(() {
        _userId = user.id;
        _userRole = user.role;
        _activeRole = saved ?? defaultRole;
      });
      if (user.role == 'teacher' || user.role == 'admin') {
        TeacherService.instance.prefetch();
      }
    } catch (_) {}
  }

  Future<void> _setActiveRole(String role) async {
    if (_userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeRole_$_userId', role);
    if (mounted) setState(() => _activeRole = role);
  }

  bool get _isTeacher => _userRole == 'teacher' || _userRole == 'admin';

  void _onTabTap(int i) {
    if (i == 0 && _navIndex != 0) _homeRefreshKey++;
    // Refresh badge when leaving Groups tab
    if (_navIndex == 3 && i != 3) _loadGroupsBadge();
    setState(() => _navIndex = i);
  }

  Widget get _homeContent {
    if (_isTeacher && _activeRole == 'teacher') {
      return TeacherDashboardScreen(
        key: const ValueKey('teacher_home'),
        onSwitchView: () => _setActiveRole('learner'),
      );
    }
    return _HomeTab(
      key: ValueKey('student_home_$_homeRefreshKey'),
      refreshKey: _homeRefreshKey,
      isTeacher: _isTeacher,
      onSwitchToTeacher: _isTeacher ? () => _setActiveRole('teacher') : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: IndexedStack(
        index: _navIndex,
        children: [
          _homeContent,
          const LearnScreen(),
          const LibraryScreen(),
          GroupsScreen(isTeacher: _isTeacher),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _navIndex,
        onTap: _onTabTap,
        groupsBadge: _groupsBadge,
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    super.key,
    this.refreshKey = 0,
    this.isTeacher = false,
    this.onSwitchToTeacher,
  });

  final int refreshKey;
  final bool isTeacher;
  final VoidCallback? onSwitchToTeacher;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _Header(
            isTeacher: isTeacher,
            onSwitchToTeacher: onSwitchToTeacher,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ResumeCard(),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const _SectionLabel('Your collections'),
                      GestureDetector(
                        onTap: () => context
                            .findAncestorStateOfType<_HomeScreenState>()!
                            ._onTabTap(2),
                        child: Text(
                          'See all',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.periwinkle,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _CollectionList(refreshKey: refreshKey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatefulWidget {
  const _Header({this.isTeacher = false, this.onSwitchToTeacher});

  final bool isTeacher;
  final VoidCallback? onSwitchToTeacher;

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  String _initials = '';
  String _name = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await UserService.instance.getMe();
      if (mounted) setState(() { _initials = user.initials; _name = user.name.split(' ').first; });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.periwinkle,
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
                      _name.isEmpty ? '반가워요! 👋' : '$_name! 👋',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                    ),
                    if (widget.isTeacher && widget.onSwitchToTeacher != null) ...[
                      const SizedBox(height: 8),
                      _StudentRoleChip(onTap: widget.onSwitchToTeacher!),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      color: AppColors.periwinkle,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _StatRow(),
        ],
      ),
    );
  }
}

class _StudentRoleChip extends StatelessWidget {
  const _StudentRoleChip({required this.onTap});
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
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 5,
              height: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.sunnyYellow,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SizedBox(width: 5),
            Text(
              'STUDENT VIEW',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
            SizedBox(width: 3),
            Icon(Icons.chevron_right, color: Colors.white, size: 12),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatefulWidget {
  const _StatRow();

  @override
  State<_StatRow> createState() => _StatRowState();
}

class _StatRowState extends State<_StatRow> {
  int _streak = 0;
  int _due = 0;
  int _mastered = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        UserService.instance.getMe(),
        UserService.instance.getMyStats(),
      ]);
      final profile = results[0] as UserProfile;
      final stats = results[1] as UserStats;
      if (mounted) {
        setState(() {
          _streak = profile.streak;
          _due = stats.dueCount;
          _mastered = stats.masteredCount;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Streak',
            value: '$_streak',
            bgColor: AppColors.sunnyYellow,
            borderColor: const Color(0xFFE6B547),
            textColor: const Color(0xFF7A5500),
            icon: Icons.local_fire_department,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Due today',
            value: '$_due',
            bgColor: AppColors.bubblegum,
            borderColor: const Color(0xFFD070A0),
            textColor: const Color(0xFF8B1A4A),
            icon: Icons.schedule_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Mastered',
            value: '$_mastered',
            bgColor: const Color(0xFFE8F5EE),
            borderColor: AppColors.forestGreen,
            textColor: const Color(0xFF16563A),
            icon: Icons.check,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.icon,
  });

  final String label;
  final String value;
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

class _ResumeCard extends StatefulWidget {
  const _ResumeCard();

  @override
  State<_ResumeCard> createState() => _ResumeCardState();
}

class _ResumeCardState extends State<_ResumeCard> {
  String? _deckId;
  String? _deckName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('last_deck_id');
    final name = prefs.getString('last_deck_name');
    if (mounted && id != null) {
      setState(() { _deckId = id; _deckName = name; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLastDeck = _deckId != null;

    return GestureDetector(
      onTap: () {
        if (hasLastDeck) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FlashcardStudyScreen(deckId: _deckId, deckName: _deckName),
            ),
          );
        } else {
          // No deck studied yet — send to Library to pick one
          context.findAncestorStateOfType<_HomeScreenState>()!._onTabTap(2);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.orange,
          borderRadius: AppRadius.cardBorderRadius,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasLastDeck ? 'Continue studying' : 'Start studying',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasLastDeck ? (_deckName ?? '') : 'Pick a deck from your library',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.pill,
              ),
              child: Text(
                hasLastDeck ? 'Go →' : 'Browse →',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.headlineMedium);
  }
}

class _CollectionList extends StatefulWidget {
  const _CollectionList({this.refreshKey = 0});
  final int refreshKey;

  @override
  State<_CollectionList> createState() => _CollectionListState();
}

class _CollectionListState extends State<_CollectionList> {
  List<Collection> _collections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_CollectionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) _load();
  }

  Future<void> _load() async {
    try {
      final collections = await CollectionService.instance.listCollections();
      if (mounted) setState(() { _collections = collections; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(color: AppColors.periwinkle),
        ),
      );
    }
    if (_collections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text('No collections yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ash)),
      );
    }
    return Column(
      children: _collections
          .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CollectionTile(collection: c),
              ))
          .toList(),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({required this.collection});

  final Collection collection;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CollectionDetailScreen(
            collectionId: collection.id,
            collectionName: collection.name,
            accentColor: collection.color,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.cardBorderRadius,
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
            Row(
              children: [
                // Emoji icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: collection.color.withOpacity(0.15),
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                  ),
                  child: Center(
                    child: Text(collection.emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(collection.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        '${collection.deckCount} deck${collection.deckCount == 1 ? '' : 's'} · ${collection.wordCount} words',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                // Due badge
                if (collection.dueCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.bubblegum,
                      borderRadius: AppRadius.pill,
                    ),
                    child: Text(
                      '${collection.dueCount} due',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AppColors.fog),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: AppRadius.pill,
              child: LinearProgressIndicator(
                value: collection.progress,
                minHeight: 5,
                backgroundColor: collection.color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(collection.color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
    this.groupsBadge = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int groupsBadge;

  @override
  Widget build(BuildContext context) {
    // Tab indices: 0=Home, 1=Learn, 2=Library, 3=Groups, 4=Profile
    const tabs = [
      (icon: Icons.home_rounded, label: 'Home', activeColor: AppColors.periwinkle),
      (icon: Icons.school_rounded, label: 'Learn', activeColor: AppColors.periwinkle),
      (icon: Icons.library_books_rounded, label: 'Library', activeColor: AppColors.periwinkle),
      (icon: Icons.group_rounded, label: 'Groups', activeColor: AppColors.bubblegum),
      (icon: Icons.person_rounded, label: 'Profile', activeColor: AppColors.sunnyYellow),
    ];

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: tabs[currentIndex].activeColor,
      unselectedItemColor: AppColors.fog,
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      items: tabs.asMap().entries.map((e) {
        final i = e.key;
        final tab = e.value;
        Widget icon = Icon(tab.icon, size: 22);
        if (i == 3 && groupsBadge > 0) {
          icon = Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(tab.icon, size: 22),
              Positioned(
                top: -4,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: AppColors.orange, shape: BoxShape.circle),
                  child: Text('$groupsBadge',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          );
        }
        return BottomNavigationBarItem(icon: icon, label: tab.label);
      }).toList(),
    );
  }
}
