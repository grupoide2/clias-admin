import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:telemedicina_web/models/ocupacion.dart';
import 'package:telemedicina_web/models/rango_tiempo_examen.dart';
import 'package:telemedicina_web/services/catalogo_service.dart';

const _azul = Color(0xFF002856);
const _rojo = Color(0xFFA51008);

/// Preguntas de salud sexual que tienen su propio catálogo de rangos de tiempo.
const _preguntasRango = <String, String>{
  'MENSTRUACION': 'Menstruación',
  'PAPANICOLAOU': 'Papanicolaou',
  'VPH': 'VPH',
};

Future<bool> _confirmarEliminar(BuildContext context, String que) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Eliminar'),
          content: Text('¿Eliminar $que? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar', style: TextStyle(color: _rojo))),
          ],
        ),
      ) ??
      false;
}

class CatalogosPage extends StatelessWidget {
  const CatalogosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          title: const Text('Catálogos', style: TextStyle(color: Colors.white)),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Ocupaciones'),
              Tab(text: 'Rangos de tiempo'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OcupacionesTab(),
            _RangosTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Ocupaciones ─────────────────────────────────────────────────────────────

class _OcupacionesTab extends StatefulWidget {
  const _OcupacionesTab();

  @override
  State<_OcupacionesTab> createState() => _OcupacionesTabState();
}

class _OcupacionesTabState extends State<_OcupacionesTab>
    with WidgetsBindingObserver {
  final _svc = CatalogoService();
  bool _loading = true;
  String? _error;
  List<Ocupacion> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _svc.listarOcupaciones(soloActivas: false);
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

  Future<void> _abrirDialogo({Ocupacion? actual}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _OcupacionDialog(actual: actual, svc: _svc),
    );
    if (ok == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _ErrorReintentar(mensaje: _error!, onReintentar: _cargar);
    }
    return Column(
      children: [
        _BarraAgregar(
          label: 'Agregar ocupación',
          onPressed: () => _abrirDialogo(),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final o = _items[i];
              return ListTile(
                title: Text(
                  o.nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: o.activo ? Colors.black87 : Colors.grey,
                  ),
                ),
                subtitle: Text(
                  '${o.soloUniversidad ? "Solo U. Cuenca" : "Libre"} · orden ${o.orden}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: o.activo,
                      activeThumbColor: _azul,
                      onChanged: (v) async {
                        try {
                          await _svc.actualizarOcupacion(
                            o.publicId,
                            nombre: o.nombre,
                            activo: v,
                            soloUniversidad: o.soloUniversidad,
                            orden: o.orden,
                          );
                          _cargar();
                        } catch (e) {
                          _snack('$e');
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: _azul),
                      onPressed: () => _abrirDialogo(actual: o),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: _rojo),
                      tooltip: 'Eliminar',
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        if (!await _confirmarEliminar(
                            context, 'la ocupación "${o.nombre}"')) {
                          return;
                        }
                        try {
                          await _svc.eliminarOcupacion(o.publicId);
                          _cargar();
                        } catch (e) {
                          messenger
                              .showSnackBar(SnackBar(content: Text('$e')));
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }
}

class _OcupacionDialog extends StatefulWidget {
  const _OcupacionDialog({this.actual, required this.svc});

  final Ocupacion? actual;
  final CatalogoService svc;

  @override
  State<_OcupacionDialog> createState() => _OcupacionDialogState();
}

class _OcupacionDialogState extends State<_OcupacionDialog> {
  late final TextEditingController _nombre;
  late final TextEditingController _orden;
  bool _soloUni = true;
  bool _activo = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final a = widget.actual;
    _nombre = TextEditingController(text: a?.nombre ?? '');
    _orden = TextEditingController(text: (a?.orden ?? 0).toString());
    _soloUni = a?.soloUniversidad ?? true;
    _activo = a?.activo ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _orden.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) return;
    setState(() => _guardando = true);
    try {
      final orden = int.tryParse(_orden.text.trim()) ?? 0;
      if (widget.actual == null) {
        await widget.svc.crearOcupacion(
          nombre: nombre,
          soloUniversidad: _soloUni,
          orden: orden,
        );
      } else {
        await widget.svc.actualizarOcupacion(
          widget.actual!.publicId,
          nombre: nombre,
          activo: _activo,
          soloUniversidad: _soloUni,
          orden: orden,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(widget.actual == null ? 'Nueva ocupación' : 'Editar ocupación'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombre,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _orden,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Orden'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: _azul,
              title: const Text('Solo Universidad de Cuenca'),
              value: _soloUni,
              onChanged: (v) => setState(() => _soloUni = v),
            ),
            if (widget.actual != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: _azul,
                title: const Text('Activo'),
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _rojo, foregroundColor: Colors.white),
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

// ─── Rangos de tiempo ────────────────────────────────────────────────────────

class _RangosTab extends StatefulWidget {
  const _RangosTab();

  @override
  State<_RangosTab> createState() => _RangosTabState();
}

class _RangosTabState extends State<_RangosTab> with WidgetsBindingObserver {
  final _svc = CatalogoService();
  bool _loading = true;
  String? _error;
  List<RangoTiempoExamen> _items = [];

  /// Filtro por pregunta; null = todas.
  String? _pregunta;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _svc.listarRangos(
        pregunta: _pregunta,
        soloActivos: false,
      );
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

  Future<void> _abrirDialogo({RangoTiempoExamen? actual}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _RangoDialog(
        actual: actual,
        svc: _svc,
        preguntaInicial: _pregunta ?? _preguntasRango.keys.first,
      ),
    );
    if (ok == true) _cargar();
  }

  Widget _filtroPreguntas() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Todas'),
            selected: _pregunta == null,
            selectedColor: _azul.withValues(alpha: 0.15),
            onSelected: (_) {
              setState(() => _pregunta = null);
              _cargar();
            },
          ),
          const SizedBox(width: 8),
          for (final e in _preguntasRango.entries) ...[
            ChoiceChip(
              label: Text(e.value),
              selected: _pregunta == e.key,
              selectedColor: _azul.withValues(alpha: 0.15),
              onSelected: (_) {
                setState(() => _pregunta = e.key);
                _cargar();
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BarraAgregar(
          label: 'Agregar rango',
          onPressed: () => _abrirDialogo(),
        ),
        _filtroPreguntas(),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          Expanded(child: _ErrorReintentar(mensaje: _error!, onReintentar: _cargar))
        else
          Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = _items[i];
              return ListTile(
                title: Text(
                  r.etiqueta,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: r.activo ? Colors.black87 : Colors.grey,
                  ),
                ),
                subtitle: Text(
                    '${_preguntasRango[r.pregunta] ?? r.pregunta} · ${r.codigo} · orden ${r.orden}',
                    style: const TextStyle(fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: r.activo,
                      activeThumbColor: _azul,
                      onChanged: (v) async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await _svc.actualizarRango(
                            r.publicId,
                            codigo: r.codigo,
                            etiqueta: r.etiqueta,
                            activo: v,
                            orden: r.orden,
                          );
                          _cargar();
                        } catch (e) {
                          messenger
                              .showSnackBar(SnackBar(content: Text('$e')));
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: _azul),
                      onPressed: () => _abrirDialogo(actual: r),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: _rojo),
                      tooltip: 'Eliminar',
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        if (!await _confirmarEliminar(
                            context, 'el rango "${r.etiqueta}"')) {
                          return;
                        }
                        try {
                          await _svc.eliminarRango(r.publicId);
                          _cargar();
                        } catch (e) {
                          messenger
                              .showSnackBar(SnackBar(content: Text('$e')));
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RangoDialog extends StatefulWidget {
  const _RangoDialog({
    this.actual,
    required this.svc,
    required this.preguntaInicial,
  });

  final RangoTiempoExamen? actual;
  final CatalogoService svc;
  final String preguntaInicial;

  @override
  State<_RangoDialog> createState() => _RangoDialogState();
}

class _RangoDialogState extends State<_RangoDialog> {
  late final TextEditingController _codigo;
  late final TextEditingController _etiqueta;
  late final TextEditingController _orden;
  late String _pregunta;
  bool _activo = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final a = widget.actual;
    _codigo = TextEditingController(text: a?.codigo ?? '');
    _etiqueta = TextEditingController(text: a?.etiqueta ?? '');
    _orden = TextEditingController(text: (a?.orden ?? 0).toString());
    _pregunta = a?.pregunta ?? widget.preguntaInicial;
    _activo = a?.activo ?? true;
  }

  @override
  void dispose() {
    _codigo.dispose();
    _etiqueta.dispose();
    _orden.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final codigo = _codigo.text.trim().toUpperCase();
    final etiqueta = _etiqueta.text.trim();
    if (codigo.isEmpty || etiqueta.isEmpty) return;
    setState(() => _guardando = true);
    try {
      final orden = int.tryParse(_orden.text.trim()) ?? 0;
      if (widget.actual == null) {
        await widget.svc.crearRango(
          pregunta: _pregunta,
          codigo: codigo,
          etiqueta: etiqueta,
          orden: orden,
        );
      } else {
        await widget.svc.actualizarRango(
          widget.actual!.publicId,
          codigo: widget.actual!.codigo,
          etiqueta: etiqueta,
          activo: _activo,
          orden: orden,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esNuevo = widget.actual == null;
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(esNuevo ? 'Nuevo rango de tiempo' : 'Editar rango de tiempo'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (esNuevo)
              DropdownButtonFormField<String>(
                initialValue: _pregunta,
                decoration: const InputDecoration(labelText: 'Pregunta'),
                items: [
                  for (final e in _preguntasRango.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => _pregunta = v ?? _pregunta),
              )
            else
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Pregunta'),
                child: Text(_preguntasRango[_pregunta] ?? _pregunta),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _codigo,
              enabled: esNuevo,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Código',
                helperText: esNuevo
                    ? 'Ej: MENST_3_A_6_MESES (no se puede cambiar luego)'
                    : 'El código es fijo',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _etiqueta,
              decoration: const InputDecoration(
                  labelText: 'Etiqueta', hintText: 'Ej: Entre 3 y 6 meses'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _orden,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Orden'),
            ),
            if (!esNuevo)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: _azul,
                title: const Text('Activo'),
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _rojo, foregroundColor: Colors.white),
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

// ─── Compartidos ─────────────────────────────────────────────────────────────

class _BarraAgregar extends StatelessWidget {
  const _BarraAgregar({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _rojo,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.add),
          label: Text(label),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _ErrorReintentar extends StatelessWidget {
  const _ErrorReintentar({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(mensaje, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onReintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
