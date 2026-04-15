-- =============================================================================
-- rls_policies.sql — Row Level Security (RLS)
-- =============================================================================
-- ⭐ CONCEPTO CLAVE PARA ESTUDIANTES ⭐
--
-- Row Level Security (RLS) es la JOYA de Supabase.
-- Permite definir en la BASE DE DATOS quién puede ver/modificar qué filas.
--
-- Sin RLS: cualquier usuario autenticado podría leer TODAS las tareas.
-- Con RLS: Supabase filtra automáticamente → cada usuario solo ve las suyas.
--
-- La función auth.uid() devuelve el UUID del usuario autenticado actual.
-- Supabase la evalúa en CADA consulta basándose en el JWT del request.
--
-- FLUJO:
--   Flutter → .select() → PostgREST → PostgreSQL evalúa RLS
--   → Solo devuelve filas donde user_id = auth.uid()
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 1: Habilitar RLS en todas las tablas
-- Sin este paso, las políticas no tienen efecto.
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.profiles         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_attachments ENABLE ROW LEVEL SECURITY;


-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 2: Políticas para la tabla `profiles`
-- ─────────────────────────────────────────────────────────────────────────────

-- SELECT: cada usuario solo puede ver SU propio perfil
CREATE POLICY "profiles: select own"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

-- INSERT: solo el propio usuario puede crear su perfil
-- (el trigger handle_new_user() lo hace automáticamente con SECURITY DEFINER)
CREATE POLICY "profiles: insert own"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- UPDATE: solo el propio usuario puede actualizar su perfil
CREATE POLICY "profiles: update own"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);


-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 3: Políticas para la tabla `tasks`
-- ─────────────────────────────────────────────────────────────────────────────

-- SELECT: el usuario solo ve SUS tareas
-- Sin esta política, .select() devolvería TODAS las tareas de todos los usuarios
CREATE POLICY "tasks: select own"
    ON public.tasks FOR SELECT
    USING (auth.uid() = user_id);

-- INSERT: el usuario solo puede crear tareas con SU user_id
-- Si intentara poner otro user_id, Supabase rechaza con error 403
CREATE POLICY "tasks: insert own"
    ON public.tasks FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- UPDATE: el usuario solo puede modificar SUS tareas
CREATE POLICY "tasks: update own"
    ON public.tasks FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- DELETE: el usuario solo puede eliminar SUS tareas
CREATE POLICY "tasks: delete own"
    ON public.tasks FOR DELETE
    USING (auth.uid() = user_id);


-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 4: Políticas para la tabla `task_attachments`
-- ─────────────────────────────────────────────────────────────────────────────

CREATE POLICY "attachments: select own"
    ON public.task_attachments FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "attachments: insert own"
    ON public.task_attachments FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "attachments: delete own"
    ON public.task_attachments FOR DELETE
    USING (auth.uid() = user_id);


-- =============================================================================
-- VERIFICACIÓN: ejecuta esto para ver las políticas activas
-- =============================================================================
-- SELECT schemaname, tablename, policyname, cmd, qual
-- FROM pg_policies
-- WHERE schemaname = 'public'
-- ORDER BY tablename, policyname;
