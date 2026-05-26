import 'package:flutter/material.dart';

import '../services/collection_service.dart';
import '../services/deck_service.dart';
import '../services/group_service.dart';
import '../services/teacher_service.dart';
import '../theme/app_theme.dart';

Future<void> showAssignDeckSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AssignDeckSheet(),
  );
}

class AssignDeckSheet extends StatefulWidget {
  const AssignDeckSheet({super.key});

  @override
  State<AssignDeckSheet> createState() => _AssignDeckSheetState();
}

class _AssignDeckSheetState extends State<AssignDeckSheet> {
  int _step = 0;
  String? _selectedDeckId;
  String? _selectedDeckName;
  bool _busy = false;

  Future<void> _onAssign(List<String> groupIds) async {
    setState(() => _busy = true);
    try {
      await Future.wait(
        groupIds.map((gid) async {
          final detail = await GroupService.instance.getGroup(gid);
          final memberIds = detail.members.map((m) => m.userId).toList();
          await DeckService.instance.shareDeck(_selectedDeckId!, memberIds);
        }),
      );
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(SnackBar(
          content: Text(
            'Deck assigned to ${groupIds.length} group${groupIds.length == 1 ? '' : 's'}',
          ),
        ));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to assign deck')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.85,
      builder: (ctx, _) => Container(
        decoration: const BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _SheetHeader(
              step: _step,
              onClose: () => Navigator.pop(context),
            ),
            Expanded(
              child: _step == 0
                  ? _PickDeckBody(
                      selectedDeckId: _selectedDeckId,
                      onDeckSelected: (id, name) => setState(() {
                        _selectedDeckId = id;
                        _selectedDeckName = name;
                      }),
                      onNext: () => setState(() => _step = 1),
                    )
                  : _PickGroupsBody(
                      deckName: _selectedDeckName!,
                      busy: _busy,
                      onBack: () => setState(() => _step = 0),
                      onAssign: _onAssign,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.step, required this.onClose});
  final int step;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.forestGreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Assign deck',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                    ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StepPill(label: '1 · Deck', active: step == 0),
              const SizedBox(width: 8),
              _StepPill(label: '2 · Groups', active: step == 1),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: AppRadius.pill,
        border: Border.all(
          color: active ? Colors.white : Colors.white.withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: active ? const Color(0xFF16563A) : Colors.white.withOpacity(0.55),
        ),
      ),
    );
  }
}

// ── Step 1 — Pick deck ────────────────────────────────────────────────────────

class _FlatDeck {
  const _FlatDeck({
    required this.id,
    required this.name,
    required this.cardCount,
    required this.collectionName,
    required this.collectionColor,
  });
  final String id;
  final String name;
  final int cardCount;
  final String collectionName;
  final Color collectionColor;
}

class _PickDeckBody extends StatefulWidget {
  const _PickDeckBody({
    required this.selectedDeckId,
    required this.onDeckSelected,
    required this.onNext,
  });
  final String? selectedDeckId;
  final void Function(String id, String name) onDeckSelected;
  final VoidCallback onNext;

  @override
  State<_PickDeckBody> createState() => _PickDeckBodyState();
}

class _PickDeckBodyState extends State<_PickDeckBody> {
  List<_FlatDeck> _allDecks = [];
  bool _loading = true;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _query = _searchController.text.toLowerCase()));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final collections = await CollectionService.instance.listCollections();
      final deckLists = await Future.wait(
        collections.map((c) => DeckService.instance.listDecks(c.id)),
      );
      final flat = <_FlatDeck>[];
      for (var i = 0; i < collections.length; i++) {
        final c = collections[i];
        for (final d in deckLists[i]) {
          flat.add(_FlatDeck(
            id: d.id,
            name: d.name,
            cardCount: d.cardCount,
            collectionName: c.name,
            collectionColor: c.color,
          ));
        }
      }
      if (mounted) setState(() { _allDecks = flat; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_FlatDeck> get _filtered {
    if (_query.isEmpty) return _allDecks;
    return _allDecks
        .where((d) =>
            d.name.toLowerCase().contains(_query) ||
            d.collectionName.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.forestGreen));
    }
    final filtered = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search decks…',
              prefixIcon: const Icon(Icons.search, color: AppColors.ash, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.periwinkle, width: 2),
              ),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    _query.isEmpty ? 'No decks in your library' : 'No decks match "$_query"',
                    style: const TextStyle(color: AppColors.ash),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _DeckRow(
                    deck: filtered[i],
                    selected: widget.selectedDeckId == filtered[i].id,
                    onTap: () => widget.onDeckSelected(filtered[i].id, filtered[i].name),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: GestureDetector(
            onTap: widget.selectedDeckId != null ? widget.onNext : null,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: widget.selectedDeckId != null
                    ? AppColors.orange
                    : AppColors.fog.withOpacity(0.35),
                borderRadius: AppRadius.pill,
              ),
              alignment: Alignment.center,
              child: const Text(
                'Next →',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DeckRow extends StatelessWidget {
  const _DeckRow({required this.deck, required this.selected, required this.onTap});
  final _FlatDeck deck;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.periwinkle.withOpacity(0.08) : Colors.white,
          borderRadius: AppRadius.cardBorderRadius,
          border: Border.all(
            color: selected ? AppColors.periwinkle : AppColors.border,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: deck.collectionColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.layers_outlined, size: 18, color: deck.collectionColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deck.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  Text(
                    deck.collectionName,
                    style: const TextStyle(fontSize: 11, color: AppColors.ash),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.border.withOpacity(0.6),
                borderRadius: AppRadius.pill,
              ),
              child: Text(
                '${deck.cardCount}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ash),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, color: AppColors.periwinkle, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Step 2 — Pick groups ──────────────────────────────────────────────────────

class _PickGroupsBody extends StatefulWidget {
  const _PickGroupsBody({
    required this.deckName,
    required this.busy,
    required this.onBack,
    required this.onAssign,
  });
  final String deckName;
  final bool busy;
  final VoidCallback onBack;
  final Future<void> Function(List<String> groupIds) onAssign;

  @override
  State<_PickGroupsBody> createState() => _PickGroupsBodyState();
}

class _PickGroupsBodyState extends State<_PickGroupsBody> {
  final Set<String> _selected = {};

  static Color _parseHex(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final groups = TeacherService.instance.cachedDashboard?.groups ?? [];
    final n = _selected.length;

    return Column(
      children: [
        // back row
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.chevron_left_rounded, color: AppColors.ink, size: 24),
                ),
              ),
              Expanded(
                child: Text(
                  widget.deckName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ash),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: groups.isEmpty
              ? const Center(
                  child: Text('No groups yet', style: TextStyle(color: AppColors.ash)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: groups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final g = groups[i];
                    final sel = _selected.contains(g.id);
                    return _GroupRow(
                      emoji: g.emoji,
                      name: g.name,
                      memberCount: g.memberCount,
                      color: _parseHex(g.color),
                      selected: sel,
                      onTap: () => setState(() {
                        if (sel) {
                          _selected.remove(g.id);
                        } else {
                          _selected.add(g.id);
                        }
                      }),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: GestureDetector(
            onTap: (n > 0 && !widget.busy)
                ? () => widget.onAssign(_selected.toList())
                : null,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: n > 0 ? AppColors.orange : AppColors.fog.withOpacity(0.35),
                borderRadius: AppRadius.pill,
              ),
              alignment: Alignment.center,
              child: widget.busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      n == 0 ? 'Select a group' : 'Assign to $n group${n == 1 ? '' : 's'}',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.emoji,
    required this.name,
    required this.memberCount,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String emoji;
  final String name;
  final int memberCount;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F5EE) : Colors.white,
          borderRadius: AppRadius.cardBorderRadius,
          border: Border.all(
            color: selected ? AppColors.forestGreen : AppColors.border,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  Text(
                    '$memberCount student${memberCount == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 11, color: AppColors.ash),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.forestGreen, size: 20)
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.fog, width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
