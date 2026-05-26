import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppErrorBody extends StatelessWidget {
  const AppErrorBody({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppColors.ash, fontSize: 16)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border, width: 1.5),
                    borderRadius: AppRadius.pill,
                  ),
                  child: const Text('Go back',
                      style: TextStyle(color: AppColors.ash, fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  decoration: const BoxDecoration(
                      color: AppColors.periwinkle, borderRadius: AppRadius.pill),
                  child: const Text('Try again',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
