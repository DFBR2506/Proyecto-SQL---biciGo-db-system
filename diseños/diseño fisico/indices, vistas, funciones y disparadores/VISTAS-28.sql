-- 1. Tarifas promedio dependiendo del uso
CREATE OR ALTER VIEW tarifas_promedio_por_uso AS
SELECT
    tdu.nombre AS tipo_de_uso,
	ROUND(AVG(b.tarifa_base_de_alquiler),2) AS tarifa_promedio,
	ROUND(MIN(b.tarifa_base_de_alquiler),2) AS tarifa_min,
    ROUND(MAX(b.tarifa_base_de_alquiler),2) AS tarifa_max
FROM bicicletas b
JOIN tipos_de_uso tdu ON tdu.id_tipo_de_uso = b.id_tipo_de_uso
WHERE b.activo = 1
GROUP BY tdu.nombre;
GO

-- 2. Información sobre rutas turisticas
CREATE OR ALTER VIEW info_rutas_turisticas AS
SELECT
	rt.nombre AS nombre_Ruta,
    COUNT(pdi.id_punto_de_interes) AS cantidad_Puntos_de_Interes,
    rt.distancia_total_km AS distancia_Kilometros,
    rt.distancia_total_mi AS distancia_Millas,
    nd.nombre AS dificultad
FROM rutas_turisticas rt
JOIN niveles_dificultad nd ON rt.id_nivel_dificultad = nd.id_nivel_dificultad
JOIN puntos_de_interes_de_las_rutas pdir ON rt.id_ruta_turistica = pdir.id_ruta_turistica
JOIN puntos_de_interes pdi ON pdir.id_punto_de_interes = pdi.id_punto_de_interes
WHERE rt.activo = 1 AND pdir.activo = 1
GROUP BY rt.nombre, rt.distancia_total_km, rt.distancia_total_mi, nd.nombre;
GO

-- 3. Alquileres activos
CREATE OR ALTER VIEW alquileres_activos AS
SELECT 
    a.id_alquiler,
    pdla.tipo_de_plan AS tipo_de_Plan,
    a.fecha_de_inicio_de_vigencia,
    a.fecha_de_fin_de_vigencia,
    p.primer_nombre + ' ' + p.primer_apellido AS nombre_usuario,
    b.id_bicicleta,
    b.modelo AS modelo_bicicleta,
    m.nombre AS marca
FROM alquileres a
JOIN usuarios u ON a.id_usuario = u.id_persona
JOIN personas p ON u.id_persona = p.id_persona
JOIN bicicletas b ON a.id_bicicleta = b.id_bicicleta
JOIN marcas m ON b.id_marca = m.id_marca
JOIN planes_de_los_alquileres pdla ON a.id_plan = pdla.id_plan
WHERE CAST(GETDATE() AS DATE) BETWEEN a.fecha_de_inicio_de_vigencia 
      AND a.fecha_de_fin_de_vigencia
      AND u.activo = 1
      AND p.activo = 1
      AND b.activo = 1
      AND pdla.activo = 1;
GO

-- 4. Reportes mensuales
CREATE OR ALTER VIEW reportes_mensuales AS
WITH estadisticas_mensuales AS (
    SELECT
        FORMAT(a.fecha_de_inicio_de_vigencia, 'yyyy') AS año,
        FORMAT(a.fecha_de_inicio_de_vigencia, 'MMMM', 'es-ES') AS mes,
        COUNT(*) AS cantidad_alquileres,
        ROUND(SUM(a.tarifa_total),2) AS total_facturado,
        ROUND(AVG(a.tarifa_total),2) AS tarifa_promedio,
        ROUND(MAX(a.tarifa_total),2) AS tarifa_maxima,
        ROUND(MIN(a.tarifa_total),2) AS tarifa_minima,
        COUNT(DISTINCT a.id_plan) AS cantidad_planes_diferentes,
        COUNT(DISTINCT a.id_usuario) AS usuarios_unicos,
        COUNT(DISTINCT a.id_bicicleta) AS bicicletas_utilizadas
    FROM alquileres a
    JOIN usuarios u ON a.id_usuario = u.id_persona
    JOIN bicicletas b ON a.id_bicicleta = b.id_bicicleta
    JOIN planes_de_los_alquileres pl ON a.id_plan = pl.id_plan
    WHERE u.activo = 1 
      AND b.activo = 1 
      AND pl.activo = 1
    GROUP BY 
        YEAR(a.fecha_de_inicio_de_vigencia),
        MONTH(a.fecha_de_inicio_de_vigencia),
        DATENAME(MONTH, a.fecha_de_inicio_de_vigencia),
        FORMAT(a.fecha_de_inicio_de_vigencia, 'yyyy'),
        FORMAT(a.fecha_de_inicio_de_vigencia, 'MMMM', 'es-ES')
)
SELECT
    año,
    mes,
    cantidad_alquileres, 
    total_facturado, 
    tarifa_promedio, 
    tarifa_maxima,
    tarifa_minima,
    cantidad_planes_diferentes,
    usuarios_unicos,
    bicicletas_utilizadas,
    CAST(total_facturado / cantidad_alquileres AS DECIMAL(10,2)) AS ingreso_promedio_por_Alquiler,
    CAST(usuarios_unicos * 100.0 / cantidad_alquileres AS DECIMAL(10,2)) AS porcentaje_usuarios_unicos
FROM estadisticas_Mensuales;
GO

-- 5. Información sobre la actividad de las bicicletas
CREATE OR ALTER VIEW informacion_actividad_bicicletas AS
WITH ultima_renta_por_bicicleta AS (
    SELECT id_bicicleta,
    MAX(fecha_de_fin_de_vigencia) AS fecha_fin_ultimo_alquiler, 
    CASE
        WHEN MAX(fecha_de_fin_de_vigencia) >= GETDATE() THEN 0
        ELSE DATEDIFF(DAY, MAX(fecha_de_fin_de_vigencia), GETDATE())
    END AS dias_desde_fin_ultimo_alquiler
    FROM alquileres a
    GROUP BY id_bicicleta
)
SELECT b.id_bicicleta, 
b.modelo, 
b.numero_de_cuadro, 
m.nombre AS marca,
b.kilometraje_km, 
b.horas_de_uso, 
b.id_punto_de_alquiler, 
urb.fecha_fin_ultimo_alquiler,
urb.dias_desde_fin_ultimo_alquiler,
CASE
    WHEN urb.dias_desde_fin_ultimo_alquiler >= 200 THEN 'Inactividad CRITICA'
    WHEN urb.dias_desde_fin_ultimo_alquiler >= 150 THEN 'Inactividad grave'
    WHEN urb.dias_desde_fin_ultimo_alquiler >= 100 THEN 'Inactividad alta'
    WHEN urb.dias_desde_fin_ultimo_alquiler >= 50 THEN 'Inactividad moderada'
    WHEN urb.dias_desde_fin_ultimo_alquiler >= 25 THEN 'Inactividad baja'
    WHEN urb.dias_desde_fin_ultimo_alquiler >= 0 THEN 'Actividad reciente'
    ELSE 'Nunca fue alquilada'
END AS estado_actividad
FROM bicicletas b
FULL JOIN ultima_renta_por_bicicleta urb ON urb.id_bicicleta = b.id_bicicleta
JOIN marcas m ON b.id_marca = m.id_marca
WHERE b.activo = 1;
GO

-- 6. bicicletas han tenido mantenimientos
CREATE OR ALTER VIEW bicicletas_han_tenido_mantenimiento AS
SELECT DISTINCT b.id_bicicleta, b.modelo, 'Ha tenido mantenimiento' AS estado, MAX(m.fecha_de_inicio) AS fecha_de_inicio_ultimo_mantenimiento, MAX(m.fecha_de_fin) AS fecha_de_fin_ultimo_mantenimiento
FROM mantenimientos m
JOIN bicicletas b ON m.id_bicicleta = b.id_bicicleta
WHERE b.activo = 1
GROUP BY b.id_bicicleta, b.modelo
UNION
SELECT b.id_bicicleta, b.modelo, 'No ha tenido mantenimiento' AS estado, NULL, NULL
FROM bicicletas b
WHERE b.activo = 1
EXCEPT
SELECT DISTINCT m.id_bicicleta, b.modelo, 'No ha tenido mantenimiento' AS estado, NULL, NULL
FROM mantenimientos m
JOIN bicicletas b ON m.id_bicicleta = b.id_bicicleta
WHERE b.activo = 1;
GO

-- 7. ranking de bicicletas por rentas, dividido en meses.
CREATE OR ALTER VIEW ranking_bicicletas_rentas_mes AS
WITH RankingBicicletas AS (
    SELECT 
        FORMAT(a.fecha_de_inicio_de_vigencia, 'yyyy') AS año,
        FORMAT(a.fecha_de_inicio_de_vigencia, 'MMMM', 'es-ES') AS mes,
        b.id_bicicleta,
        b.modelo,
        m.nombre AS marca,
        COUNT(*) AS rentas,
        DENSE_RANK() OVER (
            PARTITION BY FORMAT(a.fecha_de_inicio_de_vigencia, 'yyyy') 
            ORDER BY COUNT(*) DESC
        ) AS ranking
    FROM alquileres a
    INNER JOIN bicicletas b ON a.id_bicicleta = b.id_bicicleta
    INNER JOIN marcas m ON b.id_marca = m.id_marca
    WHERE b.activo = 1
    GROUP BY 
        FORMAT(a.fecha_de_inicio_de_vigencia, 'yyyy'),
        FORMAT(a.fecha_de_inicio_de_vigencia, 'MMMM', 'es-ES'),
        b.id_bicicleta,
        b.modelo,
        m.nombre
)
SELECT 
    *
FROM RankingBicicletas
WHERE ranking <= 10;
GO

-- 8. ranking de bicicletas por tarifa
CREATE OR ALTER VIEW ranking_bicicletas_por_tarifa AS
SELECT 
    b.id_bicicleta,
    b.modelo,
    m.nombre AS marca,
    b.tarifa_base_de_alquiler,
    DENSE_RANK() OVER (ORDER BY b.tarifa_base_de_alquiler DESC) AS ranking_en_marca
FROM bicicletas b
JOIN marcas m ON b.id_marca = m.id_marca
WHERE b.activo = 1;
GO

-- 9. Ranking de guias por experiencia en años y cantidad de rutas lideradas
CREATE OR ALTER VIEW ranking_guias_por_experiencia AS
WITH recorridos_por_guia AS (
    SELECT 
        gr.id_guia,
        COUNT(DISTINCT gr.id_recorrido) AS total_recorridos_dirigidos,
        AVG(DATEDIFF(HOUR, r.hora_de_inicio, r.hora_de_finalizacion)) AS avg_duracion_horas
    FROM guias g
    LEFT JOIN guias_de_los_recorridos gr ON gr.id_guia = g.id_persona
    JOIN recorridos r ON gr.id_recorrido = r.id_recorrido
    WHERE g.activo = 1
    GROUP BY gr.id_guia
) 
SELECT 
    g.id_persona AS id_guia,
    p.primer_nombre + ' ' + p.primer_apellido AS nombre_completo,
    g.anios_de_experiencia AS años_de_experiencia,
    g.numero_de_tarjeta_profesional,
    ISNULL(rpg.total_recorridos_dirigidos, 0) AS total_recorridos,
    ISNULL(rpg.avg_duracion_horas, 0) AS duracion_promedio_horas,
    RANK() OVER (
        ORDER BY CASE 
        WHEN g.anios_de_experiencia >= 5 
             AND ISNULL(rpg.total_recorridos_dirigidos, 0) >= 10 THEN 1
        WHEN g.anios_de_experiencia >= 3 
             AND ISNULL(rpg.total_recorridos_dirigidos, 0) >= 3 THEN 2
        ELSE 3
        END,
        g.anios_de_experiencia DESC,
        ISNULL(rpg.total_recorridos_dirigidos, 0) DESC
    ) AS ranking_experiencia,
    CASE 
        WHEN g.anios_de_experiencia >= 5 
             AND ISNULL(rpg.total_recorridos_dirigidos, 0) >= 10 THEN 'Experto'
        WHEN g.anios_de_experiencia >= 3 
             AND ISNULL(rpg.total_recorridos_dirigidos, 0) >= 3 THEN 'Intermedio'
        ELSE 'Principiante'
    END AS nivel_experiencia
FROM guias g
INNER JOIN personas p ON g.id_persona = p.id_persona
LEFT JOIN recorridos_por_guia rpg ON g.id_persona = rpg.id_guia
WHERE g.activo = 1;
GO

-- 10. Comparación de tarifas de alquiler por usuario
CREATE OR ALTER VIEW comparativo_tarifas_alquileres AS
SELECT 
    id_alquiler,
    id_usuario,
    tarifa_total,
    LAG(tarifa_total, 1)  OVER (PARTITION BY id_usuario ORDER BY fecha_de_inicio_de_vigencia) AS tarifa_anterior,
    LEAD(tarifa_total, 1) OVER (PARTITION BY id_usuario ORDER BY fecha_de_inicio_de_vigencia) AS tarifa_siguiente,
    fecha_de_inicio_de_vigencia,
    fecha_de_fin_de_vigencia,
    CASE 
        WHEN LAG(tarifa_total,1) OVER (PARTITION BY id_usuario ORDER BY fecha_de_inicio_de_vigencia) IS NULL THEN 'Primer alquiler'
        WHEN LEAD(tarifa_total,1) OVER (PARTITION BY id_usuario ORDER BY fecha_de_inicio_de_vigencia) IS NULL THEN 'Último alquiler'
        ELSE 'Intermedio'
    END AS posicion_relativa
FROM alquileres;
GO

-- 11. Actividad de los usuarios (comentar, alquilar, participar en recorridos)
CREATE OR ALTER VIEW actividad_usuarios AS
SELECT 
    u.id_persona AS id_usuario,
    p.primer_nombre + ' ' + p.primer_apellido AS nombre_completo,
    ISNULL((SELECT COUNT(*) FROM comentarios c WHERE c.id_persona = u.id_persona), 0) AS total_comentarios,
    ISNULL((SELECT COUNT(*) FROM alquileres a WHERE a.id_usuario = u.id_persona), 0) AS total_alquileres,
    ISNULL((SELECT COUNT(*) FROM participaciones pa WHERE pa.id_usuario = u.id_persona), 0) AS total_participaciones
FROM usuarios u
JOIN personas p ON u.id_persona = p.id_persona;
GO

-- 12. Analisis estadistico de las rutas
CREATE OR ALTER VIEW rutas_analisis_estadistico AS
SELECT 
    rt.id_ruta_turistica,
    rt.nombre AS nombre_ruta,
    COUNT(DISTINCT r.id_recorrido) AS total_recorridos,
    COUNT(DISTINCT p.id_participacion) AS total_participantes,
    CASE 
        WHEN COUNT(DISTINCT r.id_recorrido) > 0 THEN
            ROUND(CAST(COUNT(DISTINCT p.id_participacion) AS DECIMAL) 
            / CAST(COUNT(DISTINCT r.id_recorrido) AS DECIMAL),2)
        ELSE 0
    END AS promedio_participantes_por_recorrido,
    (SELECT COUNT(*) 
     FROM puntos_de_interes_de_las_rutas pir
     WHERE pir.id_ruta_turistica = rt.id_ruta_turistica 
       AND pir.activo = 1) AS total_puntos_interes,
    COUNT(DISTINCT gr.id_guia) AS total_guias_que_han_dirigido,
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT p.id_participacion) DESC) AS ranking_popularidad,
    CASE 
        WHEN COUNT(DISTINCT r.id_recorrido) = 0 THEN 'Sin recorridos'
        WHEN COUNT(DISTINCT r.id_recorrido) <= 3 THEN 'Volumen bajo'
        WHEN COUNT(DISTINCT r.id_recorrido) <= 10 THEN 'Volumen medio'
        ELSE 'Volumen alto'
    END AS volumen_de_recorridos,
    (SELECT COUNT(*) 
     FROM recorridos r2 
     INNER JOIN participaciones p2 ON r2.id_recorrido = p2.id_recorrido
     WHERE r2.id_ruta_turistica = rt.id_ruta_turistica 
     AND r2.fecha_de_realizacion >= DATEADD(DAY, -30, GETDATE())
    ) AS participantes_ultimos_30_dias
FROM rutas_turisticas rt
LEFT JOIN recorridos r ON rt.id_ruta_turistica = r.id_ruta_turistica
LEFT JOIN participaciones p ON r.id_recorrido = p.id_recorrido
LEFT JOIN guias_de_los_recorridos gr ON r.id_recorrido = gr.id_recorrido
WHERE rt.activo = 1
GROUP BY rt.id_ruta_turistica, rt.nombre;
GO

-- 13. Cantidad de bicicletas que hay segun su marca y su tipo(eléctrica, convencional)
CREATE OR ALTER VIEW cantidad_bicicletas_por_marca_y_tipo AS
WITH base AS (
    SELECT 
        m.nombre AS marca,
        CASE WHEN b.es_electrica = 1 THEN 'Eléctrica' ELSE 'Convencional' END AS tipo
    FROM bicicletas b
    JOIN marcas m ON b.id_marca = m.id_marca
    WHERE b.activo = 1
)
SELECT 
    marca,
    ISNULL([Eléctrica],0) AS total_electricas,
    ISNULL([Convencional],0) AS total_convencionales,
    ISNULL([Eléctrica],0) + ISNULL([Convencional],0) AS total_bicicletas
FROM base
PIVOT (
    COUNT(tipo)
    FOR tipo IN ([Eléctrica], [Convencional])
) AS pvt; 
GO

-- 14. Detalles génerales sobre las bicicletas
CREATE OR ALTER VIEW bicicletas_detalle_general AS
SELECT 
    b.id_bicicleta,
    b.modelo,
    m.nombre AS marca,
    t.nombre AS tipo_uso,
    p.nombre AS punto_alquiler,
    c.nombre AS ciudad_ubicacion,
    CASE 
        WHEN b.es_electrica = 1 THEN 'Eléctrica'
        ELSE 'Convencional'
    END AS tipo_bicicleta,
    b.anio_de_fabricacion AS año_fabricacion,
    b.tarifa_base_de_alquiler,
    b.kilometraje_km,
    b.horas_de_uso,
    efb.nombre AS estado_fisico
FROM bicicletas b
JOIN marcas m ON b.id_marca = m.id_marca
JOIN tipos_de_uso t ON b.id_tipo_de_uso = t.id_tipo_de_uso
JOIN puntos_de_alquiler p ON b.id_punto_de_alquiler = p.id_punto_alquiler
JOIN ciudades c ON p.id_ciudad = c.id_ciudad
JOIN estados_fisicos_tomados_por_las_bicicletas eftb ON eftb.id_bicicleta = b.id_bicicleta
JOIN estados_fisicos_de_las_bicicletas efb ON efb.id_estado_fisico_de_la_bicicleta = eftb.id_estado_fisico_bicicleta 
WHERE b.activo = 1 AND eftb.fecha_fin_del_estado IS NULL;
GO

-- 15. Informacion sobre los alquileres en cada mes en el que se realizaron alquileres
CREATE OR ALTER VIEW informacion_alquileres_mes AS
SELECT 
    FORMAT(fecha_de_inicio_de_vigencia, 'yyyy') AS año,
    FORMAT(fecha_de_inicio_de_vigencia, 'MMMM', 'es-ES') AS mes,
    COUNT(*) AS total_alquileres,
    SUM(tarifa_total) AS total_ingresos,
    ROUND(AVG(tarifa_total),2) AS promedio_tarifa
FROM alquileres
GROUP BY 
    FORMAT(fecha_de_inicio_de_vigencia, 'yyyy'),
    FORMAT(fecha_de_inicio_de_vigencia, 'MMMM', 'es-ES')
GO

-- 16. Ingresos por punto de alquiler
CREATE OR ALTER VIEW ingresos_por_punto_alquiler AS
SELECT 
    p.id_punto_alquiler,
    p.nombre AS punto_alquiler,
    c.nombre AS ciudad,
    COUNT(a.id_alquiler) AS total_alquileres,
    ISNULL(SUM(a.tarifa_total),0) AS ingresos_totales,
    ISNULL(ROUND(AVG(a.tarifa_total),2),0) AS ingreso_promedio
FROM puntos_de_alquiler p
LEFT JOIN bicicletas b ON p.id_punto_alquiler = b.id_punto_de_alquiler
LEFT JOIN alquileres a ON b.id_bicicleta = a.id_bicicleta
JOIN ciudades c ON p.id_ciudad = c.id_ciudad
WHERE p.activo = 1
GROUP BY p.id_punto_alquiler, p.nombre, c.nombre;
GO

-- 17. Promedios de kilometraje segun marca
CREATE OR ALTER VIEW promedio_kilometraje_marca AS
SELECT 
    m.nombre AS marca,
    ROUND(AVG(ISNULL(b.kilometraje_km,0)),2) AS promedio_km,
    COUNT(b.id_bicicleta) AS total_bicicletas,
    CASE 
        WHEN AVG(ISNULL(b.kilometraje_km,0)) < 1000 THEN 'Promedio bajo de uso'
        WHEN AVG(ISNULL(b.kilometraje_km,0)) BETWEEN 1000 AND 5000 THEN 'Promedio moderado de uso'
        ELSE 'Promedio alto de uso'
    END AS clasificacion_uso
FROM bicicletas b
JOIN marcas m ON b.id_marca = m.id_marca
GROUP BY m.nombre
HAVING COUNT(b.id_bicicleta) > 0;
GO

-- 18. Mantenimiento según las condiciones de las bicicletas
CREATE OR ALTER VIEW mantenimiento_segun_condiciones_bicicleta AS
SELECT
    b.id_bicicleta,
    b.modelo,
    b.numero_de_cuadro,
    efb.nombre AS estado_fisico,
    CASE
        WHEN LOWER(efb.nombre) LIKE 'excelente' OR LOWER(efb.nombre) LIKE 'nueva' OR LOWER(efb.nombre) LIKE 'descontinuada' THEN 'No requiere mantenimiento'
        WHEN LOWER(efb.nombre) LIKE 'bueno' THEN 'Prioridad baja'
        WHEN LOWER(efb.nombre) LIKE 'regular' THEN 'Prioridad media'
        WHEN LOWER(efb.nombre) LIKE 'dañada' THEN 'Prioridad alta'
        WHEN LOWER(efb.nombre) LIKE 'fuera de servicio' THEN 'Prioridad critica'
    END AS prioridad_mantenimiento
FROM bicicletas b
JOIN estados_fisicos_tomados_por_las_bicicletas eftb ON eftb.id_bicicleta = b.id_bicicleta
JOIN estados_fisicos_de_las_bicicletas efb ON efb.id_estado_fisico_de_la_bicicleta = eftb.id_estado_fisico_bicicleta
WHERE eftb.fecha_fin_del_estado IS NULL AND b.activo = 1
GO

-- 19. Estado de disponibilidad actual de las bicicletas
CREATE OR ALTER VIEW bicicletas_disponibilidad_actual AS
WITH UltimoEstado AS (
    SELECT 
        id_bicicleta,
        id_estado_de_disponibilidad_de_la_bicicleta,
        ROW_NUMBER() OVER (PARTITION BY id_bicicleta ORDER BY fecha_inicio_del_estado DESC) AS rn
    FROM disponibilidades_tomadas_por_las_bicicletas
)
SELECT 
    b.id_bicicleta,
    b.modelo,
    e.nombre AS estado_disponibilidad
FROM UltimoEstado ue
JOIN bicicletas b ON ue.id_bicicleta = b.id_bicicleta
JOIN estados_de_disponibilidad_de_las_bicicletas e 
     ON ue.id_estado_de_disponibilidad_de_la_bicicleta = e.id_estado_de_disponibilidad_de_la_bicicleta
WHERE ue.rn = 1 AND b.activo = 1;
GO

-- 20. Estado de disponibilidad actual de los guías
CREATE OR ALTER VIEW guias_disponibilidad_actual AS
WITH EstadoActual AS (
    SELECT 
        id_guia,
        id_estado_de_disponibilidad_del_guia,
        ROW_NUMBER() OVER (PARTITION BY id_guia ORDER BY fecha_inicio_del_estado DESC) AS rn
    FROM disponibilidades_tomadas_por_los_guias
)
SELECT 
    g.id_persona AS id_guia,
    p.primer_nombre + ' ' + p.primer_apellido AS nombre_guia,
    ISNULL(edg.nombre, 'Sin estado registrado') AS estado_actual
FROM guias g
JOIN personas p ON g.id_persona = p.id_persona
LEFT JOIN EstadoActual ea ON g.id_persona = ea.id_guia AND ea.rn = 1
LEFT JOIN estados_de_disponibilidad_de_los_guias edg 
    ON ea.id_estado_de_disponibilidad_del_guia = edg.id_estado_de_disponibilidad_del_guia
WHERE g.activo = 1;
GO

-- 21. Información detallada sobre los alquileres
CREATE OR ALTER VIEW informacion_alquileres_detallados AS
SELECT 
    a.id_alquiler,
    p.id_persona AS id_usuario,
    p.primer_nombre + ' ' + p.primer_apellido AS nombre_usuario,
    b.modelo AS bicicleta,
    pl.tipo_de_plan AS [plan],
    a.fecha_de_inicio_de_vigencia,
    a.fecha_de_fin_de_vigencia,
    a.tarifa_total,
    mp.nombre AS metodo_de_pago,
    DATEDIFF(HOUR, a.fecha_de_inicio_de_vigencia, a.fecha_de_fin_de_vigencia) AS duracion_horas,
    CASE 
        WHEN DATEDIFF(DAY, a.fecha_de_inicio_de_vigencia, a.fecha_de_fin_de_vigencia) = 0 THEN 'Uso de un solo día'
        WHEN DATEDIFF(DAY, a.fecha_de_inicio_de_vigencia, a.fecha_de_fin_de_vigencia) BETWEEN 1 AND 3 THEN 'Alquiler corto'
        ELSE 'Alquiler extendido'
    END AS categoria_duracion
FROM alquileres a
JOIN metodos_de_pago mp ON mp.id_metodo_pago = a.id_metodo_de_pago
JOIN usuarios u   ON a.id_usuario = u.id_persona
JOIN personas p   ON u.id_persona = p.id_persona
JOIN bicicletas b ON a.id_bicicleta = b.id_bicicleta
JOIN planes_de_los_alquileres pl ON a.id_plan = pl.id_plan;
GO

-- 22. Las versiones de las politicas que aceptaron los usuarios
CREATE OR ALTER VIEW politicas_aceptadas_por_usuarios AS
WITH UltimaPolitica AS (
    SELECT MAX(id_politica) AS id_ultima_politica
    FROM politicas
)
SELECT 
    p.id_persona,
    p.primer_nombre + ' ' + p.primer_apellido AS nombre_usuario,
    ISNULL(CONVERT(VARCHAR, po.version_de_los_terminos), 'N/A') AS version_politica,
    CASE 
        WHEN ap.id_politica IS NULL THEN 'No aceptó ninguna política'
        WHEN ap.id_politica = up.id_ultima_politica THEN 'Aceptó la ultima versión (' + CONVERT(VARCHAR, po.version_de_los_terminos) + ')'
        ELSE 'Aceptó una versión anterior (' + CONVERT(VARCHAR, po.version_de_los_terminos) + ')'
    END AS estado_aceptacion
FROM personas p
CROSS JOIN UltimaPolitica up
LEFT JOIN aceptaciones_de_las_politicas ap ON p.id_persona = ap.id_persona
LEFT JOIN politicas po ON ap.id_politica = po.id_politica;
GO
