import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;
import 'package:telemedicina_web/config/env.dart';
import 'package:telemedicina_web/models/metrica_dashboard.dart';

class MetricaService {
  final String _base = AppConfig.baseUrl;

  Map<String, String> get _authHeader {
    final token = html.window.localStorage['jwt'] ?? '';
    return token.isEmpty ? {} : {'Authorization': 'Bearer $token'};
  }

  Future<MetricaDashboard> dashboard() async {
    final resp = await http.get(
      Uri.parse('$_base/metricas/dashboard'),
      headers: _authHeader,
    );
    if (resp.statusCode == 200) {
      return MetricaDashboard.fromJson(
          jsonDecode(resp.body) as Map<String, dynamic>);
    }
    throw Exception('Error al cargar el dashboard (${resp.statusCode})');
  }
}
