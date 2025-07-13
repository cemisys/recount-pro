import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../models/vh_model.dart';
import '../../models/user_model.dart';

class PdfService {
  Future<bool> generarReporteDiario({
    required List<ConteoVh> conteos,
    required List<VhSegundoConteo> segundosConteos,
    required UserModel verificador,
    required DateTime fecha,
  }) async {
    try {
      final pdf = pw.Document();

      // Crear el contenido del PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildHeader(verificador, fecha),
              pw.SizedBox(height: 20),
              _buildResumen(conteos, segundosConteos),
              pw.SizedBox(height: 20),
              if (conteos.isNotEmpty) ...[
                _buildTablaConteos(conteos, 'PRIMER CONTEO'),
                pw.SizedBox(height: 20),
              ],
              if (segundosConteos.isNotEmpty) ...[
                _buildTablaSegundosConteos(segundosConteos),
                pw.SizedBox(height: 20),
              ],
              if (conteos.any((c) => c.tieneNovedad) || segundosConteos.any((c) => c.tieneNovedad)) ...[
                pw.SizedBox(height: 10),
                _buildDetalleNovedades(conteos, segundosConteos),
              ],
              pw.Spacer(),
              _buildFooter(),
            ];
          },
        ),
      );

      // Guardar y compartir el PDF
      final fileName =
          'ReCount_Pro_${DateFormat('yyyyMMdd').format(fecha)}_${verificador.nombre.replaceAll(' ', '_')}.pdf';
      final pdfBytes = await pdf.save();

      // Usar share_plus que funciona en todas las plataformas
      await Share.shareXFiles(
        [XFile.fromData(pdfBytes, name: fileName, mimeType: 'application/pdf')],
        text: 'Reporte diario ReCount Pro - ${DateFormat('dd/MM/yyyy').format(fecha)}',
      );

      return true;
    } catch (e) {
      print('Error generando PDF: $e');
      return false;
    }
  }



  pw.Widget _buildHeader(UserModel verificador, DateTime fecha) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'REPORTE DIARIO DE SEGUNDO CONTEO',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'ReCount Pro by 3M Technology®',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'CD-3M',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Centro de Distribución',
                  style: const pw.TextStyle(
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.SizedBox(height: 16),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'INFORMACIÓN DEL REPORTE',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Verificador: ${verificador.nombre}'),
                  pw.Text('Correo: ${verificador.correo}'),
                  pw.Text('Fecha: ${DateFormat('dd/MM/yyyy').format(fecha)}'),
                  pw.Text(
                      'Hora de generación: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildResumen(List<ConteoVh> conteos, List<VhSegundoConteo> segundosConteos) {
    final totalConteos = conteos.length;
    final conteosConNovedad = conteos.where((c) => c.tieneNovedad).length;
    final conteosSinNovedad = totalConteos - conteosConNovedad;

    final totalSegundosConteos = segundosConteos.length;
    final segundosConteosConNovedad = segundosConteos.where((c) => c.tieneNovedad).length;
    final segundosConteosSinNovedad = totalSegundosConteos - segundosConteosConNovedad;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RESUMEN EJECUTIVO',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          // Primer Conteo
          if (totalConteos > 0) ...[
            pw.Text(
              'PRIMER CONTEO',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildResumenItem('Total VH', totalConteos.toString()),
                _buildResumenItem('Sin Novedad', conteosSinNovedad.toString()),
                _buildResumenItem('Con Novedad', conteosConNovedad.toString()),
                _buildResumenItem(
                    'Efectividad',
                    totalConteos > 0
                        ? '${((conteosSinNovedad / totalConteos) * 100).toStringAsFixed(1)}%'
                        : '0%'),
              ],
            ),
          ],

          // Segundo Conteo
          if (totalSegundosConteos > 0) ...[
            if (totalConteos > 0) pw.SizedBox(height: 16),
            pw.Text(
              'SEGUNDO CONTEO',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildResumenItem('Total VH', totalSegundosConteos.toString()),
                _buildResumenItem('Sin Novedad', segundosConteosSinNovedad.toString()),
                _buildResumenItem('Con Novedad', segundosConteosConNovedad.toString()),
                _buildResumenItem(
                    'Efectividad',
                    totalSegundosConteos > 0
                        ? '${((segundosConteosSinNovedad / totalSegundosConteos) * 100).toStringAsFixed(1)}%'
                        : '0%'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildResumenItem(String titulo, String valor) {
    return pw.Column(
      children: [
        pw.Text(
          titulo,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          valor,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.indigo,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTablaConteos(List<ConteoVh> conteos, [String titulo = 'CONTEOS REALIZADOS']) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          titulo,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FixedColumnWidth(60),
            1: const pw.FixedColumnWidth(80),
            2: const pw.FixedColumnWidth(80),
            3: const pw.FixedColumnWidth(60),
            4: const pw.FlexColumnWidth(),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              children: [
                _buildTableCell('VH ID', isHeader: true),
                _buildTableCell('Placa', isHeader: true),
                _buildTableCell('Hora', isHeader: true),
                _buildTableCell('Estado', isHeader: true),
                _buildTableCell('Observaciones', isHeader: true),
              ],
            ),
            // Datos
            ...conteos.map((conteo) => pw.TableRow(
                  children: [
                    _buildTableCell(conteo.vhId),
                    _buildTableCell(conteo.placa),
                    _buildTableCell(
                        DateFormat('HH:mm').format(conteo.fechaCreacion)),
                    _buildTableCell(
                      conteo.tieneNovedad ? 'Con Novedad' : 'Sin Novedad',
                      textColor:
                          conteo.tieneNovedad ? PdfColors.red : PdfColors.green,
                    ),
                    _buildTableCell(
                      conteo.tieneNovedad
                          ? '${conteo.novedades?.length ?? 0} novedad(es)'
                          : 'Conteo correcto',
                    ),
                  ],
                )),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text,
      {bool isHeader = false, PdfColor? textColor}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? PdfColors.black,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildTablaSegundosConteos(List<VhSegundoConteo> segundosConteos) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'SEGUNDO CONTEO',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.teal,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(2.5),
          },
          children: [
            // Encabezados
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Placa', isHeader: true),
                _buildTableCell('Hora', isHeader: true),
                _buildTableCell('Estado', isHeader: true),
                _buildTableCell('Verificador', isHeader: true),
                _buildTableCell('Observaciones', isHeader: true),
              ],
            ),
            // Datos
            ...segundosConteos.map((conteo) => pw.TableRow(
                  children: [
                    _buildTableCell(conteo.placa),
                    _buildTableCell(
                        DateFormat('HH:mm').format(conteo.timestamp)),
                    _buildTableCell(
                      conteo.tieneNovedad ? 'Con Novedad' : 'Sin Novedad',
                      textColor:
                          conteo.tieneNovedad ? PdfColors.red : PdfColors.green,
                    ),
                    _buildTableCell(conteo.verificadorNombre),
                    _buildTableCell(
                      conteo.tieneNovedad
                          ? '${conteo.novedades.length} novedad(es)'
                          : conteo.observaciones ?? 'Sin observaciones',
                    ),
                  ],
                )),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildDetalleNovedades(List<ConteoVh> conteos, List<VhSegundoConteo> segundosConteos) {
    final conteosConNovedad = conteos.where((c) => c.tieneNovedad).toList();
    final segundosConteosConNovedad = segundosConteos.where((c) => c.tieneNovedad).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DETALLE DE NOVEDADES',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        ...conteosConNovedad.map((conteo) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 16),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'VH ${conteo.vhId} - ${conteo.placa}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  if (conteo.novedades != null)
                    ...conteo.novedades!.map((novedad) => pw.Container(
                          margin: const pw.EdgeInsets.only(bottom: 8),
                          padding: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey100,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                children: [
                                  pw.Text(
                                    'Tipo: ',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.Text(novedad.tipo),
                                  pw.SizedBox(width: 20),
                                  pw.Text(
                                    'DT: ',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.Text(novedad.dt),
                                ],
                              ),
                              pw.SizedBox(height: 4),
                              pw.Row(
                                children: [
                                  pw.Text(
                                    'SKU: ',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.Text(novedad.sku),
                                ],
                              ),
                              pw.SizedBox(height: 4),
                              pw.Row(
                                children: [
                                  pw.Text(
                                    'Descripción: ',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.Expanded(
                                      child: pw.Text(novedad.descripcion)),
                                ],
                              ),
                              pw.SizedBox(height: 4),
                              pw.Row(
                                children: [
                                  pw.Text(
                                    'Alistado: ',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.Text(novedad.alistado.toString()),
                                  pw.SizedBox(width: 20),
                                  pw.Text(
                                    'Físico: ',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.Text(novedad.fisico.toString()),
                                  pw.SizedBox(width: 20),
                                  pw.Text(
                                    'Diferencia: ',
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.red,
                                    ),
                                  ),
                                  pw.Text(
                                    novedad.diferencia.toString(),
                                    style: const pw.TextStyle(color: PdfColors.red),
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 4),
                              pw.Row(
                                children: [
                                  pw.Text(
                                    'Verificado: ',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.Text(novedad.verificado.toString()),
                                  pw.SizedBox(width: 20),
                                  pw.Text(
                                    'Armador: ',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.Text(novedad.armador),
                                ],
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            )),

        // Novedades de segundos conteos
        ...segundosConteosConNovedad.map((conteo) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 16),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.teal300),
                borderRadius: pw.BorderRadius.circular(8),
                color: PdfColors.teal50,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        'SEGUNDO CONTEO - VH ${conteo.placa}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal,
                        ),
                      ),
                      pw.Spacer(),
                      pw.Text(
                        DateFormat('HH:mm').format(conteo.timestamp),
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Verificador: ${conteo.verificadorNombre}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  if (conteo.observaciones != null) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Observaciones: ${conteo.observaciones}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Novedades encontradas:',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  ...conteo.novedades.map((novedad) => pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 8),
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius: pw.BorderRadius.circular(4),
                          color: PdfColors.white,
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              children: [
                                pw.Text(
                                  'Tipo: ',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold),
                                ),
                                pw.Text(
                                  novedad.tipo,
                                  style: pw.TextStyle(
                                    color: novedad.tipo == 'Faltante'
                                        ? PdfColors.red
                                        : PdfColors.orange,
                                  ),
                                ),
                                pw.Spacer(),
                                pw.Text(
                                  'DT: ${novedad.dt}',
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 4),
                            pw.Row(
                              children: [
                                pw.Text(
                                  'SKU: ',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold),
                                ),
                                pw.Text(novedad.sku),
                              ],
                            ),
                            pw.SizedBox(height: 4),
                            pw.Row(
                              children: [
                                pw.Text(
                                  'Descripción: ',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold),
                                ),
                                pw.Expanded(
                                    child: pw.Text(novedad.descripcion)),
                              ],
                            ),
                            pw.SizedBox(height: 4),
                            pw.Row(
                              children: [
                                pw.Text(
                                  'Alistado: ',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold),
                                ),
                                pw.Text(novedad.alistado.toString()),
                                pw.SizedBox(width: 20),
                                pw.Text(
                                  'Físico: ',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold),
                                ),
                                pw.Text(novedad.fisico.toString()),
                                pw.SizedBox(width: 20),
                                pw.Text(
                                  'Diferencia: ',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold),
                                ),
                                pw.Text(
                                  novedad.diferencia.toString(),
                                  style: pw.TextStyle(
                                    color: novedad.diferencia != 0
                                        ? PdfColors.red
                                        : PdfColors.green,
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 4),
                            pw.Row(
                              children: [
                                pw.Text(
                                  'Verificado: ',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold),
                                ),
                                pw.Text(novedad.verificado.toString()),
                                pw.SizedBox(width: 20),
                                pw.Text(
                                  'Armador: ',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold),
                                ),
                                pw.Expanded(child: pw.Text(novedad.armador)),
                              ],
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            )),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text(
          'Elaborado automáticamente por ReCount Pro by 3M Technology®',
          style: pw.TextStyle(
            fontSize: 10,
            fontStyle: pw.FontStyle.italic,
            color: PdfColors.grey600,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Documento generado el ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}',
          style: const pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey500,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }
}
