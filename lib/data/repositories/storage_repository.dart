// lib/data/repositories/storage_repository.dart
//
// ─── IMPLEMENTACIÓN ──────────────────────────────────────────────────────────
// Implementación concreta de [IStorageRepository] usando Supabase Storage.
//
// CONCEPTOS SUPABASE que se enseñan aquí:
//
//   📤  Subir archivo:
//      .storage.from(bucket).upload(path, file)
//
//   🌐  URL pública (bucket público):
//      .storage.from(bucket).getPublicUrl(path)
//      → URL directa, sin expiración, para imágenes de portada.
//
//   🔐  URL firmada (bucket privado):
//      .storage.from(bucket).createSignedUrl(path, expiresIn)
//      → URL temporal con token, para documentos sensibles.
//
//   🗑️  Eliminar archivo:
//      .storage.from(bucket).remove([path])
//
// ORGANIZACIÓN DE BUCKETS:
//   task-covers   → público  → imágenes (jpg, png, webp)
//   task-documents → privado → documentos (pdf, docx, xlsx)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart' as app;
import '../../domain/repositories/i_storage_repository.dart';

class StorageRepository implements IStorageRepository {
  StorageRepository(this._supabase);

  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  String get _userId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw const app.UnauthenticatedException();
    return id;
  }

  // ── Imágenes de portada (bucket PÚBLICO) ─────────────────────────────────

  @override
  Future<String> uploadCoverImage({
    required String taskId,
    required String filePath,
  }) async {
    try {
      final ext = p.extension(filePath); // '.jpg', '.png'…
      // Estructura de ruta: userId/taskId/cover.ext
      // Separar por userId permite que RLS del Storage filtre correctamente.
      final storagePath = '$_userId/$taskId/cover$ext';
      final file = File(filePath);

      await _supabase.storage
          .from(StorageBuckets.covers)
          .upload(
            storagePath,
            file,
            fileOptions: const FileOptions(upsert: true), // Reemplaza si ya existe
          );

      // getPublicUrl devuelve una URL permanente sin token.
      // Funciona porque el bucket está configurado como "Public" en Supabase.
      final publicUrl = _supabase.storage
          .from(StorageBuckets.covers)
          .getPublicUrl(storagePath);

      return publicUrl;
    } on StorageException catch (e) {
      throw app.StorageException(e.message);
    }
  }

  @override
  Future<void> deleteCoverImage({
    required String taskId,
    required String fileUrl,
  }) async {
    try {
      // Extraemos la ruta relativa desde la URL pública para poder eliminar.
      final uri = Uri.parse(fileUrl);
      // La URL tiene la forma: .../storage/v1/object/public/task-covers/{path}
      final pathIndex = uri.pathSegments.indexOf(StorageBuckets.covers);
      if (pathIndex == -1) return;
      final storagePath = uri.pathSegments.sublist(pathIndex + 1).join('/');

      await _supabase.storage
          .from(StorageBuckets.covers)
          .remove([storagePath]);
    } on StorageException catch (e) {
      throw app.StorageException(e.message);
    }
  }

  // ── Documentos (bucket PRIVADO) ───────────────────────────────────────────

  @override
  Future<String> uploadDocument({
    required String taskId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final ext = p.extension(filePath);
      // UUID único para evitar colisiones si el mismo usuario sube
      // dos archivos con el mismo nombre.
      final uniqueId = _uuid.v4();
      final storagePath = '$_userId/$taskId/$uniqueId$ext';
      final file = File(filePath);

      await _supabase.storage
          .from(StorageBuckets.documents)
          .upload(storagePath, file);

      // Devolvemos la RUTA (no URL) porque el bucket es privado.
      // La URL se genera bajo demanda con createSignedUrl().
      return storagePath;
    } on StorageException catch (e) {
      throw app.StorageException(e.message);
    }
  }

  @override
  Future<String> createSignedUrl({
    required String storagePath,
    int expiresIn = 3600, // 1 hora por defecto
  }) async {
    try {
      // createSignedUrl genera una URL con un token firmado HMAC.
      // El token incluye: bucket, path, expiración.
      // Después de expiresIn segundos, la URL deja de funcionar.
      final signedUrl = await _supabase.storage
          .from(StorageBuckets.documents)
          .createSignedUrl(storagePath, expiresIn);

      return signedUrl;
    } on StorageException catch (e) {
      throw app.StorageException(e.message);
    }
  }

  @override
  Future<void> deleteDocument(String storagePath) async {
    try {
      await _supabase.storage
          .from(StorageBuckets.documents)
          .remove([storagePath]);
    } on StorageException catch (e) {
      throw app.StorageException(e.message);
    }
  }
}
