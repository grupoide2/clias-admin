import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:telemedicina_web/models/recurso_multimedia.dart';
import 'package:telemedicina_web/services/recurso_service.dart';

const _azul = Color(0xFF002856);
const _rojo = Color(0xFFA51008);
const _verde = Color(0xFF1B7A3D);

/// Definición estática de un recurso conocido: sirve para que el admin sepa
/// para quién es y en qué pantalla se usa, y para prellenar el formulario.
class _RecursoDef {
  final String slug;
  final String destino; // APP | WEB
  final String categoria;
  final String tipo; // VIDEO | IMAGEN
  final String descripcion;
  const _RecursoDef(
      this.slug, this.destino, this.categoria, this.tipo, this.descripcion);
}

const _manifiesto = <_RecursoDef>[
  // ── clias-app (SISA) ──────────────────────────────────────────────────────
  _RecursoDef('video_uso_app', 'APP', 'Video de uso', 'VIDEO',
      'Video guía del automuestreo — se muestra en el chatbot y en el dashboard de la app.'),
  _RecursoDef('app_video_automuestreo', 'APP', 'Video educativo', 'VIDEO',
      'Video "Automuestreo" — carrusel de la pantalla Recursos de la app.'),
  _RecursoDef('app_video_ccu', 'APP', 'Video educativo', 'VIDEO',
      'Video "VPH y cáncer de cuello cervical" — pantalla Recursos.'),
  _RecursoDef('app_video_higiene_intima', 'APP', 'Video educativo', 'VIDEO',
      'Video "Autocuidado de la higiene íntima" — pantalla Recursos.'),
  _RecursoDef('app_video_violencia', 'APP', 'Video educativo', 'VIDEO',
      'Video "Violencia de género" — pantalla Recursos.'),
  _RecursoDef('app_video_preservativos', 'APP', 'Video educativo', 'VIDEO',
      'Video "Uso de preservativos" — pantalla Recursos.'),
  _RecursoDef('blog_automuestreo', 'APP', 'Portada de blog', 'IMAGEN',
      'Portada del blog "Automuestreo" — pantalla Recursos.'),
  _RecursoDef('blog_vph', 'APP', 'Portada de blog', 'IMAGEN',
      'Portada del blog "VPH y cáncer de cuello cervical".'),
  _RecursoDef('blog_ccu', 'APP', 'Portada de blog', 'IMAGEN',
      'Portada del blog "Cáncer de cuello uterino".'),
  _RecursoDef('blog_embarazo_seguro', 'APP', 'Portada de blog', 'IMAGEN',
      'Portada del blog "Embarazo seguro".'),
  _RecursoDef('blog_higiene_intima', 'APP', 'Portada de blog', 'IMAGEN',
      'Portada del blog "Higiene íntima".'),
  _RecursoDef('blog_violencia_genero', 'APP', 'Portada de blog', 'IMAGEN',
      'Portada del blog "Violencia de género".'),
  _RecursoDef('blog_its', 'APP', 'Portada de blog', 'IMAGEN',
      'Portada del blog "Infección de transmisión sexual".'),
  _RecursoDef('blog_infertilidad', 'APP', 'Portada de blog', 'IMAGEN',
      'Portada del blog "Infertilidad".'),
  _RecursoDef('blog_prevencion_embarazo', 'APP', 'Portada de blog', 'IMAGEN',
      'Portada del blog "Prevención de embarazo".'),
  _RecursoDef('blog_salud_sexual', 'APP', 'Portada de blog', 'IMAGEN',
      'Portada del blog "Salud sexual".'),
  _RecursoDef('blog_vih', 'APP', 'Portada de blog', 'IMAGEN',
      'Portada del blog "VIH".'),
  // ── clias-web (sitio público) ────────────────────────────────────────────
  _RecursoDef('web_video_portada_automuestreo', 'WEB', 'Video de portada', 'VIDEO',
      'Video del automuestreo en la portada del sitio (index).'),
  _RecursoDef('web_video_portada_ccu', 'WEB', 'Video de portada', 'VIDEO',
      'Video "VPH y cáncer de cuello uterino" en la portada del sitio.'),
  _RecursoDef('web_video_faq_actualizar', 'WEB', 'Video instructivo', 'VIDEO',
      'Cómo actualizar la app — página Preguntas frecuentes.'),
  _RecursoDef('web_video_faq_usar', 'WEB', 'Video instructivo', 'VIDEO',
      'Cómo usar la app — página Preguntas frecuentes.'),
  _RecursoDef('captura_web_1', 'WEB', 'Captura de la app', 'IMAGEN',
      'Captura de SISA en el carrusel de la portada y la página del proyecto.'),
  _RecursoDef('captura_web_2', 'WEB', 'Captura de la app', 'IMAGEN',
      'Captura de SISA en el carrusel de la portada y la página del proyecto.'),
  _RecursoDef('captura_web_3', 'WEB', 'Captura de la app', 'IMAGEN',
      'Captura de SISA en el carrusel de la portada y la página del proyecto.'),
  _RecursoDef('captura_web_4', 'WEB', 'Captura de la app', 'IMAGEN',
      'Captura de SISA en el carrusel de la portada y la página del proyecto.'),
  _RecursoDef('captura_web_5', 'WEB', 'Captura de la app', 'IMAGEN',
      'Captura de SISA en el carrusel de la portada y la página del proyecto.'),
  _RecursoDef('captura_web_6', 'WEB', 'Captura de la app', 'IMAGEN',
      'Captura de SISA en el carrusel de la página del proyecto.'),
  _RecursoDef('captura_web_7', 'WEB', 'Captura de la app', 'IMAGEN',
      'Captura de SISA en el carrusel de la portada.'),
  _RecursoDef('captura_web_8', 'WEB', 'Captura de la app', 'IMAGEN',
      'Captura de SISA en el carrusel de la página del proyecto.'),
];

const _destinoLabel = {'APP': 'App SISA', 'WEB': 'Sitio web'};

class RecursosPage extends StatefulWidget {
  const RecursosPage({super.key});

  @override
  State<RecursosPage> createState() => _RecursosPageState();
}

class _RecursosPageState extends State<RecursosPage> {
  final _svc = RecursoService();
  bool _loading = true;
  bool _subiendo = false;
  String? _error;
  List<RecursoMultimedia> _items = [];

  // Formulario de subida
  final _slugCtrl = TextEditingController(text: 'video_uso_app');
  final _categoriaCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  String _tipo = 'VIDEO';
  String _destino = 'APP';

  @override
  void initState() {
    super.initState();
    _prefillDesde(_manifiesto.first);
    _cargar();
  }

  @override
  void dispose() {
    _slugCtrl.dispose();
    _categoriaCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  void _prefillDesde(_RecursoDef d) {
    _slugCtrl.text = d.slug;
    _tipo = d.tipo;
    _destino = d.destino;
    _categoriaCtrl.text = d.categoria;
    _descripcionCtrl.text = d.descripcion;
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _svc.listar();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  RecursoMultimedia? _subidoPara(String slug) {
    for (final r in _items) {
      if (r.slug == slug) return r;
    }
    return null;
  }

  Future<void> _subir() async {
    final slug = _slugCtrl.text.trim();
    if (slug.isEmpty) return;
    setState(() => _subiendo = true);
    try {
      final picked = await RecursoService.pickFile(_tipo == 'VIDEO');
      if (picked == null) return;
      if (picked.bytes.length > 60 * 1024 * 1024) {
        throw Exception(
            'El archivo pesa ${_kb(picked.bytes.length)}; el máximo permitido es 60 MB.');
      }
      await _svc.subir(
        slug: slug,
        tipo: _tipo,
        destino: _destino,
        categoria: _categoriaCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        bytes: picked.bytes,
        filename: picked.name,
        contentType: picked.type,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Recurso "$slug" subido correctamente')));
      }
      await _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  String _kb(int b) => b < 1024 * 1024
      ? '${(b / 1024).toStringAsFixed(0)} KB'
      : '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _azul,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Material(
            color: _rojo,
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacementNamed('/home');
                }
              },
            ),
          ),
        ),
        title: const Text('Recursos multimedia',
            style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormularioSubida(),
                const Divider(height: 40),
                _buildCatalogo(),
                const Divider(height: 40),
                const Text('Recursos subidos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (_loading)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator()))
                else if (_error != null)
                  Column(children: [
                    Text(_error!),
                    const SizedBox(height: 8),
                    ElevatedButton(
                        onPressed: _cargar, child: const Text('Reintentar')),
                  ])
                else if (_items.isEmpty)
                  const Text('Aún no hay recursos subidos.',
                      style: TextStyle(color: Colors.grey))
                else
                  ..._items.map(_buildFila),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormularioSubida() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCCCCCC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Subir / reemplazar recurso',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
              'Elige un recurso del catálogo de abajo o escribe un slug propio.',
              style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _slugCtrl,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_\-]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Slug (identificador)',
                    helperText: 'p. ej. video_uso_app, blog_vph, captura_web_1',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _destino,
                  decoration: const InputDecoration(
                      labelText: 'Destino', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'APP', child: Text('App SISA')),
                    DropdownMenuItem(value: 'WEB', child: Text('Sitio web')),
                  ],
                  onChanged: (v) => setState(() => _destino = v ?? 'APP'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _tipo,
                  decoration: const InputDecoration(
                      labelText: 'Tipo', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'VIDEO', child: Text('VIDEO')),
                    DropdownMenuItem(value: 'IMAGEN', child: Text('IMAGEN')),
                  ],
                  onChanged: (v) => setState(() => _tipo = v ?? 'VIDEO'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _categoriaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    hintText: 'Video educativo, Portada de blog…',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _descripcionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (para quién / en qué pantalla)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: _rojo, foregroundColor: Colors.white),
            icon: _subiendo
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.upload_file),
            label: Text(_subiendo ? 'Subiendo…' : 'Elegir archivo y subir'),
            onPressed: _subiendo ? null : _subir,
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogo() {
    final grupos = <String, List<_RecursoDef>>{};
    for (final d in _manifiesto) {
      grupos.putIfAbsent(d.destino, () => []).add(d);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Catálogo de recursos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
            'Verde = ya tiene archivo subido · Gris = usa el archivo embebido en la app/sitio.',
            style: TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 12),
        for (final destino in grupos.keys) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: Text(_destinoLabel[destino] ?? destino,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _azul,
                    letterSpacing: 0.5)),
          ),
          ...grupos[destino]!.map(_buildCatalogoItem),
        ],
      ],
    );
  }

  Widget _buildCatalogoItem(_RecursoDef d) {
    final subido = _subidoPara(d.slug);
    final ya = subido != null;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        leading: Icon(d.tipo == 'VIDEO' ? Icons.movie : Icons.image,
            color: ya ? _verde : Colors.grey),
        title: Row(
          children: [
            Flexible(
                child: Text(d.slug,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13))),
            const SizedBox(width: 8),
            _chip(d.categoria, Colors.blueGrey),
            const SizedBox(width: 6),
            _chip(ya ? 'subido' : 'embebido', ya ? _verde : Colors.grey),
          ],
        ),
        subtitle: Text(d.descripcion, style: const TextStyle(fontSize: 12)),
        trailing: TextButton(
          onPressed: () => setState(() => _prefillDesde(d)),
          child: Text(ya ? 'Reemplazar' : 'Subir'),
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      );

  Widget _buildFila(RecursoMultimedia r) {
    final enManifiesto = _manifiesto.any((d) => d.slug == r.slug);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          r.tipo == 'VIDEO' ? Icons.movie : Icons.image,
          color: r.activo ? _azul : Colors.grey,
        ),
        title: Row(
          children: [
            Flexible(
                child: Text(r.slug,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: r.activo ? Colors.black87 : Colors.grey))),
            const SizedBox(width: 8),
            _chip(_destinoLabel[r.destino] ?? r.destino, _azul),
            if (r.categoria != null && r.categoria!.isNotEmpty) ...[
              const SizedBox(width: 6),
              _chip(r.categoria!, Colors.blueGrey),
            ],
            if (!enManifiesto) ...[
              const SizedBox(width: 6),
              _chip('personalizado', _rojo),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (r.descripcion != null && r.descripcion!.isNotEmpty)
              Text(r.descripcion!, style: const TextStyle(fontSize: 12)),
            Text(
                '${r.nombreArchivo} · ${_kb(r.tamano)} · ${r.contentType} · orden ${r.orden}',
                style: const TextStyle(fontSize: 11, color: Colors.black45)),
          ],
        ),
        isThreeLine:
            r.descripcion != null && r.descripcion!.isNotEmpty,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: r.activo,
              activeThumbColor: _azul,
              onChanged: (v) async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await _svc.actualizarMeta(r.publicId,
                      activo: v, orden: r.orden);
                  await _cargar();
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('$e')));
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: _rojo),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: Colors.white,
                    title: const Text('Eliminar recurso'),
                    content: Text('¿Eliminar "${r.slug}" y su archivo?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar')),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Eliminar')),
                    ],
                  ),
                );
                if (ok == true) {
                  try {
                    await _svc.eliminar(r.publicId);
                    await _cargar();
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
