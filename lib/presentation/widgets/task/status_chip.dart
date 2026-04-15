// lib/presentation/widgets/task/status_chip.dart
//
// Chip de estado de tarea con color y etiqueta según el estado.

import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final String status;

  Color get _color => switch (status) {
    TaskStatus.todo       => AppColors.todo,
    TaskStatus.inProgress => AppColors.inProgress,
    TaskStatus.done       => AppColors.done,
    _                     => AppColors.todo,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        TaskStatus.label(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}
