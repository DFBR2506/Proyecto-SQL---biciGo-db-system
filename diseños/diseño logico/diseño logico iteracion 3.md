
Bicicletas {

`	`id\_bicicleta integer pk

`	`modelo varchar

`	`número\_de\_cuadro varchar unique

`	`horas\_de\_uso integer

`	`año\_de\_fabricación date

`	`tarifa\_base\_de\_alquiler decimal

`	`etiquetas\_adicionales varchar null

`	`tamaño\_del\_marco\_(cm) decimal

`	`tamaño\_del\_marco\_(in) decimal

`	`es\_eléctrica boolean

`	`id\_tipo\_de\_uso integer \*> Tipos\_de\_uso.id\_tipo\_de\_uso

`	`id\_punto\_de\_alquiler integer unique \*> Puntos\_de\_alquiler.id\_punto\_de\_alquiler

`	`kilometraje\_(km) integer

`	`kilometraje\_(mi) integer

`	`id\_estado\_mantenimiento integer \*> Estados\_mantenimiento.id\_estado\_mantenimiento

`	`id\_seguro integer \*> Seguros.id\_seguro

`	`id\_mantenimiento integer >\* Mantenimientos.id\_mantenimiento

`	`id\_reporte integer >\* Reportes.id\_reporte

`	`id\_marca integer \*> Marcas.id\_marca

`	`id\_estado\_de\_disponibilidad integer \*> Estados\_de\_disponibilidad\_de\_las\_bicicletas.id\_estado\_de\_disponibilidad

}

Tipos\_de\_uso {

`	`id\_tipo\_de\_uso integer pk

`	`nombre varchar unique

`	`descripción varchar

}

Puntos\_de\_alquiler {

`	`id\_punto\_de\_alquiler integer pk

`	`nombre varchar unique

`	`longitud decimal

`	`latitud decimal

`	`id\_ciudad integer \*> Ciudades.id\_ciudad

`	`id\_horario integer > Horarios.id\_horario

}

Ciudades {

`	`id\_ciudad integer pk

`	`nombre varchar

`	`id\_departamento integer \*> Departamentos.id\_departamento

}

Departamentos {

`	`id\_departamento integer pk \*> Ciudades.id

`	`nombre varchar

}

Accesorios {

`	`id\_accesorio integer pk

`	`función varchar

`	`nombre varchar unique

}

Alquileres {

`	`id\_alquiler integer pk

`	`estado varchar

`	`fecha\_de\_inicio\_de\_vigencia date

`	`fecha\_de\_fin\_de\_vigencia date

`	`id\_plan integer \*> Planes\_de\_Alquiler.id\_plan

`	`id\_usuario integer >\* Usuarios.id\_usuario

`	`id\_bicicleta integer \*> Bicicletas.id\_bicicleta

`	`id\_método\_de\_pago integer > Métodos\_de\_pago.id\_método\_de\_pago

`	`tarifa\_total decimal

}

Métodos\_de\_pago {

`	`id\_método\_de\_pago integer pk

`	`nombre varchar unique

`	`es\_transferencia boolean

}

Planes\_de\_Alquiler {

`	`id\_plan integer pk

`	`tipo\_de\_plan varchar unique

`	`descripción varchar

`	`beneficios\_específicos varchar

`	`condiciones\_especiales varchar

`	`tarifa\_asociada decimal

}

Usuarios {

`	`id\_preferencia integer \*> Preferencias\_de\_los\_usuarios.id\_preferencia

`	`id\_persona integer pk > Personas.id\_persona

`	`contraseña varchar

`	`fecha\_de\_registro date

`	`id\_política integer \*> Políticas.id\_política

`	`id\_reporte integer >\* Reportes.id\_reporte

`	`id\_participaciones integer >\* Participaciones.id\_participacion

}

Comentarios {

`	`id\_comentario integer pk

`	`id\_usuario integer \*> Usuarios.id\_usuario

`	`calificación integer

`	`descripción varchar

`	`fecha\_de\_realización date

}

Idiomas {

`	`id\_idioma integer pk

`	`nombre varchar unique

`	`código\_ISO\_639\_2 varchar unique

`	`código\_ISO\_639\_1 varchar unique

}

Niveles\_de\_dificultad {

`	`id\_nivel\_dificultad integer pk

`	`nombre varchar unique

`	`descripción varchar

}

Rutas\_turísticas {

`	`id\_ruta\_turística integer pk

`	`nombre varchar unique

`	`distancia\_total\_(mi) decimal

`	`distancia\_total\_(km) integer

`	`id\_nivel\_dificultad integer \*> Niveles\_de\_dificultad.id\_nivel\_dificultad

}

Puntos\_de\_interés {

`	`id\_punto\_de\_interés integer pk

`	`nombre varchar

`	`longitud decimal

`	`latitud decimal

}

Formatos\_de\_archivo {

`	`id\_formato\_de\_archivo integer pk

`	`nombre varchar unique

`	`acrónimo varchar

}

Archivos\_multimedia {

`	`id\_archivo\_multimedia integer pk

`	`URL varchar unique

`	`tamaño\_(mb) decimal

`	`id\_formato\_de\_archivo integer \*> Formatos\_de\_archivo.id\_formato\_de\_archivo

`	`fecha\_de\_subida date

`	`pertenece\_a\_una\_bicicleta binary

}

Sistemas\_de\_medición {

`	`id\_sistema\_de\_medición integer pk

`	`nombre varchar unique

}

Preferencias\_de\_los\_usuarios {

`	`id\_preferencia integer pk

`	`id\_idioma integer \*> Idiomas.id\_idioma

`	`id\_sistema\_de\_medición integer \*> Sistemas\_de\_medición.id\_sistema\_de\_medición

}

Políticas {

`	`id\_política integer pk

`	`versión\_de\_los\_términos integer increments unique

}

Etiquetas {

`	`id\_etiqueta integer pk

`	`título varchar unique

}

Condiciones\_especiales {

`	`id\_condición\_especial integer pk

`	`nombre varchar unique

`	`descripción integer

}

Puntos\_de\_interés\_de\_las\_rutas {

`	`id\_punto\_de\_interés integer pk increments unique \*> Puntos\_de\_interés.id\_punto\_de\_interés

`	`id\_ruta\_turística integer pk \*> Rutas\_turísticas.id\_ruta\_turística

}

Rutas\_de\_usuarios {

`	`id\_ruta\_turística integer pk \*> Rutas\_turísticas.id\_ruta\_turística

`	`fecha\_realizacion date

`	`id\_ integer

}

Archivos\_multimedia\_de\_comentarios {

`	`id\_comentario integer pk \*> Comentarios.id\_comentario

`	`id\_archivo\_multimedia integer pk \*> Archivos\_multimedia.id\_archivo\_multimedia

}

Etiquetas\_de\_comentarios {

`	`id\_comentario integer pk increments \*> Comentarios.id\_comentario

`	`id\_etiqueta integer pk \*> Etiquetas.id\_etiqueta

}

Condiciones\_de\_bicicletas {

`	`id\_bicicleta integer pk \*> Bicicletas.id\_bicicleta

`	`id\_condición\_especial integer pk \*> Condiciones\_especiales.id\_condición\_especial

}

Accesorios\_de\_bicicletas {

`	`id\_bicicleta integer pk unique \*> Bicicletas.id\_bicicleta

`	`id\_accesorio integer pk \*> Accesorios.id\_accesorio

}

Estados\_de\_disponibilidad\_de\_las\_bicicletas {

`	`id\_estado\_de\_disponibilidad integer pk

`	`nombre varchar unique

`	`descripción varchar null

}

Estados\_mantenimiento {

`	`id\_estado\_mantenimiento integer pk

`	`nombre varchar unique

`	`descripción varchar null

}

Empresas\_de\_seguros {

`	`id\_empresa\_de\_seguros integer pk

`	`nombre varchar unique

`	`eslogan varchar null

}

Seguros {

`	`id\_seguro integer pk

`	`tarifa\_base integer

`	`cobertura varchar

`	`máximo\_valor\_asegurable integer

`	`id\_empresa\_de\_seguros integer \*> Empresas\_de\_seguros.id\_empresa\_de\_seguros

}

Mantenimientos {

`	`id\_mantenimiento integer pk increments unique

`	`descripción varchar

`	`fecha\_de\_inicio date

`	`fecha\_de\_fin date

`	`id\_tipo\_de\_mantenimiento integer \*> Tipos\_de\_mantenimiento.id\_tipo\_de\_mantenimiento

}

Tipos\_de\_mantenimiento {

`	`id\_tipo\_de\_mantenimiento integer pk increments unique

`	`nombre varchar unique

`	`descripción varchar null

}

Reportes {

`	`id\_reporte integer pk increments unique

`	`título varchar

`	`descripción varchar

`	`id\_estado\_del\_reporte integer \*> Estados\_del\_reporte.id\_estado\_del\_reporte

`	`fecha\_de\_creacion date

}

Estados\_del\_reporte {

`	`id\_estado\_del\_reporte integer pk increments unique

`	`nombre varchar unique

`	`descripción varchar null

}

Marcas {

`	`id\_marca integer pk increments unique

`	`nombre varchar unique

`	`eslogan varchar null

}

Horarios {

`	`id\_horario integer pk increments unique

}

Días {

`	`id\_día integer pk increments unique

`	`nombre varchar unique

}

Documentos\_de\_identificación {

`	`id\_documento\_de\_identificación integer pk increments unique

`	`número integer unique

`	`id\_tipo\_de\_documento integer \*> Tipos\_de\_documento.id\_tipo\_de\_documento

`	`fecha\_de\_expedición date

`	`id\_persona integer > Personas.id\_persona

`	`id\_ciudad integer \*> Ciudades.id\_ciudad

}

Tipos\_de\_documento {

`	`id\_tipo\_de\_documento integer pk increments unique

`	`nombre varchar unique

`	`acrónimo varchar

}

Días\_de\_los\_horarios {

`	`id\_días\_de\_los\_horarios integer pk

`	`id\_día integer increments unique \*> Días.id\_día

`	`id\_horario integer \*> Horarios.id\_horario

`	`hora\_de\_apertura time

`	`hora\_de\_cierre time

}

Archivos\_multimedia\_de\_reportes {

`	`id\_reporte integer increments unique \*> Reportes.id\_reporte

`	`id\_archivo\_multimedia integer \*> Archivos\_multimedia.id\_archivo\_multimedia

}

Métodos\_de\_pago\_aceptados\_por\_alquileres {

`	`id\_punto\_de\_alquiler integer increments unique \*> Puntos\_de\_alquiler.id\_punto\_de\_alquiler

`	`id\_método\_de\_pago integer \*> Métodos\_de\_pago.id\_método\_de\_pago

}

Archivos\_Multimedias\_de\_las\_Bicicletas {

`	`id\_archivo\_multimedia integer pk > Archivos\_multimedia.id\_archivo\_multimedia

`	`id\_bicicleta integer \*> Bicicletas.id\_bicicleta

}

Comentable {

`	`nombre varchar

`	`id\_comentario integer pk >\* Comentarios.id\_comentario

}

Aceptación\_de\_las\_políticas {

`	`id\_persona integer increments unique \*> Usuarios.id\_persona

`	`id\_política integer \*> Políticas.id\_política

`	`fecha\_de\_aceptación date

`	`id\_aceptación\_de\_las\_políticas integer pk

}

Dias\_de\_los\_Horarios {

`	`id\_dias\_de\_los\_horarios integer pk increments unique

`	`hora\_de\_apertura time

`	`hora\_de\_cierre time

`	`id\_dia integer > Días.id\_día

`	`id\_horario integer > Horarios.id\_horario

}

Comentarios\_Bicicletas {

`	`id\_comentario integer pk increments unique > Comentarios.id\_comentario

`	`id\_bicicleta integer \*> Bicicletas.id\_bicicleta

}

Comentarios\_Rutas\_Turisticas {

`	`id\_comentario integer pk increments unique > Comentarios.id\_comentario

`	`id\_ruta\_turisticas integer \*> Rutas\_turísticas.id\_ruta\_turística

}

Personas {

`	`id\_persona integer pk increments unique

`	`primer\_apellido varchar

`	`primer\_nombre varchar

`	`fecha\_de\_nacimiento date

`	`email varchar unique

`	`numero\_de\_telefono integer unique

}

Guias {

`	`id\_persona integer pk increments unique > Personas.id\_persona

`	`años\_de\_experiencia integer

`	`numero\_de\_tarjeta\_profesional integer unique

`	`id\_estado\_de\_disponibilidad\_del\_guia integer \*> Estados\_de\_Disponibilidad\_de\_los\_Guias.id\_estado\_de\_disponibilidad\_del\_guia

`	`id\_recorridos integer \*>\* Recorridos.id\_recorridos

}

Comentarios\_Guias {

`	`id\_comentario integer pk increments unique > Comentarios.id\_comentario

`	`id\_guia integer \*> Guias.id\_persona

}

Estados\_de\_Disponibilidad\_de\_los\_Guias {

`	`id\_estado\_de\_disponibilidad\_del\_guia integer pk increments unique

`	`nombre varchar unique

`	`descripcion varchar null

}

Recorridos {

`	`id\_recorridos integer pk increments unique

`	`hora\_de\_inicio time

`	`hora\_de\_finalizacion time

`	`fecha\_de\_realizacion date

`	`id\_ruta\_turistica integer \*> Rutas\_turísticas.id\_ruta\_turística

}

Estados\_de\_los\_Recorridos {

`	`id\_estado\_del\_recorrido integer pk increments unique

`	`nombre varchar unique

`	`descripcion varchar null

`	`id\_recorrido integer >\* Recorridos.id\_recorridos

}

Participaciones {

`	`id\_participacion integer pk increments unique

`	`fecha\_de\_inscripciones date

`	`tarifa\_pagada decimal

`	`id\_método\_de\_pago integer \*> Métodos\_de\_pago.id\_método\_de\_pago

`	`id\_recorrido integer \*> Recorridos.id\_recorridos

}

Estados\_de\_las\_participaciones {

`	`id\_estado\_de\_participaciones integer pk increments unique

`	`nombre varchar unique

`	`descripcion varchar null

`	`id\_participacion integer >\* Participaciones.id\_participacion

}

