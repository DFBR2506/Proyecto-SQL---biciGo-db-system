-- 1. Registrar un usuario en la base de datos
CREATE PROCEDURE registrar_usuario
    @primer_apellido VARCHAR(100),
    @primer_nombre VARCHAR(100),
    @fecha_de_nacimiento DATE,
    @email VARCHAR(200),
    @numero_de_telefono VARCHAR(20),
    @id_documento_de_identificacion INT,
    @contraseña VARCHAR(200),
    @id_preferencia INT = 1,
    @out_id_persona INT OUTPUT
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRAN;

        INSERT INTO personas (
            primer_apellido, primer_nombre, fecha_de_nacimiento, email,
            numero_de_telefono, id_documento_de_identificacion, fecha_de_registro, activo
        ) VALUES (
            LTRIM(RTRIM(@primer_apellido)),
            LTRIM(RTRIM(@primer_nombre)),
            @fecha_de_nacimiento,
            LTRIM(RTRIM(@email)),
            NULLIF(LTRIM(RTRIM(@numero_de_telefono)), ''),
            @id_documento_de_identificacion,
            GETDATE(),
            1
        );

        SET @out_id_persona = CAST(SCOPE_IDENTITY() AS INT);

        -- Guardamos el usuario con contraseña hashed (SHA2_256)
        INSERT INTO usuarios (id_persona, contrasena, id_preferencia, activo)
        VALUES (
            @out_id_persona,
            HASHBYTES('SHA2_256', CONVERT(VARBINARY(200), @contraseña)),
            @id_preferencia,
            1
        );

        COMMIT TRAN;
        SELECT @out_id_persona AS id_persona;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO

-- 2.  Crear un alquiler haciendo las verificaciones pertinentes
CREATE PROCEDURE crear_alquiler
    @fecha_inicio DATETIME,
    @fecha_fin DATETIME,
    @id_plan INT,
    @id_usuario INT,
    @id_bicicleta INT,
    @id_metodo_de_pago INT,
    @tarifa_total DECIMAL(12,2),
    @id_estado_inicial INT, 
    @out_id_alquiler INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRAN;

        -- 1) Validar fechas
        IF @fecha_inicio > @fecha_fin
        BEGIN
            THROW 51000, 'fecha_inicio no puede ser mayor que fecha_fin', 1;
        END

        -- 2) Comprobar disponibilidad: no debe existir alquiler solapado para esa bici
        IF EXISTS (
            SELECT 1 FROM alquileres a
            WHERE a.id_bicicleta = @id_bicicleta
              AND NOT (a.fecha_de_fin_de_vigencia < @fecha_inicio OR a.fecha_de_inicio_de_vigencia > @fecha_fin)
        )
        BEGIN
            THROW 51001, 'La bicicleta no está disponible en el rango de fechas indicado.', 1;
        END

        -- 3) Insertar alquiler
        INSERT INTO alquileres (
            fecha_de_inicio_de_vigencia, fecha_de_fin_de_vigencia, id_plan, id_usuario, id_bicicleta, id_metodo_de_pago, tarifa_total, fecha_de_liquidacion
        ) VALUES (
            @fecha_inicio, @fecha_fin, @id_plan, @id_usuario, @id_bicicleta, @id_metodo_de_pago, @tarifa_total, GETDATE()
        );

        SET @out_id_alquiler = CAST(SCOPE_IDENTITY() AS INT);

        -- 4) Insertar estado inicial en historial de estados (tabla: estados_tomados_por_los_alquileres)
        INSERT INTO estados_tomados_por_los_alquileres (
            id_estado_del_alquiler, id_alquiler, fecha_inicio_del_estado, fecha_fin_del_estado
        ) VALUES (
            @id_estado_inicial, @out_id_alquiler, GETDATE(), NULL
        );

        COMMIT TRAN;
        SELECT @out_id_alquiler AS id_alquiler;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO

-- 3. Cambiar el estado de un alquiler
CREATE PROCEDURE actualizar_estado_alquiler
    @id_alquiler INT,
    @id_estado_nuevo INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRAN;

        UPDATE estados_tomados_por_los_alquileres
        SET fecha_fin_del_estado = GETDATE()
        WHERE id_alquiler = @id_alquiler
          AND fecha_fin_del_estado IS NULL;

        INSERT INTO estados_tomados_por_los_alquileres (
            id_estado_del_alquiler, id_alquiler, fecha_inicio_del_estado, fecha_fin_del_estado
        ) VALUES (
            @id_estado_nuevo, @id_alquiler, GETDATE(), NULL
        );

        COMMIT TRAN;
        SELECT @@ROWCOUNT AS filas_afectadas;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO

-- 4. Actualizar el kilometraje y horas de uso de las bicicletas
CREATE PROCEDURE actualizar_kilometraje_horas_bicicleta
    @id_bicicleta INT,
    @km_adicional DECIMAL(12,2) = NULL,
    @horas_adicional INT = NULL,
    @usuario_actualiza SYSNAME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM bicicletas WHERE id_bicicleta = @id_bicicleta)
            THROW 52023, 'Bicicleta no encontrada.', 1;

        BEGIN TRAN;
            IF @km_adicional IS NOT NULL
            BEGIN
                UPDATE bicicletas
                SET kilometraje_km = COALESCE(kilometraje_km,0) + @km_adicional
                WHERE id_bicicleta = @id_bicicleta;
            END

            IF @horas_adicional IS NOT NULL
            BEGIN
                UPDATE bicicletas
                SET horas_de_uso = COALESCE(horas_de_uso,0) + @horas_adicional
                WHERE id_bicicleta = @id_bicicleta;
            END

        COMMIT TRAN;

        SELECT @@ROWCOUNT AS filas_actualizadas;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END
GO


-- 5. Consultar las disponibilidades de bicicletas de un punto de alquiler basado (o no) en rangos de fechas
CREATE PROCEDURE consultar_disponibilidad_bicicletas
    @id_punto_de_alquiler INT = NULL,
    @fecha_inicio DATE = NULL,
    @fecha_fin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Si no pasan fechas, devolvemos bicicletas que no tengan un alquiler activo (estado solapado)
        IF @fecha_inicio IS NULL OR @fecha_fin IS NULL
        BEGIN
            SELECT b.* 
            FROM bicicletas b
            WHERE (@id_punto_de_alquiler IS NULL OR b.id_punto_de_alquiler = @id_punto_de_alquiler)
              AND b.activo = 1
              AND NOT EXISTS (
                SELECT 1 FROM alquileres a
                WHERE a.id_bicicleta = b.id_bicicleta
                  AND (a.fecha_de_fin_de_vigencia IS NULL OR a.fecha_de_fin_de_vigencia >= CAST(GETDATE() AS DATE))
                  AND (a.fecha_de_inicio_de_vigencia IS NULL OR a.fecha_de_inicio_de_vigencia <= CAST(GETDATE() AS DATE))
              );
            RETURN;
        END

        -- Con fechas: excluir bicicletas con alquileres que se solapan
        SELECT b.*
        FROM bicicletas b
        WHERE (@id_punto_de_alquiler IS NULL OR b.id_punto_de_alquiler = @id_punto_de_alquiler)
          AND b.activo = 1
          AND NOT EXISTS (
            SELECT 1 FROM alquileres a
            WHERE a.id_bicicleta = b.id_bicicleta
              AND NOT (a.fecha_de_fin_de_vigencia < @fecha_inicio OR a.fecha_de_inicio_de_vigencia > @fecha_fin)
          );
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- 6. Asignar participaciones
CREATE PROCEDURE asignar_participacion
    @id_usuario INT,
    @id_recorrido INT,
    @tarifa_pagada DECIMAL(10,2),
    @id_metodo_pago INT,
    @id_estado_inicial INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO participaciones (fecha_de_inscripcion, tarifa_pagada, id_metodo_de_pago, id_recorrido, id_usuario)
        VALUES (GETDATE(), @tarifa_pagada, @id_metodo_pago, @id_recorrido, @id_usuario);

        INSERT INTO estados_tomados_por_las_participaciones (id_participacion, id_estado_de_participacion, fecha_inicio_del_estado, fecha_fin_del_estado)
        VALUES(SCOPE_IDENTITY(), @id_estado_inicial, GETDATE(), NULL);
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- 7. Eliminar usuario
CREATE PROCEDURE eliminar_usuario
    @id_usuario INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @id_persona INT;

    BEGIN TRY
        BEGIN TRAN;

        SELECT @id_persona = id_persona FROM usuarios WHERE id_persona = @id_usuario;

        UPDATE usuarios SET activo = 0 WHERE id_persona = @id_usuario;
        UPDATE personas SET activo = 0 WHERE id_persona = @id_persona;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END
GO

-- 8. Devuelve todos los alquileres que caigan entre dos fechas. 
CREATE PROCEDURE consultar_alquileres_por_rango_fechas
    @fecha_inicio DATE,
    @fecha_fin DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        a.id_alquiler,
        a.fecha_de_inicio_de_vigencia,
        a.fecha_de_fin_de_vigencia,
        a.id_usuario,
        a.id_bicicleta,
        a.tarifa_total
    FROM alquileres a
    WHERE a.fecha_de_inicio_de_vigencia BETWEEN @fecha_inicio AND @fecha_fin
    ORDER BY a.fecha_de_inicio_de_vigencia;
END;
GO

-- 9. Crear un recorrido con un guía creador (luego por separado se puede asociar mas guías)
CREATE PROCEDURE crear_recorrido
    @id_guia_creador INT,
    @id_ruta INT,
    @fecha_de_realización DATE,
    @hora_de_inicio TIME(7),
    @hora_de_finalizacion TIME(7)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRAN;
        INSERT INTO recorridos (id_ruta_turistica, hora_de_inicio, hora_de_finalizacion, fecha_de_realizacion, fecha_creacion_de_recorrido)
        VALUES (@id_ruta, @hora_de_inicio, @hora_de_finalizacion, @fecha_de_realización, GETDATE());

        INSERT INTO guias_de_los_recorridos (id_guia, id_recorrido)
        VALUES (@id_guia_creador, SCOPE_IDENTITY())
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO

-- 10. cancelar un recorrido y cancelar automaticamente todas sus participaciones
CREATE PROCEDURE cancelar_recorrido
    @id_recorrido INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRAN;

        DECLARE @fecha_realizacion DATE;
        DECLARE @id_estado_cancelado_recorrido INT = 4;
        DECLARE @id_estado_cancelado_participacion INT = 4;

        SELECT @fecha_realizacion = fecha_de_realizacion
        FROM recorridos WHERE id_recorrido = @id_recorrido

        IF @fecha_realizacion >= GETDATE()
        BEGIN
            UPDATE estados_tomados_por_los_recorridos SET fecha_fin_del_estado = GETDATE() 
            WHERE id_recorrido = @id_recorrido AND fecha_fin_del_estado IS NULL;
            INSERT INTO estados_tomados_por_los_recorridos (fecha_inicio_del_estado, fecha_fin_del_estado, id_recorrido, id_estado_del_recorrido)
            VALUES (GETDATE(), NULL, @id_recorrido, @id_estado_cancelado_recorrido);

            UPDATE estados_tomados_por_las_participaciones SET fecha_fin_del_estado = GETDATE() 
            WHERE id_participacion IN (SELECT id_participacion FROM participaciones WHERE id_recorrido = @id_recorrido)
            AND fecha_fin_del_estado IS NULL;
            INSERT INTO estados_tomados_por_las_participaciones (fecha_inicio_del_estado, fecha_fin_del_estado, id_participacion, id_estado_de_participacion)
            SELECT GETDATE(), NULL, id_participacion, @id_estado_cancelado_participacion
            FROM participaciones
            WHERE id_recorrido = @id_recorrido
        END

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END;
