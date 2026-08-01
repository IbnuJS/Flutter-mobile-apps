import 'package:flutter/material.dart';
import 'app_data.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _q => _searchCtrl.text.trim().toLowerCase();

  List<Transaksi> get _filteredTransaksi {
    final list = List<Transaksi>.from(AppData().transaksiList);
    final q = _q;
    if (q.isEmpty) return list;
    return list
        .where(
          (t) =>
              t.id.toLowerCase().contains(q) ||
              t.kategori.toLowerCase().contains(q) ||
              t.items.any((i) => i.jenisIkan.toLowerCase().contains(q)),
        )
        .toList();
  }

  List<CatatanKeuangan> get _filteredKeuangan {
    final list = List<CatatanKeuangan>.from(AppData().catatanKeuanganList);
    final q = _q;
    if (q.isEmpty) return list;
    return list
        .where(
          (c) =>
              c.id.toLowerCase().contains(q) ||
              c.keterangan.toLowerCase().contains(q) ||
              c.jenis.name.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final transaksi = _filteredTransaksi;
    final keuangan = _filteredKeuangan;

    final totalTransaksi = transaksi.length;
    final totalKeuangan = keuangan.length;

    final sortDesc = (String tanggal) {
      try {
        final parts = tanggal.split('/');
        if (parts.length != 3) return DateTime(0);
        final d = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final y = int.parse(parts[2]);
        return DateTime(y, m, d);
      } catch (_) {
        return DateTime(0);
      }
    };

    transaksi.sort(
      (a, b) => sortDesc(b.tanggal).compareTo(sortDesc(a.tanggal)),
    );
    keuangan.sort((a, b) => sortDesc(b.tanggal).compareTo(sortDesc(a.tanggal)));

    return Column(
      children: [
        // Header & Summary
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Total Transaksi',
                      value: '$totalTransaksi data',
                      icon: Icons.receipt_long_rounded,
                      color: kBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Total Keuangan',
                      value: '$totalKeuangan catatan',
                      icon: Icons.account_balance_wallet_outlined,
                      color: kGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari ID, keterangan keuangan, dan jenis ikan',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Lists terpisah
        Expanded(
          child: (transaksi.isEmpty && keuangan.isEmpty)
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Text(
                        'Belum ada riwayat',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (transaksi.isNotEmpty) ...[
                      const Text(
                        'Riwayat Transaksi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...transaksi.map(
                        (t) => _HistoryCard(item: t, type: 'transaksi'),
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (keuangan.isNotEmpty) ...[
                      const Text(
                        'Riwayat Catatan Keuangan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...keuangan.map(
                        (c) => _HistoryCard(item: c, type: 'keuangan'),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
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

class _HistoryCard extends StatelessWidget {
  final dynamic item;
  final String type;
  const _HistoryCard({required this.item, required this.type});

  Color get _color => type == 'transaksi' ? kBlue : kGreen;
  IconData get _icon =>
      type == 'transaksi' ? Icons.receipt_long : Icons.account_balance_wallet;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon, color: _color, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type == 'transaksi'
                      ? (item as Transaksi).id
                      : (item as CatatanKeuangan).keterangan,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: _color,
                  ),
                ),
                Text(
                  item.tanggal,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  type == 'transaksi'
                      ? '${(item as Transaksi).items.length} jenis ikan'
                      : '${(item as CatatanKeuangan).jenis.name[0].toUpperCase()}${(item as CatatanKeuangan).jenis.name.substring(1)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            type == 'transaksi'
                ? 'Rp ${formatRupiah((item as Transaksi).totalPenjualan)}'
                : '${(item as CatatanKeuangan).jenis == JenisKeuangan.pemasukan ? '+' : '-'} Rp ${formatRupiah((item as CatatanKeuangan).jumlah)}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
