-- ========================
-- SECCI N: UBICACIONES
-- ========================
CREATE TABLE departamentos (
    id_departamento INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL UNIQUE,
    CONSTRAINT CHK_departamentos_nombre CHECK (TRIM(nombre) <> '')
);

CREATE TABLE ciudades (
    id_ciudad INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    id_departamento INT NOT NULL,
    CONSTRAINT FK_ciudades_departamento FOREIGN KEY (id_departamento)
        REFERENCES departamentos(id_departamento)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT CHK_ciudades_nombre CHECK (TRIM(nombre) <> '')
);

-- ========================
-- SECCI N: CAT LOGOS B SICOS (tipos, accesorios, estados)
-- ========================
CREATE TABLE tipos_de_uso (
    id_tipo_de_uso INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(30) UNIQUE NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    CONSTRAINT CHK_tipos_de_uso_nombre CHECK (TRIM(nombre) <> ''),
    CONSTRAINT CHK_tipos_de_uso_descripcion CHECK (TRIM(descripcion) <> '')
);

CREATE TABLE accesorios (
    id_accesorio INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    funcion VARCHAR(300) NULL,
    CONSTRAINT CHK_accesorios_nombre CHECK (TRIM(nombre) <> ''),
    CONSTRAINT CHK_accesorios_funcion CHECK (funcion IS NULL OR TRIM(funcion) <> '')
);

CREATE TABLE estados_fisicos_de_las_bicicletas (
    id_estado_fisico_de_la_bicicleta INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(300) NULL,
    CONSTRAINT CHK_estados_mantenimiento_nombre CHECK (TRIM(nombre) <> ''),
    CONSTRAINT CHK_estados_mantenimiento_descripcion CHECK (descripcion IS NULL OR TRIM(descripcion) <> '')
);

 

-- ========================
-- SECCI N: MANTENIMIENTO, MARCAS, SEGUROS
-- ========================

CREATE TABLE marcas (
    id_marca INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL UNIQUE,
    eslogan VARCHAR(300) NULL,
    CONSTRAINT CHK_marcas_nombre CHECK (TRIM(nombre) <> ''),
    CONSTRAINT CHK_marcas_eslogan CHECK (eslogan IS NULL OR TRIM(eslogan) <> '')
);

CREATE TABLE empresas_de_seguros (
    id_empresa_de_seguros INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL UNIQUE,
    eslogan VARCHAR(300) NULL,
    CONSTRAINT CHK_empresa_seguros_nombre CHECK (TRIM(nombre) <> ''),
    CONSTRAINT CHK_empresa_seguros_eslogan CHECK (eslogan IS NULL OR TRIM(eslogan) <> '')
);

CREATE TABLE seguros (
    id_seguro INT IDENTITY(1,1) PRIMARY KEY,
    tarifa_base DECIMAL(10,2) NOT NULL,
    cobertura VARCHAR(300) NOT NULL,
    maximo_valor_asegurable DECIMAL(12,2) NOT NULL,
    id_empresa_de_seguros INT NOT NULL,
    CONSTRAINT FK_seguros_empresa FOREIGN KEY (id_empresa_de_seguros)
        REFERENCES empresas_de_seguros(id_empresa_de_seguros)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT CHK_seguros_tarifa CHECK (tarifa_base > 0),
    CONSTRAINT CHK_seguros_cobertura CHECK (TRIM(cobertura) <> ''),
    CONSTRAINT CHK_seguros_valormax CHECK (maximo_valor_asegurable > 0)
);

-- ========================
-- SECCI N: CONDICIONES ESPECIALES
-- ========================
CREATE TABLE condiciones_especiales (
    id_condicion_especial INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(60) UNIQUE NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    CONSTRAINT CHK_condiciones_especiales_nombre CHECK (TRIM(nombre) <> ''),
    CONSTRAINT CHK_condiciones_especiales_descripcion CHECK (TRIM(descripcion) <> '')
);

-- ========================
-- SECCI N: HORARIOS Y PUNTOS DE ALQUILER
-- ========================
CREATE TABLE dias (
    id_dia INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(20) NOT NULL,
    CONSTRAINT CHK_dias_nombre CHECK (LOWER(nombre) IN ('lunes','martes','miercoles','jueves','viernes','sabado','domingo'))
);

CREATE TABLE horarios (
    id_horario INT IDENTITY(1,1) PRIMARY KEY,
    descripcion VARCHAR(200) NULL
);

CREATE TABLE dias_de_los_horarios (
    id_dias_de_los_horarios INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    id_dia INT NOT NULL,
    id_horario INT NOT NULL,
    hora_de_apertura TIME NOT NULL,
    hora_de_cierre TIME NOT NULL,
    CONSTRAINT FK_dias_horarios_horario FOREIGN KEY (id_horario)
        REFERENCES horarios(id_horario)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT FK_dias_horarios_dia FOREIGN KEY (id_dia)
        REFERENCES dias(id_dia)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT CHK_dias_horarios_horas CHECK (hora_de_apertura < hora_de_cierre)
);

CREATE TABLE puntos_de_alquiler (
    id_punto_alquiler INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    id_ciudad INT NOT NULL,
    direccion VARCHAR(300) NOT NULL,
    longitud DECIMAL(12,8) NULL,
    latitud DECIMAL(12,8) NULL,
    id_horario INT NOT NULL,
    activo BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_puntos_alquiler_ciudad FOREIGN KEY (id_ciudad)
        REFERENCES ciudades(id_ciudad)
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT FK_puntos_alquiler_horario FOREIGN KEY (id_horario)
        REFERENCES horarios(id_horario)
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT CHK_puntos_alquiler_nombre CHECK (LTRIM(RTRIM(nombre)) <> ''),
    CONSTRAINT CHK_puntos_alquiler_direccion CHECK (LTRIM(RTRIM(direccion)) <> ''),
    CONSTRAINT CHK_puntos_alquiler_longitud CHECK (longitud IS NULL OR (longitud BETWEEN -180 AND 180)),
    CONSTRAINT CHK_puntos_alquiler_latitud CHECK (latitud IS NULL OR (latitud BETWEEN -90 AND 90))
);


-- ========================
-- SECCI N: ESTADOS Y BICICLETAS (entidad principal)
-- ========================
CREATE TABLE estados_de_disponibilidad_de_las_bicicletas (
    id_estado_de_disponibilidad_de_la_bicicleta INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(300) NULL,
    CONSTRAINT CHK_estados_disponibilidad_nombre CHECK (TRIM(nombre) <> '')
);

CREATE TABLE bicicletas (
    id_bicicleta INT IDENTITY(1,1) PRIMARY KEY,
    modelo VARCHAR(150) NOT NULL,
    numero_de_cuadro VARCHAR(100) NOT NULL UNIQUE,
    horas_de_uso INT NULL,
    anio_de_fabricacion INT NOT NULL,
    tarifa_base_de_alquiler DECIMAL(12,2) NOT NULL,
    etiquetas_adicionales VARCHAR(1000) NULL,
    tamano_del_marco_cm DECIMAL(6,2) NOT NULL,
    tamano_del_marco_in DECIMAL(6,2) NULL,
    es_electrica BIT NOT NULL DEFAULT 0,
    id_tipo_de_uso INT NOT NULL,
    id_punto_de_alquiler INT NOT NULL,
    kilometraje_km INT NULL,
    kilometraje_mi INT NULL,
    id_seguro INT NOT NULL,
    id_marca INT NOT NULL,
    activo BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_bicicletas_tipo_de_uso FOREIGN KEY (id_tipo_de_uso)
        REFERENCES tipos_de_uso(id_tipo_de_uso)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT FK_bicicletas_punto_alquiler FOREIGN KEY (id_punto_de_alquiler)
        REFERENCES puntos_de_alquiler(id_punto_alquiler)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT FK_bicicletas_seguro FOREIGN KEY (id_seguro)
        REFERENCES seguros(id_seguro)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT FK_bicicletas_marca FOREIGN KEY (id_marca)
        REFERENCES marcas(id_marca)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT CHK_bicicletas_modelo CHECK (LTRIM(RTRIM(modelo)) <> ''),
    CONSTRAINT CHK_bicicletas_numero_de_cuadro CHECK (LTRIM(RTRIM(numero_de_cuadro)) <> ''),
    CONSTRAINT CHK_bicicletas_anio_de_fabricacion CHECK (anio_de_fabricacion BETWEEN 1900 AND DATEPART(year, GETDATE())),
    CONSTRAINT CHK_bicicletas_tarifa CHECK (tarifa_base_de_alquiler > 0),
    CONSTRAINT CHK_bicicletas_tamano_cm CHECK (tamano_del_marco_cm BETWEEN 30 AND 80),
    CONSTRAINT CHK_bicicletas_tamano_in CHECK (tamano_del_marco_in IS NULL OR tamano_del_marco_in BETWEEN 12 AND 32),
    CONSTRAINT CHK_bicicletas_horas_de_uso CHECK (horas_de_uso IS NULL OR horas_de_uso >= 0),
    CONSTRAINT CHK_bicicletas_kilometraje_km CHECK (kilometraje_km IS NULL OR kilometraje_km >= 0),
    CONSTRAINT CHK_bicicletas_kilometraje_mi CHECK (kilometraje_mi IS NULL OR kilometraje_mi >= 0)
);

CREATE TABLE disponibilidades_tomadas_por_las_bicicletas (
    id_disponibilidad_de_la_bicicleta INT IDENTITY (1,1) PRIMARY KEY,
    id_estado_de_disponibilidad_de_la_bicicleta INT NOT NULL,
    id_bicicleta INT NOT NULL,
    fecha_inicio_del_estado DATE NOT NULL DEFAULT GETDATE(),
    fecha_fin_del_estado DATE NULL,
     CONSTRAINT FK_fk1b1 FOREIGN KEY (id_bicicleta)
        REFERENCES bicicletas(id_bicicleta)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
     CONSTRAINT FK_fk2b2 FOREIGN KEY (id_estado_de_disponibilidad_de_la_bicicleta)
        REFERENCES estados_de_disponibilidad_de_las_bicicletas(id_estado_de_disponibilidad_de_la_bicicleta)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

     CONSTRAINT CHK_CHECK1DB  CHECK (
    fecha_fin_del_estado IS NULL 
    OR fecha_fin_del_estado > fecha_inicio_del_estado)
);

CREATE TABLE estados_fisicos_tomados_por_las_bicicletas (
    id_estado_fisico_tomado_por_la_bicicleta INT IDENTITY (1,1) PRIMARY KEY,
    id_estado_fisico_bicicleta INT NOT NULL,
    id_bicicleta INT NOT NULL,
    fecha_inicio_del_estado DATE NOT NULL DEFAULT GETDATE(),
       fecha_fin_del_estado DATE NULL,
     CONSTRAINT FK_fk1bb FOREIGN KEY (id_bicicleta)
        REFERENCES bicicletas(id_bicicleta)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
     CONSTRAINT FK_fk2bb FOREIGN KEY (id_estado_fisico_bicicleta)
        REFERENCES estados_fisicos_de_las_bicicletas(id_estado_fisico_de_la_bicicleta)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
     CONSTRAINT CHK_CHECK1FB  CHECK (
    fecha_fin_del_estado IS NULL 
    OR fecha_fin_del_estado > fecha_inicio_del_estado)
);

-- ====== (1) PK compuesta -> PK propia + UNIQUE
CREATE TABLE accesorios_de_la_bicicleta (
    id_accesorio_de_la_bicicleta INT IDENTITY(1,1) PRIMARY KEY,
    id_bicicleta INT NOT NULL,
    id_accesorio INT NOT NULL,
    CONSTRAINT UQ_accesorios_de_la_bicicleta UNIQUE (id_bicicleta, id_accesorio),
    CONSTRAINT FK_accesorios_bicicleta_bicicleta FOREIGN KEY (id_bicicleta)
        REFERENCES bicicletas(id_bicicleta)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT FK_accesorios_bicicleta_accesorio FOREIGN KEY (id_accesorio)
        REFERENCES accesorios(id_accesorio)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

-- ====== (2) PK compuesta -> PK propia + UNIQUE
CREATE TABLE condiciones_de_las_bicicletas (
    id_condicion_de_la_bicicleta INT IDENTITY(1,1) PRIMARY KEY,
    id_bicicleta INT NOT NULL,
    id_condicion_especial INT NOT NULL,
    CONSTRAINT UQ_condiciones_de_las_bicicletas UNIQUE (id_bicicleta, id_condicion_especial),
    CONSTRAINT FK_condiciones_bicicleta_bicicleta FOREIGN KEY (id_bicicleta)
        REFERENCES bicicletas(id_bicicleta)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT FK_condiciones_bicicleta_condicion FOREIGN KEY (id_condicion_especial)
        REFERENCES condiciones_especiales(id_condicion_especial)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

-- ========================
-- SECCI N: MANTENIMIENTO
-- ========================

CREATE TABLE tipos_de_mantenimiento (
    id_tipo_de_mantenimiento INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(300) NULL,
    CONSTRAINT CHK_tipos_mantenimiento_nombre CHECK (TRIM(nombre) <> ''),
    CONSTRAINT CHK_tipos_mantenimiento_desc CHECK (descripcion IS NULL OR TRIM(descripcion) <> '')
);

CREATE TABLE mantenimientos (
    id_mantenimiento INT IDENTITY(1,1) PRIMARY KEY,
    descripcion VARCHAR(255) NOT NULL,
    fecha_de_inicio DATE NOT NULL,
    fecha_de_fin DATE NULL,
    id_tipo_de_mantenimiento INT NOT NULL,
    id_bicicleta INT NOT NULL,

    CONSTRAINT FK_Mantenimientos_TipoMantenimiento FOREIGN KEY (id_tipo_de_mantenimiento)
        REFERENCES tipos_de_mantenimiento (id_tipo_de_mantenimiento)
        ON UPDATE CASCADE
        ON DELETE NO ACTION,

    CONSTRAINT FK_Mantenimientos_Bicicleta FOREIGN KEY (id_bicicleta)
        REFERENCES bicicletas (id_bicicleta)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT chk_fechas_mantenimiento CHECK (fecha_de_fin IS NULL OR fecha_de_inicio <= fecha_de_fin),
    CONSTRAINT chk_descripcion_mantenimiento CHECK (TRIM(descripcion) <> '')
);

-- ========================
-- SECCI N: IDIOMAS, SISTEMAS, PREFERENCIAS
-- ========================
CREATE TABLE idiomas (
    id_idioma INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    codigo_ISO VARCHAR(10) NOT NULL,
    codigo_ISO_639_2 VARCHAR(10) NOT NULL,
    codigo_ISO_639_1 VARCHAR(10) NOT NULL,
    CONSTRAINT CHK_idiomas_nombre CHECK (TRIM(nombre) <> ''),
    CONSTRAINT CHK_idiomas_codigoISO CHECK (TRIM(codigo_ISO) <> '')
);

CREATE TABLE sistemas_de_medicion (
    id_sistema_medicion INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    CONSTRAINT CHK_sistemas_medicion_nombre CHECK (TRIM(nombre) <> '')
);

CREATE TABLE preferencias_de_los_usuarios (
    id_preferencia INT IDENTITY(1,1) PRIMARY KEY,
    id_idioma INT NOT NULL,
    id_sistema_medicion INT NOT NULL,
    CONSTRAINT FK_preferencias_idioma FOREIGN KEY (id_idioma)
        REFERENCES idiomas(id_idioma)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT FK_preferencias_sistema_medicion FOREIGN KEY (id_sistema_medicion)
        REFERENCES sistemas_de_medicion(id_sistema_medicion)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

-- ========================
-- SECCI N: TIPOS DE DOCUMENTO Y DOCUMENTOS DE IDENTIFICACI N
-- ========================
CREATE TABLE tipos_de_documento (
    id_tipo_de_documento INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    acronimo VARCHAR(10) NOT NULL UNIQUE,
    CONSTRAINT CHK_tipos_documento_nombre CHECK (TRIM(nombre) <> ''),
    CONSTRAINT CHK_tipos_documento_acronimo CHECK (TRIM(acronimo) <> '')
);

CREATE TABLE documentos_de_identificacion (
    id_documento_de_identificacion INT IDENTITY(1,1) PRIMARY KEY,
    numero BIGINT NOT NULL UNIQUE,
    id_tipo_de_documento INT NOT NULL,
    id_ciudad_de_expedicion INT  NOT NULL,
    fecha_de_expedicion DATE NOT NULL,
    CONSTRAINT FK_documentos_tipo_documento FOREIGN KEY (id_tipo_de_documento)
        REFERENCES tipos_de_documento(id_tipo_de_documento)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT FK_documentos FOREIGN KEY (id_ciudad_de_expedicion) REFERENCES ciudades(id_ciudad) 
    ON UPDATE CASCADE ON DELETE NO ACTION,
    CONSTRAINT CHK_documentos_fecha CHECK (fecha_de_expedicion <= GETDATE())
);

-- ========================
-- SECCI N: PERSONAS Y POLITICAS
-- ========================

CREATE TABLE personas (
    id_persona INT IDENTITY(1,1) PRIMARY KEY,
    primer_apellido VARCHAR(100) NOT NULL,
    primer_nombre VARCHAR(100) NOT NULL,
    fecha_de_nacimiento DATE NOT NULL,
    email VARCHAR(200) NOT NULL UNIQUE,
    numero_de_telefono VARCHAR(20) NULL UNIQUE,
    id_documento_de_identificacion INT NOT NULL,
    fecha_de_registro DATE NOT NULL DEFAULT GETDATE(),
    activo BIT NOT NULL DEFAULT 1,
    CONSTRAINT chk_nombre CHECK (TRIM(primer_nombre) <> ''),
    CONSTRAINT FK_documentos_tipo_documento_personas FOREIGN KEY (id_documento_de_identificacion)
        REFERENCES documentos_de_identificacion(id_documento_de_identificacion)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT chk_apellido CHECK (TRIM(primer_apellido) <> ''),
    CONSTRAINT chk_email CHECK (CHARINDEX('@', email) > 1 AND LTRIM(RTRIM(email)) <> ''),
    CONSTRAINT chk_fecha_nacimiento CHECK (fecha_de_nacimiento < GETDATE()),
    CONSTRAINT chk_numero_tel CHECK (numero_de_telefono IS NULL OR numero_de_telefono LIKE '[0-9]%')
);


CREATE TABLE roles (
    id_rol INT IDENTITY (1,1) PRIMARY KEY,
    nombre VARCHAR (60) NOT NULL UNIQUE,
);

CREATE TABLE roles_de_las_personas (
    id_rol_persona INT IDENTITY (1,1) PRIMARY KEY,
    id_persona INT NOT NULL,
    id_rol INT NOT NULL,
    CONSTRAINT FK_FK1RR FOREIGN KEY (id_persona) REFERENCES 
    personas(id_persona)
    ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_FK2RR FOREIGN KEY (id_rol) REFERENCES 
    roles(id_rol)
    ON DELETE CASCADE ON UPDATE CASCADE,

);

CREATE TABLE politicas (
    id_politica INT IDENTITY(1,1) PRIMARY KEY,
    version_de_los_terminos INT NOT NULL,
    fecha_de_creacion DATE DEFAULT GETDATE(),
    url_politica VARCHAR UNIQUE,
    CONSTRAINT CHK_politicas_version CHECK (version_de_los_terminos > 0)
);

CREATE TABLE aceptaciones_de_las_politicas (
    id_aceptacion_de_las_politicas INT IDENTITY(1,1) PRIMARY KEY,
    id_persona INT NOT NULL,
    id_politica INT NOT NULL,
    fecha_de_aceptacion DATE NOT NULL,

    CONSTRAINT FK_Aceptacion_Persona FOREIGN KEY (id_persona)
        REFERENCES personas (id_persona)
        ON UPDATE CASCADE 
        ON DELETE CASCADE,

    CONSTRAINT FK_Aceptacion_Politica FOREIGN KEY (id_politica)
        REFERENCES politicas (id_politica)
        ON UPDATE CASCADE 
        ON DELETE NO ACTION,

    CONSTRAINT chk_fecha_aceptacion CHECK (fecha_de_aceptacion <= GETDATE()),

    
    CONSTRAINT uq_persona_politica UNIQUE (id_persona, id_politica)
);

-- ========================
-- SECCI N: USUARIOS Y GUIAS
-- ========================
CREATE TABLE usuarios (
    id_persona INT  PRIMARY KEY,
    contrasena VARBINARY(64) NOT NULL,
    id_preferencia INT NULL,
    id_politica INT NULL,
    activo BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_usuarios_preferencia FOREIGN KEY (id_preferencia)
        REFERENCES preferencias_de_los_usuarios(id_preferencia)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
        CONSTRAINT FK_usuarios_Persona FOREIGN KEY (id_persona)
        REFERENCES personas (id_persona)
        ON UPDATE CASCADE 
        ON DELETE CASCADE,
    CONSTRAINT FK_usuarios_politica FOREIGN KEY (id_politica)
        REFERENCES politicas(id_politica)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

CREATE TABLE estados_de_disponibilidad_de_los_guias (
    id_estado_de_disponibilidad_del_guia INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255),

    CONSTRAINT chk_nombre_estado_guia CHECK (TRIM(nombre) <> '')
);


CREATE TABLE guias (
    id_persona INT PRIMARY KEY,  -- El gu a es una persona (1 a 1 con Personas)
    anios_de_experiencia INT NOT NULL CHECK (anios_de_experiencia >= 0),
    numero_de_tarjeta_profesional INT NOT NULL UNIQUE,
    activo BIT NOT NULL DEFAULT 1,

    CONSTRAINT FK_Guias_Persona FOREIGN KEY (id_persona)
        REFERENCES personas (id_persona)
        ON UPDATE CASCADE 
        ON DELETE CASCADE
);

CREATE TABLE disponibilidades_tomadas_por_los_guias (
    id_disponibilidad_del_guia INT IDENTITY (1,1) PRIMARY KEY,
    id_estado_de_disponibilidad_del_guia INT NOT NULL,
    id_guia INT NOT NULL,
    fecha_inicio_del_estado DATE NOT NULL DEFAULT GETDATE(),
    fecha_fin_del_estado DATE NULL, 
     CONSTRAINT FK_fk1g FOREIGN KEY (id_guia)
        REFERENCES guias(id_persona)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
     CONSTRAINT FK_fk2g FOREIGN KEY (id_estado_de_disponibilidad_del_guia)
        REFERENCES estados_de_disponibilidad_de_los_guias(id_estado_de_disponibilidad_del_guia)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
     CONSTRAINT CHK_CHECKGG  CHECK (
    fecha_fin_del_estado IS NULL 
    OR fecha_fin_del_estado > fecha_inicio_del_estado)
);

-- ==============================================
-- TABLA INTERMEDIA: guias_idiomas
-- Relaciona guias con los idiomas que dominan
-- ==============================================

-- ====== (3) PK compuesta -> PK propia + UNIQUE
CREATE TABLE idiomas_de_los_guias (
    id_idioma_del_guia INT IDENTITY(1,1) PRIMARY KEY,
    id_guia INT NOT NULL,
    id_idioma INT NOT NULL,
    nivel_de_dominio VARCHAR(50) NULL,  -- opcional: 'b sico', 'intermedio', 'avanzado', 'nativo'
    
    CONSTRAINT UQ_guias_idiomas UNIQUE (id_guia, id_idioma),

    CONSTRAINT FK_guias_idiomas_guia FOREIGN KEY (id_guia)
        REFERENCES guias(id_persona)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT FK_guias_idiomas_idioma FOREIGN KEY (id_idioma)
        REFERENCES idiomas(id_idioma)
        ON UPDATE CASCADE
        ON DELETE NO ACTION,

    CONSTRAINT CHK_guias_idiomas_nivel CHECK (
        nivel_de_dominio IS NULL 
        OR LOWER(nivel_de_dominio) IN ('basico', 'intermedio', 'avanzado', 'nativo')
    )
);


-- ========================
-- SECCI N: REPORTES Y ESTADOS
-- ========================
CREATE TABLE estados_de_los_reportes (
    id_estado_del_reporte INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(300) NULL,
    CONSTRAINT CHK_estados_del_reporte_nombre CHECK (TRIM(nombre) <> '')
);

CREATE TABLE reportes (
    id_reporte INT IDENTITY(1,1) PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    descripcion VARCHAR(1000) NULL,
    fecha_de_creacion DATE NOT NULL,
    id_persona INT NOT NULL,
    id_bicicleta INT NOT NULL,
     CONSTRAINT FK_reportes_persona FOREIGN KEY (id_persona)
     REFERENCES personas(id_persona)
     ON UPDATE CASCADE
     ON DELETE NO ACTION,
      CONSTRAINT FK_reportes_bici FOREIGN KEY (id_bicicleta)
     REFERENCES bicicletas(id_bicicleta)
     ON UPDATE CASCADE
     ON DELETE NO ACTION,
    CONSTRAINT CHK_reportes_titulo CHECK (TRIM(titulo) <> ''),
    CONSTRAINT CHK_fechas CHECK (fecha_de_creacion <= GETDATE())
);

CREATE TABLE estados_tomados_por_los_reportes (
    id_estado_tomado_por_el_reporte INT IDENTITY (1,1) PRIMARY KEY,
    id_estado_del_reporte INT NOT NULL,
    id_reporte INT NOT NULL,
    fecha_inicio_del_estado DATE NOT NULL DEFAULT GETDATE(),
       fecha_fin_del_estado DATE NULL,
     CONSTRAINT FK_fk1rp FOREIGN KEY (id_reporte)
        REFERENCES reportes(id_reporte)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
     CONSTRAINT FK_fk2rp FOREIGN KEY (id_estado_del_reporte)
        REFERENCES estados_de_los_reportes(id_estado_del_reporte)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
     CONSTRAINT CHK_CHECK1ER  CHECK (
    fecha_fin_del_estado IS NULL 
    OR fecha_fin_del_estado > fecha_inicio_del_estado)
);

-- ========================
-- SECCI N: METODOS DE PAGO, ALQUILERES Y PLANES
-- ========================

CREATE TABLE metodos_de_pago (
    id_metodo_pago INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    es_transferencia BIT NOT NULL DEFAULT 0,
    activo BIT NOT NULL DEFAULT 1,
    CONSTRAINT CHK_metodos_de_pago_nombre CHECK (TRIM(nombre) <> '')
);

-- ====== (4) PK compuesta -> PK propia + UNIQUE
CREATE TABLE metodos_de_pago_aceptados_por_alquileres (
    id_metodo_de_pago_aceptado_por_alquiler INT IDENTITY(1,1) PRIMARY KEY,
    id_punto_de_alquiler INT NOT NULL,
    id_metodo_de_pago INT NOT NULL,
    CONSTRAINT UQ_metodos_de_pago_aceptados UNIQUE (id_punto_de_alquiler, id_metodo_de_pago),
    CONSTRAINT FK_mpa_punto_alquiler FOREIGN KEY (id_punto_de_alquiler)
        REFERENCES puntos_de_alquiler(id_punto_alquiler)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT FK_mpa_metodo_pago FOREIGN KEY (id_metodo_de_pago)
        REFERENCES metodos_de_pago(id_metodo_pago)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

CREATE TABLE planes_de_los_alquileres (
    id_plan INT IDENTITY(1,1) PRIMARY KEY,
    tipo_de_plan VARCHAR(100) NOT NULL,
    descripcion VARCHAR(500) NULL,
    beneficios_especificos VARCHAR(500) NULL,
    condiciones_especiales VARCHAR(500) NULL,
    tarifa_asociada DECIMAL(10,2) NOT NULL,
    activo BIT NOT NULL DEFAULT 1,
    CONSTRAINT CHK_planes_tipo CHECK (TRIM(tipo_de_plan) <> ''),
    CONSTRAINT CHK_planes_tarifa CHECK (tarifa_asociada >= 0)
);

CREATE TABLE alquileres (
    id_alquiler INT IDENTITY(1,1) PRIMARY KEY,
    fecha_de_inicio_de_vigencia DATE NOT NULL,
    fecha_de_fin_de_vigencia DATE NOT NULL,
    id_plan INT NOT NULL,
    id_usuario INT NOT NULL,
    id_bicicleta INT NOT NULL,
    id_metodo_de_pago INT NOT NULL,
    tarifa_total DECIMAL  (12,2) NOT NULL,
    fecha_de_liquidacion DATE NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_alquileres_plan FOREIGN KEY (id_plan)
        REFERENCES planes_de_los_alquileres(id_plan)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT FK_alquileres_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_persona)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT FK_alquileres_bicicleta FOREIGN KEY (id_bicicleta)
        REFERENCES bicicletas(id_bicicleta)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT FK_alquileres_metodo_pago FOREIGN KEY (id_metodo_de_pago)
        REFERENCES metodos_de_pago(id_metodo_pago)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT CHK_alquileres_fechas CHECK (fecha_de_inicio_de_vigencia < fecha_de_fin_de_vigencia)

);

CREATE TABLE estados_de_los_alquileres (
    id_estado_del_alquiler INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(30) UNIQUE,
    descripcion VARCHAR (100) NULL
);

CREATE TABLE estados_tomados_por_los_alquileres (
    id_estado_tomado_por_el_alquiler INT IDENTITY (1,1),
    id_estado_del_alquiler INT NOT NULL,
    id_alquiler INT NOT NULL,
    fecha_inicio_del_estado DATE NOT NULL DEFAULT GETDATE(),
       fecha_fin_del_estado DATE NULL,
    CONSTRAINT PK_primary_key PRIMARY KEY (id_estado_tomado_por_el_alquiler),
    CONSTRAINT FK_foreign_key_1 FOREIGN KEY (id_estado_del_alquiler) REFERENCES 
    estados_de_los_alquileres (id_estado_del_alquiler)
    ON UPDATE CASCADE
    ON DELETE NO ACTION,
    CONSTRAINT FK_foreign_key_2 FOREIGN KEY (id_alquiler) REFERENCES 
    alquileres (id_alquiler)
    ON UPDATE CASCADE
    ON DELETE NO ACTION,
     CONSTRAINT CHK_CHECK1EA CHECK (
    fecha_fin_del_estado IS NULL 
    OR fecha_fin_del_estado > fecha_inicio_del_estado)
);



-- ========================
-- SECCI N: RUTAS, RECORRIDOS Y PARTICIPACIONES
-- ========================
CREATE TABLE puntos_de_interes (
    id_punto_de_interes INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    longitud DECIMAL(9,6) NOT NULL,
    latitud DECIMAL(9,6) NOT NULL,
    CONSTRAINT CHK_puntos_de_interes_nombre CHECK (TRIM(nombre) <> ''),
    CONSTRAINT CHK_puntos_de_interes_longitud CHECK (longitud BETWEEN -180 AND 180),
    CONSTRAINT CHK_puntos_de_interes_latitud CHECK (latitud BETWEEN -90 AND 90)
);

CREATE TABLE niveles_dificultad (
    id_nivel_dificultad INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(20) NOT NULL,
    descripcion VARCHAR(200) NULL,
    CONSTRAINT CHK_niveles_dificultad_nombre CHECK (LOWER(nombre) IN ('facil','moderado','dificil'))
);
CREATE TABLE rutas_turisticas (
    id_ruta_turistica INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL UNIQUE,
    descripcion VARCHAR(800) NULL,
    distancia_total_mi DECIMAL(8,2) NOT NULL,
     distancia_total_km DECIMAL(8,2) NOT NULL,
    id_nivel_dificultad INT NOT NULL,
    activo BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_rutas_nivel_dificultad FOREIGN KEY (id_nivel_dificultad)
        REFERENCES niveles_dificultad(id_nivel_dificultad)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT CHK_rutas_nombre CHECK (TRIM(nombre) <> ''),
    CONSTRAINT CHK_rutas_distancia CHECK (distancia_total_mi > 0 AND distancia_total_km >0)
);

-- ====== (5) PK compuesta -> PK propia + UNIQUE
CREATE TABLE puntos_de_interes_de_las_rutas (
    id_punto_de_interes_de_la_ruta INT IDENTITY(1,1) PRIMARY KEY,
    id_punto_de_interes INT NOT NULL,
    id_ruta_turistica INT NOT NULL,
    activo BIT NOT NULL DEFAULT 1,
    CONSTRAINT UQ_puntos_de_interes_de_las_rutas UNIQUE (id_punto_de_interes, id_ruta_turistica),
    CONSTRAINT FK_pdir_rutas_punto_de_interes FOREIGN KEY (id_punto_de_interes)
        REFERENCES puntos_de_interes(id_punto_de_interes)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT FK_pdir_rutas_ruta_turistica FOREIGN KEY (id_ruta_turistica)
        REFERENCES rutas_turisticas(id_ruta_turistica)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

CREATE TABLE recorridos (
    id_recorrido INT IDENTITY(1,1) PRIMARY KEY,
    hora_de_inicio TIME NOT NULL,
    hora_de_finalizacion TIME NOT NULL,
    fecha_de_realizacion DATE NOT NULL,
    id_ruta_turistica INT NOT NULL,
    fecha_creacion_de_recorrido DATE NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_recorridos_rutas_turisticas FOREIGN KEY (id_ruta_turistica)
        REFERENCES rutas_turisticas(id_ruta_turistica)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT CHK_recorrido_check_hora CHECK(hora_de_inicio < hora_de_finalizacion)
);

-- ====== (6) PK compuesta -> PK propia + UNIQUE
CREATE TABLE guias_de_los_recorridos (
    id_guia_del_recorrido INT IDENTITY(1,1) PRIMARY KEY,
    id_recorrido INT NOT NULL,
    id_guia INT NOT NULL,
    CONSTRAINT UQ_recorridos_guias UNIQUE (id_recorrido, id_guia),
    CONSTRAINT FK_recorridosguias_recorrido FOREIGN KEY (id_recorrido)
        REFERENCES recorridos(id_recorrido) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_recorridosguias_guia FOREIGN KEY (id_guia)
        REFERENCES guias(id_persona) ON DELETE NO ACTION ON UPDATE CASCADE
);

CREATE TABLE participaciones (
    id_participacion INT IDENTITY(1,1) PRIMARY KEY,
    fecha_de_inscripcion DATE NOT NULL,
    tarifa_pagada DECIMAL(10,2) NOT NULL CHECK (tarifa_pagada >= 0),
    id_metodo_de_pago INT NOT NULL,
    id_recorrido INT NOT NULL,
    id_usuario INT NOT NULL,
    CONSTRAINT FK_participaciones_metodo_pago FOREIGN KEY (id_metodo_de_pago)
        REFERENCES metodos_de_pago(id_metodo_pago)
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT UQ_participaciones_duplicidad UNIQUE(id_participacion,id_usuario),
    CONSTRAINT FK_participaciones_recorridos FOREIGN KEY (id_recorrido)
        REFERENCES recorridos(id_recorrido)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT FK_participaciones_usuarios FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_persona)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE estados_de_las_participaciones (
    id_estado_de_participacion INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL,
    descripcion VARCHAR(200) NULL,
);

CREATE TABLE estados_tomados_por_las_participaciones (
    id_estado_tomado_por_la_participacion INT IDENTITY (1,1) PRIMARY KEY,
    id_estado_de_participacion INT NOT NULL,
    id_participacion INT NOT NULL,
    fecha_inicio_del_estado DATE NOT NULL DEFAULT GETDATE(),
       fecha_fin_del_estado DATE NULL,
     CONSTRAINT FK_fk1p FOREIGN KEY (id_participacion)
        REFERENCES participaciones(id_participacion)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
     CONSTRAINT FK_fk2p FOREIGN KEY (id_estado_de_participacion)
        REFERENCES estados_de_las_participaciones(id_estado_de_participacion)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
     CONSTRAINT CHK_CHECK2ER  CHECK (
    fecha_fin_del_estado IS NULL 
    OR fecha_fin_del_estado > fecha_inicio_del_estado)
);


CREATE TABLE estados_de_los_recorridos (
    id_estado_del_recorrido INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL,
    descripcion VARCHAR(200) NULL,
);

CREATE TABLE estados_tomados_por_los_recorridos (
    id_estado_tomado_por_el_recorrido INT IDENTITY (1,1) PRIMARY KEY,
    id_estado_del_recorrido INT NOT NULL,
    id_recorrido INT NOT NULL,
    fecha_inicio_del_estado DATE NOT NULL DEFAULT GETDATE(),
       fecha_fin_del_estado DATE NULL,
     CONSTRAINT FK_fk1r FOREIGN KEY (id_estado_del_recorrido)
        REFERENCES estados_de_los_recorridos(id_estado_del_recorrido)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
     CONSTRAINT FK_fk2r FOREIGN KEY (id_recorrido)
        REFERENCES recorridos(id_recorrido)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT CHK_CHECK1ERR  CHECK (
    fecha_fin_del_estado IS NULL 
    OR fecha_fin_del_estado > fecha_inicio_del_estado)
);



-- ========================
-- SECCI N: COMENTARIOS, ETIQUETAS Y MULTIMEDIA RELACIONADOS
-- ========================
CREATE TABLE comentarios (
    id_comentario INT IDENTITY(1,1) PRIMARY KEY,
    id_persona INT NOT NULL,
    calificacion INT NOT NULL,
    descripcion VARCHAR(1000) NULL,
    fecha_de_creacion DATE NOT NULL DEFAULT GETDATE(),
    visible BIT NOT NULL DEFAULT 1,
    CONSTRAINT CHK_comentarios_calificacion CHECK (calificacion BETWEEN 0 AND 5),
    CONSTRAINT CHK_comentarios_descripcion CHECK (descripcion IS NULL OR LTRIM(RTRIM(descripcion)) <> ''),
    CONSTRAINT FK_comentarios_usuario FOREIGN KEY (id_persona)
        REFERENCES usuarios(id_persona)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

CREATE TABLE etiquetas (
    id_etiqueta INT IDENTITY(1,1) PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    CONSTRAINT CHK_etiquetas_titulo CHECK (TRIM(titulo) <> '')
);

-- ====== (7) PK compuesta -> PK propia + UNIQUE
CREATE TABLE etiquetas_del_comentario (
    id_etiqueta_del_comentario INT IDENTITY(1,1) PRIMARY KEY,
    id_comentario INT NOT NULL,
    id_etiqueta INT NOT NULL,
    CONSTRAINT UQ_etiquetas_del_comentario UNIQUE (id_comentario, id_etiqueta),
    CONSTRAINT FK_etiquetas_del_comentario_comentarios FOREIGN KEY (id_comentario)
        REFERENCES comentarios(id_comentario)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT FK_etiquetas_del_comentario_etiquetas FOREIGN KEY (id_etiqueta)
        REFERENCES etiquetas(id_etiqueta)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

CREATE TABLE comentables (
    id_comentario INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    CONSTRAINT PK_comentable PRIMARY KEY(id_comentario),
    CONSTRAINT FK_comentable FOREIGN KEY (id_comentario)
    REFERENCES comentarios(id_comentario)
    ON UPDATE CASCADE ON DELETE CASCADE

);

-- ====== (8) PK compuesta -> PK propia + UNIQUE
CREATE TABLE comentarios_de_las_bicicletas (
    id_comentario_de_la_bicicleta INT IDENTITY(1,1) PRIMARY KEY,
    id_comentario INT NOT NULL,
    id_bicicleta INT NOT NULL,
    CONSTRAINT UQ_comentarios_bicicletas UNIQUE (id_comentario, id_bicicleta),
    CONSTRAINT FK_comentarios_bicicletas_comentario 
    FOREIGN KEY (id_comentario) REFERENCES comentarios(id_comentario),
    CONSTRAINT FK_comentarios_bicicletas 
    FOREIGN KEY (id_bicicleta) REFERENCES bicicletas(id_bicicleta)
);

-- ====== (9) PK compuesta -> PK propia + UNIQUE
CREATE TABLE comentarios_de_las_rutas_turisticas (
    id_comentario_de_la_ruta_turistica INT IDENTITY(1,1) PRIMARY KEY,
    id_comentario INT NOT NULL,
    id_ruta_turistica INT NOT NULL,
    CONSTRAINT UQ_comentarios_rutas_turisticas UNIQUE (id_comentario, id_ruta_turistica),
    CONSTRAINT FK_comentarios_rutas FOREIGN KEY (id_comentario)
        REFERENCES comentarios(id_comentario)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT FK_rutas_comentarios FOREIGN KEY (id_ruta_turistica)
        REFERENCES rutas_turisticas(id_ruta_turistica)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- ====== (10) PK compuesta -> PK propia + UNIQUE
CREATE TABLE comentarios_de_los_guias (
    id_comentario_del_guia INT IDENTITY(1,1) PRIMARY KEY,
    id_comentario INT NOT NULL,
    id_guia INT NOT NULL,
    CONSTRAINT UQ_comentarios_guias UNIQUE (id_comentario, id_guia),
    CONSTRAINT FK_comentarios_guias_comentarios FOREIGN KEY (id_comentario)
        REFERENCES comentarios(id_comentario)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT FK_comentarios_guias_guias FOREIGN KEY (id_guia)
        REFERENCES guias(id_persona)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);


-- ========================
-- SECCI N: FORMATOS Y ARCHIVOS MULTIMEDIA
-- ========================
CREATE TABLE formatos_de_archivo (
    id_formato_archivo INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    acronimo VARCHAR(10) NOT NULL,
    CONSTRAINT CHK_formatos_de_archivo_nombre CHECK (TRIM(nombre) <> ''),
    CONSTRAINT CHK_formatos_de_archivo_siglas CHECK (TRIM(acronimo) <> '')
);

CREATE TABLE archivos_multimedia (
    id_archivo_multimedia INT IDENTITY(1,1) PRIMARY KEY,
    URL VARCHAR(300) NOT NULL,
    tamano_en_mb DECIMAL(10,2) NOT NULL,
    id_formato_de_archivo INT NOT NULL,
    fecha_de_creacion DATE NULL,
    pertenece_a_una_bicicleta BIT NOT NULL,
    visible BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_archivos_multimedia_formato FOREIGN KEY (id_formato_de_archivo)
        REFERENCES formatos_de_archivo(id_formato_archivo)
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT CHK_archivos_multimedia_url CHECK (TRIM(URL) <> ''),
    CONSTRAINT CHK_archivos_multimedia_tamano CHECK (tamano_en_mb > 0 AND tamano_en_mb <=20)
);

-- ====== (11) PK compuesta -> PK propia + UNIQUE
CREATE TABLE archivos_multimedia_de_las_bicicletas(
    id_archivo_multimedia_de_la_bicicleta INT IDENTITY(1,1) PRIMARY KEY,
    id_archivo_multimedia INT NOT NULL,
    id_bicicleta INT NOT NULL,
    CONSTRAINT UQ_archivos_de_las_bicis UNIQUE(id_archivo_multimedia,id_bicicleta),
    CONSTRAINT FK_archivo_multimedia FOREIGN KEY(id_archivo_multimedia) REFERENCES archivos_multimedia(id_archivo_multimedia)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
    CONSTRAINT FK_BICI FOREIGN KEY(id_bicicleta) REFERENCES bicicletas(id_bicicleta)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

-- ====== (12) PK compuesta -> PK propia + UNIQUE
CREATE TABLE archivos_multimedia_de_reportes (
    id_archivo_multimedia_del_reporte INT IDENTITY(1,1) PRIMARY KEY,
    id_reporte INT NOT NULL,
    id_archivo_multimedia INT NOT NULL,
    CONSTRAINT UQ_archivos_multimedia_de_reportes UNIQUE (id_reporte, id_archivo_multimedia),
    CONSTRAINT FK_am_reportes_reporte FOREIGN KEY (id_reporte)
        REFERENCES reportes(id_reporte)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT FK_am_reportes_multimedia FOREIGN KEY (id_archivo_multimedia)
        REFERENCES archivos_multimedia(id_archivo_multimedia)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

-- ====== (13) PK compuesta -> PK propia + UNIQUE
CREATE TABLE archivos_multimedia_de_comentarios (
    id_archivo_multimedia_del_comentario INT IDENTITY(1,1) PRIMARY KEY,
    id_comentario INT NOT NULL,
    id_archivo_multimedia INT NOT NULL,
    CONSTRAINT UQ_archivos_multimedia_de_comentarios UNIQUE (id_comentario, id_archivo_multimedia),
    CONSTRAINT FK_am_comentarios_comentario FOREIGN KEY (id_comentario)
        REFERENCES comentarios(id_comentario)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT FK_am_comentarios_archivo FOREIGN KEY (id_archivo_multimedia)
        REFERENCES archivos_multimedia(id_archivo_multimedia)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);
-- ==============================================
-- TABLAS DE HISTORIAL O SOMBRA CORREGIDAS
-- ==============================================

-- 1️⃣ HISTORIAL DE BICICLETAS
CREATE TABLE historial_bicicletas (
    id_historial INT IDENTITY(1,1) PRIMARY KEY,
    id_bicicleta INT NOT NULL,
    modelo VARCHAR(150) NOT NULL,
    numero_de_cuadro VARCHAR(100) NOT NULL,
    horas_de_uso INT NULL,
    anio_de_fabricacion INT NOT NULL,
    tarifa_base_de_alquiler DECIMAL(12,2) NOT NULL,
    etiquetas_adicionales VARCHAR(1000) NULL,
    tamano_del_marco_cm DECIMAL(6,2) NOT NULL,
    tamano_del_marco_in DECIMAL(6,2) NULL,
    es_electrica BIT NOT NULL,
    id_tipo_de_uso INT NOT NULL,
    id_punto_de_alquiler INT NOT NULL,
    kilometraje_km INT NULL,
    kilometraje_mi INT NULL,
    id_seguro INT NOT NULL,
    id_marca INT NOT NULL,
    activo BIT NOT NULL,
    fecha_de_creacion DATE NOT NULL DEFAULT GETDATE(),
    accion VARCHAR(20) NOT NULL,         
    fecha_cambio DATETIME DEFAULT GETDATE(),
    usuario_sql SYSNAME DEFAULT SUSER_SNAME()
);
GO


-- 2️⃣ HISTORIAL DE MANTENIMIENTOS
CREATE TABLE historial_mantenimientos (
    id_historial INT IDENTITY(1,1) PRIMARY KEY,
    id_mantenimiento INT NOT NULL,
    descripcion VARCHAR(255) NOT NULL,
    fecha_de_inicio DATE NOT NULL,
    fecha_de_fin DATE NULL,
    id_tipo_de_mantenimiento INT NOT NULL,
    id_bicicleta INT NOT NULL,
    accion VARCHAR(20) NOT NULL,
    fecha_cambio DATETIME DEFAULT GETDATE(),
    usuario_sql SYSNAME DEFAULT SUSER_SNAME()
);
GO


-- 3️⃣ HISTORIAL DE ALQUILERES
CREATE TABLE historial_alquileres (
    id_historial INT IDENTITY(1,1) PRIMARY KEY,
    id_alquiler INT NOT NULL,
    fecha_de_inicio_de_vigencia DATE NOT NULL,
    fecha_de_fin_de_vigencia DATE NOT NULL,
    id_plan INT NOT NULL,
    id_usuario INT NOT NULL,
    id_bicicleta INT NOT NULL,
    id_metodo_de_pago INT NOT NULL,
    tarifa_total DECIMAL(12,2) NOT NULL,
    fecha_de_liquidacion DATE NOT NULL,
    accion VARCHAR(20) NOT NULL, 
    fecha_cambio DATETIME DEFAULT GETDATE(),
    usuario_sql SYSNAME DEFAULT SUSER_SNAME()
);
GO


-- 4️⃣ HISTORIAL DE RECORRIDOS
CREATE TABLE historial_recorridos (
    id_historial INT IDENTITY(1,1) PRIMARY KEY,
    id_recorrido INT NOT NULL,
    hora_de_inicio TIME NOT NULL,
    hora_de_finalizacion TIME NOT NULL,
    fecha_de_realizacion DATE NOT NULL,
    id_ruta_turistica INT NOT NULL,
    fecha_creacion_de_recorrido DATE NOT NULL,
    accion VARCHAR(20) NOT NULL,
    fecha_cambio DATETIME DEFAULT GETDATE(),
    usuario_sql SYSNAME DEFAULT SUSER_SNAME()
);
GO


-- 5️⃣ HISTORIAL DE PARTICIPACIONES
CREATE TABLE historial_participaciones (
    id_historial INT IDENTITY(1,1) PRIMARY KEY,
    id_participacion INT NOT NULL,
    fecha_de_inscripcion DATE NOT NULL,
    tarifa_pagada DECIMAL(10,2) NOT NULL,
    id_metodo_de_pago INT NOT NULL,
    id_recorrido INT NOT NULL,
    id_usuario INT NOT NULL,
    accion VARCHAR(20) NOT NULL,
    fecha_cambio DATETIME DEFAULT GETDATE(),
    usuario_sql SYSNAME DEFAULT SUSER_SNAME()
);
GO


-- 6️⃣ HISTORIAL DE REPORTES
CREATE TABLE historial_reportes (
    id_historial INT IDENTITY(1,1) PRIMARY KEY,
    id_reporte INT NOT NULL,
    titulo VARCHAR(200) NOT NULL,
    descripcion VARCHAR(1000) NULL,
    fecha_de_creacion DATE NOT NULL,
    id_persona INT NOT NULL,
    id_bicicleta INT NOT NULL,
    accion VARCHAR(20) NOT NULL,
    fecha_cambio DATETIME DEFAULT GETDATE(),
    usuario_sql SYSNAME DEFAULT SUSER_SNAME()
);
GO


-- 7️⃣ HISTORIAL DE COMENTARIOS
CREATE TABLE historial_comentarios (
    id_historial INT IDENTITY(1,1) PRIMARY KEY,
    id_comentario INT NOT NULL,
    id_persona INT NOT NULL,
    calificacion INT NOT NULL,
    descripcion VARCHAR(1000) NULL,
    fecha_de_creacion DATE NOT NULL,
    visible BIT NOT NULL,
    accion VARCHAR(20) NOT NULL,
    fecha_cambio DATETIME DEFAULT GETDATE(),
    usuario_sql SYSNAME DEFAULT SUSER_SNAME()
);
GO
