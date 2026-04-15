// lib/presentation/viewmodels/task_list_viewmodel.dart
//
// ─── VIEWMODEL — Lista de tareas + Realtime ───────────────────────────────────
// Demuestra dos formas de cargar datos:
//   1. Carga puntual (snapshot): getTasks() → lista fija
//   2. Stream en tiempo real:    watchTasks() → lista auto-actualizada
//
// La lista de tareas es el lugar ideal para enseñar Realtime porque
// los estudiantes pueden ver cambios instantáneos desde otro dispositivo/tab.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/i_task_repository.dart';

class TaskListViewModel extends ChangeNotifier {
  TaskListViewModel(this._taskRepository) {
    // Carga inicial de tareas al crear el ViewModel
    loadTasks();
    // Activa escucha Realtime para actualizaciones automáticas
    _subscribeToRealtime();
  }

  final ITaskRepository _taskRepository;

  // ── Estado observable ─────────────────────────────────────────────────────

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _statusFilter = 'all'; // 'all' | 'todo' | 'in_progress' | 'done'

  List<Task> get tasks => _filteredTasks();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get statusFilter => _statusFilter;

  // ── Filtrado ──────────────────────────────────────────────────────────────

  List<Task> _filteredTasks() {
    if (_statusFilter == 'all') return _tasks;
    return _tasks.where((t) => t.status == _statusFilter).toList();
  }

  void setFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  // Conteo de tareas por estado (para mostrar badges en los filtros)
  int countByStatus(String status) =>
      _tasks.where((t) => t.status == status).length;

  // ── Carga de datos (snapshot) ─────────────────────────────────────────────

  Future<void> loadTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _taskRepository.getTasks();
    } on AppException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Eliminar tarea ────────────────────────────────────────────────────────

  Future<bool> deleteTask(String taskId) async {
    try {
      await _taskRepository.deleteTask(taskId);
      // Actualiza localmente (optimistic update) sin esperar el stream
      _tasks.removeWhere((t) => t.id == taskId);
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  // ── Realtime ──────────────────────────────────────────────────────────────

  StreamSubscription<List<Task>>? _realtimeSubscription;

  /// Suscribe la app al stream de cambios en tiempo real.
  ///
  /// Cada vez que alguien inserta, actualiza o elimina una tarea en Supabase,
  /// este stream emite la lista actualizada y reconstruye la pantalla.
  void _subscribeToRealtime() {
    _realtimeSubscription = _taskRepository.watchTasks().listen(
      (updatedTasks) {
        _tasks = updatedTasks;
        notifyListeners(); // ← La View se reconstruye automáticamente
      },
      onError: (Object e) {
        // El stream Realtime puede desconectarse por falta de red.
        // Intentamos recargar con snapshot como fallback.
        debugPrint('Realtime error: $e — fallback a snapshot');
        loadTasks();
      },
    );
  }

  // ── Limpieza ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    // MUY IMPORTANTE: cancela la suscripción para evitar memory leaks.
    // Si no lo haces, el stream seguirá activo aunque la pantalla se cierre.
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}
