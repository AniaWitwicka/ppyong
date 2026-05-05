import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_input.dart';
import '../widgets/add_collection_sheet.dart';
import 'deck_detail_screen.dart';

enum _Filter { all, inProgress, mastered, newCards }

typedef _Collection = ({
  String name,
  String emoji,
  int decks,
  int words,
  int due,
  double progress,
  Color color,
});

const _mockCollections = <_Collection>[
  (
    name: 'TOPIK Basics',
    emoji: '📚',
    decks: 4,
    words: 48,
    due: 12,
    progress: 0.45,
    color: AppColors.periwinkle,
  ),
  (
    name: 'Food & Drink',
    emoji: '🍜',
    decks: 2,
    words: 24,
    due: 3,
    progress: 0.7,
    color: AppColors.bubblegum,
  ),
  (
    name: 'K-drama phrases',
    emoji: '💬',
    decks: 3,
    words: 36,
    due: 0,
    progress: 1.0,
    color: AppColors.sunnyYellow,
  ),
  (
    name: 'Numbers & Time',
    emoji: '🕐',
    decks: 2,
    words: 20,
    due: 5,
    progress: 0.2,
    color: AppColors.forestGreen,
  ),
];

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  _Filter _filter = _Filter.all;
  String _search = '';

  List<_Collection> get _filtered {
    var list = _mockCollections.where((c) {
      if (_search.isNotEmpty) {
        return c.name.toLowerCase().contains(_search.toLowerCase());
      }
      return true;
    }).toList();

    return switch (_filter) {
      _Filter.inProgress => list.where((c) => c.progress > 0 && c.progress < 1).toList(),
      _Filter.mastered   => list.where((c) => c.progress == 1.0).toList(),
      _Filter.newCards   => list.where((c) => c.progress == 0).toList(),
      _Filter.all        => list,
    };
  }

  @override
  Widget build(BuildContext context) {
    final collections = _filtered;
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LibraryHeader(onSearch: (v) => setState(() => _search = v)),
            _FilterPills(
              selected: _filter,
              onChanged: (f) => setState(() => _filter = f),
            ),
            Expanded(
              child: collections.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      itemCount: collections.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _CollectionRow(
                        collection: collections[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DeckDetailScreen(
                              name: collections[i].name,
                              accentColor: collections[i].color,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddCollectionSheet(context),
        backgroundColor: AppColors.orange,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({required this.onSearch});
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.periwinkle,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Library',
            style: Theme.of(context)
                .textTheme
                .displayMedium
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          AppInput(
            hint: 'Search collections...',
            onChanged: onSearch,
            prefixIcon: const Icon(Icons.search, color: AppColors.fog, size: 20),
          ),
        ],
      ),
    );
  }
}

class _FilterPills extends StatelessWidget {
  const _FilterPills({required this.selected, required this.onChanged});
  final _Filter selected;
  final ValueChanged<_Filter> onChanged;

  static const _options = [
    (_Filter.all, 'All'),
    (_Filter.inProgress, 'In progress'),
    (_Filter.mastered, 'Mastered'),
    (_Filter.newCards, 'New'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: _options.map((opt) {
            final (filter, label) = opt;
            final isSelected = selected == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onChanged(filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.periwinkle : Colors.white,
                    borderRadius: AppRadius.pill,
                    border: Border.all(
                      color: isSelected ? AppColors.periwinkle : AppColors.border,
                    ),
                  ),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected ? Colors.white : AppColors.ash,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({required this.collection, required this.onTap});
  final _Collection collection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: collection.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(collection.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          collection.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                        ),
                      ),
                      if (collection.due > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: const BoxDecoration(
                            color: AppColors.bubblegum,
                            borderRadius: AppRadius.pill,
                          ),
                          child: Text(
                            '${collection.due} due',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${collection.decks} decks · ${collection.words} words',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.ash, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: AppRadius.pill,
                    child: LinearProgressIndicator(
                      value: collection.progress,
                      backgroundColor: collection.color.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation(collection.color),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded, color: AppColors.fog, size: 20),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📚', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'No collections yet',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first collection',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.ash),
          ),
        ],
      ),
    );
  }
}
