import 'package:flutter/material.dart';
import 'package:telemedicina_web/services/auth_service.dart';
import 'package:telemedicina_web/models/profile.dart';

const _azul = Color(0xFF002856);
const _rojo = Color(0xFFA51008);
const _borde = Color(0xFFE2E6EC);
const _fondo = Color(0xFFF6F8FB);
const _slate = Color(0xFF64748B);

class _MenuItem {
  final IconData icon;
  final String title;
  final String desc;
  final String route;
  const _MenuItem(this.icon, this.title, this.desc, this.route);
}

class _MenuGroup {
  final String label;
  final List<_MenuItem> items;
  const _MenuGroup(this.label, this.items);
}

const _menuAdmin = [
  _MenuGroup('Operación diaria', [
    _MenuItem(Icons.insights, 'Dashboard de uso',
        'Indicadores de uso de la app y del chatbot', '/admin/dashboard'),
    _MenuItem(Icons.devices_other, 'Status de dispositivos',
        'Seguimiento de los kits registrados y su estado', '/admin/results'),
    _MenuItem(Icons.qr_code_2, 'Generación de códigos',
        'Crea lotes de códigos QR para los kits', '/admin/codes'),
    _MenuItem(Icons.assignment_ind, 'Registrar automuestreo (folleto)',
        'Alta manual de pacientes del grupo folleto', '/admin/folleto'),
  ]),
  _MenuGroup('Configuración', [
    _MenuItem(Icons.group, 'Gestionar usuarios',
        'Administradores y médicos del sistema', '/admin/users'),
    _MenuItem(Icons.place, 'Servicios relacionados',
        'Centros de salud, protección y atención psicológica',
        '/admin/ubicaciones'),
    _MenuItem(Icons.list_alt, 'Catálogos',
        'Ocupaciones y rangos de tiempo de examen', '/admin/catalogos'),
    _MenuItem(Icons.perm_media, 'Recursos multimedia',
        'Video de uso de la app y capturas del sitio web', '/admin/recursos'),
  ]),
];

const _menuDoctor = [
  _MenuGroup('Resultados', [
    _MenuItem(Icons.note_add, 'Ingresar resultado',
        'Subir el resultado de una prueba de una paciente', '/doctor/search'),
    _MenuItem(Icons.folder_open, 'Ver resultados',
        'Historial de resultados ya cargados', '/doctor/resultados'),
  ]),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = AuthService();
  bool _loading = true;
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prof = await _auth.fetchProfile();
      setState(() {
        _profile = prof;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  void _logout() => Navigator.pushReplacementNamed(context, '/login');

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _fondo,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final prof = _profile!;
    final grupos = prof.role == 'ADMIN'
        ? _menuAdmin
        : prof.role == 'DOCTOR'
            ? _menuDoctor
            : const <_MenuGroup>[];

    return Scaffold(
      backgroundColor: _fondo,
      body: SafeArea(
        child: Column(
          children: [
            _header(prof),
            Expanded(
              child: grupos.isEmpty
                  ? const Center(
                      child: Text('Rol desconocido',
                          style: TextStyle(color: _slate)))
                  : _cuerpo(prof, grupos),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _header(Profile prof) {
    return Container(
      decoration: const BoxDecoration(
        color: _azul,
        boxShadow: [
          BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          Image.asset('assets/images/logoucuencaprincipal.png', height: 38),
          const SizedBox(width: 14),
          Container(width: 1, height: 28, color: Colors.white24),
          const SizedBox(width: 14),
          const Text('Panel administrativo',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2)),
          const Spacer(),
          Text('¡Bienvenido/a ${prof.nombre}!',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Cerrar sesión',
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Cuerpo ────────────────────────────────────────────────────────────────

  Widget _cuerpo(Profile prof, List<_MenuGroup> grupos) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final tileW = ancho < 560 ? ancho - 48 : 268.0;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prof.role == 'ADMIN' ? 'Administración' : 'Panel médico',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _azul),
                  ),
                  const SizedBox(height: 4),
                  const Text('Selecciona una sección para continuar',
                      style: TextStyle(color: _slate, fontSize: 13)),
                  const SizedBox(height: 24),
                  for (final g in grupos) ...[
                    Text(g.label.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: _slate)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (final it in g.items)
                          _MenuTile(item: it, width: tileW),
                      ],
                    ),
                    const SizedBox(height: 28),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MenuTile extends StatefulWidget {
  const _MenuTile({required this.item, required this.width});

  final _MenuItem item;
  final double width;

  @override
  State<_MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<_MenuTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: widget.width,
        height: 168,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _hover ? _azul : _borde),
          boxShadow: _hover
              ? const [
                  BoxShadow(
                      color: Color(0x1A002856),
                      blurRadius: 16,
                      offset: Offset(0, 6)),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.pushNamed(context, it.route),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _azul.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(it.icon, color: _azul, size: 22),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_forward,
                          size: 18, color: _hover ? _rojo : _borde),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(it.title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _azul),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(it.desc,
                        style: const TextStyle(fontSize: 12, color: _slate),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
