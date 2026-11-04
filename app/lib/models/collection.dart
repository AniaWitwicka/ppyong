import 'package:flutter/material.dart';

class Collection {
  const Collection({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.deckCount,
    required this.wordCount,
    required this.dueCount,
    required this.progress,
    this.canEdit = false,
    this.masteredCount = 0,
    this.learningCount = 0,
  });

  final String id;
  final String name;
  final String emoji;
  final Color color;
  final int deckCount;
  final int wordCount;
  final int dueCount;
  /// Mastered words / all words, 0–1. Needs a 7-day review gap per word,
  /// so it stays 0 for the first week of studying.
  final double progress;

  /// Words the user has reviewed: mastered, and still learning.
  final int masteredCount;
  final int learningCount;

  /// The signed-in user created it or is an admin, so they may add, edit and share.
  final bool canEdit;

  factory Collection.fromJson(Map<String, dynamic> j) => Collection(
        id: j['id'] as String,
        name: j['name'] as String,
        emoji: j['emoji'] as String,
        color: _hexToColor(j['color'] as String),
        deckCount: j['deck_count'] as int,
        wordCount: j['word_count'] as int,
        dueCount: j['due_count'] as int,
        progress: (j['progress'] as num).toDouble(),
        canEdit: j['can_edit'] as bool? ?? false,
        masteredCount: j['mastered_count'] as int? ?? 0,
        learningCount: j['learning_count'] as int? ?? 0,
      );

  static Color _hexToColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}
