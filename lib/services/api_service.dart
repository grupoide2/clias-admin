import 'dart:convert';
import 'dart:typed_data';
import 'package:telemedicina_web/models/estado_dispositivo.dart';
import 'package:universal_html/html.dart' as html;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:telemedicina_web/models/result.dart';
import 'package:telemedicina_web/models/profile.dart';
import 'package:telemedicina_web/models/paciente.dart';
import 'package:telemedicina_web/config/env.dart';

class ApiService {
  final String _baseUrl = '${AppConfig.baseUrl}/api';

  Map<String, String> get _authHeaders {
    final token = html.window.localStorage['jwt'] ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Result>> getResults(String patientId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/patients/$patientId/results'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => Result.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error al cargar resultados: ${response.statusCode}');
  }

  Future<void> uploadResult(
    String patientId,
    List<int> fileBytes,
    String filename,
  ) async {
    final uri = Uri.parse('$_baseUrl/patients/$patientId/results');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: filename,
          contentType: MediaType('application', 'pdf'),
        ),
      );

    final bearer = html.window.localStorage['jwt'] ?? '';
    if (bearer.isNotEmpty) request.headers['Authorization'] = 'Bearer $bearer';

    final response = await request.send();
    if (response.statusCode != 201) {
      throw Exception('Error al subir PDF: ${response.statusCode}');
    }
  }

  Future<Profile> fetchProfile() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Profile(nombre: 'admin', username: 'admin', role: 'ADMIN');
  }

  Future<String> fetchPatientIdFromDevice(String deviceCode) async {
    final resp = await http.get(
      Uri.parse('$_baseUrl/dispositivos_registrados/$deviceCode'),
      headers: {'Content-Type': 'application/json'},
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final publicId = data['cuentaUsuarioPublicId'];
      if (publicId == null) {
        throw Exception('Dispositivo sin cuenta de usuario asociada');
      }
      return publicId.toString();
    }
    throw Exception('Error al cargar dispositivo: ${resp.statusCode}');
  }

  Future<Paciente> getPaciente(String publicId) async {
    final resp = await http.get(
      Uri.parse('$_baseUrl/paciente/usuario/$publicId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (resp.statusCode != 200) {
      throw Exception('Error al cargar paciente: ${resp.statusCode}');
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return Paciente.fromJson(json);
  }

  // Obtiene el UUID del paciente-----------
  Future<String> fetchPublicIdFromInternalId(String idInterno) async {
    final uri = Uri.parse(
      '${_baseUrl.replaceFirst('/api', '/usuarios')}/public-indent/$idInterno',
    );
    final resp = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (resp.statusCode == 200) {
      return resp.body.replaceAll(
        '"',
        '',
      ); // para limpiar las comillas del UUID si vienen en JSON plano
    } else {
      throw Exception('r publicId, cod: ${resp.statusCode}');
    }
  }

  //Método par mandar la notificiación al paciente ----------------------------
  Future<void> enviarNotificacionPuntual({
    required String cuentaUsuarioPublicId,
    required String titulo,
    required String mensaje,
    required String tipoAccion,
    required String accionUrl,
  }) async {
    final uri = Uri.parse(
      '${_baseUrl.replaceFirst('/api', '')}/notificaciones',
    );

    final body = jsonEncode({
      'cuentaUsuarioPublicId': cuentaUsuarioPublicId,
      'tipoNotificacion': 'RESULTADO',
      'titulo': titulo,
      'mensaje': mensaje,
      'tipoAccion': tipoAccion,
      'accion': accionUrl,
    });

    final response = await http.post(uri, headers: _authHeaders, body: body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Error al enviar notificación: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // Subir resultado en PDF
  Future<void> uploadResultadoMedico({
    required List<int> fileBytes,
    required String fileName,
    required String dispositivo,
    required String diagnostico,
    required List<String> genotipos,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/prueba/medico/subir');
    final request =
        http.MultipartRequest('POST', uri)
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              fileBytes,
              filename: fileName,
              contentType: MediaType('application', 'pdf'),
            ),
          )
          ..fields['nombre'] = fileName
          ..fields['dispositivo'] = dispositivo
          ..fields['diagnostico'] = diagnostico
          ..fields['genotipos'] = jsonEncode(genotipos);

    final bearer = html.window.localStorage['jwt'] ?? '';
    if (bearer.isNotEmpty) request.headers['Authorization'] = 'Bearer $bearer';

    final response = await request.send();
    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception(
        'Error al subir resultado: ${response.statusCode} - $body',
      );
    }
  }

  /// Nuevo método para obtener datos del médico por ID
  Future<Map<String, dynamic>> fetchMedicoById(int id) async {
    final resp = await http.get(
      Uri.parse('$_baseUrl/medicos/$id'),
      headers: _authHeaders,
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data;
    }
    throw Exception('Error al obtener médico: ${resp.statusCode}');
  }

  /// Método corregido para guardar código QR
  Future<void> guardarQRConInfo({
    required String codigo,
    required String fechaExpiracion,
  }) async {
    final uri = Uri.parse('$_baseUrl/codigosqr');
    final request =
        http.MultipartRequest('POST', uri)
          ..fields['codigo'] = codigo
          ..fields['fechaExpiracion'] = fechaExpiracion;

    final bearer = html.window.localStorage['jwt'] ?? '';
    if (bearer.isNotEmpty) request.headers['Authorization'] = 'Bearer $bearer';

    final response = await request.send();
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = await response.stream.bytesToString();
      throw Exception(
        'Error al guardar código QR: ${response.statusCode} - $body',
      );
    }
  }

  Future<Map<String, dynamic>> obtenerDispositivos({
    int page = 0,
    int size = 10,
    String estado = 'todos',
    String? desde,
    String? hasta,
  }) async {
    var params = 'page=$page&size=$size';
    if (estado != 'todos') params += '&estado=${Uri.encodeComponent(estado)}';
    if (desde != null) params += '&fechaInicio=$desde';
    if (hasta != null) params += '&fechaFin=$hasta';

    final uri = Uri.parse('$_baseUrl/estado-dispositivos?$params');
    final response = await http.get(uri, headers: _authHeaders);

    if (response.statusCode != 200) {
      throw Exception('Error al cargar dispositivos: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final items = decoded['content'] as List<dynamic>;

    return {
      'content': items.map<EstadoDispositivo>((item) => EstadoDispositivo(
        codigo: item['codigo'] as String,
        estado: item['estado'] as String,
        fechaRegistro: item['fechaRegistro'] != null ? DateTime.parse(item['fechaRegistro'] as String) : null,
        fechaExamen: item['fechaExamen'] != null ? DateTime.parse(item['fechaExamen'] as String) : null,
        fechaResultado: item['fechaResultado'] != null ? DateTime.parse(item['fechaResultado'] as String) : null,
      )).toList(),
      'totalElements': decoded['totalElements'] as int,
    };
  }

  /// Listar códigos QR con su status derivado
  Future<List<Map<String, dynamic>>> obtenerCodigosQR({String? status}) async {
    final uri = Uri.parse(
      '$_baseUrl/codigosqr${(status != null && status != 'todos') ? '?status=$status' : ''}',
    );

    final response = await http.get(uri, headers: _authHeaders);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map<Map<String, dynamic>>((item) {
        return {
          'codigo': item['codigo'],
          'status': item['status'],
          'fechaExpiracion': DateTime.parse(item['fechaExpiracion']),
        };
      }).toList();
    } else {
      throw Exception('Error al cargar códigos QR: ${response.statusCode}');
    }
  }

  /// Listar resultados
  /// Llama a GET /prueba/admin y mapea la respuesta
  Future<List<Map<String, dynamic>>> getResultadosVph() async {
    final backendBase = _baseUrl.replaceFirst(RegExp(r'/api$'), '');
    final uri = Uri.parse('$backendBase/prueba/admin');
    final response = await http.get(uri, headers: _authHeaders);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map<Map<String, dynamic>>((item) {
        return {
          'codigo': item['dispositivo'],
          'diagnostico': item['diagnostico'],
          'genotipos': List<String>.from(item['genotipos'] ?? []),
        };
      }).toList();
    } else {
      throw Exception('Error al cargar resultados VPH: ${response.statusCode}');
    }
  }

  /// Consulta sólo el nombre del paciente a partir del código de dispositivo
  Future<String> fetchPatientNameFromExamenVph(String dispositivoCodigo) async {
    final uri = Uri.parse(
      '${AppConfig.baseUrl}/prueba/medico/nombre/$dispositivoCodigo',
    );
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      return resp.body;
    }
    throw Exception('Error al obtener nombre del paciente: ${resp.statusCode}');
  }

  /// Borra SOLO los campos de contenido, fecha_resultado, nombre, tamano, tipo y diagnostico
  Future<void> clearExamenVphFields(String codigo) async {
    final uri = Uri.parse(
      '${AppConfig.baseUrl}/prueba/medico/clear-fields/$codigo',
    );
    final response = await http.patch(uri, headers: _authHeaders);
    if (response.statusCode != 200) {
      throw Exception(
        'Error al vaciar campos: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Devuelve la lista de prefijos de dispositivo desde el backend.
  Future<List<String>> fetchDevicePrefixes() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/prueba/medico/prefixes');
    final response = await http.get(uri, headers: _authHeaders);
    if (response.statusCode == 200) {
      // Esperamos un JSON como ["010151-", "020202-", ...]
      final List<dynamic> decoded = json.decode(response.body);
      return decoded.map((e) => e.toString()).toList();
    } else {
      throw Exception(
        'Error al cargar prefijos (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Registra una paciente del grupo folleto desde clias-admin.
  Future<void> registrarFolleto(Map<String, dynamic> datos) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/sesion-chat/admin/folleto');
    final response = await http.post(
      uri,
      headers: _authHeaders,
      body: jsonEncode(datos),
    );
    if (response.statusCode != 201) {
      throw Exception(
        'Error al registrar folleto (${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<Uint8List> descargarPdfExamen(String codigoDispositivo) async {
    final backendBase = _baseUrl.replaceFirst(RegExp(r'/api$'), '');
    final uri = Uri.parse('$backendBase/prueba/medico/pdf/$codigoDispositivo');
    final response = await http.get(uri, headers: _authHeaders);
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception('Error al descargar PDF: ${response.statusCode}');
  }
}
