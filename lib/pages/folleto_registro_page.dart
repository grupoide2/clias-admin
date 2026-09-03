import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:telemedicina_web/services/api_service.dart';
import 'package:telemedicina_web/services/catalogo_service.dart';

class FolletoRegistroPage extends StatefulWidget {
  const FolletoRegistroPage({Key? key}) : super(key: key);

  @override
  State<FolletoRegistroPage> createState() => _FolletoRegistroPageState();
}

class _FolletoRegistroPageState extends State<FolletoRegistroPage>
    with WidgetsBindingObserver {
  int _paso = 0;
  bool _enviando = false;
  String? _error;

  // ── Paso 1: datos de la paciente ──────────────────────────────────────────
  final _formPaso1 = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _fechaNacCtrl = TextEditingController();
  String _pais = 'ECUADOR';
  String _zona = 'RURAL';
  String _idioma = 'ESPAÑOL';
  String _estadoCivil = 'SOLTERO/A';
  String _sexo = 'FEMENINO';

  // ── Paso 2: aptitud + salud sexual ────────────────────────────────────────
  final _formPaso2 = GlobalKey<FormState>();

  // Aptitud (null = sin responder)
  bool? _edadApta;
  bool? _vidaSexual;
  bool? _relacionesRecientes;   // descalifica si true
  bool? _consentimiento;
  bool? _espanol;
  bool? _embarazada;            // descalifica si true
  bool? _tratamiento;           // descalifica si true
  bool? _medicamento;           // descalifica si true
  bool? _menstruando;

  // Salud sexual
  final _fechaMenstrCtrl = TextEditingController();
  // "¿Hace cuánto fue el primer día de tu última menstruación?"
  // — su propio catálogo (pregunta = MENSTRUACION) + la opción FECHA_EXACTA.
  String _hacecuantoMenstruacion = 'FECHA_EXACTA';
  String _ultimoPap = 'PAP_MENOS_1_ANIO';
  String _ultimoVph = 'VPH_MENOS_1_ANIO';
  final _parejasCtrl = TextEditingController();
  String _tieneEts = 'NO';
  String? _nombreEts;

  // ── Información socioeconómica ────────────────────────────────────────────
  String _ingresos = 'MENOR_450';
  String _perteneceUni = 'NO';
  String _ocupacionUni = 'DOCENTE';
  final _ocupacionLibreCtrl = TextEditingController();

  // ── Paso 3: dispositivo QR ────────────────────────────────────────────────
  final _formPaso3 = GlobalKey<FormState>();
  final _dispositivoCtrl = TextEditingController();
  DateTime _fechaRegistro = DateTime.now();
  DateTime _fechaExamen = DateTime.now();

  // ── Catálogos ─────────────────────────────────────────────────────────────
  static const _paises = ['ECUADOR','COLOMBIA','VENEZUELA','PERU','CHILE','ARGENTINA','BOLIVIA','URUGUAY','BRAZIL'];
  static const _zonas = ['RURAL','URBANA'];
  static const _idiomas = ['ESPAÑOL','INGLÉS','OTRO'];
  static const _estadosCiviles = ['SOLTERO/A','CASADO/A','DIVORCIADO/A','VIUDO/A','UNIÓN LIBRE'];
  static const _sexos = ['FEMENINO','MASCULINO','OTRO'];
  // Cada pregunta de salud sexual tiene su propio catálogo (rango_tiempo_examen,
  // filtrado por `pregunta`). Estos mapas son solo el fallback embebido si no hay red.
  static const _papFallback = {
    'PAP_MENOS_1_ANIO': 'Menos de 1 año',
    'PAP_1_A_3_ANIOS': 'De 1 a 3 años',
    'PAP_MAS_3_ANIOS': 'Más de 3 años',
    'PAP_NUNCA': 'Nunca',
  };
  static const _vphFallback = {
    'VPH_MENOS_1_ANIO': 'Menos de 1 año',
    'VPH_1_A_3_ANIOS': 'De 1 a 3 años',
    'VPH_MAS_3_ANIOS': 'Más de 3 años',
    'VPH_NUNCA': 'Nunca',
  };
  static const _menstruacionFallback = {
    'MENST_3_A_6_MESES': 'Entre 3 y 6 meses',
    'MENST_6_A_12_MESES': 'Entre 6 y 12 meses',
    'MENST_MAS_12_MESES': 'Más de 12 meses',
  };
  // Opción fija adicional de la pregunta de menstruación (no viene del catálogo).
  static const _menstruacionFechaExacta = 'FECHA_EXACTA';
  static const _opcionesEts = ['SI','NO','NOSE'];
  static const _opcionesEtsLabel = {'SI': 'Sí', 'NO': 'No', 'NOSE': 'No sé'};
  static const _nombresEts = ['VPH','Clamidia','Gonorrea','Sifilis','Herpes','VIH/SIDA','Tricomona','Otra'];

  static const _ingresosOpciones = ['MENOR_450','ENTRE_450_900','ENTRE_901_1350','MAYOR_1350'];
  static const _ingresosLabel = {
    'MENOR_450': 'Menos de \$450',
    'ENTRE_450_900': '\$450 – \$900',
    'ENTRE_901_1350': '\$901 – \$1350',
    'MAYOR_1350': 'Más de \$1350',
  };
  static const _perteneceOpciones = ['SI','NO'];
  static const _ocupacionesUniFallback = [
    'CONTRATO DE SERVICIO','TRABAJADORA','EMPLEADA','SERVICIOS PROFESIONALES','DOCENTE','ADMINISTRATIVA',
  ];

  // Catálogo de ocupaciones (con fallback embebido)
  final _catalogoSvc = CatalogoService();
  List<String> _ocupacionesUni = List.of(_ocupacionesUniFallback);

  // Catálogos de rangos de tiempo por pregunta (con fallback embebido).
  List<String> _papCodes = _papFallback.keys.toList();
  Map<String, String> _papLabels = Map.of(_papFallback);
  List<String> _vphCodes = _vphFallback.keys.toList();
  Map<String, String> _vphLabels = Map.of(_vphFallback);
  List<String> _menstruacionCodes = _menstruacionFallback.keys.toList();
  Map<String, String> _menstruacionLabels = Map.of(_menstruacionFallback);

  // ── Colores corporativos ──────────────────────────────────────────────────
  static const _azul = Color(0xFF002856);
  static const _rojo = Color(0xFFA51008);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarCatalogos();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver a esta pestaña se recargan los catálogos por si el admin agregó
    // una ocupación / rango mientras el formulario ya estaba abierto.
    if (state == AppLifecycleState.resumed) {
      _cargarCatalogos();
    }
  }

  Future<void> _cargarCatalogos() async {
    await _cargarOcupaciones();
    await _cargarRangos();
  }

  Future<void> _cargarOcupaciones() async {
    try {
      final ocupaciones = await _catalogoSvc.listarOcupaciones(soloActivas: true);
      if (!mounted) return;
      setState(() {
        final soloUni = ocupaciones
            .where((o) => o.soloUniversidad)
            .map((o) => o.nombre)
            .toList();
        if (soloUni.isNotEmpty) {
          _ocupacionesUni = soloUni;
          if (!_ocupacionesUni.contains(_ocupacionUni)) {
            _ocupacionUni = _ocupacionesUni.first;
          }
        }
      });
    } catch (_) {
      // Sin red / error: se mantiene el fallback embebido de ocupaciones.
    }
  }

  Future<void> _cargarRangos() async {
    try {
      final pap = await _catalogoSvc.listarRangos(
          pregunta: 'PAPANICOLAOU', soloActivos: true);
      final vph = await _catalogoSvc.listarRangos(
          pregunta: 'VPH', soloActivos: true);
      final menst = await _catalogoSvc.listarRangos(
          pregunta: 'MENSTRUACION', soloActivos: true);
      if (!mounted) return;
      setState(() {
        if (pap.isNotEmpty) {
          _papCodes = pap.map((r) => r.codigo).toList();
          _papLabels = {for (final r in pap) r.codigo: r.etiqueta};
          if (!_papCodes.contains(_ultimoPap)) _ultimoPap = _papCodes.first;
        }
        if (vph.isNotEmpty) {
          _vphCodes = vph.map((r) => r.codigo).toList();
          _vphLabels = {for (final r in vph) r.codigo: r.etiqueta};
          if (!_vphCodes.contains(_ultimoVph)) _ultimoVph = _vphCodes.first;
        }
        if (menst.isNotEmpty) {
          _menstruacionCodes = menst.map((r) => r.codigo).toList();
          _menstruacionLabels = {for (final r in menst) r.codigo: r.etiqueta};
          if (_hacecuantoMenstruacion != _menstruacionFechaExacta &&
              !_menstruacionCodes.contains(_hacecuantoMenstruacion)) {
            _hacecuantoMenstruacion = _menstruacionFechaExacta;
          }
        }
      });
    } catch (_) {
      // Sin red / error: se mantienen los fallbacks embebidos.
    }
  }

  /// Opciones de la pregunta de menstruación = catálogo + "Escribir la fecha exacta".
  List<String> get _menstruacionOpciones =>
      [..._menstruacionCodes, _menstruacionFechaExacta];
  Map<String, String> get _menstruacionOpcionesLabel =>
      {..._menstruacionLabels, _menstruacionFechaExacta: 'Escribir la fecha exacta'};

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _telefonoCtrl.dispose();
    _fechaNacCtrl.dispose();
    _fechaMenstrCtrl.dispose();
    _parejasCtrl.dispose();
    _dispositivoCtrl.dispose();
    _ocupacionLibreCtrl.dispose();
    super.dispose();
  }

  // ── Verificación de aptitud ───────────────────────────────────────────────

  String? _motivoExclusion() {
    if (_edadApta == false)          return 'La paciente no está en el rango de edad requerido (30–65 años).';
    if (_vidaSexual == false)        return 'La paciente no cumple el criterio de vida sexual activa.';
    if (_relacionesRecientes == true) return 'La paciente tuvo relaciones sexuales en las últimas 48 horas.';
    if (_consentimiento == false)    return 'La paciente no dio su consentimiento para participar.';
    if (_espanol == false)           return 'La paciente no puede comunicarse en español.';
    if (_embarazada == true)         return 'La paciente está embarazada.';
    if (_tratamiento == true)        return 'La paciente tuvo tratamiento cervical en los últimos 6 meses.';
    if (_medicamento == true)        return 'La paciente utilizó medicamento intravaginal en la última semana.';
    return null;
  }

  bool get _todasAptitudRespondidas =>
      _edadApta != null &&
      _vidaSexual != null &&
      _relacionesRecientes != null &&
      _consentimiento != null &&
      _espanol != null &&
      _embarazada != null &&
      _tratamiento != null &&
      _medicamento != null &&
      _menstruando != null;

  // ── Envío final ───────────────────────────────────────────────────────────

  Future<void> _enviar() async {
    if (!(_formPaso3.currentState?.validate() ?? false)) return;

    setState(() { _enviando = true; _error = null; });

    final payload = <String, dynamic>{
      'nombre': _nombreCtrl.text.trim(),
      'apellido': _apellidoCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim(),
      'fechaNacimiento': _fechaNacCtrl.text.trim(),
      'pais': _pais,
      'zonaResidencial': _zona,
      'lenguaMaterna': _idioma,
      'estadoCivil': _estadoCivil,
      'sexo': _sexo,
      'saludSexual': {
        'estaEmbarazada': false,
        'fechaUltimaMenstruacion':
            _hacecuantoMenstruacion == _menstruacionFechaExacta
                ? _fechaMenstrCtrl.text.trim()
                : _menstruacionOpcionesLabel[_hacecuantoMenstruacion],
        'ultimoExamenPap': _ultimoPap,
        'tiempoPruebaVph': _ultimoVph,
        'numParejasSexuales': int.tryParse(_parejasCtrl.text.trim()) ?? 0,
        'tieneEts': _tieneEts,
        'nombreEts': _tieneEts == 'SI' ? _nombreEts : null,
        'estaMenstruando': _menstruando == true ? 'SI' : 'NO',
      },
      'informacionSocioeconomica': {
        'ingresos': _ingresos,
        'dependenciaUniversitaria': _perteneceUni,
        'ocupacion': _perteneceUni == 'SI'
            ? _ocupacionUni
            : _ocupacionLibreCtrl.text.trim(),
      },
      'dispositivo': _dispositivoCtrl.text.trim(),
      'fechaExamen': _fechaExamen.toIso8601String(),
      'fechaRegistro': _fechaRegistro.toIso8601String(),
    };

    try {
      await ApiService().registrarFolleto(payload);
      if (mounted) {
        _mostrarExito();
        _limpiarFormulario();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _limpiarFormulario() {
    _nombreCtrl.clear();
    _apellidoCtrl.clear();
    _telefonoCtrl.clear();
    _fechaNacCtrl.clear();
    _fechaMenstrCtrl.clear();
    _parejasCtrl.clear();
    _dispositivoCtrl.clear();
    _ocupacionLibreCtrl.clear();
    setState(() {
      _paso = 0;
      _pais = 'ECUADOR'; _zona = 'RURAL'; _idioma = 'ESPAÑOL';
      _estadoCivil = 'SOLTERO/A'; _sexo = 'FEMENINO';
      _edadApta = null; _vidaSexual = null; _relacionesRecientes = null;
      _consentimiento = null; _espanol = null; _embarazada = null;
      _tratamiento = null; _medicamento = null; _menstruando = null;
      _hacecuantoMenstruacion = _menstruacionFechaExacta;
      _ultimoPap = _papCodes.isNotEmpty ? _papCodes.first : 'PAP_MENOS_1_ANIO';
      _ultimoVph = _vphCodes.isNotEmpty ? _vphCodes.first : 'VPH_MENOS_1_ANIO';
      _tieneEts = 'NO'; _nombreEts = null;
      _ingresos = 'MENOR_450';
      _perteneceUni = 'NO';
      _ocupacionUni = _ocupacionesUni.contains('DOCENTE') ? 'DOCENTE' : _ocupacionesUni.first;
      _error = null;
      _fechaRegistro = DateTime.now();
      _fechaExamen = DateTime.now();
    });
  }

  void _mostrarExito() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registro exitoso'),
        content: const Text('La paciente del grupo folleto fue registrada correctamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
            color: const Color(0xFFA51008),
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/images/logoucuencaprincipal.png',
                  height: 32,
                ),
                const SizedBox(width: 8),
              ],
            ),
            const Text(
              'Registrar Automuestreo — Grupo Folleto',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Recargar catálogos (ocupaciones y rangos)',
            onPressed: _cargarCatalogos,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              _buildIndicadorPasos(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildPasoActual(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicadorPasos() {
    const pasos = [
      'Datos\npaciente',
      'Información\nsocioeconómica',
      'Aptitud\n& Salud',
      'Dispositivo\nQR',
    ];
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(pasos.length, (i) {
          final activo = i == _paso;
          final completado = i < _paso;
          return Row(
            children: [
              if (i > 0)
                Container(width: 40, height: 2,
                    color: completado ? _azul : Colors.grey[300]),
              Column(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: activo || completado ? _azul : Colors.grey[300],
                    child: completado
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text('${i + 1}',
                            style: TextStyle(
                              color: activo ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            )),
                  ),
                  const SizedBox(height: 4),
                  Text(pasos[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: activo ? _azul : Colors.grey[600],
                        fontWeight: activo ? FontWeight.bold : FontWeight.normal,
                      )),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPasoActual() {
    switch (_paso) {
      case 0: return _buildPaso1();
      case 1: return _buildPasoSocioeconomico();
      case 2: return _buildPaso2();
      case 3: return _buildPaso3();
      default: return const SizedBox.shrink();
    }
  }

  // ── PASO 1: datos demográficos ────────────────────────────────────────────

  Widget _buildPaso1() {
    return Form(
      key: _formPaso1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titulo('Datos de la paciente'),
          _subtitulo('Complete la información personal de la paciente.'),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _campo('Nombre*', _nombreCtrl, requerido: true)),
            const SizedBox(width: 16),
            Expanded(child: _campo('Apellido*', _apellidoCtrl, requerido: true)),
          ]),
          const SizedBox(height: 16),
          _campo('Número de teléfono*', _telefonoCtrl,
              requerido: true, esNumero: true, minLen: 7,
              hint: 'Mínimo 7 dígitos'),
          const SizedBox(height: 16),
          _labelCampo('Fecha de nacimiento*'),
          _dateField(_fechaNacCtrl, 'dd/MM/yyyy',
              firstDate: DateTime(1900), lastDate: DateTime(2009)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _dropdown('País*', _paises, _pais, (v) => setState(() => _pais = v!))),
            const SizedBox(width: 16),
            Expanded(child: _dropdown('Zona residencial*', _zonas, _zona, (v) => setState(() => _zona = v!))),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _dropdown('Lengua materna*', _idiomas, _idioma, (v) => setState(() => _idioma = v!))),
            const SizedBox(width: 16),
            Expanded(child: _dropdown('Estado civil*', _estadosCiviles, _estadoCivil, (v) => setState(() => _estadoCivil = v!))),
          ]),
          const SizedBox(height: 16),
          _dropdown('Sexo*', _sexos, _sexo, (v) => setState(() => _sexo = v!)),

          const SizedBox(height: 32),
          _botonContinuar(() {
            if (_formPaso1.currentState?.validate() ?? false) {
              setState(() => _paso = 1);
            }
          }),
        ],
      ),
    );
  }

  // ── PASO 2: información socioeconómica ────────────────────────────────────

  Widget _buildPasoSocioeconomico() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('Información socioeconómica'),
        _subtitulo('Contexto social y económico de la paciente.'),
        const SizedBox(height: 20),
        _dropdown('Ingresos mensuales*', _ingresosOpciones, _ingresos,
            (v) => setState(() => _ingresos = v!), labels: _ingresosLabel),
        const SizedBox(height: 16),
        _dropdown('¿Pertenece a la Universidad de Cuenca?*', _perteneceOpciones,
            _perteneceUni, (v) => setState(() {
              _perteneceUni = v!;
              if (v == 'SI' && !_ocupacionesUni.contains(_ocupacionUni)) {
                _ocupacionUni =
                    _ocupacionesUni.isNotEmpty ? _ocupacionesUni.first : '';
              }
            }), labels: const {'SI': 'Sí', 'NO': 'No'}),
        const SizedBox(height: 16),
        if (_perteneceUni == 'SI')
          _dropdown('Ocupación principal*', _ocupacionesUni,
              _ocupacionesUni.contains(_ocupacionUni)
                  ? _ocupacionUni
                  : (_ocupacionesUni.isNotEmpty ? _ocupacionesUni.first : ''),
              (v) => setState(() => _ocupacionUni = v!))
        else ...[
          _labelCampo('Ocupación principal'),
          TextFormField(
            controller: _ocupacionLibreCtrl,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              hintText: 'Ej: Comerciante, Ama de casa',
            ),
          ),
        ],
        const SizedBox(height: 32),
        Row(children: [
          OutlinedButton(
            onPressed: () => setState(() => _paso = 0),
            child: const Text('← Atrás'),
          ),
          const SizedBox(width: 16),
          _botonContinuar(() => setState(() => _paso = 2)),
        ]),
      ],
    );
  }

  // ── PASO 3: aptitud + salud sexual ───────────────────────────────────────

  Widget _buildPaso2() {
    final exclusion = _motivoExclusion();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('Verificación de aptitud'),
        _subtitulo('Responda todas las preguntas antes de continuar.'),
        const SizedBox(height: 20),
        _preguntaSiNo('¿La edad de la paciente está entre 30 y 65 años?', _edadApta, (v) => setState(() => _edadApta = v)),
        _preguntaSiNo('¿Tiene o ha tenido vida sexual activa?', _vidaSexual, (v) => setState(() => _vidaSexual = v)),
        _preguntaSiNo('¿Ha tenido relaciones sexuales en las últimas 48 horas?', _relacionesRecientes, (v) => setState(() => _relacionesRecientes = v)),
        _preguntaSiNo('¿Da su consentimiento para participar en el estudio?', _consentimiento, (v) => setState(() => _consentimiento = v)),
        _preguntaSiNo('¿Puede comunicarse en español?', _espanol, (v) => setState(() => _espanol = v)),
        _preguntaSiNo('¿Está embarazada?', _embarazada, (v) => setState(() => _embarazada = v)),
        _preguntaSiNo('¿Ha tenido tratamiento previo del cuello uterino en los últimos 6 meses?', _tratamiento, (v) => setState(() => _tratamiento = v)),
        _preguntaSiNo('¿Ha utilizado medicamento intravaginal en la última semana?', _medicamento, (v) => setState(() => _medicamento = v)),
        _preguntaSiNo('¿Está con su período menstrual en este momento?', _menstruando, (v) => setState(() => _menstruando = v)),

        if (exclusion != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.cancel, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Paciente no apta: $exclusion',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (exclusion == null && _todasAptitudRespondidas) ...[
          const Divider(height: 40),
          _titulo('Datos de salud sexual'),
          const SizedBox(height: 16),
          _dropdown(
            '¿Hace cuánto fue el primer día de tu última menstruación?*',
            _menstruacionOpciones, _hacecuantoMenstruacion,
            (v) => setState(() => _hacecuantoMenstruacion = v!),
            labels: _menstruacionOpcionesLabel,
          ),
          const SizedBox(height: 16),
          if (_hacecuantoMenstruacion == _menstruacionFechaExacta) ...[
            _labelCampo('Fecha del primer día de la última menstruación*'),
            _dateField(_fechaMenstrCtrl, 'dd/MM/yyyy',
                firstDate: DateTime(2000), lastDate: DateTime.now()),
            const SizedBox(height: 16),
          ],
          _dropdown(
            '¿Hace cuánto fue el último examen de Papanicolaou (Pap)?*',
            _papCodes, _ultimoPap,
            (v) => setState(() => _ultimoPap = v!),
            labels: _papLabels,
          ),
          const SizedBox(height: 16),
          _dropdown(
            '¿Cuándo fue la última prueba de VPH?*',
            _vphCodes, _ultimoVph,
            (v) => setState(() => _ultimoVph = v!),
            labels: _vphLabels,
          ),
          const SizedBox(height: 16),
          _campo('Número de parejas sexuales*', _parejasCtrl,
              requerido: true, esNumero: true, hint: 'Ej: 2'),
          const SizedBox(height: 16),
          _dropdown(
            '¿Tiene o sospecha tener alguna ITS?*',
            _opcionesEts, _tieneEts,
            (v) => setState(() {
              _tieneEts = v!;
              if (v == 'SI') _nombreEts = _nombresEts.first;
              else _nombreEts = null;
            }),
            labels: _opcionesEtsLabel,
          ),
          if (_tieneEts == 'SI') ...[
            const SizedBox(height: 16),
            _dropdown(
              '¿Cuál ITS tiene o ha tenido?*',
              _nombresEts, _nombreEts ?? _nombresEts.first,
              (v) => setState(() => _nombreEts = v),
            ),
          ],
        ],

        const SizedBox(height: 32),
        Row(children: [
          OutlinedButton(
            onPressed: () => setState(() => _paso = 1),
            child: const Text('← Atrás'),
          ),
          const SizedBox(width: 16),
          if (exclusion == null &&
              _todasAptitudRespondidas &&
              (_hacecuantoMenstruacion != _menstruacionFechaExacta ||
                  _fechaMenstrCtrl.text.isNotEmpty))
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _azul, foregroundColor: Colors.white),
              onPressed: () => setState(() => _paso = 3),
              child: const Text('Continuar →'),
            ),
        ]),
      ],
    );
  }

  // ── PASO 3: dispositivo QR ────────────────────────────────────────────────

  Widget _buildPaso3() {
    return Form(
      key: _formPaso3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titulo('Dispositivo QR'),
          _subtitulo('Ingrese el código que aparece en el kit de automuestreo.'),
          const SizedBox(height: 24),

          // Resumen
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Resumen del registro',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Paciente: ${_nombreCtrl.text.trim()} ${_apellidoCtrl.text.trim()}'),
                Text('Teléfono: ${_telefonoCtrl.text.trim()}'),
                Text('Fecha nacimiento: ${_fechaNacCtrl.text.trim()}'),
                const Text('Grupo: FOLLETO'),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _labelCampo('Fecha y hora de registro del dispositivo*'),
          _dateTimePicker(
            _fechaRegistro,
            (dt) => setState(() => _fechaRegistro = dt),
          ),

          const SizedBox(height: 16),
          _labelCampo('Fecha y hora de toma de muestra (examen)*'),
          _dateTimePicker(
            _fechaExamen,
            (dt) => setState(() => _fechaExamen = dt),
          ),

          const SizedBox(height: 24),
          _labelCampo('Código del dispositivo QR*'),
          TextFormField(
            controller: _dispositivoCtrl,
            decoration: const InputDecoration(
              hintText: 'Ej: 010151-ABC123',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'El código del dispositivo es requerido';
              return null;
            },
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
          Row(children: [
            OutlinedButton(
              onPressed: _enviando ? null : () => setState(() => _paso = 2),
              child: const Text('← Atrás'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _rojo, foregroundColor: Colors.white),
              onPressed: _enviando ? null : _enviar,
              child: _enviando
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Registrar ✓'),
            ),
          ]),
        ],
      ),
    );
  }

  // ── Widgets de apoyo ──────────────────────────────────────────────────────

  Widget _titulo(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(texto,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _azul)),
  );

  Widget _subtitulo(String texto) => Text(texto,
      style: TextStyle(fontSize: 13, color: Colors.grey[600]));

  Widget _labelCampo(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
  );

  Widget _campo(String label, TextEditingController ctrl,
      {bool requerido = false, bool esNumero = false, int? minLen, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelCampo(label),
        TextFormField(
          controller: ctrl,
          keyboardType: esNumero ? TextInputType.number : TextInputType.text,
          inputFormatters: esNumero ? [FilteringTextInputFormatter.digitsOnly] : null,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          validator: (v) {
            if (requerido && (v == null || v.trim().isEmpty)) return 'Campo requerido';
            if (minLen != null && (v?.length ?? 0) < minLen) return 'Mínimo $minLen caracteres';
            return null;
          },
        ),
      ],
    );
  }

  Widget _dropdown(String label, List<String> opciones, String valor,
      ValueChanged<String?> onChanged, {Map<String, String>? labels}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelCampo(label),
        DropdownButtonFormField<String>(
          value: valor,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          items: opciones.map((o) => DropdownMenuItem(
            value: o,
            child: Text(labels?[o] ?? o, overflow: TextOverflow.ellipsis),
          )).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}  $h:$min';
  }

  Widget _dateTimePicker(DateTime value, ValueChanged<DateTime> onChanged) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          locale: const Locale('es'),
        );
        if (date == null || !mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: value.hour, minute: value.minute),
        );
        if (time == null) return;
        onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[600]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatDateTime(value),
                style: const TextStyle(fontSize: 15)),
            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _dateField(TextEditingController ctrl, String hint,
      {required DateTime firstDate, required DateTime lastDate}) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      decoration: InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        suffixIcon: const Icon(Icons.calendar_today, size: 18),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: lastDate,
          firstDate: firstDate,
          lastDate: lastDate,
          locale: const Locale('es'),
        );
        if (picked != null) {
          ctrl.text = '${picked.day.toString().padLeft(2,'0')}/'
              '${picked.month.toString().padLeft(2,'0')}/${picked.year}';
        }
      },
      validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
    );
  }

  Widget _preguntaSiNo(String pregunta, bool? valor, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(pregunta, style: const TextStyle(fontSize: 13))),
          const SizedBox(width: 12),
          _botonRespuesta('Sí', valor == true, () => onChanged(true)),
          const SizedBox(width: 8),
          _botonRespuesta('No', valor == false, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _botonRespuesta(String label, bool seleccionado, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? _azul : Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: seleccionado ? _azul : Colors.grey[300]!),
        ),
        child: Text(label,
            style: TextStyle(
              color: seleccionado ? Colors.white : Colors.grey[700],
              fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
            )),
      ),
    );
  }

  Widget _botonContinuar(VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: _azul, foregroundColor: Colors.white),
      onPressed: onPressed,
      child: const Text('Continuar →'),
    );
  }
}
