import 'package:flutter/material.dart';
import '../models/collection.dart';
import '../services/collection_service.dart';
import '../theme/app_theme.dart';
import 'collection_detail_screen.dart';
import 'flashcard_study_screen.dart';
import '../services/invite_service.dart';
import 'groups_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  int _homeRefreshKey = 0;
  int _groupsBadge = 0;

  @override
  void initState() {
    super.initState();
    _loadGroupsBadge();
  }

  Future<void> _loadGroupsBadge() async {
    try {
      final count = await InviteService.instance.pendingCount();
      if (mounted) setState(() => _groupsBadge = count);
    } catch (_) {}
  }

  void _onTabTap(int i) {
    if (i == 0 && _navIndex != 0) _homeRefreshKey++;
    // Refresh badge when leaving Groups tab
    if (_navIndex == 3 && i != 3) _loadGroupsBadge();
    setState(() => _navIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: IndexedStack(
        index: _navIndex,
        children: [
          _HomeTab(refreshKey: _homeRefreshKey),
          const FlashcardStudyScreen(),
          const LibraryScreen(),
          const GroupsScreen(),
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
  const _HomeTab({this.refreshKey = 0});
  final int refreshKey;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const _Header(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _StatRow(),
                  const SizedBox(height: 20),
                  const _ResumeCard(),
                  const SizedBox(height: 28),
                  const _SectionLabel('Your collections'),
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.periwinkle,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          Text(
            '뿅',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 36,
                ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Annyeong! 👋',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
              Text(
                'Ready to learn some Korean?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.85),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Streak',
            value: '7',
            unit: 'days',
            color: AppColors.sunnyYellow,
            icon: '🔥',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Due',
            value: '12',
            unit: 'cards',
            color: AppColors.bubblegum,
            icon: '📚',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Mastered',
            value: '34',
            unit: 'cards',
            color: AppColors.forestGreen,
            icon: '✓',
            lightText: true,
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
    required this.unit,
    required this.color,
    required this.icon,
    this.lightText = false,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;
  final String icon;
  final bool lightText;

  @override
  Widget build(BuildContext context) {
    final textColor = lightText ? Colors.white : AppColors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.cardBorderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: textColor,
                  fontSize: 24,
                ),
          ),
          Text(
            unit,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: textColor.withOpacity(0.75)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const FlashcardStudyScreen(deckName: 'TOPIK Basics — Deck 2'),
        ),
      ),
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
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
                  'Continue studying',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'TOPIK Basics — Deck 2',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              'Go →',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    ));
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
          border: Border(left: BorderSide(color: collection.color, width: 4)),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(collection.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text('${collection.deckCount} decks',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.fog),
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
