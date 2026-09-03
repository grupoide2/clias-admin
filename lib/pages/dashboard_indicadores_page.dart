import 'package:flutter/material.dart';
import 'package:telemedicina_web/models/metrica_dashboard.dart';
import 'package:telemedicina_web/services/metrica_service.dart';

const _azul = Color(0xFF002856);
const _rojo = Color(0xFFA51008);

class DashboardIndicadoresPage extends StatefulWidget {
  const DashboardIndicadoresPage({super.key});

  @override
  State<DashboardIndicadoresPage> createState() =>
      _DashboardIndicadoresPageState();
}

class _DashboardIndicadoresPageState extends State<DashboardIndicadoresPage> {
  final _svc = MetricaService();
  bool _loading = true;
  String? _error;
  MetricaDashboard? _data;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await _svc.dashboard();
      if (!mounted) return;
      setState(() {
        _data = d;
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
        title: const Text('Dashboard de uso',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loading ? null : _cargar,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    final d = _data!;
    final tiles = <Widget>[
      _tile(Icons.groups, 'Pacientes registradas', '${d.pacientesRegistradas}'),
      _tile(Icons.colorize, 'Automuestreos realizados',
          '${d.automuestreosRealizados}'),
      _tile(Icons.forum, 'Pacientes que usaron el chatbot',
          '${d.pacientesUsaronChatbot}'),
      _tile(Icons.chat_bubble_outline, 'Sesiones de chatbot',
          '${d.sesionesChatbot}'),
      _tile(Icons.send, 'Mensajes enviados al chatbot',
          '${d.mensajesEnviadosChatbot}'),
      _tile(Icons.timer, 'Tiempo promedio de uso de la app',
          d.tiempoPromedioApp),
      _tile(Icons.timer_outlined, 'Tiempo promedio de uso del chatbot',
          d.tiempoPromedioChatbot),
      _tile(Icons.description, 'Resultados disponibles',
          '${d.resultadosDisponibles}'),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Resumen general',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: tiles,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String label, String valor) {
    return Container(
      width: 220,
      height: 150,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD9DEE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _azul, size: 26),
          const SizedBox(height: 10),
          Text(valor,
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: _azul)),
          const SizedBox(height: 4),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
