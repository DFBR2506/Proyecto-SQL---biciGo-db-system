
Bicicletas {
	id_bicicleta integer pk
	modelo varchar
	número_de_cuadro varchar unique
	horas_de_uso integer
	año_de_fabricación date
	tarifa_base_de_alquiler decimal
	etiquetas_adicionales varchar null
	tamaño_del_marco_(cm) decimal
	tamaño_del_marco_(in) decimal
	es_eléctrica boolean
	id_tipo_de_uso integer *> Tipos_de_uso.id_tipo_de_uso
	id_punto_de_alquiler integer unique *> Puntos_de_alquiler.id_punto_de_alquiler
	kilometraje_(km) integer
	kilometraje_(mi) integer
	id_seguro integer *> Seguros.id_seguro
	id_marca integer *> Marcas.id_marca
}

Tipos_de_uso {
	id_tipo_de_uso integer pk
	nombre varchar unique
	descripción varchar
}

Puntos_de_alquiler {
	id_punto_de_alquiler integer pk
	nombre varchar unique
	longitud decimal
	latitud decimal
	id_ciudad integer *> Ciudades.id_ciudad
	id_horario integer > Horarios.id_horario
	dirección varchar
	activo boolean
}

Ciudades {
	id_ciudad integer pk
	nombre varchar
	id_departamento integer *> Departamentos.id_departamento
}

Departamentos {
	id_departamento integer pk *> Ciudades.id
	nombre varchar unique
}

Accesorios {
	id_accesorio integer pk
	función varchar
	nombre varchar unique
}

Alquileres {
	id_alquiler integer pk
	fecha_de_inicio_de_vigencia date
	fecha_de_fin_de_vigencia date
	id_plan integer *> Planes_de_los_Alquileres.id_plan
	id_usuario integer >* Usuarios.id_usuario
	id_bicicleta integer *> Bicicletas.id_bicicleta
	id_método_de_pago integer > Métodos_de_pago.id_método_de_pago
	tarifa_total decimal
	fecha_de_liquidación date
}

Métodos_de_pago {
	id_método_de_pago integer pk
	nombre varchar unique
	es_transferencia boolean
	activo boolean
}

Planes_de_los_Alquileres {
	id_plan integer pk
	tipo_de_plan varchar unique
	descripción varchar
	beneficios_específicos varchar
	condiciones_especiales varchar
	tarifa_asociada decimal
	activo boolean
}

Usuarios {
	id_preferencia integer *> Preferencias_de_los_usuarios.id_preferencia
	id_persona integer pk *> Personas.id_persona
	contraseña varchar
	activo boolean
}

Comentarios {
	id_comentario integer pk
	id_persona integer *> Usuarios.id_persona
	calificación integer
	descripción varchar
	fecha_de_creación date
	id_comentable integer null
	visible boolean
}

Idiomas {
	id_idioma integer pk
	nombre varchar unique
	código_ISO_639_2 varchar unique
	código_ISO_639_1 varchar unique
}

Niveles_de_dificultad {
	id_nivel_dificultad integer pk
	nombre varchar unique
	descripción varchar
}

Rutas_turísticas {
	id_ruta_turística integer pk
	nombre varchar unique
	distancia_total_(mi) decimal
	distancia_total_(km) integer
	id_nivel_dificultad integer *> Niveles_de_dificultad.id_nivel_dificultad
	descripcion varchar
	activo boolean
}

Puntos_de_interés {
	id_punto_de_interés integer pk
	nombre varchar
	longitud decimal
	latitud decimal
}

Formatos_de_archivo {
	id_formato_de_archivo integer pk
	nombre varchar unique
	acrónimo varchar
}

Archivos_multimedia {
	id_archivo_multimedia integer pk
	URL varchar unique
	tamaño_en_mb decimal
	id_formato_de_archivo integer *> Formatos_de_archivo.id_formato_de_archivo
	fecha_de_creación date
	pertenece_a_una_bicicleta binary
	visible boolean
}

Sistemas_de_medición {
	id_sistema_de_medición integer pk
	nombre varchar unique
}

Preferencias_de_los_usuarios {
	id_preferencia integer pk
	id_idioma integer *> Idiomas.id_idioma
	id_sistema_de_medición integer *> Sistemas_de_medición.id_sistema_de_medición
}

Políticas {
	id_política integer pk
	versión_de_los_términos integer increments unique
	fecha_de_creación date
	url_politica integer unique
}

Etiquetas {
	id_etiqueta integer pk
	título varchar unique
}

Condiciones_especiales {
	id_condición_especial integer pk
	nombre varchar unique
	descripción integer
}

Puntos_de_interés_de_las_rutas {
	id_punto_de_interés integer increments unique *> Puntos_de_interés.id_punto_de_interés
	id_ruta_turística integer *> Rutas_turísticas.id_ruta_turística
	id_punto_de_interes_de_la_ruta integer pk
	activo boolean
}

Archivos_multimedia_de_comentarios {
	id_archivo_multimedia_del_comentario integer pk
	id_comentario integer *> Comentarios.id_comentario
	id_archivo_multimedia integer *> Archivos_multimedia.id_archivo_multimedia
}

Etiquetas_del_comentario {
	id_etiqueta_del_comentario integer pk
	id_comentario integer increments *> Comentarios.id_comentario
	id_etiqueta integer *> Etiquetas.id_etiqueta
}

Condiciones_de_bicicletas {
	id_condiciones_de_bicicletas integer pk
	id_bicicleta integer *> Bicicletas.id_bicicleta
	id_condición_especial integer *> Condiciones_especiales.id_condición_especial
}

Accesorios_de_las_bicicletas {
	id_accesorio_de_la_bicicleta integer pk
	id_bicicleta integer unique *> Bicicletas.id_bicicleta
	id_accesorio integer *> Accesorios.id_accesorio
}

Estados_de_disponibilidad_de_las_bicicletas {
	id_estado_de_disponibilidad_de_la_bicicleta integer pk increments unique
	nombre varchar unique
	descripción varchar null
}

estados_fisicos_de_las_bicicletas {
	id_estado_fisico_de_la_bicicleta integer pk
	nombre varchar unique
	descripción varchar null
}

Empresas_de_seguros {
	id_empresa_de_seguros integer pk
	nombre varchar unique
	eslogan varchar null
}

Seguros {
	id_seguro integer pk
	tarifa_base integer
	cobertura varchar
	máximo_valor_asegurable integer
	id_empresa_de_seguros integer *> Empresas_de_seguros.id_empresa_de_seguros
}

Mantenimientos {
	id_mantenimiento integer pk increments unique
	descripción varchar
	fecha_de_inicio date
	fecha_de_fin date
	id_tipo_de_mantenimiento integer *> Tipos_de_mantenimiento.id_tipo_de_mantenimiento
	id_bicicleta integer *> Bicicletas.id_bicicleta
}

Tipos_de_mantenimiento {
	id_tipo_de_mantenimiento integer pk increments unique
	nombre varchar unique
	descripción varchar null
}

Reportes {
	id_reporte integer pk increments unique
	título varchar
	descripción varchar
	fecha_de_creacion date
	id_persona integer *> Guias.id_persona
	id_bicicleta integer *> Bicicletas.id_bicicleta
}

Estados_del_reporte {
	id_estado_del_reporte integer pk increments unique
	nombre varchar unique
	descripción varchar null
}

Marcas {
	id_marca integer pk increments unique
	nombre varchar unique
	eslogan varchar null
}

Horarios {
	id_horario integer pk increments unique
	descripción varchar
}

Días {
	id_día integer pk increments unique
	nombre varchar unique
}

Documentos_de_identificación {
	id_documento_de_identificación integer pk increments unique
	número integer unique
	id_tipo_de_documento integer *> Tipos_de_documento.id_tipo_de_documento
	fecha_de_expedición date
	id_persona integer > Personas.id_persona
	id_ciudad integer *> Ciudades.id_ciudad
}

Tipos_de_documento {
	id_tipo_de_documento integer pk increments unique
	nombre varchar unique
	acrónimo varchar
}

Días_de_los_horarios {
	id_días_de_los_horarios integer pk
	id_día integer increments unique *> Días.id_día
	id_horario integer *> Horarios.id_horario
	hora_de_apertura time
	hora_de_cierre time
}

Archivos_multimedia_de_reportes {
	id_archivo_multimedia_de_reporte integer pk
	id_reporte integer increments unique *> Reportes.id_reporte
	id_archivo_multimedia integer *> Archivos_multimedia.id_archivo_multimedia
}

Métodos_de_pago_aceptados_por_alquileres {
	id_metodo_de_pago_aceptado_por_alquiler integer pk
	id_punto_de_alquiler integer increments unique *> Puntos_de_alquiler.id_punto_de_alquiler
	id_método_de_pago integer *> Métodos_de_pago.id_método_de_pago
}

Archivos_Multimedias_de_las_Bicicletas {
	id_archivo_multimedia integer pk > Archivos_multimedia.id_archivo_multimedia
	id_bicicleta integer null *> Bicicletas.id_bicicleta
}

Comentable {
	nombre varchar unique
	id_comentable integer pk >* Comentarios.id_comentable
}

Aceptación_de_las_políticas {
	id_persona integer increments unique *> Usuarios.id_persona
	id_política integer *> Políticas.id_política
	fecha_de_aceptación date
	id_aceptación_de_las_políticas integer pk
}

Comentarios_de_las_Bicicletas {
	id_comentario integer pk increments unique > Comentarios.id_comentario
	id_bicicleta integer null *> Bicicletas.id_bicicleta
}

comentarios_de_las_rutas_turisticas {
	id_comentario integer pk increments unique > Comentarios.id_comentario
	id_ruta_turisticas integer *> Rutas_turísticas.id_ruta_turística
}

Personas {
	id_persona integer pk increments unique
	primer_apellido varchar
	primer_nombre varchar
	fecha_de_nacimiento date
	email varchar unique
	numero_de_telefono integer unique
	id_reporte integer null *> Reportes.id_reporte
	fecha_de_registro date
}

Guias {
	id_persona integer pk increments unique > Personas.id_persona
	años_de_experiencia integer
	numero_de_tarjeta_profesional varchar unique
	id_recorrido integer *>* Recorridos.id_recorrido
}

comentarios_de_los_guias {
	id_comentario integer pk increments unique > Comentarios.id_comentario
	id_personas integer *> Guias.id_persona
}

Estados_de_Disponibilidad_de_los_Guias {
	id_estado_de_disponibilidad_del_guia integer pk increments unique
	nombre varchar unique
	descripcion varchar null
}

Recorridos {
	id_recorrido integer pk increments unique
	hora_de_inicio time
	hora_de_finalizacion time
	fecha_de_realizacion date
	id_ruta_turística integer null *> Rutas_turísticas.id_ruta_turística
	fecha_de_creación_de_recorrido date
}

Estados_de_los_Recorridos {
	id_estado_del_recorrido integer pk increments unique
	nombre varchar unique
	descripcion varchar null
}

Participaciones {
	id_participacion integer pk increments unique
	fecha_de_inscripcion date
	tarifa_pagada decimal
	id_método_de_pago integer *> Métodos_de_pago.id_método_de_pago
	id_recorrido integer *> Recorridos.id_recorrido
	id_usuario integer *> Usuarios.id_persona
}

Estados_de_las_participaciones {
	id_estado_de_participaciones integer pk increments unique
	nombre varchar unique
	descripcion varchar null
}

guias_de_los_recorridos {
	id_guia integer increments unique *> Guias.id_persona
	id_recorrido integer *> Recorridos.id_recorrido
	id_guia_del_recorrido integer pk
}

Estados_de_los_alquileres {
	id_estado_del_alquiler integer pk increments unique
	nombre varchar unique
	descripción varchar null
}

Roles {
	id_rol integer pk increments unique
	nombre integer unique
	descripción integer null
}

estados_fisicos_tomados_por_la_bicicleta {
	id_estado_fisico_tomado_por_la_bicicleta integer pk *> estados_fisicos_de_las_bicicletas.id_estado_mantenimiento
	id_estado_fisico_bicicleta integer *> estados_fisicos_de_las_bicicletas.id_estado_fisico_de_la_bicicleta
	id_bicleta integer *> Bicicletas.id_bicicleta
	fecha_inicio_estado datetime
	fecha_fin_estado datetime
}

disponibilidades_tomadas_por_las_bicicletas {
	id_disponibilidad_de_la_bicicleta integer pk
	id_estado_de_disponibilidad_de_la_bicicleta integer *> Estados_de_disponibilidad_de_las_bicicletas.id_estado_de_disponibilidad_de_la_bicicleta
	id_bicicleta integer *> Bicicletas.id_bicicleta
	fecha_inicio_estado datetime
	fecha_fin_estado datetime
}

disponibilidades_tomadas_por_los_guias {
	id_guia integer *> Guias.id_persona
	id_estado_disponibilidad_del_guia integer *> Estados_de_Disponibilidad_de_los_Guias.id_estado_de_disponibilidad_del_guia
	fecha_inicio_estado datetime
	fecha_fin_estado datetime
}

estados_tomados_por_los_alquileres {
	id_estado_tomado_por_el_alquiler integer pk
	id_estado_del_alquiler integer *> Estados_de_los_alquileres.id_estado_del_alquiler
	id_alquiler integer *> Alquileres.id_alquiler
	fecha_inicio_estado datetime
	fecha_fin_estado datetime
}

estados_tomados_por_los_reportes {
	id_reporte integer *> Reportes.id_reporte
	id_estado_del_reporte integer *> Estados_del_reporte.id_estado_del_reporte
	fecha_inicio_estado datetime
	fecha_fin_estado datetime
}

estados_tomados_por_las_participaciones {
	id_participación integer *> Participaciones.id_participacion
	id_estado_de_participaciones integer *> Estados_de_las_participaciones.id_estado_de_participaciones
	fecha_inicio_estado datetime
	fecha_fin_estado datetime
	id_estado_tomado_por_la_participacion integer pk
}

estados_tomados_por_los_recorridos {
	id_recorrido integer *> Recorridos.id_recorrido
	id_estado_del_recorrido integer *> Estados_de_los_Recorridos.id_estado_del_recorrido
	fecha_inicio_estado datetime
	fecha_fin_estado datetime
	id_estado_tomado_por_el_recorrido integer pk
}

roles_de_las_personas {
	id_rol_de_la_persona integer pk increments unique
	id_rol integer > Roles.id_rol
	id_persona integer > Personas.id_persona
}

idiomas_de_los_guias {
	id_idioma_del_guia integer pk increments unique
	id_guia integer *> Guias.id_persona
	id_idioma integer *> Idiomas.id_idioma
	nivel_de_dominio integer
}

