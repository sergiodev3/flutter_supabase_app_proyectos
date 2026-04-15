-- =============================================================================
-- schema.sql — Esquema completo de la base de datos
-- =============================================================================
-- INSTRUCCIONES:
--   Ejecuta este archivo en el SQL Editor de Supabase:
--   https://supabase.com/dashboard → tu proyecto → SQL Editor → New Query
--
-- ORDEN DE EJECUCIÓN: ejecuta cada bloque EN ORDEN (las FK dependen de tablas previas)
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. EXTENSIONES
-- ─────────────────────────────────────────────────────────────────────────────

-- Habilita la generación de UUIDs con uuid_generate_v4()
-- Supabase ya la tiene activa por defecto, pero la incluimos por claridad.
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. TABLA: profiles
-- ─────────────────────────────────────────────────────────────────────────────
-- Extiende auth.users con datos públicos del perfil.
-- Relación: 1 auth.user → 1 profile (one-to-one)

CREATE TABLE IF NOT EXISTS public.profiles (
    id          UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email       TEXT        NOT NULL,
    full_name   TEXT,
    avatar_url  TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Comentarios educativos en las columnas (visibles en el dashboard de Supabase)
COMMENT ON TABLE  public.profiles           IS 'Perfil público de cada usuario autenticado.';
COMMENT ON COLUMN public.profiles.id        IS 'Mismo UUID que auth.users.id (FK + PK).';
COMMENT ON COLUMN public.profiles.email     IS 'Correo electrónico del usuario (espejado de auth.users).';
COMMENT ON COLUMN public.profiles.avatar_url IS 'URL pública del avatar en Supabase Storage.';


-- ─────────────────────────────────────────────────────────────────────────────
-- 3. TABLA: tasks
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.tasks (
    id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    title           TEXT        NOT NULL CHECK (char_length(title) >= 1 AND char_length(title) <= 200),
    description     TEXT,
    -- CHECK constraint: solo acepta los valores definidos en TaskStatus
    status          TEXT        NOT NULL DEFAULT 'todo'
                                CHECK (status IN ('todo', 'in_progress', 'done')),
    -- CHECK constraint: solo acepta los valores definidos en TaskPriority
    priority        TEXT        NOT NULL DEFAULT 'medium'
                                CHECK (priority IN ('low', 'medium', 'high')),
    user_id         UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    cover_image_url TEXT,
    due_date        DATE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  public.tasks              IS 'Tareas del tablero. Cada tarea pertenece a un usuario.';
COMMENT ON COLUMN public.tasks.user_id      IS 'FK al usuario dueño. RLS usa este campo para filtrar.';
COMMENT ON COLUMN public.tasks.status       IS 'Estado: todo | in_progress | done';
COMMENT ON COLUMN public.tasks.priority     IS 'Prioridad: low | medium | high';
COMMENT ON COLUMN public.tasks.cover_image_url IS 'URL pública de la imagen en bucket task-covers.';

-- Índice para acelerar la consulta más frecuente: tareas de un usuario
CREATE INDEX IF NOT EXISTS idx_tasks_user_id    ON public.tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status     ON public.tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON public.tasks(created_at DESC);


-- ─────────────────────────────────────────────────────────────────────────────
-- 4. TABLA: task_attachments
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.task_attachments (
    id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id     UUID        NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    user_id     UUID        NOT NULL REFERENCES auth.users(id)  ON DELETE CASCADE,
    file_name   TEXT        NOT NULL,
    file_url    TEXT        NOT NULL,   -- Ruta en Storage (para generar URLs firmadas)
    file_type   TEXT        NOT NULL,   -- 'pdf', 'docx', 'xlsx'…
    file_size   BIGINT      NOT NULL,   -- Tamaño en bytes
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  public.task_attachments         IS 'Archivos adjuntos de las tareas (PDF, DOCX, etc.).';
COMMENT ON COLUMN public.task_attachments.task_id IS 'ON DELETE CASCADE: al borrar la tarea, se borran sus adjuntos.';
COMMENT ON COLUMN public.task_attachments.file_url IS 'Ruta en bucket task-documents. Generar URL firmada en el cliente.';

CREATE INDEX IF NOT EXISTS idx_attachments_task_id ON public.task_attachments(task_id);
CREATE INDEX IF NOT EXISTS idx_attachments_user_id ON public.task_attachments(user_id);


-- ─────────────────────────────────────────────────────────────────────────────
-- 5. FUNCIÓN + TRIGGER: crear perfil automáticamente al registrarse
-- ─────────────────────────────────────────────────────────────────────────────
-- Cuando Supabase Auth crea un usuario en auth.users, este trigger
-- inserta automáticamente una fila en public.profiles.
-- Así el perfil siempre existe y no tenemos que crearlo manualmente desde Flutter.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER  -- Ejecuta con permisos de superusuario (necesario para leer auth.users)
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name)
    VALUES (
        NEW.id,
        NEW.email,
        -- Lee el nombre del user_metadata enviado desde Flutter en signUp()
        NEW.raw_user_meta_data ->> 'full_name'
    );
    RETURN NEW;
END;
$$;

-- Dispara la función DESPUÉS de cada INSERT en auth.users
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();


-- ─────────────────────────────────────────────────────────────────────────────
-- 6. FUNCIÓN: actualizar updated_at automáticamente
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER set_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE TRIGGER set_tasks_updated_at
    BEFORE UPDATE ON public.tasks
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
