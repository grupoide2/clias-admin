class RangoTiempoExamen {
  final String publicId;

  /// Pregunta a la que pertenece: MENSTRUACION | PAPANICOLAOU | VPH.
  final String pregunta;
  final String codigo;
  final String etiqueta;
  final bool activo;
  final int orden;

  RangoTiempoExamen({
    required this.publicId,
    required this.pregunta,
    required this.codigo,
    required this.etiqueta,
    required this.activo,
    required this.orden,
  });

  factory RangoTiempoExamen.fromJson(Map<String, dynamic> json) =>
      RangoTiempoExamen(
        publicId: json['publicId'] as String,
        pregunta: json['pregunta'] as String? ?? 'PAPANICOLAOU',
        codigo: json['codigo'] as String,
        etiqueta: json['etiqueta'] as String,
        activo: json['activo'] as bool? ?? true,
        orden: (json['orden'] as num?)?.toInt() ?? 0,
      );
}
