import 'dart:math';
import 'package:flutter/material.dart';
import '../models/card.dart';
import '../services/card_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/deck_picker.dart';
import '../widgets/quiz_question.dart';

// ── Data ──────────────────────────────────────────────────────────────────

class _Question {
  const _Question({
    required this.card,
    required this.options,
    required this.correctIndex,
  });
  final CardModel card;
  final List<String> options;
  final int correctIndex;
}

enum _Phase { pick, loading, quiz, complete }

// ── Root screen ───────────────────────────────────────────────────────────

class MultipleChoiceScreen extends StatefulWidget {
  const MultipleChoiceScreen({super.key, this.deckId, this.deckName});
  final String? deckId;
  final String? deckName;

  @override
  State<MultipleChoiceScreen> createState() => _MultipleChoiceScreenState();
}

class _MultipleChoiceScreenState extends State<MultipleChoiceScreen> {
  _Phase _phase = _Phase.pick;
  String? _deckId;
  String? _deckName;
  List<_Question> _questions = [];
  int _qi = 0;
  int _correct = 0;
  int _wrong = 0;

  @override
  void initState() {
    super.initState();
    _deckId = widget.deckId;
    _deckName = widget.deckName;
    if (_deckId != null) _loadAndStart();
  }

  void _onDeckSelected(String id, String name) {
    setState(() {
      _deckId = id;
      _deckName = name;
    });
    _loadAndStart();
  }

  Future<void> _loadAndStart() async {
    setState(() => _phase = _Phase.loading);
    try {
      final cards = await CardService.instance.listCards(_deckId!);
      if (!mounted) return;
      if (cards.length < 2) {
        setState(() => _phase = _Phase.pick);
        showAppToast(context,
            variant: ToastVariant.error,
            title: 'Not enough cards',
            subtitle: 'Add at least 2 cards to this deck');
        return;
      }
      final rng = Random();
      final shuffled = List<CardModel>.from(cards)..shuffle(rng);
      final questions = shuffled.map((card) {
        final others = cards.where((c) => c.id != card.id).toList()..shuffle(rng);
        final wrongAnswers = others.take(3).map((c) => c.translation).toList();
        final options = [card.translation, ...wrongAnswers]..shuffle(rng);
        return _Question(
          card: card,
          options: options,
          correctIndex: options.indexOf(card.translation),
        );
      }).toList();
      setState(() {
        _questions = questions;
        _qi = 0;
        _correct = 0;
        _wrong = 0;
        _phase = _Phase.quiz;
      });
    } catch (_) {
      if (mounted) setState(() => _phase = _Phase.pick);
    }
  }

  void _onAnswer(bool correct) {
    CardService.instance.reviewCard(_questions[_qi].card.id, correct).catchError((_) {});
    setState(() {
      if (correct) { _correct++; } else { _wrong++; }
    });
  }

  void _nextQuestion() {
    if (_qi + 1 >= _questions.length) {
      setState(() => _phase = _Phase.complete);
    } else {
      setState(() => _qi++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _Phase.pick => DeckPickerScreen(
          title: 'Multiple choice',
          subtitle: 'Choose a deck to quiz yourself',
          accentColor: AppColors.orange,
          onDeckSelected: _onDeckSelected,
        ),
      _Phase.loading => const Scaffold(
          backgroundColor: AppColors.offWhite,
          body: Center(child: CircularProgressIndicator(color: AppColors.orange)),
        ),
      _Phase.quiz => QuizQuestionView(
          key: ValueKey(_qi),
          prompt: _questions[_qi].card.korean,
          hint: _questions[_qi].card.romanisation,
          footer: 'Question ${_qi + 1} of ${_questions.length}',
          options: _questions[_qi].options,
          correctIndex: _questions[_qi].correctIndex,
          progress: (_qi + 1) / _questions.length,
          correct: _correct,
          wrong: _wrong,
          onAnswer: _onAnswer,
          onNext: _nextQuestion,
        ),
      _Phase.complete => _CompletionScreen(
          deckName: _deckName,
          total: _questions.length,
          correct: _correct,
          wrong: _wrong,
          onTryAgain: _loadAndStart,
          onBack: () => Navigator.pop(context),
        ),
    };
  }
}


// ── Completion screen ─────────────────────────────────────────────────────

class _CompletionScreen extends StatelessWidget {
  const _CompletionScreen({
    this.deckName,
    required this.total,
    required this.correct,
    required this.wrong,
    required this.onTryAgain,
    required this.onBack,
  });

  final String? deckName;
  final int total;
  final int correct;
  final int wrong;
  final VoidCallback onTryAgain;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final score = total == 0 ? 0 : (correct / total * 100).round();

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Trophy squircle
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.sunnyYellow,
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                child: const Center(
                  child: Text('🎉', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Quiz complete!',
                  style: Theme.of(context)
                      .textTheme
                      .displayMedium
                      ?.copyWith(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                deckName != null
                    ? '$deckName · $total question${total == 1 ? '' : 's'}'
                    : 'You answered $total question${total == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              // Stat cards
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      value: '$correct',
                      label: 'CORRECT',
                      bg: const Color(0xFFE8F5EE),
                      valueColor: const Color(0xFF267F53),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      value: '$wrong',
                      label: 'WRONG',
                      bg: const Color(0xFFFEF0F6),
                      valueColor: const Color(0xFFC45A8A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      value: '$score%',
                      label: 'SCORE',
                      bg: const Color(0xFFFEF9E8),
                      valueColor: const Color(0xFF7A5500),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Try again
              GestureDetector(
                onTap: onTryAgain,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: AppRadius.pill,
                  ),
                  child: const Center(
                    child: Text('Try again',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Back ghost button
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border, width: 1.5),
                    borderRadius: AppRadius.pill,
                  ),
                  child: const Center(
                    child: Text('Back to study modes',
                        style: TextStyle(
                            color: AppColors.ash,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.bg,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color bg;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.cardBorderRadius,
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: valueColor)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ash,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
