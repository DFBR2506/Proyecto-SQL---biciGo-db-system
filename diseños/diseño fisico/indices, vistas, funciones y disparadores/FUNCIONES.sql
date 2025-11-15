--1. proximo mantenimiento de bicicletas
CREATE OR ALTER FUNCTION dbo.calcular_kilometraje_hasta_proximo_mantenimiento(@idBicicleta INT)
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
CREATE OR ALTER FUNCTION dbo.calcular_horas_en_alquiler(@idBicicleta INT)
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
CREATE OR ALTER FUNCTION dbo.calcular_tarifa_total_horas (
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
CREATE OR ALTER FUNCTION dbo.puede_alquilar(@id_persona INT)
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

--5 Bicicletas por rango de precio.
CREATE OR ALTER FUNCTION dbo.bicicletas_por_rango_de_precio(@precio_min INT, @precio_max INT)
RETURNS TABLE
AS
RETURN
    SELECT b.id_bicicleta,
    b.numero_de_cuadro,
    b.modelo,
    CASE b.es_electrica
        WHEN 1 THEN 'si'
        WHEN 0 THEN 'no'
    END AS es_electrica,
    b.tarifa_base_de_alquiler
    FROM bicicletas b 
    WHERE b.tarifa_base_de_alquiler BETWEEN @precio_min AND @precio_max AND b.activo = 1;
GO

--6 calcular la calificación promedio para bicicletas, guías o rutas.
CREATE OR ALTER FUNCTION dbo.calcular_calificación_promedio(@id_comentable INT, @tipo_comentable VARCHAR(20))
RETURNS DECIMAL(3,2)
AS
BEGIN
    SET @tipo_comentable = LOWER(@tipo_comentable);
    IF (@tipo_comentable IN ('bicicleta', 'guia', 'guía', 'ruta'))
    BEGIN
        DECLARE @cantidad_comentarios INT, @suma_calificaciones INT, @promedio DECIMAL(3,2);

        IF (@tipo_comentable = 'bicicleta')
        BEGIN
            SELECT @cantidad_comentarios = COUNT(*), @suma_calificaciones = SUM(c.calificacion)
            FROM comentarios_de_las_bicicletas cb
            JOIN comentarios c ON c.id_comentario = cb.id_comentario
            WHERE cb.id_bicicleta = @id_comentable
        END
        ELSE IF (@tipo_comentable = 'ruta')
        BEGIN
            SELECT @cantidad_comentarios = COUNT(*), @suma_calificaciones = SUM(c.calificacion)
            FROM comentarios_de_las_rutas_turisticas cr
            JOIN comentarios c ON c.id_comentario = cr.id_comentario
            WHERE cr.id_ruta_turistica = @id_comentable
        END
        ELSE
        BEGIN
            SELECT @cantidad_comentarios = COUNT(*), @suma_calificaciones = SUM(c.calificacion)
            FROM comentarios_de_los_guias cg
            JOIN comentarios c ON c.id_comentario = cg.id_comentario
            WHERE cg.id_guia = @id_comentable
        END;
    END
    ELSE
    BEGIN
        RETURN NULL;
    END;

    IF (@cantidad_comentarios = 0 OR @cantidad_comentarios IS NULL)
    BEGIN
        RETURN NULL;
    END
    
    SET @promedio = CAST(@suma_calificaciones AS DECIMAL(10,2)) / CAST(@cantidad_comentarios AS DECIMAL(10,2));
    RETURN @promedio;

END;
GO

-- 7. buscar guias que hablen un idioma
CREATE OR ALTER FUNCTION dbo.listar_guias_por_idioma(@nombre_idioma VARCHAR(30))
RETURNS TABLE
AS
RETURN
(
    SELECT 
        p.id_persona AS id_guia,
        p.primer_nombre + ' ' + p.primer_apellido AS nombre_completo,
        g.numero_de_tarjeta_profesional
    FROM idiomas i 
    JOIN idiomas_de_los_guias idg ON idg.id_idioma = i.id_idioma
    JOIN guias g ON g.id_persona = idg.id_guia
    JOIN personas p ON p.id_persona = g.id_persona
    WHERE LOWER(i.nombre) = LOWER(@nombre_idioma) AND g.activo = 1
);
GO

-- 8. Bicicletas disponibles por ciudad
CREATE OR ALTER FUNCTION dbo.bicicletas_disponibles_por_ciudad(@nombre_ciudad VARCHAR(40))
RETURNS TABLE
AS
RETURN
(
    SELECT pa.nombre AS punto_de_alquiler,
    id_bicicleta,
    m.nombre AS marca,
    b.modelo
    FROM ciudades c
    JOIN puntos_de_alquiler pa ON pa.id_ciudad = c.id_ciudad
    JOIN bicicletas b ON b.id_punto_de_alquiler = pa.id_punto_alquiler
    JOIN marcas m ON b.id_marca = m.id_marca
    WHERE LOWER(@nombre_ciudad) = LOWER(c.nombre) AND b.activo = 1
);
GO


-- 9. Historial de mantenimientos de una bicicleta
CREATE OR ALTER FUNCTION dbo.historial_de_mantenimiento_bicicleta(@id_bicicleta INT)
RETURNS TABLE
AS
RETURN
(
    SELECT m.descripcion, 
    tm.nombre AS tipo_de_mantenimiento, 
    m.fecha_de_inicio, 
    m.fecha_de_fin
    FROM mantenimientos m
    JOIN tipos_de_mantenimiento tm ON m.id_tipo_de_mantenimiento = tm.id_tipo_de_mantenimiento
    JOIN bicicletas b ON b.id_bicicleta = m.id_bicicleta
    WHERE m.id_bicicleta = @id_bicicleta AND b.activo = 1
);
GO

-- 10. recorridos según ruta
CREATE OR ALTER FUNCTION dbo.recorridos_por_ruta(@nombre_ruta VARCHAR(50))
RETURNS TABLE
AS
RETURN
(
    SELECT r.id_recorrido,
    r.fecha_de_realizacion,
    r.hora_de_inicio,
    r.hora_de_finalizacion,
    COUNT(DISTINCT p.id_participacion) AS cantidad_de_participantes,
    COUNT(DISTINCT gr.id_guia) AS cantidad_de_guias_designados
    FROM rutas_turisticas rt
    JOIN recorridos r ON r.id_ruta_turistica = rt.id_ruta_turistica
    JOIN participaciones p ON r.id_recorrido = p.id_recorrido
    JOIN guias_de_los_recorridos gr ON gr.id_recorrido = r.id_recorrido
    WHERE LOWER(rt.nombre) = LOWER(@nombre_ruta) AND rt.activo = 1
    GROUP BY r.id_recorrido, r.fecha_de_realizacion, r.hora_de_inicio, r.hora_de_finalizacion
);
GO
