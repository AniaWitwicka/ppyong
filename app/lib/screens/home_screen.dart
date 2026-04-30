import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'deck_detail_screen.dart';
import 'flashcard_study_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  static const _screens = [
    _HomeTab(),
    FlashcardStudyScreen(),
    LibraryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: IndexedStack(index: _navIndex, children: _screens),
      bottomNavigationBar: _BottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      bottom: false,
      child: Column(
        children: [
          _Header(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatRow(),
                  SizedBox(height: 20),
                  _ResumeCard(),
                  SizedBox(height: 28),
                  _SectionLabel('Your collections'),
                  SizedBox(height: 12),
                  _CollectionList(),
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

class _CollectionList extends StatelessWidget {
  const _CollectionList();

  static const _collections = [
    (name: 'TOPIK Basics', decks: 4, color: AppColors.periwinkle),
    (name: 'Food & Drink', decks: 2, color: AppColors.bubblegum),
    (name: 'K-drama phrases', decks: 3, color: AppColors.sunnyYellow),
    (name: 'Numbers & Time', decks: 2, color: AppColors.forestGreen),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _collections
          .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CollectionTile(
                  name: c.name,
                  deckCount: c.decks,
                  accentColor: c.color,
                ),
              ))
          .toList(),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({
    required this.name,
    required this.deckCount,
    required this.accentColor,
  });

  final String name;
  final int deckCount;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeckDetailScreen(name: name, accentColor: accentColor),
        ),
      ),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.cardBorderRadius,
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
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
                Text(name,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '$deckCount decks',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.fog),
        ],
      ),
    ));
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.school_rounded, label: 'Learn'),
      (icon: Icons.library_books_rounded, label: 'Library'),
      (icon: Icons.person_rounded, label: 'Profile'),
    ];

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: AppColors.periwinkle,
      unselectedItemColor: AppColors.fog,
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      items: items
          .map((i) => BottomNavigationBarItem(
                icon: Icon(i.icon),
                label: i.label,
              ))
          .toList(),
    );
  }
}
