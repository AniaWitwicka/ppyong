import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.periwinkle,
        title: Text(
          'Library',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: const Center(child: Text('Library — coming soon')),
    );
  }
}
