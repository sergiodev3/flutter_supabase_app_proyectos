// lib/domain/repositories/i_storage_repository.dart
//
// ─── CONTRATO (Interfaz) ─────────────────────────────────────────────────────
// Operaciones sobre Supabase Storage.
//
// Dos buckets con distintas reglas de acceso:
//   task-covers   → PÚBLICO  → URL directa, sin expiración
//   task-documents → PRIVADO → URL firmada, expira en N segundos
//
// Esta diferencia es intencionalmente educativa: muestra que no todos
// los archivos deben ser públicos y cómo controlar el acceso con Storage.
// ─────────────────────────────────────────────────────────────────────────────

/// Contrato para operaciones de almacenamiento de archivos.
abstract interface class IStorageRepository {
  // ── Imágenes de portada (bucket público) ─────────────────────────────────────

  /// Sube una imagen de portada al bucket `task-covers`.
  /// Devuelve la URL pública directa del archivo.
  ///
  /// Ruta en Storage: `{userId}/{taskId}/cover.{ext}`
  Future<String> uploadCoverImage({
    required String taskId,
    required String filePath,  // Ruta local del archivo
  });

  /// Elimina la imagen de portada de una tarea.
  Future<void> deleteCoverImage({
    required String taskId,
    required String fileUrl,
  });

  // ── Documentos adjuntos (bucket privado) ─────────────────────────────────────

  /// Sube un documento al bucket `task-documents`.
  /// Devuelve la ruta del archivo en Storage (para generar URLs firmadas).
  ///
  /// Ruta en Storage: `{userId}/{taskId}/{uuid}.{ext}`
  Future<String> uploadDocument({
    required String taskId,
    required String filePath,
    required String fileName,
  });

  /// Genera una URL firmada temporal para un documento privado.
  /// [expiresIn] es el tiempo en segundos (por defecto 1 hora).
  ///
  /// CONCEPTO CLAVE: A diferencia de las URLs públicas, las URLs firmadas
  /// expiran y solo son válidas por el tiempo especificado.
  Future<String> createSignedUrl({
    required String storagePath,
    int expiresIn = 3600,
  });

  /// Elimina un documento del Storage.
  Future<void> deleteDocument(String storagePath);
}
