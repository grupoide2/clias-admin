import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;
import 'package:telemedicina_web/config/env.dart';
import 'package:telemedicina_web/models/ocupacion.dart';
import 'package:telemedicina_web/models/rango_tiempo_examen.dart';

/// Catálogos administrados desde clias-admin. Los endpoints NO llevan prefijo /api.
class CatalogoService {
  final String _base = AppConfig.baseUrl;

  Map<String, String> get _headers {
    final token = html.window.localStorage['jwt'] ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ── Ocupaciones ────────────────────────────────────────────────────────────

  Future<List<Ocupacion>> listarOcupaciones({bool soloActivas = false}) async {
    final resp = await http.get(
      Uri.parse('$_base/ocupaciones?soloActivas=$soloActivas'),
      headers: _headers,
    );
    if (resp.statusCode == 200) {
      return (jsonDecode(resp.body) as List)
          .map((e) => Ocupacion.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error al cargar ocupaciones (${resp.statusCode})');
  }

  Future<void> crearOcupacion({
    required String nombre,
    bool soloUniversidad = true,
    int orden = 0,
  }) async {
    final resp = await http.post(
      Uri.parse('$_base/ocupaciones'),
      headers: _headers,
      body: jsonEncode({
        'nombre': nombre,
        'activo': true,
        'soloUniversidad': soloUniversidad,
        'orden': orden,
      }),
    );
    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw Exception(_errMsg(resp) ?? 'Error al crear ocupación (${resp.statusCode})');
    }
  }

  Future<void> actualizarOcupacion(
    String publicId, {
    required String nombre,
    required bool activo,
    required bool soloUniversidad,
    required int orden,
  }) async {
    final resp = await http.put(
      Uri.parse('$_base/ocupaciones/$publicId'),
      headers: _headers,
      body: jsonEncode({
        'nombre': nombre,
        'activo': activo,
        'soloUniversidad': soloUniversidad,
        'orden': orden,
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception(_errMsg(resp) ?? 'Error al actualizar ocupación (${resp.statusCode})');
    }
  }

  Future<void> eliminarOcupacion(String publicId) async {
    final resp = await http.delete(
      Uri.parse('$_base/ocupaciones/$publicId'),
      headers: _headers,
    );
    if (resp.statusCode != 204 && resp.statusCode != 200) {
      throw Exception('Error al eliminar ocupación (${resp.statusCode})');
    }
  }

  // ── Rangos de tiempo de examen ─────────────────────────────────────────────

  Future<List<RangoTiempoExamen>> listarRangos({
    String? pregunta,
    bool soloActivos = false,
  }) async {
    final q = StringBuffer('soloActivos=$soloActivos');
    if (pregunta != null && pregunta.isNotEmpty) q.write('&pregunta=$pregunta');
    final resp = await http.get(
      Uri.parse('$_base/rango-tiempo-examen?$q'),
      headers: _headers,
    );
    if (resp.statusCode == 200) {
      return (jsonDecode(resp.body) as List)
          .map((e) => RangoTiempoExamen.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error al cargar rangos de tiempo (${resp.statusCode})');
  }

  Future<void> crearRango({
    required String pregunta,
    required String codigo,
    required String etiqueta,
    int orden = 0,
  }) async {
    final resp = await http.post(
      Uri.parse('$_base/rango-tiempo-examen'),
      headers: _headers,
      body: jsonEncode({
        'pregunta': pregunta,
        'codigo': codigo,
        'etiqueta': etiqueta,
        'activo': true,
        'orden': orden,
      }),
    );
    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw Exception(_errMsg(resp) ?? 'Error al crear rango (${resp.statusCode})');
    }
  }

  /// El código es inmutable; el backend solo aplica etiqueta/activo/orden.
  Future<void> actualizarRango(
    String publicId, {
    required String codigo,
    required String etiqueta,
    required bool activo,
    required int orden,
  }) async {
    final resp = await http.put(
      Uri.parse('$_base/rango-tiempo-examen/$publicId'),
      headers: _headers,
      body: jsonEncode({
        'codigo': codigo,
        'etiqueta': etiqueta,
        'activo': activo,
        'orden': orden,
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception(_errMsg(resp) ?? 'Error al actualizar rango (${resp.statusCode})');
    }
  }

  Future<void> eliminarRango(String publicId) async {
    final resp = await http.delete(
      Uri.parse('$_base/rango-tiempo-examen/$publicId'),
      headers: _headers,
    );
    if (resp.statusCode != 204 && resp.statusCode != 200) {
      throw Exception('Error al eliminar rango (${resp.statusCode})');
    }
  }
}

String? _errMsg(http.Response r) {
  try {
    final d = jsonDecode(r.body);
    if (d is Map && d['mensaje'] is String) return d['mensaje'] as String;
  } catch (_) {}
  return null;
}
