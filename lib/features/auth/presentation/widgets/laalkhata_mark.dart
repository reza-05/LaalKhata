import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class LaalKhataMark extends StatelessWidget {
  const LaalKhataMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'LaalKhata title',
      child: Column(
        children: [
          Text(
            'LaalKhata',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.burgundy,
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                  shadows: [
                    Shadow(
                      color: AppColors.burgundy.withValues(alpha: 0.18),
                      blurRadius: 0,
                      offset: const Offset(0.8, 0),
                    ),
                  ],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Digital Expense Notebook for IUTians',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.mutedInk,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
          ),
        ],
      ),
    );
  }
}
