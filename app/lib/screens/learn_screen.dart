import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'flashcard_study_screen.dart';
import 'multiple_choice_screen.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: [
                  _ModeCard(
                    title: 'Flashcards',
                    description:
                        'Flip cards to reveal translations. Swipe to rate yourself.',
                    tags: const ['Both directions', 'SRS'],
                    color: AppColors.periwinkle,
                    cornerTint: const Color(0xFFEEF3FE),
                    icon: Icons.style_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FlashcardStudyScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ModeCard(
                    title: 'Multiple choice',
                    description:
                        'Pick the correct translation from 4 options.',
                    tags: const ['4 options', 'Instant feedback'],
                    color: AppColors.orange,
                    cornerTint: const Color(0xFFFFF8F4),
                    icon: Icons.checklist_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MultipleChoiceScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ComingSoonCard(
                    title: 'Matching',
                    description: 'Match Korean words to their translations.',
                    color: AppColors.bubblegum,
                    cornerTint: const Color(0xFFFEF0F6),
                    icon: Icons.compare_arrows_rounded,
                  ),
                  const SizedBox(height: 12),
                  _ComingSoonCard(
                    title: 'Type the answer',
                    description:
                        'Type the Korean or translation from memory.',
                    color: AppColors.sunnyYellow,
                    cornerTint: const Color(0xFFFEF9E8),
                    icon: Icons.keyboard_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.periwinkle,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learn',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            'Pick a study mode',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF1A3A7A),
                  fontSize: 13,
                ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.description,
    required this.tags,
    required this.color,
    required this.cornerTint,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final List<String> tags;
  final Color color;
  final Color cornerTint;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _CardShell(
        color: color,
        cornerTint: cornerTint,
        icon: icon,
        title: title,
        description: description,
        tags: tags,
        disabled: false,
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({
    required this.title,
    required this.description,
    required this.color,
    required this.cornerTint,
    required this.icon,
  });

  final String title;
  final String description;
  final Color color;
  final Color cornerTint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: _CardShell(
        color: color,
        cornerTint: cornerTint,
        icon: icon,
        title: title,
        description: description,
        tags: const [],
        disabled: true,
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.color,
    required this.cornerTint,
    required this.icon,
    required this.title,
    required this.description,
    required this.tags,
    required this.disabled,
  });

  final Color color;
  final Color cornerTint;
  final IconData icon;
  final String title;
  final String description;
  final List<String> tags;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color, width: 2),
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        child: Stack(
          children: [
            // Decorative corner tint
            Positioned(
              top: 0,
              right: 0,
              child: _CornerTint(color: cornerTint),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon container
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(18)),
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 13),
                        ),
                        if (tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            children: tags
                                .map((t) => _TagChip(label: t, color: color))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Right side: chevron or coming soon badge
                  if (disabled)
                    _ComingSoonBadge()
                  else
                    Icon(Icons.chevron_right_rounded, color: color, size: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerTint extends StatelessWidget {
  const _CornerTint({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(80),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color == AppColors.sunnyYellow
              ? const Color(0xFF7A5500)
              : color,
        ),
      ),
    );
  }
}

class _ComingSoonBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.fog.withOpacity(0.2),
        borderRadius: AppRadius.pill,
      ),
      child: const Text(
        'Soon',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.fog,
        ),
      ),
    );
  }
}
