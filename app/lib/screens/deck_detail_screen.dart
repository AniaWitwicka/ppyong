import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'flashcard_study_screen.dart';

class DeckDetailScreen extends StatelessWidget {
  const DeckDetailScreen({super.key, required this.name, required this.accentColor});

  final String name;
  final Color accentColor;

  static const _mockDecks = [
    _DeckData(title: 'Deck 1 — Greetings', mastered: 8, learning: 4, newCards: 3),
    _DeckData(title: 'Deck 2 — Numbers', mastered: 3, learning: 7, newCards: 10),
    _DeckData(title: 'Deck 3 — Colours', mastered: 0, learning: 2, newCards: 12),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            _Header(name: name, accentColor: accentColor),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: _mockDecks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) => _DeckCard(deck: _mockDecks[i], accentColor: accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.accentColor});

  final String name;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: accentColor,
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              name,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              '3 decks',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.85)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckData {
  const _DeckData({
    required this.title,
    required this.mastered,
    required this.learning,
    required this.newCards,
  });

  final String title;
  final int mastered;
  final int learning;
  final int newCards;

  int get total => mastered + learning + newCards;
}

class _DeckCard extends StatefulWidget {
  const _DeckCard({required this.deck, required this.accentColor});

  final _DeckData deck;
  final Color accentColor;

  @override
  State<_DeckCard> createState() => _DeckCardState();
}

class _DeckCardState extends State<_DeckCard> {
  bool _expanded = false;

  static const _mockCards = [
    (korean: '안녕하세요', romanisation: 'annyeonghaseyo', translation: 'Hello'),
    (korean: '감사합니다', romanisation: 'gamsahamnida', translation: 'Thank you'),
    (korean: '괜찮아요', romanisation: 'gwaenchanayo', translation: 'It\'s okay'),
    (korean: '죄송합니다', romanisation: 'joesonghamnida', translation: 'I\'m sorry'),
  ];

  @override
  Widget build(BuildContext context) {
    final deck = widget.deck;
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deck.title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _ProgressBar(deck: deck),
                const SizedBox(height: 10),
                _SrsChips(deck: deck),
                const SizedBox(height: 16),
                _ActionButtons(accentColor: widget.accentColor, deckTitle: deck.title),
              ],
            ),
          ),
          _ExpandToggle(
            expanded: _expanded,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded) _CardList(cards: _mockCards),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.deck});

  final _DeckData deck;

  @override
  Widget build(BuildContext context) {
    final total = deck.total;
    if (total == 0) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: AppRadius.pill,
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            Flexible(
              flex: deck.mastered,
              child: Container(color: AppColors.forestGreen),
            ),
            Flexible(
              flex: deck.learning,
              child: Container(color: AppColors.periwinkle),
            ),
            Flexible(
              flex: deck.newCards,
              child: Container(color: AppColors.border),
            ),
          ],
        ),
      ),
    );
  }
}

class _SrsChips extends StatelessWidget {
  const _SrsChips({required this.deck});

  final _DeckData deck;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(label: '${deck.mastered} mastered', color: AppColors.forestGreen, light: true),
        const SizedBox(width: 8),
        _Chip(label: '${deck.learning} learning', color: AppColors.periwinkle),
        const SizedBox(width: 8),
        _Chip(label: '${deck.newCards} new', color: AppColors.fog),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, this.light = false});

  final String label;
  final Color color;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(light ? 1.0 : 0.15),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              color: light ? Colors.white : color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.accentColor, required this.deckTitle});

  final Color accentColor;
  final String deckTitle;

  void _showPreview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PreviewSheet(deckTitle: deckTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PillButton(
            label: 'Study now',
            color: AppColors.orange,
            textColor: Colors.white,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FlashcardStudyScreen(deckName: deckTitle),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PillButton(
            label: 'Preview cards',
            color: accentColor.withOpacity(0.15),
            textColor: accentColor,
            onTap: () => _showPreview(context),
          ),
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: color, borderRadius: AppRadius.pill),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _ExpandToggle extends StatelessWidget {
  const _ExpandToggle({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.vertical(bottom: AppRadius.card),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              expanded ? 'Hide cards' : 'Show cards',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.ash,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(
              expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppColors.ash,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewSheet extends StatelessWidget {
  const _PreviewSheet({required this.deckTitle});
  final String deckTitle;

  static const _cards = [
    (korean: '안녕하세요', romanisation: 'annyeonghaseyo', translation: 'Hello'),
    (korean: '감사합니다', romanisation: 'gamsahamnida', translation: 'Thank you'),
    (korean: '괜찮아요', romanisation: 'gwaenchanayo', translation: "It's okay"),
    (korean: '죄송합니다', romanisation: 'joesonghamnida', translation: "I'm sorry"),
  ];

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
              width: 40,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.fog,
                borderRadius: AppRadius.pill,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(deckTitle,
                        style: Theme.of(context).textTheme.headlineMedium),
                  ),
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
                itemCount: _cards.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: AppColors.border, height: 1),
                itemBuilder: (context, i) {
                  final c = _cards[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.korean,
                                  style: Theme.of(context).textTheme.titleMedium),
                              Text(c.romanisation,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppColors.ash)),
                            ],
                          ),
                        ),
                        Text(c.translation,
                            style: Theme.of(context).textTheme.bodyLarge),
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

class _CardList extends StatelessWidget {
  const _CardList({required this.cards});

  final List<({String korean, String romanisation, String translation})> cards;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: cards
          .map((c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.korean, style: Theme.of(context).textTheme.titleMedium),
                          Text(c.romanisation,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.ash)),
                        ],
                      ),
                    ),
                    Text(c.translation, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
