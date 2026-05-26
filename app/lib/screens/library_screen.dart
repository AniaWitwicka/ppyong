import 'package:flutter/material.dart';
import '../models/collection.dart';
import '../services/collection_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_input.dart';
import '../widgets/app_toast.dart';
import '../widgets/add_collection_sheet.dart';
import 'collection_detail_screen.dart';

enum _Filter { all, inProgress, mastered, newCards }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Collection> _collections = [];
  bool _loading = true;
  bool _hasError = false;
  _Filter _filter = _Filter.all;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _hasError = false; });
    try {
      final collections = await CollectionService.instance.listCollections();
      setState(() { _collections = collections; _loading = false; });
    } catch (_) {
      setState(() { _loading = false; _hasError = true; });
      if (mounted) {
        showAppToast(context,
            variant: ToastVariant.error,
            title: 'Failed to load collections',
            subtitle: 'Check your connection and try again');
      }
    }
  }

  List<Collection> get _filtered {
    var list = _collections.where((c) {
      if (_search.isNotEmpty) {
        return c.name.toLowerCase().contains(_search.toLowerCase());
      }
      return true;
    }).toList();

    return switch (_filter) {
      _Filter.inProgress => list.where((c) => c.progress > 0 && c.progress < 1).toList(),
      _Filter.mastered   => list.where((c) => c.progress >= 1.0).toList(),
      _Filter.newCards   => list.where((c) => c.progress == 0).toList(),
      _Filter.all        => list,
    };
  }

  @override
  Widget build(BuildContext context) {
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
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () async {
          await showAddCollectionSheet(context);
          _load();
        },
        backgroundColor: AppColors.orange,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.periwinkle),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('Could not load collections',
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
      );
    }

    final collections = _filtered;
    if (collections.isEmpty) return const _EmptyState();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: collections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _CollectionRow(
        collection: collections[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CollectionDetailScreen(
              collectionId: collections[i].id,
              collectionName: collections[i].name,
              accentColor: collections[i].color,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────

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

// ── Filter pills ──────────────────────────────────────────────────────────

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

// ── Collection row ────────────────────────────────────────────────────────

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({required this.collection, required this.onTap});
  final Collection collection;
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
                      if (collection.dueCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: const BoxDecoration(
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
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${collection.deckCount} decks · ${collection.wordCount} words',
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

// ── Empty state ───────────────────────────────────────────────────────────

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
          Text('No collections yet',
              style: Theme.of(context).textTheme.headlineMedium),
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
