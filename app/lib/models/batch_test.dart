import 'dart:math';
import 'card.dart';

/// One multiple-choice question about [card].
class TestQuestion {
  const TestQuestion({
    required this.card,
    required this.prompt,
    required this.hint,
    required this.options,
    required this.correctIndex,
    required this.isRetry,
  });
  final CardModel card;

  /// What the learner sees (Korean or the translation).
  final String prompt;

  /// Romanisation under a Korean prompt, '' otherwise.
  final String hint;
  final List<String> options;
  final int correctIndex;

  /// A second (or later) try after a wrong answer — it doesn't count.
  final bool isRetry;
}

/// The mini test after a flashcard batch.
///
/// Each word in [batch] is asked once in the studied direction; the wrong
/// options come from [pool] (usually the whole deck). A wrong answer puts
/// the word back at the end until it's answered right, but only the first
/// try is the result — that's what gets saved as word progress.
class BatchTest {
  BatchTest(
    List<CardModel> batch,
    List<CardModel> pool, {
    required this.koreanPrompt,
    Random? rng,
  })  : _rng = rng ?? Random(),
        _pool = pool {
    final order = List<CardModel>.from(batch)..shuffle(_rng);
    _questions = [for (final c in order) _question(c, isRetry: false)];
  }

  /// true: show Korean, pick the translation. false: the other way round.
  final bool koreanPrompt;
  final Random _rng;
  final List<CardModel> _pool;
  late final List<TestQuestion> _questions;
  int _index = 0;

  /// First-try result per card id, in the order answered.
  final Map<String, bool> results = {};

  /// Multiple choice needs at least one wrong option to pick from.
  static bool canTest(List<CardModel> pool, {required bool koreanPrompt}) =>
      {for (final c in pool) _answerOf(c, koreanPrompt)}.length >= 2;

  static String _answerOf(CardModel c, bool koreanPrompt) =>
      (koreanPrompt ? c.translation : c.korean).trim();

  TestQuestion _question(CardModel card, {required bool isRetry}) {
    final answer = _answerOf(card, koreanPrompt);
    final wrong = {
      for (final c in _pool) _answerOf(c, koreanPrompt),
    }..remove(answer);
    final distractors = wrong.toList()..shuffle(_rng);
    final options = [answer, ...distractors.take(3)]..shuffle(_rng);
    return TestQuestion(
      card: card,
      prompt: koreanPrompt ? card.korean : card.translation,
      hint: koreanPrompt ? card.romanisation : '',
      options: options,
      correctIndex: options.indexOf(answer),
      isRetry: isRetry,
    );
  }

  TestQuestion get current => _questions[_index];

  /// 0-based position, and how many questions there are so far (grows with retries).
  int get position => _index;
  int get length => _questions.length;

  bool get isLastQuestion => _index + 1 >= _questions.length;

  int get remembered => results.values.where((r) => r).length;
  int get missed => results.values.where((r) => !r).length;

  /// Records whether [current] was answered right. Returns null on a retry
  /// (nothing to save), otherwise the first-try result to save for this word.
  bool? answer(bool correct) {
    final q = current;
    if (!correct) _questions.add(_question(q.card, isRetry: true));
    if (q.isRetry) return null;
    results[q.card.id] = correct;
    return correct;
  }

  /// Moves on; returns false when the test is over.
  bool next() {
    if (isLastQuestion) return false;
    _index++;
    return true;
  }
}
