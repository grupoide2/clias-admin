class MetricaDashboard {
  final int pacientesRegistradas;
  final int automuestreosRealizados;
  final int pacientesUsaronChatbot;
  final int sesionesChatbot;
  final int mensajesEnviadosChatbot;
  final String tiempoPromedioApp;
  final String tiempoPromedioChatbot;
  final int resultadosDisponibles;

  MetricaDashboard({
    required this.pacientesRegistradas,
    required this.automuestreosRealizados,
    required this.pacientesUsaronChatbot,
    required this.sesionesChatbot,
    required this.mensajesEnviadosChatbot,
    required this.tiempoPromedioApp,
    required this.tiempoPromedioChatbot,
    required this.resultadosDisponibles,
  });

  factory MetricaDashboard.fromJson(Map<String, dynamic> j) => MetricaDashboard(
        pacientesRegistradas: (j['pacientesRegistradas'] as num?)?.toInt() ?? 0,
        automuestreosRealizados:
            (j['automuestreosRealizados'] as num?)?.toInt() ?? 0,
        pacientesUsaronChatbot:
            (j['pacientesUsaronChatbot'] as num?)?.toInt() ?? 0,
        sesionesChatbot: (j['sesionesChatbot'] as num?)?.toInt() ?? 0,
        mensajesEnviadosChatbot:
            (j['mensajesEnviadosChatbot'] as num?)?.toInt() ?? 0,
        tiempoPromedioApp: j['tiempoPromedioAppFormato'] as String? ?? '00:00:00',
        tiempoPromedioChatbot:
            j['tiempoPromedioChatbotFormato'] as String? ?? '00:00:00',
        resultadosDisponibles:
            (j['resultadosDisponibles'] as num?)?.toInt() ?? 0,
      );
}
