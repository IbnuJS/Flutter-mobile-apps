// ═══════════════════════════════════════════════════════════════════════════════
//  input.dart
//  Halaman Input Transaksi
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_data.dart';
import 'data/local/local_data_manager.dart';

// ─── Jarak rapat bersama ───────────────────────────────────────────────────
// Dipakai untuk SEMUA pasangan "kolom berdekatan" di halaman ini: jarak
// TextField-ke-tombol-daftar (Jenis Ikan, Harga) DAN jarak antar-kolom
// Berat-Harga. Satu sumber nilai — jika diubah, seluruh pasangan ikut
// menyesuaikan otomatis, sehingga keduanya TERJAMIN selalu berdekatan sama
// persis, bukan sekadar angka 6 yang kebetulan sama di beberapa tempat.
const double _kGapRapat = 6;

// ═══════════════════════════════════════════════════════════════════════════════
//  MASTER DATA — Daftar preset jenis ikan & harga (singleton, in-memory)
// ═══════════════════════════════════════════════════════════════════════════════

/// Singleton yang menyimpan daftar preset jenis ikan dan harga per kg.
/// Data ini dikelola pengguna (tambah / edit / hapus) dan dipakai
/// sebagai saran di kolom input transaksi.
class IkanMasterData {
  static final IkanMasterData _instance = IkanMasterData._internal();
  factory IkanMasterData() => _instance;
  IkanMasterData._internal();

  /// Daftar nama jenis ikan (preset). Pengguna bisa tambah/edit/hapus.
  final List<String> jenisIkanList = ['Ikan'];

  /// Daftar preset harga per kg (dalam Rupiah, sebagai double).
  /// Pengguna bisa tambah/edit/hapus.
  final List<double> hargaList = [15000];

  // ── Jenis Ikan ─────────────────────────────────────────────────────────────

  void tambahJenis(String nama) {
    final trimmed = nama.trim();
    if (trimmed.isEmpty) return;
    if (jenisIkanList.any((j) => j.toLowerCase() == trimmed.toLowerCase())) {
      return; // cegah duplikat
    }
    jenisIkanList.add(trimmed);
  }

  void editJenis(int index, String namaBaru) {
    final trimmed = namaBaru.trim();
    if (trimmed.isEmpty) return;
    jenisIkanList[index] = trimmed;
  }

  void hapusJenis(int index) {
    if (jenisIkanList.length > 1) jenisIkanList.removeAt(index);
  }

  // ── Harga ──────────────────────────────────────────────────────────────────

  void tambahHarga(double harga) {
    if (harga <= 0) return;
    if (hargaList.contains(harga)) return; // cegah duplikat
    hargaList
      ..add(harga)
      ..sort();
  }

  void editHarga(int index, double hargaBaru) {
    if (hargaBaru <= 0) return;
    hargaList[index] = hargaBaru;
    hargaList.sort();
  }

  void hapusHarga(int index) {
    if (hargaList.length > 1) hargaList.removeAt(index);
  }
}

// ─── MODEL ENTRI IKAN ─────────────────────────────────────────────────────────

class JenisIkanEntry {
  final TextEditingController jenisCtrl;
  final TextEditingController beratCtrl;
  final TextEditingController hargaCtrl;

  JenisIkanEntry()
    : jenisCtrl = TextEditingController(),
      beratCtrl = TextEditingController(),
      hargaCtrl = TextEditingController();

  double get subtotal {
    final berat = double.tryParse(beratCtrl.text) ?? 0;
    final harga =
        double.tryParse(
          hargaCtrl.text.replaceAll('.', '').replaceAll(',', ''),
        ) ??
        0;
    return berat * harga;
  }

  bool get isLengkap =>
      jenisCtrl.text.trim().isNotEmpty &&
      beratCtrl.text.isNotEmpty &&
      hargaCtrl.text.isNotEmpty;

  void dispose() {
    jenisCtrl.dispose();
    beratCtrl.dispose();
    hargaCtrl.dispose();
  }
}

// ─── HALAMAN INPUT TRANSAKSI ──────────────────────────────────────────────────

class InputTransaksiPage extends StatefulWidget {
  final void Function(int index)? onNavigate;
  const InputTransaksiPage({super.key, this.onNavigate});

  @override
  State<InputTransaksiPage> createState() => _InputTransaksiPageState();
}

class _InputTransaksiPageState extends State<InputTransaksiPage> {
  final List<JenisIkanEntry> _entries = [JenisIkanEntry()];
  final _tanggalCtrl = TextEditingController();

  final Set<String> _invalidFieldIds = <String>{};

  String _fid(int entryIndex, String field) => 'e$entryIndex:$field';

  bool _validateEntry(int i) {
    final e = _entries[i];

    final jenisOk = e.jenisCtrl.text.trim().isNotEmpty;
    final berat = double.tryParse(e.beratCtrl.text.replaceAll(',', '.'));
    final beratOk = berat != null && berat > 0;
    final harga = double.tryParse(
      e.hargaCtrl.text.replaceAll('.', '').replaceAll(',', '.'),
    );
    final hargaOk = harga != null && harga > 0;

    final jenisId = _fid(i, 'jenis');
    final beratId = _fid(i, 'berat');
    final hargaId = _fid(i, 'harga');

    setState(() {
      if (!jenisOk) _invalidFieldIds.add(jenisId);
      if (!beratOk) _invalidFieldIds.add(beratId);
      if (!hargaOk) _invalidFieldIds.add(hargaId);

      if (jenisOk) _invalidFieldIds.remove(jenisId);
      if (beratOk) _invalidFieldIds.remove(beratId);
      if (hargaOk) _invalidFieldIds.remove(hargaId);
    });

    return jenisOk && beratOk && hargaOk;
  }

  bool _validateAll() {
    _invalidFieldIds.clear();
    return List.generate(_entries.length, _validateEntry).every((v) => v);
  }

  double get _grandTotal => _entries.fold(0, (s, e) => s + e.subtotal);

  void _addEntry() => setState(() => _entries.add(JenisIkanEntry()));

  void _removeEntry(int i) {
    if (_entries.length <= 1) return;
    setState(() {
      _entries[i].dispose();
      _entries.removeAt(i);
    });
  }

  Future<void> _simpan() async {
    if (_tanggalCtrl.text.isEmpty) {
      _snack('Mohon pilih tanggal transaksi', isError: true);
      return;
    }

    final ok = _validateAll();
    if (!ok) {
      _snack('Lengkapi semua data item ikan', isError: true);
      return;
    }

    final validEntries = _entries.where((e) => e.isLengkap).toList();
    if (validEntries.isEmpty) {
      _snack(
        'Lengkapi minimal satu jenis ikan, berat, dan harga',
        isError: true,
      );
      return;
    }

    final items = validEntries
        .map(
          (e) => TransaksiItem(
            jenisIkan: e.jenisCtrl.text.trim(),
            jumlahKg: double.tryParse(e.beratCtrl.text) ?? 0,
            hargaPerKg:
                double.tryParse(
                  e.hargaCtrl.text.replaceAll('.', '').replaceAll(',', ''),
                ) ??
                0,
          ),
        )
        .toList();

    final newTrx = Transaksi(
      id: 'TRX${DateTime.now().millisecondsSinceEpoch}',
      tanggal: _tanggalCtrl.text,
      items: items,
      kategori: items.first.jenisIkan,
    );

    await LocalDataManager.tambahTransaksi(newTrx);

    for (final e in _entries) {
      e.dispose();
    }

    setState(() {
      _entries
        ..clear()
        ..add(JenisIkanEntry());
      _tanggalCtrl.clear();
      _invalidFieldIds.clear();
    });

    final totalItem = validEntries.length;
    final totalBeratKg = items.fold(0.0, (s, i) => s + i.jumlahKg);
    final totalPenjualan = items.fold(0.0, (s, i) => s + i.subtotal);
    _snack(
      'Tersimpan: $totalItem jenis • ${totalBeratKg.toStringAsFixed(2)} kg • Rp ${formatRupiah(totalPenjualan)}',
      isError: false,
    );

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) widget.onNavigate?.call(4);
  }

  void _snack(String msg, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(msg, style: kSnackTextStyle),
        backgroundColor: isError ? kRed : kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      ),
    );
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.dispose();
    }
    _tanggalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tambah data transaksi penjualan ikan',
            style: TextStyle(
              fontSize: 14,
              color: kBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _RingkasanJenisIkan(),
          const SizedBox(height: 12),

          _TanggalCard(ctrl: _tanggalCtrl, onChanged: () => setState(() {})),
          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(Icons.set_meal_rounded, color: kBlue, size: 20),
              const SizedBox(width: 6),
              const Text(
                'Daftar Ikan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: kBlue,
                ),
              ),
              const Spacer(),
              Text(
                '${_entries.length} item',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ...List.generate(
            _entries.length,
            (i) => _IkanEntryWidget(
              key: ValueKey(i),
              entry: _entries[i],
              index: i,
              onRemove: () => _removeEntry(i),
              onChanged: () => setState(() {}),
            ),
          ),

          GestureDetector(
            onTap: _addEntry,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: kBlueBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBlue.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: kBlue,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Tambah Jenis Ikan',
                    style: TextStyle(color: kBlue, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: kBlue.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Total Transaksi',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Rp ${formatRupiah(_grandTotal)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _simpan,
              icon: const Icon(Icons.save_rounded, size: 20),
              label: const Text(
                'Simpan Transaksi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  KARTU TANGGAL
// ══════════════════════════════════════════════════════════════════════════════

class _TanggalCard extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onChanged;
  const _TanggalCard({required this.ctrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: kBlue, size: 20),
              SizedBox(width: 6),
              Text(
                'Informasi Transaksi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: kBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Tanggal Transaksi',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            readOnly: true,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2060),
              );
              if (picked != null) {
                ctrl.text =
                    '${picked.day.toString().padLeft(2, '0')}/'
                    '${picked.month.toString().padLeft(2, '0')}/'
                    '${picked.year}';
                onChanged();
              }
            },
            decoration: buildInputDecoration(
              hint: 'Pilih tanggal transaksi',
              suffix: const Icon(Icons.calendar_today_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  WIDGET ENTRI IKAN
// ══════════════════════════════════════════════════════════════════════════════

class _IkanEntryWidget extends StatefulWidget {
  final JenisIkanEntry entry;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _IkanEntryWidget({
    super.key,
    required this.entry,
    required this.index,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_IkanEntryWidget> createState() => _IkanEntryWidgetState();
}

class _IkanEntryWidgetState extends State<_IkanEntryWidget> {
  final Color _color = kBlue;

  bool _isInvalid(String field) {
    final parent = context.findAncestorStateOfType<_InputTransaksiPageState>();
    if (parent == null) return false;
    final id = parent._fid(widget.index, field);
    return parent._invalidFieldIds.contains(id);
  }

  String? _getErrorText(String field) {
    if (!_isInvalid(field)) return null;
    switch (field) {
      case 'jenis':
        return 'Nama ikan wajib diisi';
      case 'berat':
        return 'Berat harus > 0';
      case 'harga':
        return 'Harga harus > 0';
      default:
        return 'Input tidak valid';
    }
  }

  InputBorder _borderFor(String field, {bool focused = false}) {
    final isInvalid = _isInvalid(field);
    final color = isInvalid ? kRed : (focused ? kBlue : Colors.black26);
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: color, width: focused ? 1.5 : 1.0),
    );
  }

  // ── Dialog: Kelola Daftar Jenis Ikan ───────────────────────────────────────

  Future<void> _showKelolaJenisIkan(BuildContext ctx) async {
    await showDialog(
      context: ctx,
      builder: (dialogCtx) => _KelolaJenisIkanDialog(
        onPilih: (nama) {
          widget.entry.jenisCtrl.text = nama;
          setState(() {});
          widget.onChanged();
        },
      ),
    );
    setState(() {});
  }

  // ── Dialog: Kelola Daftar Harga ────────────────────────────────────────────

  Future<void> _showKelolaHarga(BuildContext ctx) async {
    await showDialog(
      context: ctx,
      builder: (dialogCtx) => _KelolaHargaDialog(
        onPilih: (harga) {
          widget.entry.hargaCtrl.text = harga.toStringAsFixed(0);
          setState(() {});
          widget.onChanged();
        },
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header kartu ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(13),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.jenisCtrl.text.isEmpty
                        ? 'Ikan #${widget.index + 1}'
                        : entry.jenisCtrl.text,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kBlue,
                      fontSize: 13.50,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.index > 0)
                  GestureDetector(
                    onTap: widget.onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: kRed.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: kRed,
                        size: 15,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Body kartu ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Kolom Jenis Ikan + tombol daftar ──────────────────────
                _SectionLabel(label: 'Jenis Ikan'),
                const SizedBox(height: 6),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _AutocompleteJenisIkan(
                          controller: entry.jenisCtrl,
                          errorText: _getErrorText('jenis'),
                          enabledBorder: _borderFor('jenis', focused: false),
                          focusedBorder: _borderFor('jenis', focused: true),
                          onChanged: () {
                            setState(() {});
                            widget.onChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: _kGapRapat),
                      // Tombol buka dialog kelola daftar jenis ikan
                      _DaftarButton(
                        tooltip: 'Daftar & kelola jenis ikan',
                        onTap: () => _showKelolaJenisIkan(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ── Berat & Harga ──────────────────────────────────────────
                // ── Label Berat & Harga sejajar ─────────────────────────────
                Row(
                  children: [
                    Expanded(child: _SectionLabel(label: 'Berat (kg)')),
                    const SizedBox(width: _kGapRapat),
                    Expanded(
                      child: _SectionLabel(label: 'Harga per kg (Rp)'),
                    ),
                    const SizedBox(width: _kGapRapat),
                    // Placeholder tak-terlihat menyamai lebar tombol filter
                    // di baris kolom bawah, agar kedua label tetap sejajar
                    // persis dengan kolom Berat & Harga di bawahnya.
                    IgnorePointer(
                      child: Opacity(
                        opacity: 0,
                        child: _DaftarButton(tooltip: '', onTap: () {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // ── Kolom Berat, Harga, & tombol daftar — satu baris ────────
                // Berat & Harga sama-sama Expanded(flex:1) dalam SATU Row,
                // sehingga lebar keduanya otomatis identik. Tombol filter
                // diletakkan SETELAH keduanya (bukan menempel di kolom Harga
                // saja) — persis seperti pada kolom Jenis Ikan & filternya.
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: entry.beratCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          decoration: buildInputDecoration(hint: '0.0'),
                          onChanged: (_) {
                            setState(() {});
                            widget.onChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: _kGapRapat),
                      Expanded(
                        child: TextField(
                          controller: entry.hargaCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          decoration: buildInputDecoration(hint: '0'),
                          onChanged: (_) {
                            setState(() {});
                            widget.onChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: _kGapRapat),
                      // Tombol buka dialog kelola daftar harga.
                      // height:null → meregang ikut IntrinsicHeight di atas.
                      _DaftarButton(
                        tooltip: 'Daftar & kelola harga per kg',
                        onTap: () => _showKelolaHarga(context),
                        height: null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ── Subtotal ───────────────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: entry.subtotal > 0
                        ? _color.withValues(alpha: 0.08)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: entry.subtotal > 0
                          ? _color.withValues(alpha: 0.3)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calculate_rounded,
                            size: 15,
                            color: entry.subtotal > 0
                                ? _color
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Subtotal',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: entry.subtotal > 0
                                  ? _color
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Rp ${formatRupiah(entry.subtotal)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: entry.subtotal > 0
                              ? _color
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TOMBOL KECIL — buka daftar (ikon list)
// ══════════════════════════════════════════════════════════════════════════════

class _DaftarButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onTap;
  // Default 36 → perilaku lama tetap (dipakai tombol Jenis Ikan, tidak berubah).
  // Diisi null khusus di kolom Harga → meregang ikut IntrinsicHeight induknya.
  final double? height;
  const _DaftarButton({
    required this.tooltip,
    required this.onTap,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: height,
          width: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: kBlueBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: kBlue.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.list_rounded, color: kBlue, size: 20),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  AUTOCOMPLETE — Jenis Ikan
// ══════════════════════════════════════════════════════════════════════════════

/// TextField dengan saran dari IkanMasterData.jenisIkanList.
/// Pengguna tetap bisa mengetik bebas — saran hanya muncul jika ada kecocokan.
class _AutocompleteJenisIkan extends StatefulWidget {
  final TextEditingController controller;
  final String? errorText;
  final InputBorder enabledBorder;
  final InputBorder focusedBorder;
  final VoidCallback onChanged;

  const _AutocompleteJenisIkan({
    required this.controller,
    required this.errorText,
    required this.enabledBorder,
    required this.focusedBorder,
    required this.onChanged,
  });

  @override
  State<_AutocompleteJenisIkan> createState() => _AutocompleteJenisIkanState();
}

class _AutocompleteJenisIkanState extends State<_AutocompleteJenisIkan> {
  // PERBAIKAN BUG: FocusNode dibuat SEKALI di initState(), bukan di build().
  // Sebelumnya widget ini StatelessWidget dengan `focusNode: FocusNode()`
  // langsung di dalam build() — setiap kali mengetik satu huruf, onChanged()
  // memicu setState() di parent → widget ini di-rebuild → FocusNode() BARU
  // tercipta setiap kali → koneksi input dari OS terputus-sambung ulang →
  // kursor ketik ter-reset ke posisi awal setiap huruf yang diketik.
  // Dengan FocusNode dibuat sekali di initState(), identitasnya stabil
  // sepanjang hidup widget sehingga kursor tidak lagi berpindah posisi.
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (TextEditingValue tv) {
        final q = tv.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable<String>.empty();
        return IkanMasterData().jenisIkanList.where(
          (j) => j.toLowerCase().contains(q),
        );
      },
      onSelected: (String selected) {
        widget.controller.text = selected;
        widget.onChanged();
      },
      fieldViewBuilder: (ctx, ctrl, focusNode, onFieldSubmitted) {
        return TextField(
          controller: ctrl,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ ]+')),
          ],
          decoration: buildInputDecoration(hint: 'Nama Ikan').copyWith(
            errorText: widget.errorText,
            enabledBorder: widget.enabledBorder,
            focusedBorder: widget.focusedBorder,
          ),
          onChanged: (_) => widget.onChanged(),
        );
      },
      optionsViewBuilder: (ctx, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180, maxWidth: 220),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final opt = options.elementAt(i);
                  return InkWell(
                    onTap: () => onSelected(opt),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.set_meal_rounded,
                            size: 15,
                            color: kBlue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            opt,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  DIALOG — Kelola Daftar Jenis Ikan
// ══════════════════════════════════════════════════════════════════════════════

class _KelolaJenisIkanDialog extends StatefulWidget {
  final void Function(String nama) onPilih;
  const _KelolaJenisIkanDialog({required this.onPilih});

  @override
  State<_KelolaJenisIkanDialog> createState() => _KelolaJenisIkanDialogState();
}

class _KelolaJenisIkanDialogState extends State<_KelolaJenisIkanDialog> {
  final _ctrl = TextEditingController();
  int? _editingIndex;
  String? _errorMsg;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _simpan() {
    final val = _ctrl.text.trim();
    if (val.isEmpty) {
      setState(() => _errorMsg = 'Nama ikan tidak boleh kosong');
      return;
    }
    setState(() {
      if (_editingIndex == null) {
        IkanMasterData().tambahJenis(val);
      } else {
        IkanMasterData().editJenis(_editingIndex!, val);
        _editingIndex = null;
      }
      _ctrl.clear();
      _errorMsg = null;
    });
  }

  void _mulaiEdit(int index) {
    setState(() {
      _editingIndex = index;
      _ctrl.text = IkanMasterData().jenisIkanList[index];
      _errorMsg = null;
    });
  }

  void _batalEdit() {
    setState(() {
      _editingIndex = null;
      _ctrl.clear();
      _errorMsg = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = IkanMasterData().jenisIkanList;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: const BoxDecoration(
          color: kBlue,
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Row(
          children: [
            const Icon(Icons.set_meal_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Daftar Jenis Ikan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Colors.white70, size: 20),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Input tambah / edit
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ ]+'),
                      ),
                    ],
                    decoration: buildInputDecoration(
                      hint: _editingIndex == null
                          ? 'Tambah jenis ikan baru'
                          : 'Edit nama ikan',
                    ).copyWith(errorText: _errorMsg),
                    onSubmitted: (_) => _simpan(),
                  ),
                ),
                const SizedBox(width: 6),
                if (_editingIndex != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: kRed, size: 20),
                    tooltip: 'Batal edit',
                    padding: EdgeInsets.zero,
                    onPressed: _batalEdit,
                  ),
                IconButton(
                  icon: Icon(
                    _editingIndex == null
                        ? Icons.add_circle_rounded
                        : Icons.check_circle_rounded,
                    color: kGreen,
                    size: 26,
                  ),
                  tooltip: _editingIndex == null ? 'Tambah' : 'Simpan edit',
                  padding: EdgeInsets.zero,
                  onPressed: _simpan,
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),

            // Daftar ikan
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final isEditing = _editingIndex == i;
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 0,
                    ),
                    leading: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isEditing
                            ? kBlue
                            : kBlue.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.set_meal_rounded,
                          size: 15,
                          color: isEditing ? Colors.white : kBlue,
                        ),
                      ),
                    ),
                    title: Text(
                      list[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isEditing
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isEditing ? kBlue : Colors.black87,
                      ),
                    ),
                    onTap: () {
                      widget.onPilih(list[i]);
                      Navigator.pop(context);
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit
                        InkWell(
                          onTap: () => _mulaiEdit(i),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 17,
                              color: isEditing ? kBlue : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Hapus
                        InkWell(
                          onTap: list.length > 1
                              ? () {
                                  setState(() {
                                    IkanMasterData().hapusJenis(i);
                                    if (_editingIndex == i) _batalEdit();
                                  });
                                }
                              : null,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.delete_rounded,
                              size: 17,
                              color: list.length > 1 ? kRed : Colors.grey[300],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 6),
            Text(
              'Ketuk nama ikan untuk langsung memilihnya',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: kBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Tutup',
              style: TextStyle(color: kBlue, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  DIALOG — Kelola Daftar Harga per Kg
// ══════════════════════════════════════════════════════════════════════════════

class _KelolaHargaDialog extends StatefulWidget {
  final void Function(double harga) onPilih;
  const _KelolaHargaDialog({required this.onPilih});

  @override
  State<_KelolaHargaDialog> createState() => _KelolaHargaDialogState();
}

class _KelolaHargaDialogState extends State<_KelolaHargaDialog> {
  final _ctrl = TextEditingController();
  int? _editingIndex;
  String? _errorMsg;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _simpan() {
    final raw = _ctrl.text.replaceAll('.', '').replaceAll(',', '');
    final val = double.tryParse(raw);
    if (val == null || val <= 0) {
      setState(() => _errorMsg = 'Masukkan harga yang valid (> 0)');
      return;
    }
    setState(() {
      if (_editingIndex == null) {
        IkanMasterData().tambahHarga(val);
      } else {
        IkanMasterData().editHarga(_editingIndex!, val);
        _editingIndex = null;
      }
      _ctrl.clear();
      _errorMsg = null;
    });
  }

  void _mulaiEdit(int index) {
    setState(() {
      _editingIndex = index;
      _ctrl.text = IkanMasterData().hargaList[index].toStringAsFixed(0);
      _errorMsg = null;
    });
  }

  void _batalEdit() {
    setState(() {
      _editingIndex = null;
      _ctrl.clear();
      _errorMsg = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = IkanMasterData().hargaList;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: const BoxDecoration(
          color: kGreen,
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.price_change_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Daftar Harga per Kg',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Colors.white70, size: 20),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Input tambah / edit
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: buildInputDecoration(
                      hint: _editingIndex == null
                          ? 'Tambah harga baru (Rp)'
                          : 'Edit harga (Rp)',
                    ).copyWith(errorText: _errorMsg),
                    onSubmitted: (_) => _simpan(),
                  ),
                ),
                const SizedBox(width: 6),
                if (_editingIndex != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: kRed, size: 20),
                    tooltip: 'Batal edit',
                    padding: EdgeInsets.zero,
                    onPressed: _batalEdit,
                  ),
                IconButton(
                  icon: Icon(
                    _editingIndex == null
                        ? Icons.add_circle_rounded
                        : Icons.check_circle_rounded,
                    color: kGreen,
                    size: 26,
                  ),
                  tooltip: _editingIndex == null ? 'Tambah' : 'Simpan edit',
                  padding: EdgeInsets.zero,
                  onPressed: _simpan,
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),

            // Daftar harga
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final isEditing = _editingIndex == i;
                  final displayHarga = formatRupiah(list[i]);
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 0,
                    ),
                    leading: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isEditing
                            ? kGreen
                            : kGreen.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.attach_money_rounded,
                          size: 15,
                          color: isEditing ? Colors.white : kGreen,
                        ),
                      ),
                    ),
                    title: Text(
                      'Rp $displayHarga / kg',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isEditing
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isEditing ? kGreen : Colors.black87,
                      ),
                    ),
                    onTap: () {
                      widget.onPilih(list[i]);
                      Navigator.pop(context);
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit
                        InkWell(
                          onTap: () => _mulaiEdit(i),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 17,
                              color: isEditing ? kGreen : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Hapus
                        InkWell(
                          onTap: list.length > 1
                              ? () {
                                  setState(() {
                                    IkanMasterData().hapusHarga(i);
                                    if (_editingIndex == i) _batalEdit();
                                  });
                                }
                              : null,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.delete_rounded,
                              size: 17,
                              color: list.length > 1 ? kRed : Colors.grey[300],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 6),
            Text(
              'Ketuk harga untuk langsung memilihnya',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: kGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Tutup',
              style: TextStyle(color: kGreen, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  LABEL SEKSI
// ══════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: Colors.grey.shade600,
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  RINGKASAN JENIS IKAN
// ══════════════════════════════════════════════════════════════════════════════

class _RingkasanJenisIkan extends StatelessWidget {
  const _RingkasanJenisIkan();

  @override
  Widget build(BuildContext context) {
    final all = AppData().transaksiList;
    if (all.isEmpty) return const SizedBox.shrink();

    final Map<String, int> countMap = {};
    final Map<String, double> beratMap = {};

    for (final t in all) {
      for (final item in t.items) {
        countMap[item.jenisIkan] = (countMap[item.jenisIkan] ?? 0) + 1;
        beratMap[item.jenisIkan] =
            (beratMap[item.jenisIkan] ?? 0) + item.jumlahKg;
      }
    }

    final entries = countMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    const colors = [
      Color(0xFF1565C0),
      Color(0xFF2E7D32),
      Color(0xFFE65100),
      Color(0xFF6A1B9A),
      Color(0xFF00838F),
    ];

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: kBlue, size: 20),
              SizedBox(width: 6),
              Text(
                'Jenis Ikan Tercatat',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kBlue,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entries.asMap().entries.map((e) {
              final idx = e.key;
              final name = e.value.key;
              final count = e.value.value;
              final berat = beratMap[name] ?? 0;
              final color = colors[idx % colors.length];

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$count entri · ${berat % 1 == 0 ? berat.toStringAsFixed(0) : berat} kg',
                      style: TextStyle(
                        fontSize: 12,
                        color: color.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
