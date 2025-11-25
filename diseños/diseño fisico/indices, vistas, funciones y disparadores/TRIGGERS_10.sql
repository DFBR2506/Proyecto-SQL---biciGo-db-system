---1 corregido

CREATE OR ALTER TRIGGER trg_after_insert_alquileres_actualizar_disponibilidad
ON alquileres
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @id_estado_en_alquiler INT = 3;

    UPDATE d
    SET d.fecha_fin_del_estado = i.fecha_de_inicio_de_vigencia
    FROM disponibilidades_tomadas_por_las_bicicletas d
    INNER JOIN inserted i ON d.id_bicicleta = i.id_bicicleta
    WHERE d.fecha_fin_del_estado IS NULL;

    INSERT INTO disponibilidades_tomadas_por_las_bicicletas (
        id_estado_de_disponibilidad_de_la_bicicleta,
        id_bicicleta,
        fecha_inicio_del_estado,
        fecha_fin_del_estado
    )
    SELECT 
        @id_estado_en_alquiler,
        i.id_bicicleta,
        i.fecha_de_inicio_de_vigencia,
        NULL
    FROM inserted i;
END;
GO


---2 corregido / perfecto 

CREATE OR ALTER TRIGGER trg_instead_of_insert_participaciones_validar_usuario_y_limite
ON participaciones
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN usuarios u ON i.id_usuario = u.id_persona
        WHERE u.activo = 0
    )
    BEGIN
        RAISERROR('No se puede inscribir a un usuario inactivo en una participación.', 16, 1);
        RETURN;
    END

    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE (
            SELECT COUNT(*)
            FROM participaciones p
            WHERE p.id_recorrido = i.id_recorrido
        ) >= 20
    )
    BEGIN
        RAISERROR('El recorrido ha alcanzado su límite máximo de participantes (20).', 16, 1);
        RETURN;
    END

    INSERT INTO participaciones (
        fecha_de_inscripcion, tarifa_pagada, id_metodo_de_pago,
        id_recorrido, id_usuario
    )
    SELECT 
        fecha_de_inscripcion, tarifa_pagada, id_metodo_de_pago,
        id_recorrido, id_usuario
    FROM inserted;
END;
GO

--- 3 Nuevo trigger. Evitar eliminacion de marcas

CREATE OR ALTER TRIGGER trg_prevent_delete_marca_con_bicicletas
ON marcas
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM deleted d
        INNER JOIN bicicletas b ON b.id_marca = d.id_marca
    )
    BEGIN
        RAISERROR('No se puede eliminar una marca que tiene bicicletas asociadas.', 16, 1);
        RETURN;
    END

    DELETE m
    FROM marcas m
    INNER JOIN deleted d ON m.id_marca = d.id_marca;
END;
GO


--- 4 Suena bien / perfecto

CREATE OR ALTER TRIGGER trg_instead_of_delete_bicicletas_soft_delete
ON bicicletas
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE b
    SET activo = 0
    FROM bicicletas b
    INNER JOIN deleted d ON b.id_bicicleta = d.id_bicicleta;

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
        d.id_seguro, d.id_marca, 0 AS activo,
        GETDATE(), 'SOFT_DELETE', GETDATE(), SUSER_SNAME()
    FROM deleted d;
END;
GO

--- 5 Nuevo trigger.  No permitir mover bicicletas de lugar si estan actualmente alquiladas.

CREATE OR ALTER TRIGGER trg_instead_of_update_bicicletas_validar_movimiento
ON bicicletas
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Obtener el ID del estado "Alquilada" dinámicamente
    DECLARE @id_estado_alquilada INT;

    SELECT @id_estado_alquilada = id_estado_de_disponibilidad_de_la_bicicleta
    FROM estados_de_disponibilidad_de_las_bicicletas
    WHERE nombre = 'Alquilada';

    -- Validar movimiento de punto de alquiler
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN deleted d ON i.id_bicicleta = d.id_bicicleta
        INNER JOIN disponibilidades_tomadas_por_las_bicicletas db
            ON db.id_bicicleta = i.id_bicicleta
        WHERE db.fecha_fin_del_estado IS NULL
          AND db.id_estado_de_disponibilidad_de_la_bicicleta = @id_estado_alquilada
          AND i.id_punto_de_alquiler <> d.id_punto_de_alquiler
    )
    BEGIN
        RAISERROR('No se puede mover una bicicleta que está actualmente alquilada.', 16, 1);
        RETURN;
    END;

    -- Si pasa la validación, ejecutar realmente el UPDATE
    UPDATE b
    SET 
        b.modelo              = i.modelo,
        b.numero_de_cuadro    = i.numero_de_cuadro,
        b.horas_de_uso        = i.horas_de_uso,
        b.anio_de_fabricacion = i.anio_de_fabricacion,
        b.tarifa_base_de_alquiler = i.tarifa_base_de_alquiler,
        b.etiquetas_adicionales   = i.etiquetas_adicionales,
        b.tamano_del_marco_cm     = i.tamano_del_marco_cm,
        b.tamano_del_marco_in     = i.tamano_del_marco_in,
        b.es_electrica         = i.es_electrica,
        b.id_tipo_de_uso       = i.id_tipo_de_uso,
        b.id_punto_de_alquiler = i.id_punto_de_alquiler,
        b.kilometraje_km       = i.kilometraje_km,
        b.kilometraje_mi       = i.kilometraje_mi,
        b.id_seguro            = i.id_seguro,
        b.id_marca             = i.id_marca,
        b.activo               = i.activo
    FROM bicicletas b
    INNER JOIN inserted i ON b.id_bicicleta = i.id_bicicleta;
END;
GO



--- 6 Arreglado la busqueda por caracteres, reemplazado por asignar directamente el numero del ID. Quitada la parte de notificaciones.

CREATE OR ALTER TRIGGER trg_prevent_delete_punto_de_alquiler_con_bicicletas
ON puntos_de_alquiler
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Verificar si el punto de alquiler tiene bicicletas asociadas
    IF EXISTS (
        SELECT 1    
        FROM bicicletas b
        INNER JOIN deleted d ON b.id_punto_de_alquiler = d.id_punto_alquiler
        WHERE b.activo = 1 -- Solo considera bicicletas activas
    )
    BEGIN
        RAISERROR('No se puede eliminar el punto de alquiler, ya que tiene bicicletas asociadas.', 16, 1);
        RETURN;
    END

    -- Si no tiene bicicletas asociadas, se permite la eliminación
    DELETE p
    FROM puntos_de_alquiler p
    INNER JOIN deleted d ON p.id_punto_alquiler = d.id_punto_alquiler;
END;
GO





--- 7 Suena bien / corregido 
CREATE OR ALTER TRIGGER trg_prevent_delete_closed_reports
ON reportes
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @id_estado_cerrado INT;

    -- Obtener dinámicamente el ID del estado 'Cerrado'
    SELECT @id_estado_cerrado = id_estado_del_reporte
    FROM estados_de_los_reportes
    WHERE nombre = 'Cerrado';

    -- Evitar eliminación de reportes cuya última transición esté vigente con estado = Cerrado
    IF EXISTS (
        SELECT 1
        FROM deleted d
        INNER JOIN estados_tomados_por_los_reportes etr
            ON etr.id_reporte = d.id_reporte
        WHERE etr.fecha_fin_del_estado IS NULL
          AND etr.id_estado_del_reporte = @id_estado_cerrado
    )
    BEGIN
        RAISERROR('No se pueden eliminar reportes que se encuentran en estado Cerrado.', 16, 1);
        RETURN;
    END;

    -- Si el reporte no está cerrado, permitir la eliminación real
    DELETE r
    FROM reportes r
    INNER JOIN deleted d ON r.id_reporte = d.id_reporte;
END;
GO



--- 8 Suena bien / Corregido

CREATE OR ALTER TRIGGER trg_instead_of_insert_alquileres_verificar_disponibilidad
ON alquileres
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @id_estado_alquilada INT = 3;


    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN disponibilidades_tomadas_por_las_bicicletas db 
            ON db.id_bicicleta = i.id_bicicleta
        WHERE db.fecha_fin_del_estado IS NULL
          AND db.id_estado_de_disponibilidad_de_la_bicicleta = @id_estado_alquilada
    )
    BEGIN
        RAISERROR('La bicicleta seleccionada ya está alquilada y no está disponible.', 16, 1);
        RETURN;
    END;

    IF EXISTS (
        SELECT 1 
        FROM inserted i
        WHERE i.fecha_de_fin_de_vigencia IS NOT NULL 
          AND i.fecha_de_fin_de_vigencia < i.fecha_de_inicio_de_vigencia
    )
    BEGIN
        RAISERROR('La fecha de fin no puede ser anterior a la fecha de inicio.', 16, 1);
        RETURN;
    END;

    INSERT INTO alquileres (
        fecha_de_inicio_de_vigencia, fecha_de_fin_de_vigencia, 
        id_plan, id_usuario, id_bicicleta, id_metodo_de_pago,
        tarifa_total, fecha_de_liquidacion
    )
    SELECT 
        fecha_de_inicio_de_vigencia, fecha_de_fin_de_vigencia, 
        id_plan, id_usuario, id_bicicleta, id_metodo_de_pago,
        tarifa_total, fecha_de_liquidacion
    FROM inserted;

END;
GO


--- 9 Suena bien / Perfecto 

CREATE OR ALTER TRIGGER trg_after_update_bicicletas_impedir_actualizacion_inactivas
ON bicicletas
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Si la versión previa (deleted) ya estaba inactiva => no permitir cambios
    IF EXISTS (
        SELECT 1
        FROM deleted d
        WHERE d.activo = 0
    )
    BEGIN
        RAISERROR('No se puede modificar una bicicleta que está marcada como inactiva.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

--- 10  Nuevo Trigger. A
CREATE OR ALTER TRIGGER trg_after_insert_historial_alquileres
ON alquileres
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO historial_alquileres (
        id_alquiler, fecha_de_inicio_de_vigencia, fecha_de_fin_de_vigencia,
        id_plan, id_usuario, id_bicicleta, id_metodo_de_pago, tarifa_total,
        fecha_de_liquidacion, accion, fecha_cambio, usuario_sql
    )
    SELECT
        i.id_alquiler,
        CAST(i.fecha_de_inicio_de_vigencia AS DATE),
        CAST(i.fecha_de_fin_de_vigencia AS DATE),
        i.id_plan,
        i.id_usuario,
        i.id_bicicleta,
        i.id_metodo_de_pago,
        i.tarifa_total,
        CAST(i.fecha_de_liquidacion AS DATE),
        'INSERT',
        GETDATE(),
        SUSER_SNAME()
    FROM inserted i;
END;
GO
