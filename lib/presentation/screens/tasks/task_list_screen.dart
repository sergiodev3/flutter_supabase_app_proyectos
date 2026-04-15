// lib/presentation/screens/tasks/task_list_screen.dart
//
// ─── PANTALLA LISTA DE TAREAS ─────────────────────────────────────────────────
// Demuestra:
//   • Lectura de datos con .select() + relaciones anidadas
//   • Filtrado en el cliente por estado
//   • Realtime: la lista se actualiza sola con watchTasks()
//   • Pull-to-refresh manual como alternativa al Realtime
//   • Skeleton loading con shimmer mientras cargan los datos
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../viewmodels/task_list_viewmodel.dart';
import '../../widgets/task/task_card.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TaskListViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        actions: [
          // Botón de perfil
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go(AppRoutes.profile),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de filtros por estado ──────────────────────────────────
          _FilterBar(vm: vm),

          // ── Contenido principal ──────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              // Pull-to-refresh: útil como alternativa manual al Realtime
              onRefresh: vm.loadTasks,
              child: _buildBody(context, vm),
            ),
          ),
        ],
      ),

      // ── FAB: crear nueva tarea ────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.taskNew),
        icon: const Icon(Icons.add),
        label: const Text('Nueva tarea'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBody(BuildContext context, TaskListViewModel vm) {
    // Estado: cargando por primera vez → mostrar skeleton
    if (vm.isLoading && vm.tasks.isEmpty) {
      return _TaskListSkeleton();
    }

    // Estado: error
    if (vm.errorMessage != null && vm.tasks.isEmpty) {
      return _ErrorState(
        message: vm.errorMessage!,
        onRetry: vm.loadTasks,
      );
    }

    // Estado: vacío
    if (vm.tasks.isEmpty) {
      return const _EmptyState();
    }

    // Estado: con datos
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: vm.tasks.length,
      itemBuilder: (_, i) => TaskCard(
        task: vm.tasks[i],
        onTap: () => context.push(
          AppRoutes.taskDetail.replaceFirst(':id', vm.tasks[i].id),
        ),
        onDelete: () async {
          final confirm = await _confirmDelete(context);
          if (confirm) await vm.deleteTask(vm.tasks[i].id);
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Eliminar tarea'),
            content: const Text('¿Estás seguro de que quieres eliminar esta tarea? Esta acción no se puede deshacer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ── Subwidgets ─────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.vm});
  final TaskListViewModel vm;

  static const _filters = [
    ('all',                    'Todas'),
    (TaskStatus.todo,          'Pendiente'),
    (TaskStatus.inProgress,    'En progreso'),
    (TaskStatus.done,          'Completadas'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((f) {
            final (value, label) = f;
            final isSelected = vm.statusFilter == value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) => vm.setFilter(value),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFF64748B),
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.task_alt, size: 64, color: Color(0xFFCBD5E1)),
          SizedBox(height: 16),
          Text(
            'No tienes tareas aún',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Toca el botón + para crear tu primera tarea',
            style: TextStyle(color: Color(0xFFCBD5E1)),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton de carga usando shimmer — evita la pantalla en blanco.
class _TaskListSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
