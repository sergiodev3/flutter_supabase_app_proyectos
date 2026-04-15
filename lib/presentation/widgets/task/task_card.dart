// lib/presentation/widgets/task/task_card.dart
//
// Tarjeta de tarea para la lista del tablero.
// Muestra: imagen de portada (opcional), título, descripción, estado y prioridad.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/task.dart';
import 'status_chip.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onDelete,
  });

  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias, // Recorta la imagen respetando el border-radius
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Imagen de portada (si existe) ──────────────────────────────
            if (task.coverImageUrl != null)
              CachedNetworkImage(
                imageUrl: task.coverImageUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                // Muestra skeleton mientras carga la imagen de Supabase Storage
                placeholder: (_, __) => Container(
                  height: 140,
                  color: const Color(0xFFE2E8F0),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 140,
                  color: const Color(0xFFE2E8F0),
                  child: const Icon(Icons.broken_image_outlined, size: 40),
                ),
              ),

            // ── Contenido ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título + menú de opciones
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onDelete != null)
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'delete') onDelete?.call();
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 18,
                                      color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Eliminar',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          child: const Icon(Icons.more_vert, size: 20),
                        ),
                    ],
                  ),

                  // Descripción (opcional)
                  if (task.description != null &&
                      task.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Chips de estado y prioridad + fecha de vencimiento
                  Row(
                    children: [
                      StatusChip(status: task.status),
                      const SizedBox(width: 6),
                      _PriorityDot(priority: task.priority),
                      const Spacer(),
                      if (task.dueDate != null)
                        _DueDateBadge(dueDate: task.dueDate!),
                      if (task.attachments.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            const Icon(Icons.attach_file, size: 14,
                                color: Color(0xFF94A3B8)),
                            Text(
                              '${task.attachments.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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

// ── Subwidgets privados ────────────────────────────────────────────────────────

class _PriorityDot extends StatelessWidget {
  const _PriorityDot({required this.priority});
  final String priority;

  Color get _color => switch (priority) {
    TaskPriority.high   => AppColors.high,
    TaskPriority.medium => AppColors.medium,
    _                   => AppColors.low,
  };

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Prioridad: ${TaskPriority.label(priority)}',
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: _color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _DueDateBadge extends StatelessWidget {
  const _DueDateBadge({required this.dueDate});
  final DateTime dueDate;

  bool get _isOverdue =>
      dueDate.isBefore(DateTime.now()) &&
      dueDate.difference(DateTime.now()).inDays < 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: 12,
          color: _isOverdue ? AppColors.high : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 3),
        Text(
          DateFormat('dd MMM', 'es').format(dueDate),
          style: TextStyle(
            fontSize: 11,
            color: _isOverdue ? AppColors.high : const Color(0xFF94A3B8),
            fontWeight:
                _isOverdue ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
