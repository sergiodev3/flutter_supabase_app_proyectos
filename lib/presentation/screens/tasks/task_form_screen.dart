// lib/presentation/screens/tasks/task_form_screen.dart
//
// ─── PANTALLA CREAR / EDITAR TAREA ────────────────────────────────────────────
// Demuestra:
//   • .insert() para crear y .update() para editar (mismo formulario)
//   • Selección de imagen con image_picker → subida a Storage
//   • Validaciones del lado del cliente con Form + GlobalKey
//   • Manejo de estado de carga durante la subida de archivos
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/task.dart';
import '../../viewmodels/task_form_viewmodel.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/loading_overlay.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.existingTask});

  /// Si no es null, la pantalla funciona en modo EDICIÓN.
  final Task? existingTask;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey        = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descController  = TextEditingController(text: task?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Comprime la imagen antes de subir
      maxWidth: 1200,
    );
    if (xFile != null && mounted) {
      context.read<TaskFormViewModel>().setCoverImageFile(File(xFile.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<TaskFormViewModel>();
    vm.setTitle(_titleController.text.trim());
    vm.setDescription(_descController.text.trim());

    final saved = await vm.save();
    if (saved != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.isEditing
              ? 'Tarea actualizada correctamente.'
              : 'Tarea creada correctamente.'),
          backgroundColor: AppColors.done,
        ),
      );
      context.pop(); // Regresa a la lista (o al detalle si venía de edición)
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TaskFormViewModel>();

    return LoadingOverlay(
      isLoading: vm.isLoading,
      message: vm.isUploadingImage ? 'Subiendo imagen…' : 'Guardando…',
      child: Scaffold(
        appBar: AppBar(
          title: Text(vm.isEditing ? 'Editar tarea' : 'Nueva tarea'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Error ──────────────────────────────────────────────────
                if (vm.errorMessage != null)
                  _buildErrorBanner(vm.errorMessage!),

                // ── Imagen de portada ──────────────────────────────────────
                _CoverImagePicker(vm: vm, onTap: _pickImage),
                const SizedBox(height: 20),

                // ── Título ─────────────────────────────────────────────────
                AppTextField(
                  label: 'Título *',
                  hint: 'Ej: Implementar autenticación',
                  controller: _titleController,
                  prefixIcon: Icons.title,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'El título es obligatorio' : null,
                ),
                const SizedBox(height: 16),

                // ── Descripción ────────────────────────────────────────────
                AppTextField(
                  label: 'Descripción',
                  hint: 'Describe qué hay que hacer…',
                  controller: _descController,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: 20),

                // ── Estado ─────────────────────────────────────────────────
                _DropdownField<String>(
                  label: 'Estado',
                  value: vm.status,
                  items: TaskStatus.all.map((s) =>
                    DropdownMenuItem(value: s, child: Text(TaskStatus.label(s))),
                  ).toList(),
                  onChanged: (v) => vm.setStatus(v!),
                ),
                const SizedBox(height: 16),

                // ── Prioridad ──────────────────────────────────────────────
                _DropdownField<String>(
                  label: 'Prioridad',
                  value: vm.priority,
                  items: TaskPriority.all.map((p) =>
                    DropdownMenuItem(value: p, child: Text(TaskPriority.label(p))),
                  ).toList(),
                  onChanged: (v) => vm.setPriority(v!),
                ),
                const SizedBox(height: 16),

                // ── Fecha de vencimiento ───────────────────────────────────
                _DateField(
                  dueDate: vm.dueDate,
                  onChanged: vm.setDueDate,
                ),
                const SizedBox(height: 32),

                // ── Guardar ────────────────────────────────────────────────
                AppButton(
                  label: vm.isEditing ? 'Guardar cambios' : 'Crear tarea',
                  onPressed: _save,
                  isLoading: vm.isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.error)),
    );
  }
}

// ── Subwidgets del formulario ──────────────────────────────────────────────────

class _CoverImagePicker extends StatelessWidget {
  const _CoverImagePicker({required this.vm, required this.onTap});
  final TaskFormViewModel vm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasNewFile = vm.coverImageFile != null;
    final hasExistingUrl = vm.coverImageUrl != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            style: BorderStyle.solid,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasNewFile
            // Muestra la imagen local seleccionada (previa a subir)
            ? Image.file(vm.coverImageFile!, fit: BoxFit.cover)
            : hasExistingUrl
                // Muestra imagen existente de Supabase Storage
                ? CachedNetworkImage(
                    imageUrl: vm.coverImageUrl!,
                    fit: BoxFit.cover,
                  )
                // Placeholder: invita a seleccionar imagen
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 40, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 8),
                      Text('Toca para agregar portada',
                          style: TextStyle(color: Color(0xFF94A3B8))),
                    ],
                  ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.dueDate, required this.onChanged});
  final DateTime? dueDate;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fecha de vencimiento',
            style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: dueDate ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            );
            onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 18, color: Color(0xFF94A3B8)),
                const SizedBox(width: 10),
                Text(
                  dueDate != null
                      ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                      : 'Sin fecha de vencimiento',
                  style: TextStyle(
                    color: dueDate != null
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF94A3B8),
                  ),
                ),
                if (dueDate != null) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: () => onChanged(null),
                    child: const Icon(Icons.close,
                        size: 16, color: Color(0xFF94A3B8)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
