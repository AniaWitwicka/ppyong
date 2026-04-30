import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FlashcardStudyScreen extends StatelessWidget {
  const FlashcardStudyScreen({super.key, this.deckName});

  final String? deckName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        title: Text(
          deckName ?? 'Study',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: const Center(
        child: Text('Flashcard study — coming soon'),
      ),
    );
  }
}
