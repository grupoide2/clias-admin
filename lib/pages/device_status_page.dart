import 'dart:html' as html;
import 'dart:math';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:telemedicina_web/models/estado_dispositivo.dart';
import 'package:telemedicina_web/services/api_service.dart';

class DeviceStatusPage extends StatefulWidget {
  const DeviceStatusPage({Key? key}) : super(key: key);
  @override
  State<DeviceStatusPage> createState() => _DeviceStatusPageState();
}

class _DeviceStatusPageState extends State<DeviceStatusPage> {
  bool _loading = false;
  bool _hasLoaded = false;
  String? _loadError;
  List<EstadoDispositivo> _dispositivos = [];
  DateTimeRange? _rangoFechas;
  String _filtroStatus = 'todos';
  int _rowsPerPage = 10;
  int _currentPage = 0;
  int _totalElements = 0;

  final List<String> _statuses = [
    'todos',
    'generado',
    'registrado',
    'en proceso',
    'resultado listo',
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null);
  }

  // Carga la página actual según el estado de los filtros
  Future<void> _cargarPagina() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final formato = DateFormat('yyyy-MM-dd');
      final result = await ApiService().obtenerDispositivos(
        page: _currentPage,
        size: _rowsPerPage,
        estado: _filtroStatus,
        desde: _rangoFechas != null ? formato.format(_rangoFechas!.start) : null,
        hasta: _rangoFechas != null ? formato.format(_rangoFechas!.end) : null,
      );
      setState(() {
        _dispositivos = result['content'] as List<EstadoDispositivo>;
        _totalElements = result['totalElements'] as int;
        _hasLoaded = true;
      });
    } catch (e) {
      setState(() => _loadError = 'Error al cargar dispositivos: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _cargarTodos() async {
    setState(() {
      _rangoFechas = null;
      _currentPage = 0;
    });
    await _cargarPagina();
  }

  Future<void> _cargarPorFechas(DateTime desde, DateTime hasta) async {
    setState(() {
      _rangoFechas = DateTimeRange(start: desde, end: hasta);
      _currentPage = 0;
    });
    await _cargarPagina();
  }

  Future<void> _descargarReporte() async {
    setState(() => _loading = true);
    try {
      final formato = DateFormat('yyyy-MM-dd');
      final result = await ApiService().obtenerDispositivos(
        page: 0,
        size: 100000,
        estado: _filtroStatus,
        desde: _rangoFechas != null ? formato.format(_rangoFechas!.start) : null,
        hasta: _rangoFechas != null ? formato.format(_rangoFechas!.end) : null,
      );
      final data = result['content'] as List<EstadoDispositivo>;

      if (data.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay datos para exportar con los filtros actuales')),
          );
        }
        return;
      }

      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      final headerStyle = CellStyle(
        backgroundColorHex: '#D9D9D9',
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
      final cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Center);

      final headers = ['Código', 'Estado', 'Fecha de Registro', 'Fecha de Examen', 'Fecha de Resultado', 'Fecha de Entrega en el GAD'];
      for (int c = 0; c < headers.length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
        cell.value = headers[c];
        cell.cellStyle = headerStyle;
      }

      final fmt = DateFormat('yyyy-MM-dd HH:mm:ss');
      for (int i = 0; i < data.length; i++) {
        final d = data[i];
        final values = [
          d.codigo,
          d.estado,
          d.fechaRegistro != null ? fmt.format(d.fechaRegistro!.toLocal()) : '---',
          d.fechaExamen != null ? fmt.format(d.fechaExamen!.toLocal()) : '---',
          d.fechaResultado != null ? fmt.format(d.fechaResultado!.toLocal()) : '---',
          '',
        ];
        for (int c = 0; c < values.length; c++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: i + 1));
          cell.value = values[c];
          cell.cellStyle = cellStyle;
        }
      }

      final columnWidths = [15.0, 20.0, 25.0, 25.0, 25.0, 30.0];
      for (int i = 0; i < columnWidths.length; i++) {
        sheet.setColWidth(i, columnWidths[i]);
      }

      final bytes = Uint8List.fromList(excel.encode()!);
      final fechaActual = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      await FileSaver.instance.saveFile(
        name: 'reporte_dispositivos_$fechaActual',
        bytes: bytes,
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reporte descargado (${data.length} registros)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar reporte: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _descargarPdf(String codigo) async {
    try {
      final bytes = await ApiService().descargarPdfExamen(codigo);
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'examen_$codigo.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descargar PDF: $e')),
        );
      }
    }
  }

  Widget _buildStatusChip(String status) {
    final s = status.toLowerCase();
    Color color;
    IconData icon;
    switch (s) {
      case 'generado':
        color = Colors.amber;
        icon = Icons.circle;
        break;
      case 'registrado':
        color = Colors.blue;
        icon = Icons.check_circle;
        break;
      case 'en proceso':
        color = Colors.orange;
        icon = Icons.autorenew;
        break;
      case 'resultado listo':
        color = Colors.green;
        icon = Icons.done_all;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        s[0].toUpperCase() + s.substring(1),
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildPaginationControls() {
    final totalPages = (_totalElements / _rowsPerPage).ceil();
    final firstRow = _totalElements == 0 ? 0 : _currentPage * _rowsPerPage + 1;
    final lastRow = min((_currentPage + 1) * _rowsPerPage, _totalElements);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text('Filas por página:', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _rowsPerPage,
            underline: const SizedBox(),
            items: [10, 20, 50, 100, 200].map((v) => DropdownMenuItem(
              value: v,
              child: Text('$v', style: const TextStyle(fontSize: 13)),
            )).toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  _rowsPerPage = v;
                  _currentPage = 0;
                });
                _cargarPagina();
              }
            },
          ),
          const SizedBox(width: 24),
          Text(
            '$firstRow–$lastRow de $_totalElements',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: _currentPage > 0
                ? () {
                    setState(() => _currentPage = 0);
                    _cargarPagina();
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 0
                ? () {
                    setState(() => _currentPage--);
                    _cargarPagina();
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage + 1 < totalPages
                ? () {
                    setState(() => _currentPage++);
                    _cargarPagina();
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed: _currentPage + 1 < totalPages
                ? () {
                    setState(() => _currentPage = totalPages - 1);
                    _cargarPagina();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBotones() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Center(
        child: Wrap(
          spacing: 18,
          runSpacing: 28,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _cargarTodos,
              icon: const Icon(Icons.list),
              label: const Text('Mostrar todos los dispositivos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002856),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) {
                    DateTime? fechaInicio;
                    DateTime? fechaFin;
                    String format(DateTime d) => DateFormat('dd MMM y', 'es').format(d);
                    return StatefulBuilder(
                      builder: (ctx, setStateDialog) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          title: const Text('Selecciona un rango de fechas'),
                          content: SizedBox(
                            width: 360,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F3F5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    (fechaInicio != null && fechaFin != null)
                                        ? 'Desde: ${format(fechaInicio!)}   —   Hasta: ${format(fechaFin!)}'
                                        : 'Selecciona un rango (Desde — Hasta)',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                SizedBox(
                                  width: 350,
                                  height: 320,
                                  child: SfDateRangePicker(
                                    view: DateRangePickerView.month,
                                    selectionMode: DateRangePickerSelectionMode.range,
                                    showNavigationArrow: true,
                                    maxDate: DateTime.now(),
                                    monthViewSettings: const DateRangePickerMonthViewSettings(firstDayOfWeek: 1),
                                    onSelectionChanged: (args) {
                                      if (args.value is PickerDateRange) {
                                        final r = args.value as PickerDateRange;
                                        setStateDialog(() {
                                          fechaInicio = r.startDate;
                                          fechaFin = r.endDate ?? r.startDate;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                if (fechaInicio != null && fechaFin != null) {
                                  Navigator.pop(ctx);
                                  await _cargarPorFechas(fechaInicio!, fechaFin!);
                                }
                              },
                              child: const Text('Aceptar'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
              icon: const Icon(Icons.calendar_month),
              label: const Text('Buscar por fechas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002856),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _descargarReporte,
              icon: const Icon(Icons.download),
              label: const Text('Descargar reporte de los dispositivos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF002856),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Material(
            color: const Color(0xFFA51008),
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset('assets/images/logoucuencaprincipal.png', height: 32),
            const Text(
              'Estado de Dispositivos',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Material(
              color: const Color(0xFFA51008),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _cargarTodos,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loadError != null)
            Container(
              alignment: Alignment.center,
              width: double.infinity,
              color: Colors.red,
              padding: const EdgeInsets.all(8),
              child: Text(
                _loadError!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 8),
          _buildBotones(),
          const SizedBox(height: 16),
          if (_hasLoaded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
                child: PopupMenuButton<String>(
                  initialValue: _filtroStatus,
                  onSelected: (v) {
                    setState(() {
                      _filtroStatus = v;
                      _currentPage = 0;
                    });
                    _cargarPagina();
                  },
                  itemBuilder: (_) => _statuses.map((s) => PopupMenuItem(
                    value: s,
                    child: Text(s[0].toUpperCase() + s.substring(1)),
                  )).toList(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        const Text(
                          'Filtrar por estado:',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                        const SizedBox(width: 18, height: 12),
                        Expanded(
                          child: Text(
                            _filtroStatus[0].toUpperCase() + _filtroStatus.substring(1),
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.black54),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_hasLoaded && _dispositivos.isEmpty)
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                'No hay dispositivos para el filtro seleccionado.',
                style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
            )
          else if (_hasLoaded && _dispositivos.isNotEmpty)
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 8, bottom: 8),
                              child: Text(
                                'Listado de Dispositivos',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                    child: DataTable(
                                      columnSpacing: 30,
                                      headingRowColor: WidgetStateProperty.all(const Color(0xFF082B5F)),
                                      columns: const [
                                        DataColumn(label: Text('Código', style: TextStyle(color: Colors.white))),
                                        DataColumn(
                                          label: SizedBox(
                                            width: 50,
                                            child: Text('Estado', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                                          ),
                                        ),
                                        DataColumn(label: Text('Fecha de Registro', style: TextStyle(color: Colors.white))),
                                        DataColumn(label: Text('Fecha de Examen', style: TextStyle(color: Colors.white))),
                                        DataColumn(label: Text('Fecha del Resultado listo', style: TextStyle(color: Colors.white))),
                                        DataColumn(label: Text('PDF', style: TextStyle(color: Colors.white))),
                                      ],
                                      rows: _buildRows(),
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildPaginationControls(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<DataRow> _buildRows() {
    final fmt = DateFormat('yyyy-MM-dd HH:mm:ss');
    String f(DateTime? dt) => dt != null ? fmt.format(dt.toLocal()) : '---';
    return _dispositivos.map((d) {
      final tienePdf = d.estado.toLowerCase() == 'resultado listo';
      return DataRow(cells: [
        DataCell(Text(d.codigo)),
        DataCell(_buildStatusChip(d.estado)),
        DataCell(Text(f(d.fechaRegistro))),
        DataCell(Text(f(d.fechaExamen))),
        DataCell(Text(f(d.fechaResultado))),
        DataCell(
          Tooltip(
            message: tienePdf ? 'Descargar PDF' : 'PDF no disponible',
            child: IconButton(
              icon: Icon(
                Icons.picture_as_pdf,
                color: tienePdf ? const Color(0xFFA51008) : Colors.grey[400],
              ),
              onPressed: tienePdf ? () => _descargarPdf(d.codigo) : null,
            ),
          ),
        ),
      ]);
    }).toList();
  }
}
