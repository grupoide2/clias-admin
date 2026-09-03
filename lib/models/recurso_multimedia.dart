class RecursoMultimedia {
  final String publicId;
  final String slug;
  final String tipo;

  /// APP (clias-app) | WEB (clias-web).
  final String destino;
  final String? categoria;
  final String? descripcion;
  final String nombreArchivo;
  final String contentType;
  final int tamano;
  final bool activo;
  final int orden;
  final String url;

  RecursoMultimedia({
    required this.publicId,
    required this.slug,
    required this.tipo,
    required this.destino,
    required this.categoria,
    required this.descripcion,
    required this.nombreArchivo,
    required this.contentType,
    required this.tamano,
    required this.activo,
    required this.orden,
    required this.url,
  });

  factory RecursoMultimedia.fromJson(Map<String, dynamic> j) => RecursoMultimedia(
        publicId: j['publicId'] as String,
        slug: j['slug'] as String,
        tipo: j['tipo'] as String,
        destino: j['destino'] as String? ?? 'APP',
        categoria: j['categoria'] as String?,
        descripcion: j['descripcion'] as String?,
        nombreArchivo: j['nombreArchivo'] as String? ?? '',
        contentType: j['contentType'] as String? ?? '',
        tamano: (j['tamano'] as num?)?.toInt() ?? 0,
        activo: j['activo'] as bool? ?? true,
        orden: (j['orden'] as num?)?.toInt() ?? 0,
        url: j['url'] as String? ?? '',
      );
}
