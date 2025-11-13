?-- ==============================================
-- TRIGGER BICICLETAS
-- ==============================================

CREATE OR ALTER TRIGGER trg_bicicletas_historial
ON bicicletas
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- ?? REGISTROS INSERTADOS O ACTUALIZADOS
    INSERT INTO historial_bicicletas (
        id_bicicleta, modelo, numero_de_cuadro, horas_de_uso, anio_de_fabricacion,
        tarifa_base_de_alquiler, etiquetas_adicionales, tamano_del_marco_cm, tamano_del_marco_in,
        es_electrica, id_tipo_de_uso, id_punto_de_alquiler, kilometraje_km, kilometraje_mi,
        id_seguro, id_marca, activo, fecha_de_creacion, accion, fecha_cambio, usuario_sql
    )
    SELECT 
        i.id_bicicleta, i.modelo, i.numero_de_cuadro, i.horas_de_uso, i.anio_de_fabricacion,
        i.tarifa_base_de_alquiler, i.etiquetas_adicionales, i.tamano_del_marco_cm, i.tamano_del_marco_in,
        i.es_electrica, i.id_tipo_de_uso, i.id_punto_de_alquiler, i.kilometraje_km, i.kilometraje_mi,
        i.id_seguro, i.id_marca, i.activo,
        GETDATE() AS fecha_de_creacion, -- ?? ahora generada aquí
        CASE 
            WHEN EXISTS (SELECT 1 FROM deleted WHERE deleted.id_bicicleta = i.id_bicicleta) THEN 'UPDATE'
            ELSE 'INSERT'
        END AS accion,
        GETDATE() AS fecha_cambio,
        SUSER_SNAME() AS usuario_sql
    FROM inserted i;

    -- ?? REGISTROS ELIMINADOS
    INSERT INTO historial_bicicletas (
        id_bicicleta, modelo, numero_de_cuadro, horas_de_uso, anio_de_fabricacion,
        tarifa_base_de_alquiler, etiquetas_adicionales, tamano_del_marco_cm, tamano_del_marco_in,
        es_electrica, id_tipo_de_uso, id_punto_de_alquiler, kilometraje_km, kilometraje_mi,
        id_seguro, id_marca, activo, fecha_de_creacion, accion, fecha_cambio, usuario_sql
    )
    SELECT 
        d.id_bicicleta, d.modelo, d.numero_de_cuadro, d.horas_de_uso, d.anio_de_fabricacion,
        d.tarifa_base_de_alquiler, d.etiquetas_adicionales, d.tamano_del_marco_cm, d.tamano_del_marco_in,
        d.es_electrica, d.id_tipo_de_uso, d.id_punto_de_alquiler, d.kilometraje_km, d.kilometraje_mi,
        d.id_seguro, d.id_marca, d.activo,
        GETDATE() AS fecha_de_creacion, -- ?? igual aquí
        'DELETE' AS accion,
        GETDATE() AS fecha_cambio,
        SUSER_SNAME() AS usuario_sql
    FROM deleted d;
END;
GO

-- ==============================================
-- TRIGGER MANTENIMIENTOS
-- ==============================================
CREATE OR ALTER TRIGGER trg_mantenimientos_historial
ON mantenimientos
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO historial_mantenimientos (
        id_mantenimiento, descripcion, fecha_de_inicio, fecha_de_fin,
        id_tipo_de_mantenimiento, id_bicicleta,
        accion, fecha_cambio, usuario_sql
    )
    SELECT 
        COALESCE(i.id_mantenimiento, d.id_mantenimiento),
        COALESCE(i.descripcion, d.descripcion),
        COALESCE(i.fecha_de_inicio, d.fecha_de_inicio),
        COALESCE(i.fecha_de_fin, d.fecha_de_fin),
        COALESCE(i.id_tipo_de_mantenimiento, d.id_tipo_de_mantenimiento),
        COALESCE(i.id_bicicleta, d.id_bicicleta),
        CASE 
            WHEN i.id_mantenimiento IS NOT NULL AND d.id_mantenimiento IS NULL THEN 'INSERT'
            WHEN i.id_mantenimiento IS NOT NULL AND d.id_mantenimiento IS NOT NULL THEN 'UPDATE'
            ELSE 'DELETE'
        END,
        GETDATE(), SUSER_SNAME()
    FROM inserted i
    FULL JOIN deleted d ON i.id_mantenimiento = d.id_mantenimiento;
END;
GO

-- ==============================================
-- TRIGGER ALQUILERES
-- ==============================================
CREATE OR ALTER TRIGGER trg_alquileres_historial
ON alquileres
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO historial_alquileres (
        id_alquiler, fecha_de_inicio_de_vigencia, fecha_de_fin_de_vigencia,
        id_plan, id_usuario, id_bicicleta, id_metodo_de_pago, tarifa_total,
        fecha_de_liquidacion, accion, fecha_cambio, usuario_sql
    )
    SELECT 
        COALESCE(i.id_alquiler, d.id_alquiler),
        COALESCE(i.fecha_de_inicio_de_vigencia, d.fecha_de_inicio_de_vigencia),
        COALESCE(i.fecha_de_fin_de_vigencia, d.fecha_de_fin_de_vigencia),
        COALESCE(i.id_plan, d.id_plan),
        COALESCE(i.id_usuario, d.id_usuario),
        COALESCE(i.id_bicicleta, d.id_bicicleta),
        COALESCE(i.id_metodo_de_pago, d.id_metodo_de_pago),
        COALESCE(i.tarifa_total, d.tarifa_total),
        -- ?? Aquí usamos el nombre real de la columna original:
        COALESCE(i.fecha_de_liquidacion, d.fecha_de_liquidacion) AS fecha_liquidacion,
        CASE 
            WHEN i.id_alquiler IS NOT NULL AND d.id_alquiler IS NULL THEN 'INSERT'
            WHEN i.id_alquiler IS NOT NULL AND d.id_alquiler IS NOT NULL THEN 'UPDATE'
            ELSE 'DELETE'
        END AS accion,
        GETDATE() AS fecha_cambio,
        SUSER_SNAME() AS usuario_sql
    FROM inserted i
    FULL JOIN deleted d ON i.id_alquiler = d.id_alquiler;
END;
GO
-- ==============================================
-- TRIGGER RECORRIDOS
-- ==============================================
CREATE OR ALTER TRIGGER trg_recorridos_historial
ON recorridos
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO historial_recorridos (
        id_recorrido, hora_de_inicio, hora_de_finalizacion,
        fecha_de_realizacion, id_ruta_turistica,
        fecha_creacion_de_recorrido, accion, fecha_cambio, usuario_sql
    )
    SELECT 
        COALESCE(i.id_recorrido, d.id_recorrido),
        COALESCE(i.hora_de_inicio, d.hora_de_inicio),
        COALESCE(i.hora_de_finalizacion, d.hora_de_finalizacion),
        COALESCE(i.fecha_de_realizacion, d.fecha_de_realizacion),
        COALESCE(i.id_ruta_turistica, d.id_ruta_turistica),
        COALESCE(i.fecha_creacion_de_recorrido, d.fecha_creacion_de_recorrido),
        CASE 
            WHEN i.id_recorrido IS NOT NULL AND d.id_recorrido IS NULL THEN 'INSERT'
            WHEN i.id_recorrido IS NOT NULL AND d.id_recorrido IS NOT NULL THEN 'UPDATE'
            ELSE 'DELETE'
        END,
        GETDATE(), SUSER_SNAME()
    FROM inserted i
    FULL JOIN deleted d ON i.id_recorrido = d.id_recorrido;
END;
GO

-- ==============================================
-- TRIGGER PARTICIPACIONES
-- ==============================================
CREATE OR ALTER TRIGGER trg_participaciones_historial
ON participaciones
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO historial_participaciones (
        id_participacion, fecha_de_inscripcion, tarifa_pagada,
        id_metodo_de_pago, id_recorrido, id_usuario,
        accion, fecha_cambio, usuario_sql
    )
    SELECT 
        COALESCE(i.id_participacion, d.id_participacion),
        COALESCE(i.fecha_de_inscripcion, d.fecha_de_inscripcion),
        COALESCE(i.tarifa_pagada, d.tarifa_pagada),
        COALESCE(i.id_metodo_de_pago, d.id_metodo_de_pago),
        COALESCE(i.id_recorrido, d.id_recorrido),
        COALESCE(i.id_usuario, d.id_usuario),
        CASE 
            WHEN i.id_participacion IS NOT NULL AND d.id_participacion IS NULL THEN 'INSERT'
            WHEN i.id_participacion IS NOT NULL AND d.id_participacion IS NOT NULL THEN 'UPDATE'
            ELSE 'DELETE'
        END,
        GETDATE(), SUSER_SNAME()
    FROM inserted i
    FULL JOIN deleted d ON i.id_participacion = d.id_participacion;
END;
GO

-- ==============================================
-- TRIGGER REPORTES
-- ==============================================
CREATE OR ALTER TRIGGER trg_reportes_historial
ON reportes
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO historial_reportes (
        id_reporte, titulo, descripcion, fecha_de_creacion,
        id_persona, id_bicicleta,
        accion, fecha_cambio, usuario_sql
    )
    SELECT 
        COALESCE(i.id_reporte, d.id_reporte),
        COALESCE(i.titulo, d.titulo),
        COALESCE(i.descripcion, d.descripcion),
        COALESCE(i.fecha_de_creacion, d.fecha_de_creacion),
        COALESCE(i.id_persona, d.id_persona),
        COALESCE(i.id_bicicleta, d.id_bicicleta),
        CASE 
            WHEN i.id_reporte IS NOT NULL AND d.id_reporte IS NULL THEN 'INSERT'
            WHEN i.id_reporte IS NOT NULL AND d.id_reporte IS NOT NULL THEN 'UPDATE'
            ELSE 'DELETE'
        END,
        GETDATE(), SUSER_SNAME()
    FROM inserted i
    FULL JOIN deleted d ON i.id_reporte = d.id_reporte;
END;
GO

-- ==============================================
-- TRIGGER COMENTARIOS
-- ==============================================

CREATE OR ALTER TRIGGER trg_comentarios_historial
ON comentarios
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO historial_comentarios (
        id_comentario, id_persona, calificacion, descripcion,
        fecha_de_creacion, visible,
        accion, fecha_cambio, usuario_sql
    )
    SELECT 
        COALESCE(i.id_comentario, d.id_comentario),
        COALESCE(i.id_persona, d.id_persona),
        COALESCE(i.calificacion, d.calificacion),
        COALESCE(i.descripcion, d.descripcion),
        COALESCE(i.fecha_de_creacion, d.fecha_de_creacion),
        COALESCE(i.visible, d.visible),
        CASE 
            WHEN i.id_comentario IS NOT NULL AND d.id_comentario IS NULL THEN 'INSERT'
            WHEN i.id_comentario IS NOT NULL AND d.id_comentario IS NOT NULL THEN 'UPDATE'
            ELSE 'DELETE'
        END,
        GETDATE(), SUSER_SNAME()
    FROM inserted i
    FULL JOIN deleted d ON i.id_comentario = d.id_comentario;
END;
GO

