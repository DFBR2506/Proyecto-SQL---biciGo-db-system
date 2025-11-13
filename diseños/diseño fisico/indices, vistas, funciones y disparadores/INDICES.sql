/* ============================================================
   OPTIMIZACIÓN DE LA BASE DE DATOS BiciGo  
   15 ÍNDICES DISEÑADOS PARA ACELERAR VISTAS Y CONSULTAS
   ============================================================ */

/* ============================================================
   INDEX 1 — Acelera consultas por rangos de fecha en alquileres
   Usado en: Alquileres_Activos, Reportes_Mensuales, comparativos
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_alquileres_fecha_inicio_fin'
      AND object_id = OBJECT_ID('alquileres')
)
CREATE INDEX IX_alquileres_fecha_inicio_fin
ON alquileres (fecha_de_inicio_de_vigencia, fecha_de_fin_de_vigencia);
GO


/* ============================================================
   INDEX 2 — Joins Alquileres ? Bicicletas
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_alquileres_id_bicicleta'
      AND object_id = OBJECT_ID('alquileres')
)
CREATE INDEX IX_alquileres_id_bicicleta
ON alquileres (id_bicicleta);
GO


/* ============================================================
   INDEX 3 — Joins Alquileres ? Usuarios
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_alquileres_id_usuario'
      AND object_id = OBJECT_ID('alquileres')
)
CREATE INDEX IX_alquileres_id_usuario
ON alquileres (id_usuario);
GO


/* ============================================================
   INDEX 4 — Conteo de rentas por bicicleta (Ranking_Bicicletas)
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_alquileres_bicicleta_fecha'
      AND object_id = OBJECT_ID('alquileres')
)
CREATE INDEX IX_alquileres_bicicleta_fecha
ON alquileres (id_bicicleta, fecha_de_inicio_de_vigencia);
GO


/* ============================================================
   INDEX 5 — Mantenimientos filtrados por fecha
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_mantenimientos_fecha_inicio'
      AND object_id = OBJECT_ID('mantenimientos')
)
CREATE INDEX IX_mantenimientos_fecha_inicio
ON mantenimientos (fecha_de_inicio);
GO


/* ============================================================
   INDEX 6 — Mantenimientos abiertos (fecha_fin IS NULL)
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_mantenimientos_abiertos'
      AND object_id = OBJECT_ID('mantenimientos')
)
CREATE INDEX IX_mantenimientos_abiertos
ON mantenimientos (fecha_de_fin)
WHERE fecha_de_fin IS NULL;
GO


/* ============================================================
   INDEX 7 — Joins Bicicletas ? Punto de Alquiler
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_bicicletas_punto_alquiler'
      AND object_id = OBJECT_ID('bicicletas')
)
CREATE INDEX IX_bicicletas_punto_alquiler
ON bicicletas (id_punto_de_alquiler);
GO


/* ============================================================
   INDEX 8 — Joins Bicicletas ? Marca
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_bicicletas_marca'
      AND object_id = OBJECT_ID('bicicletas')
)
CREATE INDEX IX_bicicletas_marca
ON bicicletas (id_marca);
GO


/* ============================================================
   INDEX 9 — Joins Bicicletas ? Tipo de Uso
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_bicicletas_tipo_de_uso'
      AND object_id = OBJECT_ID('bicicletas')
)
CREATE INDEX IX_bicicletas_tipo_de_uso
ON bicicletas (id_tipo_de_uso);
GO


/* ============================================================
   INDEX 10 — Recorridos por Ruta + fecha
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_recorridos_id_ruta'
      AND object_id = OBJECT_ID('recorridos')
)
CREATE INDEX IX_recorridos_id_ruta
ON recorridos (id_ruta_turistica, fecha_de_realizacion);
GO


/* ============================================================
   INDEX 11 — Participaciones por Recorrido
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_participaciones_id_recorrido'
      AND object_id = OBJECT_ID('participaciones')
)
CREATE INDEX IX_participaciones_id_recorrido
ON participaciones (id_recorrido);
GO


/* ============================================================
   INDEX 12 — Participaciones por Usuario
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_participaciones_id_usuario'
      AND object_id = OBJECT_ID('participaciones')
)
CREATE INDEX IX_participaciones_id_usuario
ON participaciones (id_usuario);
GO


/* ============================================================
   INDEX 13 — Último estado de bicicleta (ROW_NUMBER)
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_disponibilidad_bicicleta_fecha'
      AND object_id = OBJECT_ID('disponibilidades_tomadas_por_las_bicicletas')
)
CREATE INDEX IX_disponibilidad_bicicleta_fecha
ON disponibilidades_tomadas_por_las_bicicletas (id_bicicleta, fecha_inicio_del_estado DESC);
GO


/* ============================================================
   INDEX 14 — Último estado del guía (ROW_NUMBER)
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_disponibilidad_guia_fecha'
      AND object_id = OBJECT_ID('disponibilidades_tomadas_por_los_guias')
)
CREATE INDEX IX_disponibilidad_guia_fecha
ON disponibilidades_tomadas_por_los_guias (id_guia, fecha_inicio_del_estado DESC);
GO


/* ============================================================
   INDEX 15 — Puntos de interés por ruta (solo activos)
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_puntos_interes_ruta'
      AND object_id = OBJECT_ID('puntos_de_interes_de_las_rutas')
)
CREATE INDEX IX_puntos_interes_ruta
ON puntos_de_interes_de_las_rutas (id_ruta_turistica)
WHERE activo = 1;
GO



/* ============================================================
   MANTENIMIENTO DE ÍNDICES  
   Ejecutar 1 vez por semana o cada 15 días
   ============================================================ */
-- Reorganizar índices fragmentados entre 5% y 30%
SELECT 
    'ALTER INDEX [' + i.name + '] ON [' + s.name + '].[' + t.name + '] REORGANIZE;' AS Reorganizar
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) d
JOIN sys.indexes i       ON d.object_id = i.object_id AND d.index_id = i.index_id
JOIN sys.tables t        ON i.object_id = t.object_id
JOIN sys.schemas s       ON t.schema_id = s.schema_id
WHERE avg_fragmentation_in_percent BETWEEN 5 AND 30
  AND i.index_id > 0;

-- Reconstruir índices con fragmentación mayor a 30%
SELECT 
    'ALTER INDEX [' + i.name + '] ON [' + s.name + '].[' + t.name + '] REBUILD;' AS Reconstruir
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) d
JOIN sys.indexes i       ON d.object_id = i.object_id AND d.index_id = i.index_id
JOIN sys.tables t        ON i.object_id = t.object_id
JOIN sys.schemas s       ON t.schema_id = s.schema_id
WHERE avg_fragmentation_in_percent > 30
  AND i.index_id > 0;
GO
