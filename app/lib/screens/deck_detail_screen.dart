import 'package:flutter/material.dart';
import '../models/card.dart';
import '../models/deck.dart';
import '../services/card_service.dart';
import '../services/deck_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/edit_deck_sheet.dart';
import '../widgets/add_flashcard_sheet.dart';
import '../widgets/deck_share_dialog.dart';
import 'flashcard_study_screen.dart';

class DeckDetailScreen extends StatefulWidget {
  const DeckDetailScreen({
    super.key,
    required this.deckId,
    required this.accentColor,
  });

  final String deckId;
  final Color accentColor;

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  DeckDetail? _deck;
  List<CardModel> _cards = [];
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
        DeckService.instance.getDeck(widget.deckId),
        CardService.instance.listCards(widget.deckId),
      ]);
      setState(() {
        _deck = results[0] as DeckDetail;
        _cards = results[1] as List<CardModel>;
        _loading = false;
      });
    } catch (_) {
      setState(() { _loading = false; _hasError = true; });
      if (mounted) {
        showAppToast(context, variant: ToastVariant.error, title: 'Failed to load deck');
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

    if (_hasError || _deck == null) {
      return Scaffold(
        backgroundColor: AppColors.offWhite,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😕', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text('Could not load deck',
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

    final deck = _deck!;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showAddFlashcardSheet(context,
              deckId: widget.deckId, deckName: deck.name, cardCount: _cards.length);
          _load();
        },
        backgroundColor: AppColors.orange,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              collectionName: deck.collectionName,
              accentColor: widget.accentColor,
              deckId: widget.deckId,
              deckName: deck.name,
            ),
            Expanded(
              child: ListView(
                children: [
                  _HeroSection(
                    deckName: deck.name,
                    mastered: deck.masteredCount,
                    learning: deck.learningCount,
                    newCards: deck.newCount,
                    accentColor: widget.accentColor,
                    cards: _cards,
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _CardsHeader(),
                  ..._cards.map((c) => _ExpandableCardRow(card: c)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.collectionName, required this.accentColor, required this.deckId, required this.deckName});

  final String collectionName;
  final Color accentColor;
  final String deckId;
  final String deckName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.chevron_left_rounded, color: AppColors.ink, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              collectionName,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.ash, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => showDeckShareDialog(context, deckId: deckId, deckName: deckName),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFEEF3FE),
                borderRadius: AppRadius.pill,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.share_outlined, size: 14, color: AppColors.periwinkle),
                  const SizedBox(width: 5),
                  Text(
                    'Share',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => showEditDeckSheet(context, deckName: deckName),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFEEF3FE),
                borderRadius: AppRadius.pill,
              ),
              child: Text(
                'Edit deck',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero section ──────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.deckName,
    required this.mastered,
    required this.learning,
    required this.newCards,
    required this.accentColor,
    required this.cards,
  });

  final String deckName;
  final int mastered;
  final int learning;
  final int newCards;
  final Color accentColor;
  final List<CardModel> cards;

  int get total => mastered + learning + newCards;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            deckName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          _MetaPills(total: total),
          const SizedBox(height: 14),
          _ProgressBar(mastered: mastered, learning: learning, newCards: newCards),
          const SizedBox(height: 6),
          const _ProgressLegend(),
          const SizedBox(height: 12),
          _SrsChips(mastered: mastered, learning: learning, newCards: newCards),
          const SizedBox(height: 16),
          _ActionButtons(deckName: deckName, accentColor: accentColor, cards: cards),
        ],
      ),
    );
  }
}

class _MetaPills extends StatelessWidget {
  const _MetaPills({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        _MetaPill(label: '$total words', bg: const Color(0xFFEEF3FE), color: AppColors.periwinkle),
        const _MetaPill(label: 'This week', bg: Color(0xFFFEF0F6), color: AppColors.bubblegum),
        const _MetaPill(label: 'Added by teacher', bg: AppColors.offWhite, color: AppColors.fog, bordered: true),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.bg, required this.color, this.bordered = false});
  final String label;
  final Color bg;
  final Color color;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.pill,
        border: bordered ? Border.all(color: AppColors.border) : null,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.mastered, required this.learning, required this.newCards});
  final int mastered;
  final int learning;
  final int newCards;

  @override
  Widget build(BuildContext context) {
    final total = mastered + learning + newCards;
    if (total == 0) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: AppRadius.pill,
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            Flexible(flex: mastered, child: Container(color: AppColors.forestGreen)),
            Flexible(flex: learning, child: Container(color: AppColors.periwinkle)),
            Flexible(flex: newCards, child: Container(color: AppColors.border)),
          ],
        ),
      ),
    );
  }
}

class _ProgressLegend extends StatelessWidget {
  const _ProgressLegend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _LegendDot(color: AppColors.forestGreen, label: 'Mastered'),
        SizedBox(width: 12),
        _LegendDot(color: AppColors.periwinkle, label: 'Learning'),
        SizedBox(width: 12),
        _LegendDot(color: AppColors.border, label: 'New'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11, color: AppColors.ash)),
      ],
    );
  }
}

class _SrsChips extends StatelessWidget {
  const _SrsChips({required this.mastered, required this.learning, required this.newCards});
  final int mastered;
  final int learning;
  final int newCards;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(label: '$mastered mastered', color: AppColors.forestGreen, solid: true),
        const SizedBox(width: 8),
        _Chip(label: '$learning learning', color: AppColors.periwinkle),
        const SizedBox(width: 8),
        _Chip(label: '$newCards new', color: AppColors.fog),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, this.solid = false});
  final String label;
  final Color color;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: solid ? color : color.withOpacity(0.15),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              color: solid ? Colors.white : color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.deckName, required this.accentColor, required this.cards});
  final String deckName;
  final Color accentColor;
  final List<CardModel> cards;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FlashcardStudyScreen(deckName: deckName)),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: const BoxDecoration(color: AppColors.orange, borderRadius: AppRadius.pill),
              alignment: Alignment.center,
              child: Text('Study now',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _showPreview(context, cards),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.pill,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text('Preview cards',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.ink, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }

  void _showPreview(BuildContext context, List<CardModel> cards) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PreviewSheet(deckTitle: deckName, cards: cards),
    );
  }
}

// ── Cards list ────────────────────────────────────────────────────────────

class _CardsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text('All cards', style: Theme.of(context).textTheme.headlineMedium),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              'Sort by status',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableCardRow extends StatefulWidget {
  const _ExpandableCardRow({required this.card});
  final CardModel card;

  @override
  State<_ExpandableCardRow> createState() => _ExpandableCardRowState();
}

class _ExpandableCardRowState extends State<_ExpandableCardRow> {
  bool _expanded = false;

  Color get _statusColor => switch (widget.card.status) {
        CardStatus.mastered => AppColors.forestGreen,
        CardStatus.learning => AppColors.periwinkle,
        CardStatus.newCard  => AppColors.fog,
      };

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _expanded ? const Color(0xFFF8FAFF) : Colors.white,
          borderRadius: AppRadius.cardBorderRadius,
          border: Border.all(
            color: _expanded ? AppColors.periwinkle : AppColors.border,
            width: _expanded ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.korean,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                  ),
                  Text(
                    card.romanisation,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.fog,
                          fontSize: 12,
                        ),
                  ),
                  Text(
                    card.translation,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.ash,
                          fontSize: 13,
                        ),
                  ),
                  if (_expanded && card.notes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      card.notes,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.ash,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: _expanded ? AppColors.periwinkle : AppColors.fog,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Preview sheet ─────────────────────────────────────────────────────────

class _PreviewSheet extends StatelessWidget {
  const _PreviewSheet({required this.deckTitle, required this.cards});
  final String deckTitle;
  final List<CardModel> cards;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.vertical(top: AppRadius.card),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: const BoxDecoration(color: AppColors.border, borderRadius: AppRadius.pill),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: Text(deckTitle, style: Theme.of(context).textTheme.headlineMedium)),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.ash),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            Expanded(
              child: ListView.separated(
                controller: controller,
                itemCount: cards.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                itemBuilder: (context, i) {
                  final c = cards[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.korean, style: Theme.of(context).textTheme.titleMedium),
                              Text(c.romanisation,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ash)),
                            ],
                          ),
                        ),
                        Text(c.translation, style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
