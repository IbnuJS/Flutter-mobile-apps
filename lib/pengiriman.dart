// ═══════════════════════════════════════════════════════════════════════════════
//  pengiriman.dart
//  Halaman Pengiriman / Share (index 0 di MainShell)
//  HANYA: Ekspor File PDF
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'app_data.dart';

class SharePage extends StatefulWidget {
  final void Function(int index)? onNavigate;
  const SharePage({super.key, this.onNavigate});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  // ── Controllers ───────────────────────────────────────────────────────────────
  final _catatanCtrl = TextEditingController();

  // ── State ─────────────────────────────────────────────────────────────────────
  bool _isSavingTeks = false;
  bool _teksSaved = false;

  // ── Transaksi yang dipilih (default: transaksi terbaru) ───────────────────────
  int _selectedTransaksiIndex = 0;

  @override
  void dispose() {
    _catatanCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  List<Transaksi> get _transaksiList => AppData().transaksiList;

  Transaksi? get _selectedTransaksi {
    if (_transaksiList.isEmpty) return null;
    if (_selectedTransaksiIndex >= _transaksiList.length) {
      return _transaksiList.first;
    }
    return _transaksiList[_selectedTransaksiIndex];
  }

  /// Bangun isi file teks dari transaksi
  String _buildTeksLaporan(Transaksi t) {
    final catatan = _catatanCtrl.text.trim();
    final now = DateTime.now();
    final buffer = StringBuffer();

    buffer.writeln('=================================================');
    buffer.writeln('      LAPORAN TRANSAKSI STARISTIK PERIKANAN      ');
    buffer.writeln('=================================================');
    buffer.writeln(
      'Dicetak   : ${now.day.toString().padLeft(2, '0')}/'
      '${now.month.toString().padLeft(2, '0')}/${now.year}  '
      '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}',
    );
    buffer.writeln('------------------------------------------------');
    buffer.writeln('ID        : ${t.id}');
    buffer.writeln('Tanggal   : ${t.tanggal}');
    buffer.writeln('------------------------------------------------');
    buffer.writeln('DETAIL ITEM:');
    for (final item in t.items) {
      buffer.writeln('  • ${item.jenisIkan}');
      buffer.writeln('    Berat   : ${item.jumlahKg} kg');
      buffer.writeln('    Harga   : Rp ${formatRupiah(item.hargaPerKg)} / kg');
      buffer.writeln('    Subtotal: Rp ${formatRupiah(item.subtotal)}');
    }
    buffer.writeln('------------------------------------------------');
    buffer.writeln('TOTAL     : Rp ${formatRupiah(t.totalPenjualan)}');
    if (catatan.isNotEmpty) {
      buffer.writeln('------------------------------------------------');
      buffer.writeln('Catatan   : $catatan');
    }
    buffer.writeln('================================================');
    buffer.writeln('   STATISTIK PERIKANAN — SISTEM BUDIDAYA IKAN   ');
    buffer.writeln('================================================');

    return buffer.toString();
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? kRed : kGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Aksi: FILE PDF ───────────────────────────────────────────────────────────
  void _simpanFileTeks() async {
    final t = _selectedTransaksi;
    if (t == null) {
      _showSnack('Tidak ada data transaksi', isError: true);
      return;
    }

    setState(() => _isSavingTeks = true);

    try {
      final pdf = pw.Document();
      final teks = _buildTeksLaporan(t);
      final catatan = _catatanCtrl.text.trim();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'LAPORAN TRANSAKSI STATISTIK PERIKANAN',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text('ID: ${t.id}', style: pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Tanggal: ${t.tanggal}',
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 10),

                // Isi utama
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 0.8, color: PdfColors.grey400),
                  ),
                  child: pw.Text(
                    teks,
                    style: pw.TextStyle(fontSize: 11, font: pw.Font.courier()),
                  ),
                ),

                if (catatan.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Catatan: $catatan',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ],

                pw.Spacer(),
                pw.Text(
                  'Dibuat otomatis oleh aplikasi',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Laporan_${t.id}.pdf',
      );

      if (!mounted) return;
      setState(() {
        _teksSaved = true;
        _isSavingTeks = false;
      });

      _showSnack('PDF laporan ${t.id} berhasil dibuat!', isError: false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSavingTeks = false;
        _teksSaved = false;
      });
      _showSnack('Gagal membuat file PDF', isError: true);
    }

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _teksSaved = false);
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  WIDGETS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildTransaksiSelector() {
    final list = _transaksiList;
    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 18),
            SizedBox(width: 8),
            Text(
              'Belum ada transaksi. Tambahkan dulu via menu Input.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Transaksi',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .04),
                blurRadius: 4,
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedTransaksiIndex,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: kBlue),
              items: List.generate(list.length, (i) {
                final t = list[i];
                return DropdownMenuItem<int>(
                  value: i,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: kBlueBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: kBlue,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.id,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: kBlue,
                              ),
                            ),
                            Text(
                              '${t.tanggal}  •  ${t.kategori}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rp ${formatRupiah(t.totalPenjualan)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: kBlue,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              onChanged: (v) => setState(() {
                _selectedTransaksiIndex = v ?? 0;
                _teksSaved = false;
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard(Transaksi t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBlueBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBlue.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_long, color: kBlue, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.id,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kBlue,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${t.tanggal}  •  ${t.kategori}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: kBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Rp ${formatRupiah(t.totalPenjualan)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFCDD8F6)),
          const SizedBox(height: 10),
          ...t.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.fiber_manual_record, size: 6, color: kBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.jenisIkan,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    '${item.jumlahKg} kg',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rp ${formatRupiah(item.subtotal)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeksPreview(Transaksi t) {
    final isi = _buildTeksLaporan(t);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.preview, color: kBlue, size: 16),
            const SizedBox(width: 6),
            const Text(
              'Pratinjau File Laporan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kBlue,
              ),
            ),
            const Spacer(),
            Text(
              '${t.id}.PDF',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blueGrey.shade800),
          ),
          child: Text(
            isi,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Color(0xFF89DDFF),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    final btnColor = const Color(0xFF0E7490);
    final btnIcon = _teksSaved
        ? Icons.check_rounded
        : Icons.file_download_outlined;

    final VoidCallback? onPressed = _isSavingTeks ? null : _simpanFileTeks;

    final String btnLabel = _teksSaved
        ? 'File Berhasil Dibuat!'
        : (_isSavingTeks
              ? 'Membuat File...'
              : 'Ekspor File Laporan format PDF');

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: _isSavingTeks
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(btnIcon, size: 20),
        label: Text(
          btnLabel,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _teksSaved ? kGreen : btnColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: btnColor.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white70,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          shadowColor: btnColor.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  UI
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kirim Laporan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kBlue,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pilih transaksi lalu ekspor File Laporan PDF',
            style: TextStyle(fontSize: 13.5, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          _buildTransaksiSelector(),
          const SizedBox(height: 16),

          if (_selectedTransaksi != null) ...[
            _buildPreviewCard(_selectedTransaksi!),
            const SizedBox(height: 16),
          ],

          const Text(
            'Ekspor PDF',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),

          if (_selectedTransaksi != null) ...[
            _buildTeksPreview(_selectedTransaksi!),
            const SizedBox(height: 16),
          ],

          const Text(
            'Catatan (Opsional)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _catatanCtrl,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: buildInputDecoration(
              hint: 'Tambah catatan pada laporan...',
            ),
          ),
          const SizedBox(height: 20),

          _buildActionButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
