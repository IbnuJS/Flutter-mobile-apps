import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'app_data.dart';

class InvoiceService {
  /// Membuat dan mencetak invoice PDF untuk sebuah transaksi.
  static Future<void> generateAndPrintInvoice(Transaksi transaksi) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(color: PdfColors.blue900),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DIGITAL STATISTIK PERIKANAN',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'ID: ${transaksi.id}',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Tanggal: ${transaksi.tanggal}'),
                    pw.Text('Kategori: ${transaksi.kategori}'),
                    pw.SizedBox(height: 18),
                    pw.TableHelper.fromTextArray(
                      border: null,
                      headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                      headerDecoration: const pw.BoxDecoration(
                        color: PdfColors.blue900,
                      ),
                      cellHeight: 28,
                      cellAlignments: {
                        0: pw.Alignment.centerLeft,
                        1: pw.Alignment.center,
                        2: pw.Alignment.centerRight,
                        3: pw.Alignment.centerRight,
                      },
                      headers: const [
                        'Jenis Ikan / Produk',
                        'Berat (Kg)',
                        'Harga/Kg',
                        'Subtotal',
                      ],
                      data: transaksi.items.map((item) {
                        return [
                          item.jenisIkan,
                          item.jumlahKg.toString(),
                          formatRupiah(item.hargaPerKg),
                          formatRupiah(item.subtotal),
                        ];
                      }).toList(),
                    ),

                    pw.SizedBox(height: 12),
                    pw.Divider(),
                    pw.SizedBox(height: 8),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        'Total Penjualan: ${formatRupiah(transaksi.totalPenjualan)}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              pw.Padding(
                padding: const pw.EdgeInsets.all(20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Syarat & Ketentuan:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      '1. Invoice ini adalah bukti transaksi sah secara digital.',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      '2. Barang yang sudah dibeli tidak dapat ditukar atau dikembalikan.',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'Terima kasih telah menggunakan sistem Digital Statistik Perikanan.',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${transaksi.id}.pdf',
    );
  }
}
