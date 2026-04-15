// lib/presentation/screens/tasks/task_detail_screen.dart
//
// ─── PANTALLA DETALLE DE TAREA ────────────────────────────────────────────────
// Demuestra:
//   • .delete() para eliminar la tarea completa
//   • Subida de documentos (PDF/DOCX) a Supabase Storage
//   • URLs firmadas para archivos privados (expiran en 1 hora)
//   • Gestión de adjuntos: listar, subir, eliminar
//   • Abrir archivos con url_launcher
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/task.dart';
import '../../viewmodels/task_detail_viewmodel.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/task/status_chip.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TaskDetailViewModel>();

    // Escucha mensajes de éxito/error para mostrar snackbars
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (vm.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(vm.successMessage!),
              backgroundColor: AppColors.done),
        );
        vm.clearMessages();
      }
      if (vm.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(vm.errorMessage!),
              backgroundColor: AppColors.error),
        );
        vm.clearMessages();
      }
    });

    return LoadingOverlay(
      isLoading: vm.isLoading,
      child: Scaffold(
        body: vm.isLoading && vm.task == null
            ? const Center(child: CircularProgressIndicator())
            : vm.task == null
                ? _buildError(context, vm)
                : _buildContent(context, vm),
      ),
    );
  }

  Widget _buildError(BuildContext context, TaskDetailViewModel vm) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 12),
            Text(vm.errorMessage ?? 'Tarea no encontrada'),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Regresar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TaskDetailViewModel vm) {
    final task = vm.task!;

    return CustomScrollView(
      slivers: [
        // ── AppBar con imagen de portada ─────────────────────────────────
        SliverAppBar(
          expandedHeight: task.coverImageUrl != null ? 220 : 0,
          pinned: true,
          flexibleSpace: task.coverImageUrl != null
              ? FlexibleSpaceBar(
                  background: CachedNetworkImage(
                    imageUrl: task.coverImageUrl!,
                    fit: BoxFit.cover,
                  ),
                )
              : null,
          actions: [
            // Botón Editar — pasa la tarea como `extra` para evitar una
            // segunda consulta a la BD en la pantalla de edición
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(
                AppRoutes.taskEdit.replaceFirst(':id', task.id),
                extra: task,
              ),
            ),
            // Botón Eliminar
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _confirmAndDelete(context, vm),
            ),
          ],
        ),

        // ── Contenido ────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Chips de estado y prioridad
              Row(
                children: [
                  StatusChip(status: task.status),
                  const SizedBox(width: 8),
                  _PriorityChip(priority: task.priority),
                ],
              ),
              const SizedBox(height: 16),

              // Título
              Text(
                task.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),

              // Fechas
              _MetaRow(
                icon: Icons.calendar_today_outlined,
                label: 'Creada',
                value: DateFormat('dd MMM yyyy, HH:mm', 'es')
                    .format(task.createdAt),
              ),
              if (task.dueDate != null)
                _MetaRow(
                  icon: Icons.event_outlined,
                  label: 'Vence',
                  value: DateFormat('dd MMM yyyy', 'es').format(task.dueDate!),
                  valueColor: task.dueDate!.isBefore(DateTime.now())
                      ? AppColors.error
                      : null,
                ),
              const SizedBox(height: 20),

              // Descripción
              if (task.description != null && task.description!.isNotEmpty) ...[
                const Text(
                  'Descripción',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF475569)),
                ),
                const SizedBox(height: 6),
                Text(
                  task.description!,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Sección Adjuntos ────────────────────────────────────────
              _AttachmentsSection(vm: vm),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndDelete(
      BuildContext context, TaskDetailViewModel vm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: const Text(
          '¿Eliminar esta tarea? También se borrarán todos sus adjuntos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await vm.deleteTask();
      if (success && context.mounted) context.go(AppRoutes.taskList);
    }
  }
}

// ── Sección de Adjuntos ────────────────────────────────────────────────────────

class _AttachmentsSection extends StatelessWidget {
  const _AttachmentsSection({required this.vm});
  final TaskDetailViewModel vm;

  Future<void> _pickAndUpload(BuildContext context) async {
    // file_picker permite seleccionar PDF, DOCX, XLSX, etc.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xlsx', 'xls', 'pptx', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      if (context.mounted) {
        await context.read<TaskDetailViewModel>().uploadAttachment(
              File(result.files.single.path!),
            );
      }
    }
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachments = vm.task?.attachments ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Adjuntos',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF475569)),
            ),
            const Spacer(),
            if (vm.isUploading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              TextButton.icon(
                onPressed: () => _pickAndUpload(context),
                icon: const Icon(Icons.attach_file, size: 16),
                label: const Text('Adjuntar'),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (attachments.isEmpty)
          const Text(
            'Sin adjuntos. Toca "Adjuntar" para subir un PDF o documento.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          )
        else
          ...attachments.map(
            (a) => _AttachmentTile(
              attachment: a,
              onOpen: () => _openFile(a.fileUrl),
              onDelete: () => vm.deleteAttachment(a),
            ),
          ),
      ],
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.attachment,
    required this.onOpen,
    required this.onDelete,
  });
  final TaskAttachment attachment;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  IconData get _icon => switch (attachment.fileType) {
        'pdf'  => Icons.picture_as_pdf_outlined,
        'docx' || 'doc' => Icons.description_outlined,
        'xlsx' || 'xls' => Icons.table_chart_outlined,
        _      => Icons.insert_drive_file_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(_icon, color: AppColors.primary, size: 22),
      ),
      title: Text(attachment.fileName,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${attachment.fileType.toUpperCase()} · ${attachment.formattedSize}',
        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.open_in_new, size: 18),
            onPressed: onOpen,
            tooltip: 'Abrir',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18,
                color: AppColors.error),
            onPressed: onDelete,
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }
}

// ── Helpers UI ─────────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 6),
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF64748B))),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  color: valueColor ?? const Color(0xFF334155),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});
  final String priority;

  Color get _color => switch (priority) {
        TaskPriority.high   => AppColors.high,
        TaskPriority.medium => AppColors.medium,
        _                   => AppColors.low,
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_outlined, size: 12, color: _color),
          const SizedBox(width: 4),
          Text(
            TaskPriority.label(priority),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
