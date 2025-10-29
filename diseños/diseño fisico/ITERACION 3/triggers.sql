-- ==============================================
-- TRIGGERS DE LAS TABLAS SOMBRA
-- ==============================================
CREATE TRIGGER trg_historial_bicicletas
ON bicicletas
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- REGISTRO DE INSERCIONES
    INSERT INTO historial_bicicletas (
        id_bicicleta, modelo, numero_de_cuadro, horas_de_uso, anio_de_fabricacion,
        tarifa_base_de_alquiler, etiquetas_adicionales, tamano_del_marco_cm, tamano_del_marco_in,
        es_electrica, id_tipo_de_uso, id_punto_de_alquiler, kilometraje_km, kilometraje_mi,
        id_estado_mantenimiento, id_seguro, id_marca, id_estado_de_disponibilidad, activo,
        accion
    )
    SELECT 
        i.id_bicicleta, i.modelo, i.numero_de_cuadro, i.horas_de_uso, i.anio_de_fabricacion,
        i.tarifa_base_de_alquiler, i.etiquetas_adicionales, i.tamano_del_marco_cm, i.tamano_del_marco_in,
        i.es_electrica, i.id_tipo_de_uso, i.id_punto_de_alquiler, i.kilometraje_km, i.kilometraje_mi,
        i.id_estado_mantenimiento, i.id_seguro, i.id_marca, i.id_estado_de_disponibilidad, i.activo,
        'INSERT'
    FROM inserted i;

    -- REGISTRO DE ACTUALIZACIONES
    INSERT INTO historial_bicicletas (
        id_bicicleta, modelo, numero_de_cuadro, horas_de_uso, anio_de_fabricacion,
        tarifa_base_de_alquiler, etiquetas_adicionales, tamano_del_marco_cm, tamano_del_marco_in,
        es_electrica, id_tipo_de_uso, id_punto_de_alquiler, kilometraje_km, kilometraje_mi,
        id_estado_mantenimiento, id_seguro, id_marca, id_estado_de_disponibilidad, activo,
        accion
    )
    SELECT 
        i.id_bicicleta, i.modelo, i.numero_de_cuadro, i.horas_de_uso, i.anio_de_fabricacion,
        i.tarifa_base_de_alquiler, i.etiquetas_adicionales, i.tamano_del_marco_cm, i.tamano_del_marco_in,
        i.es_electrica, i.id_tipo_de_uso, i.id_punto_de_alquiler, i.kilometraje_km, i.kilometraje_mi,
        i.id_estado_mantenimiento, i.id_seguro, i.id_marca, i.id_estado_de_disponibilidad, i.activo,
        'UPDATE'
    FROM inserted i;

    -- REGISTRO DE ELIMINACIONES
    INSERT INTO historial_bicicletas (
        id_bicicleta, modelo, numero_de_cuadro, horas_de_uso, anio_de_fabricacion,
        tarifa_base_de_alquiler, etiquetas_adicionales, tamano_del_marco_cm, tamano_del_marco_in,
        es_electrica, id_tipo_de_uso, id_punto_de_alquiler, kilometraje_km, kilometraje_mi,
        id_estado_mantenimiento, id_seguro, id_marca, id_estado_de_disponibilidad, activo,
        accion
    )
    SELECT 
        d.id_bicicleta, d.modelo, d.numero_de_cuadro, d.horas_de_uso, d.anio_de_fabricacion,
        d.tarifa_base_de_alquiler, d.etiquetas_adicionales, d.tamano_del_marco_cm, d.tamano_del_marco_in,
        d.es_electrica, d.id_tipo_de_uso, d.id_punto_de_alquiler, d.kilometraje_km, d.kilometraje_mi,
        d.id_estado_mantenimiento, d.id_seguro, d.id_marca, d.id_estado_de_disponibilidad, d.activo,
        'DELETE'
    FROM deleted d;
END;

-- Crear trigger para auditoría
CREATE TRIGGER trg_historial_mantenimientos
ON dbo.mantenimientos
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT (solo en inserted)
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO historial_mantenimientos (
            id_mantenimiento, descripcion, fecha_de_inicio, fecha_de_fin,
            id_tipo_de_mantenimiento, id_bicicleta, accion
        )
        SELECT
            i.id_mantenimiento, i.descripcion, i.fecha_de_inicio, i.fecha_de_fin,
            i.id_tipo_de_mantenimiento, i.id_bicicleta, 'INSERT'
        FROM inserted i;
    END

    -- UPDATE (en ambos)
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        -- Antes del cambio
        INSERT INTO historial_mantenimientos (
            id_mantenimiento, descripcion, fecha_de_inicio, fecha_de_fin,
            id_tipo_de_mantenimiento, id_bicicleta, accion
        )
        SELECT
            d.id_mantenimiento, d.descripcion, d.fecha_de_inicio, d.fecha_de_fin,
            d.id_tipo_de_mantenimiento, d.id_bicicleta, 'UPDATE_BEFORE'
        FROM deleted d;

        -- Después del cambio
        INSERT INTO historial_mantenimientos (
            id_mantenimiento, descripcion, fecha_de_inicio, fecha_de_fin,
            id_tipo_de_mantenimiento, id_bicicleta, accion
        )
        SELECT
            i.id_mantenimiento, i.descripcion, i.fecha_de_inicio, i.fecha_de_fin,
            i.id_tipo_de_mantenimiento, i.id_bicicleta, 'UPDATE_AFTER'
        FROM inserted i;
    END

    -- DELETE (solo en deleted)
    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO historial_mantenimientos (
            id_mantenimiento, descripcion, fecha_de_inicio, fecha_de_fin,
            id_tipo_de_mantenimiento, id_bicicleta, accion
        )
        SELECT
            d.id_mantenimiento, d.descripcion, d.fecha_de_inicio, d.fecha_de_fin,
            d.id_tipo_de_mantenimiento, d.id_bicicleta, 'DELETE'
        FROM deleted d;
    END
END;
GO


-- Crear trigger de auditoría
CREATE TRIGGER trg_historial_alquileres
ON dbo.alquileres
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT (solo en inserted)
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO historial_alquileres (
            id_alquiler, estado, fecha_de_inicio_de_vigencia, fecha_de_fin_de_vigencia,
            id_plan, id_usuario, id_bicicleta, id_metodo_de_pago, tarifa_total, accion
        )
        SELECT
            i.id_alquiler, i.estado, i.fecha_de_inicio_de_vigencia, i.fecha_de_fin_de_vigencia,
            i.id_plan, i.id_usuario, i.id_bicicleta, i.id_metodo_de_pago, i.tarifa_total, 'INSERT'
        FROM inserted i;
    END

    -- UPDATE (en ambos)
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        -- Antes del cambio
        INSERT INTO historial_alquileres (
            id_alquiler, estado, fecha_de_inicio_de_vigencia, fecha_de_fin_de_vigencia,
            id_plan, id_usuario, id_bicicleta, id_metodo_de_pago, tarifa_total, accion
        )
        SELECT
            d.id_alquiler, d.estado, d.fecha_de_inicio_de_vigencia, d.fecha_de_fin_de_vigencia,
            d.id_plan, d.id_usuario, d.id_bicicleta, d.id_metodo_de_pago, d.tarifa_total, 'UPDATE_BEFORE'
        FROM deleted d;

        -- Después del cambio
        INSERT INTO historial_alquileres (
            id_alquiler, estado, fecha_de_inicio_de_vigencia, fecha_de_fin_de_vigencia,
            id_plan, id_usuario, id_bicicleta, id_metodo_de_pago, tarifa_total, accion
        )
        SELECT
            i.id_alquiler, i.estado, i.fecha_de_inicio_de_vigencia, i.fecha_de_fin_de_vigencia,
            i.id_plan, i.id_usuario, i.id_bicicleta, i.id_metodo_de_pago, i.tarifa_total, 'UPDATE_AFTER'
        FROM inserted i;
    END

    -- DELETE (solo en deleted)
    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO historial_alquileres (
            id_alquiler, estado, fecha_de_inicio_de_vigencia, fecha_de_fin_de_vigencia,
            id_plan, id_usuario, id_bicicleta, id_metodo_de_pago, tarifa_total, accion
        )
        SELECT
            d.id_alquiler, d.estado, d.fecha_de_inicio_de_vigencia, d.fecha_de_fin_de_vigencia,
            d.id_plan, d.id_usuario, d.id_bicicleta, d.id_metodo_de_pago, d.tarifa_total, 'DELETE'
        FROM deleted d;
    END
END;
GO

-- Crear trigger de auditoría
CREATE TRIGGER trg_historial_recorridos
ON dbo.recorridos
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT (solo en inserted)
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO historial_recorridos (
            id_recorrido, hora_de_inicio, hora_de_finalizacion,
            fecha_de_realizacion, id_ruta_turistica, accion
        )
        SELECT
            i.id_recorrido, i.hora_de_inicio, i.hora_de_finalizacion,
            i.fecha_de_realizacion, i.id_ruta_turistica, 'INSERT'
        FROM inserted i;
    END

    -- UPDATE (en ambos)
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        -- Antes del cambio
        INSERT INTO historial_recorridos (
            id_recorrido, hora_de_inicio, hora_de_finalizacion,
            fecha_de_realizacion, id_ruta_turistica, accion
        )
        SELECT
            d.id_recorrido, d.hora_de_inicio, d.hora_de_finalizacion,
            d.fecha_de_realizacion, d.id_ruta_turistica, 'UPDATE_BEFORE'
        FROM deleted d;

        -- Después del cambio
        INSERT INTO historial_recorridos (
            id_recorrido, hora_de_inicio, hora_de_finalizacion,
            fecha_de_realizacion, id_ruta_turistica, accion
        )
        SELECT
            i.id_recorrido, i.hora_de_inicio, i.hora_de_finalizacion,
            i.fecha_de_realizacion, i.id_ruta_turistica, 'UPDATE_AFTER'
        FROM inserted i;
    END

    -- DELETE (solo en deleted)
    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO historial_recorridos (
            id_recorrido, hora_de_inicio, hora_de_finalizacion,
            fecha_de_realizacion, id_ruta_turistica, accion
        )
        SELECT
            d.id_recorrido, d.hora_de_inicio, d.hora_de_finalizacion,
            d.fecha_de_realizacion, d.id_ruta_turistica, 'DELETE'
        FROM deleted d;
    END
END;
GO


-- Crear trigger para auditoría
CREATE TRIGGER trg_historial_participaciones
ON dbo.participaciones
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT (solo en inserted)
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO historial_participaciones (
            id_participacion, fecha_de_inscripcion, tarifa_pagada,
            id_metodo_de_pago, id_recorrido, id_usuario, accion
        )
        SELECT
            i.id_participacion, i.fecha_de_inscripcion, i.tarifa_pagada,
            i.id_metodo_de_pago, i.id_recorrido, i.id_usuario, 'INSERT'
        FROM inserted i;
    END

    -- UPDATE (en ambos)
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        -- Antes del cambio
        INSERT INTO historial_participaciones (
            id_participacion, fecha_de_inscripcion, tarifa_pagada,
            id_metodo_de_pago, id_recorrido, id_usuario, accion
        )
        SELECT
            d.id_participacion, d.fecha_de_inscripcion, d.tarifa_pagada,
            d.id_metodo_de_pago, d.id_recorrido, d.id_usuario, 'UPDATE_BEFORE'
        FROM deleted d;

        -- Después del cambio
        INSERT INTO historial_participaciones (
            id_participacion, fecha_de_inscripcion, tarifa_pagada,
            id_metodo_de_pago, id_recorrido, id_usuario, accion
        )
        SELECT
            i.id_participacion, i.fecha_de_inscripcion, i.tarifa_pagada,
            i.id_metodo_de_pago, i.id_recorrido, i.id_usuario, 'UPDATE_AFTER'
        FROM inserted i;
    END

    -- DELETE (solo en deleted)
    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO historial_participaciones (
            id_participacion, fecha_de_inscripcion, tarifa_pagada,
            id_metodo_de_pago, id_recorrido, id_usuario, accion
        )
        SELECT
            d.id_participacion, d.fecha_de_inscripcion, d.tarifa_pagada,
            d.id_metodo_de_pago, d.id_recorrido, d.id_usuario, 'DELETE'
        FROM deleted d;
    END
END;
GO


CREATE TRIGGER trg_historial_reportes
ON dbo.reportes
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- 🟢 INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO historial_reportes (
            id_reporte, titulo, descripcion, id_estado_del_reporte,
            fecha_de_creacion, id_persona, id_bicicleta, accion
        )
        SELECT
            i.id_reporte, i.titulo, i.descripcion, i.id_estado_del_reporte,
            i.fecha_de_creacion, i.id_persona, i.id_bicicleta, 'INSERT'
        FROM inserted i;
    END

    -- 🟡 UPDATE
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        -- Estado antes de la modificación
        INSERT INTO historial_reportes (
            id_reporte, titulo, descripcion, id_estado_del_reporte,
            fecha_de_creacion, id_persona, id_bicicleta, accion
        )
        SELECT
            d.id_reporte, d.titulo, d.descripcion, d.id_estado_del_reporte,
            d.fecha_de_creacion, d.id_persona, d.id_bicicleta, 'UPDATE_BEFORE'
        FROM deleted d;

        -- Estado después de la modificación
        INSERT INTO historial_reportes (
            id_reporte, titulo, descripcion, id_estado_del_reporte,
            fecha_de_creacion, id_persona, id_bicicleta, accion
        )
        SELECT
            i.id_reporte, i.titulo, i.descripcion, i.id_estado_del_reporte,
            i.fecha_de_creacion, i.id_persona, i.id_bicicleta, 'UPDATE_AFTER'
        FROM inserted i;
    END

    -- 🔴 DELETE
    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO historial_reportes (
            id_reporte, titulo, descripcion, id_estado_del_reporte,
            fecha_de_creacion, id_persona, id_bicicleta, accion
        )
        SELECT
            d.id_reporte, d.titulo, d.descripcion, d.id_estado_del_reporte,
            d.fecha_de_creacion, d.id_persona, d.id_bicicleta, 'DELETE'
        FROM deleted d;
    END
END;
GO

CREATE TRIGGER trg_historial_comentarios
ON dbo.comentarios
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- 🟢 INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO historial_comentarios (
            id_comentario, id_persona, calificacion, descripcion,
            fecha_de_realizacion, visible, accion
        )
        SELECT
            i.id_comentario, i.id_persona, i.calificacion, i.descripcion,
            i.fecha_de_realizacion, i.visible, 'INSERT'
        FROM inserted i;
    END

    -- 🟡 UPDATE
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        -- Estado antes
        INSERT INTO historial_comentarios (
            id_comentario, id_persona, calificacion, descripcion,
            fecha_de_realizacion, visible, accion
        )
        SELECT
            d.id_comentario, d.id_persona, d.calificacion, d.descripcion,
            d.fecha_de_realizacion, d.visible, 'UPDATE_BEFORE'
        FROM deleted d;

        -- Estado después
        INSERT INTO historial_comentarios (
            id_comentario, id_persona, calificacion, descripcion,
            fecha_de_realizacion, visible, accion
        )
        SELECT
            i.id_comentario, i.id_persona, i.calificacion, i.descripcion,
            i.fecha_de_realizacion, i.visible, 'UPDATE_AFTER'
        FROM inserted i;
    END

    -- 🔴 DELETE
    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO historial_comentarios (
            id_comentario, id_persona, calificacion, descripcion,
            fecha_de_realizacion, visible, accion
        )
        SELECT
            d.id_comentario, d.id_persona, d.calificacion, d.descripcion,
            d.fecha_de_realizacion, d.visible, 'DELETE'
        FROM deleted d;
    END
END;
GO