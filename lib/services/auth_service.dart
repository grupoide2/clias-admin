// auth_service.dart
import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:telemedicina_web/models/profile.dart';
import 'package:telemedicina_web/config/env.dart';

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  Profile? _profile;

  final String _baseUrl = '${AppConfig.baseUrl}/api';

  // Iniciar sesión
  Future<bool> login(String usuario, String contrasena) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'usuario': usuario, 'contrasena': contrasena}),
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;

      // Guardar token JWT en localStorage para que api_service lo use en cada request
      final token = data['token'] as String?;
      if (token != null && token.isNotEmpty) {
        html.window.localStorage['jwt'] = token;
      }

      _profile = Profile(
        nombre: data['nombre'] as String,
        username: data['usuario'] as String,
        role: data['role'] as String,
      );

      html.window.localStorage['profile_nombre']   = _profile!.nombre;
      html.window.localStorage['profile_username'] = _profile!.username;
      html.window.localStorage['profile_role']     = _profile!.role;

      return true;
    } else {
      return false;
    }
  }

  // Obtener el perfil del usuario
  Future<Profile> fetchProfile() async {
    if (_profile != null) return _profile!;

    // Recuperar desde localStorage si la página fue refrescada
    final nombre   = html.window.localStorage['profile_nombre'];
    final username = html.window.localStorage['profile_username'];
    final role     = html.window.localStorage['profile_role'];
    final jwt      = html.window.localStorage['jwt'];

    if (nombre != null && username != null && role != null && jwt != null) {
      _profile = Profile(nombre: nombre, username: username, role: role);
      return _profile!;
    }

    throw Exception('Perfil no cargado');
  }

  // Logout
  void logout() {
    _profile = null;
    html.window.localStorage.remove('jwt');
    html.window.localStorage.remove('profile_nombre');
    html.window.localStorage.remove('profile_username');
    html.window.localStorage.remove('profile_role');
  }
}
