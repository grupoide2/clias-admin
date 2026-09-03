import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:universal_html/html.dart' as html;
import 'package:telemedicina_web/config/env.dart';
import 'package:telemedicina_web/models/recurso_multimedia.dart';

class RecursoService {
  final String _base = AppConfig.baseUrl;

  Map<String, String> get _authHeader {
    final token = html.window.localStorage['jwt'] ?? '';
    return token.isEmpty ? {} : {'Authorization': 'Bearer $token'};
  }

  Future<List<RecursoMultimedia>> listar({String? destino}) async {
    final q = StringBuffer('soloActivos=false');
    if (destino != null && destino.isNotEmpty) q.write('&destino=$destino');
    final resp = await http.get(
      Uri.parse('$_base/recursos?$q'),
      headers: _authHeader,
    );
    if (resp.statusCode == 200) {
      return (jsonDecode(resp.body) as List)
          .map((e) => RecursoMultimedia.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error al cargar recursos (${resp.statusCode})');
  }

  Future<void> subir({
    required String slug,
    required String tipo,
    required String destino,
    String? categoria,
    String? descripcion,
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    final ct = contentType.contains('/')
        ? contentType.split('/')
        : ['application', 'octet-stream'];
    final req = http.MultipartRequest('POST', Uri.parse('$_base/recursos'))
      ..headers.addAll(_authHeader)
      ..fields['slug'] = slug
      ..fields['tipo'] = tipo
      ..fields['destino'] = destino;
    if (categoria != null && categoria.isNotEmpty) req.fields['categoria'] = categoria;
    if (descripcion != null && descripcion.isNotEmpty) {
      req.fields['descripcion'] = descripcion;
    }
    req.files.add(http.MultipartFile.fromBytes(
        'archivo',
        bytes,
        filename: filename,
        contentType: MediaType(ct[0], ct[1]),
      ));
    final resp = await req.send();
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      final body = await resp.stream.bytesToString();
      throw Exception(_errMsg(body) ?? 'Error al subir el recurso (${resp.statusCode})');
    }
  }

  Future<void> actualizarMeta(
    String publicId, {
    required bool activo,
    required int orden,
    String? destino,
    String? categoria,
    String? descripcion,
  }) async {
    final resp = await http.put(
      Uri.parse('$_base/recursos/$publicId'),
      headers: {..._authHeader, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'activo': activo,
        'orden': orden,
        if (destino != null) 'destino': destino,
        if (categoria != null) 'categoria': categoria,
        if (descripcion != null) 'descripcion': descripcion,
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception(_errMsg(resp.body) ?? 'Error al actualizar (${resp.statusCode})');
    }
  }

  Future<void> eliminar(String publicId) async {
    final resp = await http.delete(
      Uri.parse('$_base/recursos/$publicId'),
      headers: _authHeader,
    );
    if (resp.statusCode != 204 && resp.statusCode != 200) {
      throw Exception('Error al eliminar (${resp.statusCode})');
    }
  }

  /// Selector de archivo en el navegador; devuelve null si el usuario cancela.
  static Future<({Uint8List bytes, String name, String type})?> pickFile(
      String accept) async {
    final input = html.FileUploadInputElement()..accept = accept;
    input.click();
    await input.onChange.first;
    final files = input.files;
    if (files == null || files.isEmpty) return null;
    final file = files.first;
    final reader = html.FileReader()..readAsArrayBuffer(file);
    await reader.onLoad.first;
    final bytes = Uint8List.fromList((reader.result as ByteBuffer).asUint8List());
    return (
      bytes: bytes,
      name: file.name,
      type: file.type.isNotEmpty ? file.type : 'application/octet-stream',
    );
  }
}

String? _errMsg(String body) {
  try {
    final d = jsonDecode(body);
    if (d is Map && d['mensaje'] is String) return d['mensaje'] as String;
  } catch (_) {}
  return null;
}
