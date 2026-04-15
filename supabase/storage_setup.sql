-- =============================================================================
-- storage_setup.sql — Configuración de Supabase Storage
-- =============================================================================
-- INSTRUCCIONES:
--   Puedes crear los buckets desde el Dashboard de Supabase (Storage > New bucket)
--   O ejecutar este SQL en el SQL Editor.
--
-- BUCKETS:
--   task-covers    → PÚBLICO  → imágenes de portada (jpg, png, webp)
--   task-documents → PRIVADO  → documentos adjuntos (pdf, docx, xlsx)
--
-- Diferencia clave:
--   Bucket PÚBLICO:  URL directa sin token. Ideal para imágenes que se muestran en la UI.
--   Bucket PRIVADO:  Requiere URL firmada con expiración. Para archivos sensibles.
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- Crear buckets
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
    -- Bucket público para imágenes de portada
    (
        'task-covers',
        'task-covers',
        true,                             -- public = true → URLs directas sin token
        5242880,                          -- Límite: 5 MB por archivo
        ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
    ),
    -- Bucket privado para documentos
    (
        'task-documents',
        'task-documents',
        false,                            -- public = false → requiere URL firmada
        20971520,                         -- Límite: 20 MB por archivo
        ARRAY['application/pdf',
              'application/msword',
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
              'application/vnd.ms-excel',
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              'text/plain']
    )
ON CONFLICT (id) DO NOTHING;  -- No falla si ya existen


-- ─────────────────────────────────────────────────────────────────────────────
-- Políticas de Storage
-- ─────────────────────────────────────────────────────────────────────────────
-- Estructura de ruta: {user_id}/{task_id}/{filename}
-- Esto asegura que cada usuario solo sube/lee archivos en su carpeta.

-- == task-covers (público) ==

-- Cualquiera puede VER imágenes de portada (necesario para mostrarlas en la UI)
CREATE POLICY "covers: public read"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'task-covers');

-- Solo el usuario autenticado puede SUBIR en su propia carpeta
CREATE POLICY "covers: upload own folder"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'task-covers'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Solo el dueño puede ACTUALIZAR sus archivos
CREATE POLICY "covers: update own"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'task-covers'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Solo el dueño puede ELIMINAR sus archivos
CREATE POLICY "covers: delete own"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'task-covers'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );


-- == task-documents (privado) ==

-- Solo el dueño puede LEER sus documentos (URL firmada no es suficiente sin esto)
CREATE POLICY "documents: select own"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'task-documents'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "documents: upload own"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'task-documents'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "documents: delete own"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'task-documents'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );


-- =============================================================================
-- NOTAS PARA ESTUDIANTES:
--
-- storage.foldername(name) → devuelve el array de segmentos del path.
-- Si el archivo está en 'user-123/task-456/doc.pdf':
--   (storage.foldername(name))[1] = 'user-123'   ← comprobamos que sea el usuario actual
--   (storage.foldername(name))[2] = 'task-456'
--
-- auth.uid()::text → el UUID del usuario autenticado, convertido a texto.
-- =============================================================================
