/* ============================================================
   SECCIÓN A — VISTAS DE AGREGACIÓN Y ANÁLISIS BÁSICO
============================================================ */

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
INNER JOIN usuarios u ON a.id_usuario = u.id_persona
INNER JOIN personas p ON u.id_persona = p.id_persona
INNER JOIN bicicletas b ON a.id_bicicleta = b.id_bicicleta
INNER JOIN marcas m ON b.id_marca = m.id_marca
INNER JOIN planes_de_los_alquileres pdla ON a.id_plan = pdla.id_plan
WHERE CAST(GETDATE() AS DATE) BETWEEN a.fecha_de_inicio_de_vigencia 
      AND a.fecha_de_fin_de_vigencia
      AND u.activo = 1
      AND p.activo = 1
      AND b.activo = 1
      AND pdla.activo = 1;
GO

/* ============================================================
   SECCIÓN B — CTE + AGREGACIÓN AVANZADA
============================================================ */

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
    INNER JOIN usuarios u ON a.id_usuario = u.id_persona
    INNER JOIN bicicletas b ON a.id_bicicleta = b.id_bicicleta
    INNER JOIN planes_de_los_alquileres pl ON a.id_plan = pl.id_plan
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
    WHEN urb.dias_desde_fin_ultimo_alquiler >= 200 THEN 'inactividad CRITICA'
    WHEN urb.dias_desde_fin_ultimo_alquiler >= 150 THEN 'inactividad grave'
    WHEN urb.dias_desde_fin_ultimo_alquiler >= 100 THEN 'inactividad alta'
    WHEN urb.dias_desde_fin_ultimo_alquiler >= 50 THEN 'inactividad moderada'
    WHEN urb.dias_desde_fin_ultimo_alquiler >= 25 THEN 'inactividad baja'
    WHEN urb.dias_desde_fin_ultimo_alquiler >= 0 THEN 'actividad reciente'
    ELSE 'nunca fue alquilada'
END AS estado_actividad
FROM bicicletas b
FULL JOIN ultima_renta_por_bicicleta urb ON urb.id_bicicleta = b.id_bicicleta
JOIN marcas m ON b.id_marca = m.id_marca
WHERE b.activo = 1;
GO

/* ============================================================
   SECCIÓN C — OPERACIONES DE CONJUNTO
============================================================ */

-- 6. info_mantenimiento_bicicletas
CREATE OR ALTER VIEW info_mantenimiento_bicicletas AS
SELECT 
    b.id_bicicleta,
    b.modelo,
    b.numero_de_cuadro,
    m.nombre AS marca,
    pa.nombre AS punto_alquiler,
    COUNT(*) AS mantenimientos_recientes,
    MAX(man.fecha_de_inicio) AS ultimo_mantenimiento
FROM bicicletas b
INNER JOIN marcas m ON b.id_marca = m.id_marca
INNER JOIN puntos_de_alquiler pa ON b.id_punto_de_alquiler = pa.id_punto_alquiler
INNER JOIN mantenimientos man ON b.id_bicicleta = man.id_bicicleta
WHERE b.activo = 1
  AND man.fecha_de_inicio >= DATEADD(DAY, -90, GETDATE())
GROUP BY b.id_bicicleta, b.modelo, b.numero_de_cuadro, m.nombre, pa.nombre
HAVING COUNT(*) > 1
UNION
SELECT 
    b.id_bicicleta,
    b.modelo,
    b.numero_de_cuadro,
    m.nombre AS marca,
    pa.nombre AS punto_alquiler,
    NULL AS mantenimientos_recientes,
    man.fecha_de_inicio AS ultimo_mantenimiento
FROM bicicletas b
INNER JOIN marcas m ON b.id_marca = m.id_marca
INNER JOIN puntos_de_alquiler pa ON b.id_punto_de_alquiler = pa.id_punto_alquiler
INNER JOIN mantenimientos man ON b.id_bicicleta = man.id_bicicleta
WHERE b.activo = 1
  AND man.fecha_de_fin IS NULL;
GO


-- 7. vw_bicicletas_con_o_sin_mantenimiento
CREATE OR ALTER VIEW vw_bicicletas_con_o_sin_mantenimiento AS
SELECT b.id_bicicleta, b.modelo, 'Con mantenimiento' AS estado
FROM bicicletas b
WHERE b.id_bicicleta IN (SELECT id_bicicleta FROM mantenimientos)
UNION
SELECT b.id_bicicleta, b.modelo, 'Sin mantenimiento' AS estado
FROM bicicletas b
EXCEPT
SELECT DISTINCT m.id_bicicleta, b.modelo, 'Sin mantenimiento'
FROM mantenimientos m
JOIN bicicletas b ON m.id_bicicleta = b.id_bicicleta;
GO


-- 8. vw_bicicletas_aseguradas_vs_no_aseguradas
CREATE OR ALTER VIEW vw_bicicletas_aseguradas_vs_no_aseguradas AS
SELECT b.id_bicicleta, b.modelo, 'Asegurada' AS estado
FROM bicicletas b
INTERSECT
SELECT s.id_seguro, b.modelo, 'Asegurada'
FROM seguros s
JOIN bicicletas b ON s.id_seguro = b.id_seguro
UNION
SELECT b.id_bicicleta, b.modelo, 'No asegurada' AS estado
FROM bicicletas b
EXCEPT
SELECT b.id_bicicleta, b.modelo, 'No asegurada'
FROM bicicletas b
JOIN seguros s ON b.id_seguro = s.id_seguro;
GO



/* ============================================================
   SECCIÓN D — FUNCIONES DE VENTANA
============================================================ */

-- 9. Ranking_Bicicletas
CREATE OR ALTER VIEW Ranking_Bicicletas AS
WITH RankingBicicletas AS (
    SELECT 
        FORMAT(a.fecha_de_inicio_de_vigencia, 'yyyy-MM') AS año_mes,
        DATENAME(MONTH, a.fecha_de_inicio_de_vigencia) AS mes,
        b.id_bicicleta,
        b.modelo,
        m.nombre AS marca,
        COUNT(*) AS rentas,
        RANK() OVER (
            PARTITION BY FORMAT(a.fecha_de_inicio_de_vigencia, 'yyyy-MM') 
            ORDER BY COUNT(*) DESC
        ) AS ranking
    FROM alquileres a
    INNER JOIN bicicletas b ON a.id_bicicleta = b.id_bicicleta
    INNER JOIN marcas m ON b.id_marca = m.id_marca
    WHERE b.activo = 1
    GROUP BY 
        FORMAT(a.fecha_de_inicio_de_vigencia, 'yyyy-MM'),
        DATENAME(MONTH, a.fecha_de_inicio_de_vigencia),
        b.id_bicicleta,
        b.modelo,
        m.nombre
)
SELECT 
    año_mes,
    mes,
    id_bicicleta,
    modelo,
    marca,
    rentas,
    ranking
FROM RankingBicicletas
WHERE ranking <= 10;
GO


-- 10. vw_ranking_bicicletas_por_tarifa
CREATE OR ALTER VIEW vw_ranking_bicicletas_por_tarifa AS
SELECT 
    m.nombre AS marca,
    b.modelo,
    b.tarifa_base_de_alquiler,
    DENSE_RANK() OVER (PARTITION BY m.nombre ORDER BY b.tarifa_base_de_alquiler DESC) AS ranking_en_marca
FROM bicicletas b
JOIN marcas m ON b.id_marca = m.id_marca;
GO


-- 11. vw_ranking_guias_por_experiencia
CREATE OR ALTER VIEW vw_ranking_guias_por_experiencia AS
WITH RecorridosPorGuia AS (
    SELECT 
        gr.id_guia,
        COUNT(DISTINCT gr.id_recorrido) AS total_recorridos_dirigidos,
        AVG(DATEDIFF(HOUR, r.hora_de_inicio, r.hora_de_finalizacion)) AS avg_duracion_horas
    FROM guias_de_los_recorridos gr
    INNER JOIN recorridos r ON gr.id_recorrido = r.id_recorrido
    GROUP BY gr.id_guia
)
SELECT 
    g.id_persona,
    p.primer_nombre + ' ' + p.primer_apellido AS nombre_guia,
    g.anios_de_experiencia,
    g.numero_de_tarjeta_profesional,
    ISNULL(rpg.total_recorridos_dirigidos, 0) AS total_recorridos,
    ISNULL(rpg.avg_duracion_horas, 0) AS duracion_promedio_horas,
    RANK() OVER (
        ORDER BY g.anios_de_experiencia DESC,
        ISNULL(rpg.total_recorridos_dirigidos, 0) DESC
    ) AS ranking_experiencia,
    CASE 
        WHEN g.anios_de_experiencia >= 5 
             AND ISNULL(rpg.total_recorridos_dirigidos, 0) >= 10 THEN 'Experto'
        WHEN g.anios_de_experiencia >= 3 
             AND ISNULL(rpg.total_recorridos_dirigidos, 0) >= 5 THEN 'Intermedio'
        ELSE 'Principiante'
    END AS nivel_experiencia
FROM guias g
INNER JOIN personas p ON g.id_persona = p.id_persona
LEFT JOIN RecorridosPorGuia rpg ON g.id_persona = rpg.id_guia
WHERE g.activo = 1;
GO


-- 12. vw_comparativo_tarifas_alquileres
CREATE OR ALTER VIEW vw_comparativo_tarifas_alquileres AS
SELECT 
    id_alquiler,
    id_usuario,
    tarifa_total,
    LAG(tarifa_total, 1)  OVER (PARTITION BY id_usuario ORDER BY fecha_de_inicio_de_vigencia) AS tarifa_anterior,
    LEAD(tarifa_total, 1) OVER (PARTITION BY id_usuario ORDER BY fecha_de_inicio_de_vigencia) AS tarifa_siguiente,
    CASE 
        WHEN LAG(tarifa_total,1) OVER (PARTITION BY id_usuario ORDER BY fecha_de_inicio_de_vigencia) IS NULL THEN 'Primer alquiler'
        WHEN LEAD(tarifa_total,1) OVER (PARTITION BY id_usuario ORDER BY fecha_de_inicio_de_vigencia) IS NULL THEN 'Último alquiler'
        ELSE 'Intermedio'
    END AS posicion_relativa
FROM alquileres;
GO



/* ============================================================
   SECCIÓN E — SUBCONSULTAS AUTÓNOMAS / CORRELACIONADAS
============================================================ */

-- 13. vw_usuarios_actividad_total
CREATE OR ALTER VIEW vw_usuarios_actividad_total AS
SELECT 
    u.id_persona AS id_usuario,
    p.primer_nombre + ' ' + p.primer_apellido AS nombre_completo,
    ISNULL((SELECT COUNT(*) FROM comentarios c WHERE c.id_persona = u.id_persona), 0) AS total_comentarios,
    ISNULL((SELECT COUNT(*) FROM alquileres a WHERE a.id_usuario = u.id_persona), 0) AS total_alquileres,
    ISNULL((SELECT COUNT(*) FROM participaciones pa WHERE pa.id_usuario = u.id_persona), 0) AS total_participaciones
FROM usuarios u
JOIN personas p ON u.id_persona = p.id_persona;
GO



-- 14. rutas_analisis_estadistico
CREATE OR ALTER VIEW rutas_analisis_estadistico AS
SELECT 
    rt.id_ruta_turistica,
    rt.nombre AS nombre_ruta,
    COUNT(DISTINCT r.id_recorrido) AS total_recorridos,
    COUNT(DISTINCT p.id_participacion) AS total_participantes,
    CASE 
        WHEN COUNT(DISTINCT r.id_recorrido) > 0 THEN
            CAST(COUNT(DISTINCT p.id_participacion) AS DECIMAL) 
            / CAST(COUNT(DISTINCT r.id_recorrido) AS DECIMAL)
        ELSE 0
    END AS promedio_participantes_por_recorrido,
    (SELECT COUNT(*) 
     FROM puntos_de_interes_de_las_rutas pir
     WHERE pir.id_ruta_turistica = rt.id_ruta_turistica 
       AND pir.activo = 1) AS total_puntos_interes,
    COUNT(DISTINCT gr.id_guia) AS total_guias_que_han_dirigido,
    RANK() OVER (ORDER BY COUNT(DISTINCT p.id_participacion) DESC) AS ranking_popularidad,
    CASE 
        WHEN COUNT(DISTINCT r.id_recorrido) = 0 THEN 'Sin actividad'
        WHEN COUNT(DISTINCT r.id_recorrido) <= 3 THEN 'Baja actividad'
        WHEN COUNT(DISTINCT r.id_recorrido) <= 10 THEN 'Media actividad'
        ELSE 'Alta actividad'
    END AS nivel_actividad,
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



/* ============================================================
   SECCIÓN F — PIVOT
============================================================ */

-- 15. vw_pivot_bicicletas_por_marca_y_tipo
CREATE OR ALTER VIEW vw_pivot_bicicletas_por_marca_y_tipo AS
WITH base AS (
    SELECT 
        m.nombre AS marca,
        CASE WHEN b.es_electrica = 1 THEN 'Eléctrica' ELSE 'Convencional' END AS tipo
    FROM bicicletas b
    JOIN marcas m ON b.id_marca = m.id_marca
)
SELECT 
    marca,
    ISNULL([Eléctrica],0) AS total_electricas,
    ISNULL([Convencional],0) AS total_convencionales
FROM base
PIVOT (
    COUNT(tipo)
    FOR tipo IN ([Eléctrica], [Convencional])
) AS pvt;
GO



/* ============================================================
   SECCIÓN G — VISTAS PRINCIPALES DEL BLOQUE ORIGINAL
============================================================ */

-- 16. vw_bicicletas_detalle_general
CREATE OR ALTER VIEW vw_bicicletas_detalle_general AS
SELECT 
    b.id_bicicleta,
    b.modelo,
    m.nombre AS marca,
    t.nombre AS tipo_uso,
    p.nombre AS punto_alquiler,
    c.nombre AS ciudad,
    CASE 
        WHEN b.es_electrica = 1 THEN 'Eléctrica'
        ELSE 'Convencional'
    END AS tipo_bicicleta,
    YEAR(b.anio_de_fabricacion) AS anio_fabricacion,
    ROUND(b.tarifa_base_de_alquiler,2) AS tarifa,
    b.kilometraje_km,
    b.horas_de_uso,
    CASE 
        WHEN b.kilometraje_km > 5000 THEN 'CRÍTICO'
        WHEN b.kilometraje_km > 3000 THEN 'ALTO'
        WHEN b.kilometraje_km > 1000 THEN 'MEDIO'
        ELSE 'BAJO'
    END AS prioridad_mantenimiento
FROM bicicletas b
JOIN marcas m ON b.id_marca = m.id_marca
JOIN tipos_de_uso t ON b.id_tipo_de_uso = t.id_tipo_de_uso
JOIN puntos_de_alquiler p ON b.id_punto_de_alquiler = p.id_punto_alquiler
JOIN ciudades c ON p.id_ciudad = c.id_ciudad
WHERE b.activo = 1;
GO


-- 17. vw_alquileres_mes
CREATE OR ALTER VIEW vw_alquileres_mes AS
SELECT 
    DATEPART(YEAR , fecha_de_inicio_de_vigencia) AS anio,
    DATEPART(MONTH, fecha_de_inicio_de_vigencia) AS mes,
    COUNT(*) AS total_alquileres,
    SUM(tarifa_total) AS total_ingresos,
    ROUND(AVG(tarifa_total),2) AS promedio_tarifa
FROM alquileres
GROUP BY 
    DATEPART(YEAR , fecha_de_inicio_de_vigencia),
    DATEPART(MONTH, fecha_de_inicio_de_vigencia)
HAVING SUM(tarifa_total) > 0;
GO


-- 18. vw_ingresos_por_punto_alquiler
CREATE OR ALTER VIEW vw_ingresos_por_punto_alquiler AS
SELECT 
    p.id_punto_alquiler,
    p.nombre AS punto_alquiler,
    c.nombre AS ciudad,
    COUNT(a.id_alquiler) AS total_alquileres,
    SUM(a.tarifa_total) AS ingresos_totales,
    ROUND(AVG(a.tarifa_total),2) AS ingreso_promedio
FROM puntos_de_alquiler p
JOIN bicicletas b ON p.id_punto_alquiler = b.id_punto_de_alquiler
JOIN alquileres a ON b.id_bicicleta = a.id_bicicleta
JOIN ciudades c ON p.id_ciudad = c.id_ciudad
GROUP BY p.id_punto_alquiler, p.nombre, c.nombre
HAVING SUM(a.tarifa_total) > 0;
GO


-- 19. vw_promedio_kilometraje_marca
CREATE OR ALTER VIEW vw_promedio_kilometraje_marca AS
SELECT 
    m.nombre AS marca,
    ROUND(AVG(ISNULL(b.kilometraje_km,0)),2) AS promedio_km,
    COUNT(b.id_bicicleta) AS total_bicicletas,
    CASE 
        WHEN AVG(ISNULL(b.kilometraje_km,0)) < 1000 THEN 'Bajo uso'
        WHEN AVG(ISNULL(b.kilometraje_km,0)) BETWEEN 1000 AND 5000 THEN 'Uso moderado'
        ELSE 'Alta exigencia'
    END AS clasificacion_uso
FROM bicicletas b
JOIN marcas m ON b.id_marca = m.id_marca
GROUP BY m.nombre
HAVING COUNT(b.id_bicicleta) > 0;
GO


-- 20. vw_bicicletas_condiciones
CREATE OR ALTER VIEW vw_bicicletas_condiciones AS
SELECT 
    b.id_bicicleta,
    b.modelo,
    ce.nombre AS condicion_especial,
    CASE 
        WHEN b.tamano_del_marco_cm < 40 THEN 'Marco pequeño'
        WHEN b.tamano_del_marco_cm BETWEEN 40 AND 60 THEN 'Marco mediano'
        ELSE 'Marco grande'
    END AS categoria_marco,
    CASE 
        WHEN b.es_electrica = 1 THEN 'Eléctrica'
        ELSE 'Convencional'
    END AS tipo_bicicleta
FROM bicicletas b
LEFT JOIN condiciones_de_las_bicicletas cb ON b.id_bicicleta = cb.id_bicicleta
LEFT JOIN condiciones_especiales ce ON cb.id_condicion_especial = ce.id_condicion_especial;
GO


-- 21. vw_bicicletas_estado_actual
CREATE OR ALTER VIEW vw_bicicletas_estado_actual AS
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
WHERE ue.rn = 1;
GO


-- 22. vw_guias_disponibilidad_actual
CREATE OR ALTER VIEW vw_guias_disponibilidad_actual AS
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
    ISNULL(edg.nombre, 'Sin estado registrado') AS estado_actual,
    CASE 
        WHEN g.activo = 1 THEN 'Activo'
        ELSE 'Inactivo'
    END AS estado_guia
FROM guias g
JOIN personas p ON g.id_persona = p.id_persona
LEFT JOIN EstadoActual ea ON g.id_persona = ea.id_guia AND ea.rn = 1
LEFT JOIN estados_de_disponibilidad_de_los_guias edg 
    ON ea.id_estado_de_disponibilidad_del_guia = edg.id_estado_de_disponibilidad_del_guia;
GO



-- 23. vw_usuarios_actividad_total
CREATE OR ALTER VIEW vw_usuarios_actividad_total AS
SELECT 
    u.id_persona AS id_usuario,
    p.primer_nombre + ' ' + p.primer_apellido AS nombre_completo,
    ISNULL((SELECT COUNT(*) FROM comentarios c WHERE c.id_persona = u.id_persona), 0) AS total_comentarios,
    ISNULL((SELECT COUNT(*) FROM alquileres a WHERE a.id_usuario = u.id_persona), 0) AS total_alquileres,
    ISNULL((SELECT COUNT(*) FROM participaciones pa WHERE pa.id_usuario = u.id_persona), 0) AS total_participaciones
FROM usuarios u
JOIN personas p ON u.id_persona = p.id_persona;
GO


-- 24. vw_alquileres_detallados
CREATE OR ALTER VIEW vw_alquileres_detallados AS
SELECT 
    a.id_alquiler,
    p.primer_nombre + ' ' + p.primer_apellido AS usuario,
    b.modelo AS bicicleta,
    pl.tipo_de_plan AS [plan],
    a.tarifa_total,
    DATEDIFF(DAY, a.fecha_de_inicio_de_vigencia, a.fecha_de_fin_de_vigencia) AS duracion_dias,
    CASE 
        WHEN DATEDIFF(DAY, a.fecha_de_inicio_de_vigencia, a.fecha_de_fin_de_vigencia) = 0 THEN 'Uso de un solo día'
        WHEN DATEDIFF(DAY, a.fecha_de_inicio_de_vigencia, a.fecha_de_fin_de_vigencia) BETWEEN 1 AND 3 THEN 'Alquiler corto'
        ELSE 'Alquiler extendido'
    END AS categoria_duracion
FROM alquileres a
JOIN usuarios u   ON a.id_usuario = u.id_persona
JOIN personas p   ON u.id_persona = p.id_persona
JOIN bicicletas b ON a.id_bicicleta = b.id_bicicleta
JOIN planes_de_los_alquileres pl ON a.id_plan = pl.id_plan;
GO

SELECT * FROM vw_alquileres_detallados


-- 25. vw_usuarios_version_politica
CREATE OR ALTER VIEW vw_usuarios_version_politica AS
SELECT 
    p.id_persona,
    p.primer_nombre + ' ' + p.primer_apellido AS nombre_usuario,
    ISNULL(CONVERT(VARCHAR, po.version_de_los_terminos), 'N/A') AS version_politica,
    CASE 
        WHEN ap.id_politica IS NULL THEN 'No aceptó ninguna política'
        ELSE 'Aceptó la versión ' + CONVERT(VARCHAR, po.version_de_los_terminos)
    END AS estado_aceptacion
FROM personas p
LEFT JOIN aceptaciones_de_las_politicas ap ON p.id_persona = ap.id_persona
LEFT JOIN politicas po ON ap.id_politica = po.id_politica;
GO


-- 26. vw_usuarios_con_recorridos_y_participaciones
CREATE OR ALTER VIEW vw_usuarios_con_recorridos_y_participaciones AS
SELECT DISTINCT 
    p.id_persona,
    p.primer_nombre + ' ' + p.primer_apellido AS nombre_usuario,
    'Participó en recorridos' AS tipo_actividad
FROM participaciones pa
JOIN usuarios u ON pa.id_usuario = u.id_persona
JOIN personas p ON u.id_persona = p.id_persona
UNION
SELECT DISTINCT 
    p.id_persona,
    p.primer_nombre + ' ' + p.primer_apellido,
    'Guió recorridos' AS tipo_actividad
FROM guias_de_los_recorridos gr
JOIN guias g ON gr.id_guia = g.id_persona
JOIN personas p ON g.id_persona = p.id_persona;
GO



-- 27. vw_rutas_participadas_no_guiadas
CREATE OR ALTER VIEW vw_rutas_participadas_no_guiadas AS
SELECT DISTINCT r.id_ruta_turistica, rt.nombre AS ruta
FROM recorridos r
JOIN participaciones pa ON pa.id_recorrido = r.id_recorrido
JOIN rutas_turisticas rt ON rt.id_ruta_turistica = r.id_ruta_turistica
EXCEPT
SELECT DISTINCT r.id_ruta_turistica, rt.nombre
FROM recorridos r
JOIN guias_de_los_recorridos gr ON r.id_recorrido = gr.id_recorrido
JOIN rutas_turisticas rt ON rt.id_ruta_turistica = r.id_ruta_turistica;
GO


-- 28. vw_promedio_tarifas_por_mes
CREATE OR ALTER VIEW vw_promedio_tarifas_por_mes AS
WITH tarifas AS (
    SELECT 
        DATEPART(YEAR , fecha_de_inicio_de_vigencia) AS anio,
        DATEPART(MONTH, fecha_de_inicio_de_vigencia) AS mes,
        tarifa_total
    FROM alquileres
)
SELECT 
    anio,
    mes,
    ROUND(AVG(tarifa_total) OVER (PARTITION BY anio ORDER BY mes),2) AS promedio_mensual,
    ROUND(SUM(tarifa_total) OVER (PARTITION BY anio ORDER BY mes),2) AS acumulado_anual
FROM tarifas;
GO
