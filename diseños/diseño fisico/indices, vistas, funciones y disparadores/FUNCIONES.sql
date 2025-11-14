--1. proximo mantenimiento de bicicletas
CREATE FUNCTION dbo.calcular_kilometraje_hasta_proximo_mantenimiento(@idBicicleta INT)
RETURNS INT
AS
BEGIN
    DECLARE @kmActual INT, @intervalo INT = 500, @restante INT;

    SELECT @kmActual = kilometraje_km
    FROM bicicletas
    WHERE id_bicicleta = @idBicicleta;

    IF @kmActual IS NULL
        RETURN NULL;

    SET @restante = @intervalo - (@kmActual % @intervalo);

    RETURN CASE 
        WHEN @restante = @intervalo THEN 0  
        ELSE @restante
    END;
END;
GO

--2. Tiempo de uso de bicicletas
CREATE FUNCTION dbo.calcular_horas_en_alquiler(@idBicicleta INT)
RETURNS INT
AS
BEGIN
    DECLARE @horas INT;

    SELECT @horas = SUM(DATEDIFF(HOUR, 
        fecha_de_inicio_de_vigencia, 
        fecha_de_fin_de_vigencia))
    FROM alquileres
    WHERE id_bicicleta = @idBicicleta
      AND fecha_de_inicio_de_vigencia IS NOT NULL
      AND fecha_de_fin_de_vigencia IS NOT NULL;
    RETURN ISNULL(@horas, 0);
END;
GO

--3. Calcular el precio total de alquiler según horas
CREATE FUNCTION dbo.calcular_tarifa_total_horas (
    @tarifa_base DECIMAL(10,2),
    @horas INT,
    @es_electrica BIT
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @iva DECIMAL(5,2) = 0.19;
    DECLARE @recargo_electrica DECIMAL(5,2) = CASE WHEN @es_electrica = 1 THEN 0.10 ELSE 0 END;

    RETURN @tarifa_base * @horas * (1 + @iva + @recargo_electrica);
END;
GO

--4 Evaluar si un usuario puede alquilar (activo + mayor de edad + aceptó política vigente). 
CREATE FUNCTION dbo.puede_alquilar(@id_persona INT)
RETURNS BIT
AS
BEGIN

    DECLARE @fecha_nacimiento DATE, @es_mayor BIT, @ultima_version_terminos INT, @acepto BIT;
    
    SELECT @fecha_nacimiento = p.fecha_de_nacimiento FROM personas p WHERE p.id_persona = @id_persona;

    IF (DATEADD(YEAR, 18, @fecha_nacimiento) > GETDATE())
    BEGIN
        SET @es_mayor = 0;
    END
    ELSE
    BEGIN
        SET @es_mayor = 1;
    END

    SELECT @ultima_version_terminos = MAX(id_politica) FROM politicas;
    SELECT @acepto = CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
    FROM aceptaciones_de_las_politicas 
    WHERE id_persona = @id_persona AND id_politica = @ultima_version_terminos;

    RETURN CASE WHEN @es_mayor = 1 AND @acepto = 1 THEN 1 ELSE 0 END;
END;
GO

--5 Si una bicicleta esta disponible o no.
CREATE FUNCTION fn_EstaAlquilada (@id_bicicleta INT)
RETURNS BIT
AS
BEGIN
    DECLARE @estado VARCHAR(100);
    SELECT TOP 1 @estado = ed.nombre
    FROM disponibilidades_tomadas_por_las_bicicletas db
    JOIN estados_de_disponibilidad_de_las_bicicletas ed 
        ON db.id_estado_de_disponibilidad_de_la_bicicleta = ed.id_estado_de_disponibilidad_de_la_bicicleta
    WHERE db.id_bicicleta = @id_bicicleta
    ORDER BY db.fecha_inicio_del_estado DESC;

    RETURN CASE WHEN @estado = 'En alquiler' THEN 1 ELSE 0 END;
END;
GO

--6  Años de experiencia de un guia a partir de su registro.
CREATE FUNCTION fn_ExperienciaRealGuia (@id_guia INT)
RETURNS INT
AS
BEGIN
    DECLARE @inicio DATE;
    SELECT @inicio = p.fecha_de_registro
    FROM personas p
    JOIN guias g ON g.id_persona = p.id_persona
    WHERE g.id_persona = @id_guia;

    RETURN DATEDIFF(YEAR, @inicio, GETDATE());
END;
GO


-- 7. Guias Disponibles por Ciudad

CREATE FUNCTION fn_GuiasDisponiblesPorCiudad(@idCiudad INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        p.id_persona AS id_guia,
        p.primer_nombre + ' ' + p.primer_apellido AS nombre_completo,
        c.nombre AS ciudad,
        g.anios_de_experiencia,
        g.numero_de_tarjeta_profesional,
        CASE 
            WHEN g.activo = 1 THEN 'Disponible'
            ELSE 'Inactivo'
        END AS estado_disponibilidad
    FROM guias AS g
    INNER JOIN personas AS p
        ON g.id_persona = p.id_persona
    INNER JOIN documentos_de_identificacion AS d
        ON p.id_documento_de_identificacion = d.id_documento_de_identificacion
    INNER JOIN ciudades AS c
        ON d.id_ciudad_de_expedicion = c.id_ciudad
    WHERE c.id_ciudad = @idCiudad
      AND g.activo = 1
);
GO


-- 8. Bicicletas disponibles por ciudad
CREATE OR ALTER FUNCTION fn_BicicletasDisponiblesPorCiudad(@nombreCiudad VARCHAR(100))
RETURNS TABLE
AS
RETURN
(
    SELECT 
        b.id_bicicleta, 
        b.modelo, 
        m.nombre AS marca, 
        pa.nombre AS punto_alquiler
    FROM bicicletas b
    JOIN marcas m ON b.id_marca = m.id_marca
    JOIN puntos_de_alquiler pa ON pa.id_punto_alquiler = b.id_punto_de_alquiler
    JOIN ciudades c ON pa.id_ciudad = c.id_ciudad
    WHERE c.nombre = @nombreCiudad AND b.activo = 1
);
GO


-- 9. Historial de mantenimientos de una bicicleta
CREATE OR ALTER FUNCTION fn_HistorialMantenimientosBicicleta(@id_bicicleta INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        m.descripcion, 
        tm.nombre AS tipo_mantenimiento, 
        m.fecha_de_inicio, 
        m.fecha_de_fin
    FROM mantenimientos m
    JOIN tipos_de_mantenimiento tm 
        ON m.id_tipo_de_mantenimiento = tm.id_tipo_de_mantenimiento
    WHERE m.id_bicicleta = @id_bicicleta
    ORDER BY m.fecha_de_inicio DESC
);
GO

-- 10. Alquileres activos por usuario
CREATE OR ALTER FUNCTION fn_AlquileresActivosPorUsuario(@id_usuario INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        a.id_alquiler, 
        b.modelo, 
        a.fecha_de_inicio_de_vigencia, 
        a.fecha_de_fin_de_vigencia, 
        a.tarifa_total
    FROM alquileres a
    JOIN bicicletas b ON a.id_bicicleta = b.id_bicicleta
    WHERE a.id_usuario = @id_usuario
      AND GETDATE() BETWEEN a.fecha_de_inicio_de_vigencia AND a.fecha_de_fin_de_vigencia
);
GO
