import 'package:flutter/material.dart';
import '../models/study_queue.dart';
import '../theme/app_theme.dart';

/// "Words per session" pills: 10 / 15 / 20 / All (0).
/// Shared by flashcard study and Multiple choice.
class SessionSizePills extends StatelessWidget {
  const SessionSizePills({
    super.key,
    required this.size,
    required this.onChanged,
    this.color = AppColors.periwinkle,
  });
  final int size;
  final ValueChanged<int> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in StudyQueue.sizes)
          GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: size == value ? color : Colors.white,
                borderRadius: AppRadius.pill,
                border: Border.all(
                  color: size == value ? color : AppColors.fog.withOpacity(0.5),
                ),
              ),
              child: Text(
                value == 0 ? 'All' : '$value',
                style: TextStyle(
                  color: size == value ? Colors.white : AppColors.ash,
                  fontSize: 14,
                  fontWeight: size == value ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// "47 cards → 3 sessions of up to 20", or "All 12 cards in one go".
String sessionSizeHint(int count, int size) {
  if (size == 0 || size >= count) {
    return 'All $count card${count == 1 ? '' : 's'} in one go';
  }
  final sessions = (count / size).ceil();
  return '$count cards → $sessions sessions of up to $size';
}
