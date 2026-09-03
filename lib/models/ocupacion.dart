class Ocupacion {
  final String publicId;
  final String nombre;
  final bool activo;
  final bool soloUniversidad;
  final int orden;

  Ocupacion({
    required this.publicId,
    required this.nombre,
    required this.activo,
    required this.soloUniversidad,
    required this.orden,
  });

  factory Ocupacion.fromJson(Map<String, dynamic> json) => Ocupacion(
        publicId: json['publicId'] as String,
        nombre: json['nombre'] as String,
        activo: json['activo'] as bool? ?? true,
        soloUniversidad: json['soloUniversidad'] as bool? ?? false,
        orden: (json['orden'] as num?)?.toInt() ?? 0,
      );
}
