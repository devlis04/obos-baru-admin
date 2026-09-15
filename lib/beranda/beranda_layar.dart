import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../tema.dart';
import '../uang.dart';
import '../umpan.dart';
import 'admin_drawer.dart';
import 'dashboard_repo.dart';

class BerandaLayar extends StatefulWidget {
  const BerandaLayar({super.key});

  @override
  State<BerandaLayar> createState() => _BerandaLayarState();
}

class _BerandaLayarState extends State<BerandaLayar> {
  final _repo = DashboardRepo(Supabase.instance.client);
  bool _muat = true;
  late DateTime _senin;
  late DateTime _hari;
  IsiDashboard _isi = IsiDashboard.kosong(
    DateTime(2000),
    DateTime(2000),
  );

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _hari = DateTime(now.year, now.month, now.day);
    _senin = _seninDari(_hari);
    _isi = IsiDashboard.kosong(_senin, _hari);
    _muatData();
  }

  DateTime _seninDari(DateTime w) {
    final h = DateTime(w.year, w.month, w.day);
    return h.subtract(Duration(days: h.weekday - 1));
  }

  bool get _mingguIni {
    final s = _seninDari(DateTime.now());
    return s.year == _senin.year && s.month == _senin.month && s.day == _senin.day;
  }

  bool get _hariIni {
    final n = DateTime.now();
    return n.year == _hari.year && n.month == _hari.month && n.day == _hari.day;
  }

  String get _judulMinggu {
    if (_mingguIni) return 'Pencapaian minggu ini';
    return 'Pencapaian ${Uang.pendek(_senin)} – ${Uang.tanggal(_isi.sabtu)}';
  }

  String get _judulHari {
    if (_hariIni) return 'Pencapaian hari ini';
    return 'Pencapaian ${Uang.hariTanggal(_hari)}';
  }

  Future<void> _muatData() async {
    setState(() => _muat = true);
    try {
      final isi = await _repo.isi(senin: _senin, hari: _hari);
      if (!mounted) return;
      setState(() {
        _isi = isi;
        _senin = isi.senin;
        _hari = isi.hari;
        _muat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _muat = false);
      umpan(context, pesanGagal(e, 'Dashboard belum bisa dimuat.'));
    }
  }

  Future<void> _pilihMinggu() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _senin,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      helpText: 'Pilih tanggal di minggu Senin–Sabtu',
      cancelText: 'Batal',
      confirmText: 'Tampilkan',
    );
    if (picked == null) return;
    setState(() => _senin = _seninDari(picked));
    await _muatData();
  }

  Future<void> _pilihHari() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _hari,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      helpText: 'Pilih tanggal pencapaian',
      cancelText: 'Batal',
      confirmText: 'Tampilkan',
    );
    if (picked == null) return;
    setState(() => _hari = DateTime(picked.year, picked.month, picked.day));
    await _muatData();
  }

  double _persenLaba(int omset, int laba) {
    final modal = omset - laba;
    if (omset <= 0 || modal <= 0) return 0;
    return (laba / modal) * 100;
  }

  String _teksRasio(int omset, int laba) {
    final n = _persenLaba(omset, laba);
    return '${n.toStringAsFixed(2)}%';
  }

  double _pct(num nilai, num target) {
    if (target <= 0) return 0;
    return nilai / target;
  }

  static const _kodePasang = [
    ('SBGS01', 'SBGS02'),
    ('SBGS03', 'SBGS04'),
    ('SBGS05', 'SBGS06'),
    ('SBGS07', 'SBGS08'),
  ];

  List<(KartuDash?, KartuDash?)> _pasanganRute() {
    KartuDash? cari(String kode) {
      for (final k in _isi.rute) {
        if (k.rute.toUpperCase() == kode) return k;
      }
      return null;
    }

    final dipakai = <String>{};
    final out = <(KartuDash?, KartuDash?)>[];
    for (final p in _kodePasang) {
      final a = cari(p.$1);
      final b = cari(p.$2);
      if (a != null) dipakai.add(a.rute);
      if (b != null) dipakai.add(b.rute);
      out.add((a, b));
    }
    final sisa = [
      for (final k in _isi.rute)
        if (!dipakai.contains(k.rute)) k,
    ]..sort((a, b) => a.rute.compareTo(b.rute));
    for (var i = 0; i < sisa.length; i += 2) {
      out.add((sisa[i], i + 1 < sisa.length ? sisa[i + 1] : null));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: appBarAdmin(
        'Dashboard',
        actions: [
          IconButton(
            tooltip: 'Segarkan',
            onPressed: _muat ? null : _muatData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      drawer: const AdminDrawer(halaman: HalamanAdmin.beranda),
      body: Column(
        children: [
          if (_muat)
            LinearProgressIndicator(
              backgroundColor: theme.colorScheme.primary.withAlpha(30),
            )
          else
            const SizedBox(height: 4),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _muatData,
              child: LayoutBuilder(
                builder: (context, c) {
                  final duaSisi = c.maxWidth >= 980;
                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                          child: duaSisi
                              ? Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 11,
                                      child: _kolomTotal(theme),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(flex: 13, child: _kolomRute()),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 11,
                                      child: _kolomTotal(theme),
                                    ),
                                    const SizedBox(height: 10),
                                    Expanded(flex: 13, child: _kolomRute()),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kolomTotal(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Minggu Senin–Sabtu · Order vs Actual.',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Expanded(flex: 13, child: _kartuMinggu(theme)),
        const SizedBox(height: 10),
        Expanded(flex: 9, child: _kartuHari(theme)),
      ],
    );
  }

  Widget _kolomRute() {
    final pasang = _pasanganRute();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Per rute',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _isi.rute.isEmpty && !_muat
              ? Text(
                  'Belum ada akun sales di users.',
                  style: TextStyle(color: Colors.grey.shade600),
                )
              : Column(
                  children: [
                    for (var i = 0; i < pasang.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _slotRute(pasang[i].$1)),
                            const SizedBox(width: 8),
                            Expanded(child: _slotRute(pasang[i].$2)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _slotRute(KartuDash? k) {
    if (k == null) return const SizedBox.expand();
    return _kartuRute(k);
  }

  Widget _kartuMinggu(ThemeData theme) {
    final t = _isi.total;
    final m = t.minggu;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total · $_judulMinggu',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Pilih minggu',
                  onPressed: _muat ? null : _pilihMinggu,
                  icon: const Icon(Icons.date_range_outlined, color: Tema.seed),
                ),
              ],
            ),
            const Divider(height: 8),
            Expanded(
              child: _isiTarget(
                _barisTarget(
                  label: 'Rasio laba',
                  warna: Colors.green,
                  targetText: '${t.targetPersen.toStringAsFixed(2)}%',
                  orderText: _teksRasio(m.omsetOrder, m.labaOrder),
                  actualText: _teksRasio(m.omsetActual, m.labaActual),
                  persentaseOrder: _pct(
                    _persenLaba(m.omsetOrder, m.labaOrder),
                    t.targetPersen,
                  ),
                  persentaseActual: _pct(
                    _persenLaba(m.omsetActual, m.labaActual),
                    t.targetPersen,
                  ),
                ),
              ),
            ),
            const Divider(height: 8),
            Expanded(
              child: _isiTarget(
                _barisTarget(
                  label: 'Total omset',
                  warna: theme.colorScheme.primary,
                  targetText: Uang.rp(t.targetOmset),
                  orderText: Uang.rp(m.omsetOrder),
                  actualText: Uang.rp(m.omsetActual),
                  persentaseOrder: _pct(m.omsetOrder, t.targetOmset),
                  persentaseActual: _pct(m.omsetActual, t.targetOmset),
                ),
              ),
            ),
            const Divider(height: 8),
            Expanded(
              child: _isiTarget(
                _barisTarget(
                  label: 'Effective call',
                  warna: Colors.orangeAccent,
                  targetText: '${m.targetEc} toko',
                  orderText: '${m.ecOrder} toko',
                  actualText: '${m.ecActual} toko',
                  persentaseOrder: _pct(m.ecOrder, m.targetEc),
                  persentaseActual: _pct(m.ecActual, m.targetEc),
                ),
              ),
            ),
            const Divider(height: 8),
            Expanded(
              child: _isiTarget(
                _barisTarget(
                  label: 'Kunjungan visit',
                  warna: Colors.red,
                  targetText: '${m.targetVisit} toko',
                  actualText: '${m.visit} toko',
                  persentaseActual: _pct(m.visit, m.targetVisit),
                  tampilkanOrder: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kartuHari(ThemeData theme) {
    final t = _isi.total;
    final h = t.hari;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total · $_judulHari',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Pilih tanggal',
                  onPressed: _muat ? null : _pilihHari,
                  icon: const Icon(
                    Icons.calendar_today_outlined,
                    color: Tema.seed,
                  ),
                ),
              ],
            ),
            const Divider(height: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _kotakHari(
                      label: 'Rasio laba',
                      warna: Colors.green,
                      orderText: _teksRasio(h.omsetOrder, h.labaOrder),
                      actualText: _teksRasio(h.omsetActual, h.labaActual),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _kotakHari(
                      label: 'Omset',
                      warna: theme.colorScheme.primary,
                      orderText: Uang.rp(h.omsetOrder),
                      actualText: Uang.rp(h.omsetActual),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _kotakHari(
                      label: 'Effective call',
                      warna: Colors.orangeAccent,
                      targetText: '${h.targetEc} toko',
                      orderText: '${h.ecOrder} toko',
                      actualText: '${h.ecActual} toko',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _kotakHari(
                      label: 'Kunjungan visit',
                      warna: Colors.red,
                      targetText: '${h.targetVisit} toko',
                      actualText: '${h.visit} toko',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kartuRute(KartuDash k) {
    final m = k.minggu;
    final h = k.hari;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              k.judul,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _sisiRute(
                      judul: 'Minggu',
                      anak: [
                        _barisKecil(
                          'Omset',
                          Uang.rp(m.omsetOrder),
                          Uang.rp(m.omsetActual),
                        ),
                        _barisKecil(
                          'Rasio',
                          _teksRasio(m.omsetOrder, m.labaOrder),
                          _teksRasio(m.omsetActual, m.labaActual),
                        ),
                        _barisKecil('EC', '${m.ecOrder}', '${m.ecActual}'),
                        Text(
                          'Visit ${m.visit} / ${m.targetVisit}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  VerticalDivider(
                    width: 16,
                    thickness: 1,
                    color: Colors.grey.shade300,
                  ),
                  Expanded(
                    child: _sisiRute(
                      judul: _hariIni ? 'Hari ini' : Uang.tanggal(_hari),
                      anak: [
                        _barisKecil(
                          'Omset',
                          Uang.rp(h.omsetOrder),
                          Uang.rp(h.omsetActual),
                        ),
                        _barisKecil(
                          'Rasio',
                          _teksRasio(h.omsetOrder, h.labaOrder),
                          _teksRasio(h.omsetActual, h.labaActual),
                        ),
                        _barisKecil('EC', '${h.ecOrder}', '${h.ecActual}'),
                        Text(
                          'Visit ${h.visit} / ${h.targetVisit}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _sisiRute({required String judul, required List<Widget> anak}) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              judul,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            ...anak,
          ],
        ),
      ),
    );
  }

  Widget _isiTarget(Widget anak) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: SizedBox(width: 420, child: anak),
    );
  }

  Widget _barisKecil(String label, String order, String actual) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ),
          Expanded(
            child: Text(
              order,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              actual,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barisTarget({
    required String label,
    required Color warna,
    required String targetText,
    required String actualText,
    required double persentaseActual,
    String? orderText,
    double persentaseOrder = 0,
    bool tampilkanOrder = true,
  }) {
    final gayaTarget = TextStyle(
      fontSize: 12,
      color: Colors.grey.shade600,
      fontWeight: FontWeight.w500,
    );
    const gayaIsi = TextStyle(
      fontSize: 12,
      color: Colors.black87,
      fontWeight: FontWeight.bold,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: warna,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _barisUang('Target', targetText, gayaTarget),
              if (tampilkanOrder) _barisUang('Order', orderText ?? '', gayaIsi),
              _barisUang('Actual', actualText, gayaIsi),
            ],
          ),
        ),
        if (tampilkanOrder) ...[
          _cincin(label: 'Order', persentase: persentaseOrder, warna: warna),
          const SizedBox(width: 8),
        ],
        _cincin(label: 'Actual', persentase: persentaseActual, warna: warna),
      ],
    );
  }

  Widget _barisUang(String judul, String nilai, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, top: 1),
      child: Row(
        children: [
          SizedBox(width: 52, child: Text(judul, style: style)),
          Expanded(
            child: Text(
              nilai,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cincin({
    required String label,
    required double persentase,
    required Color warna,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 42,
          height: 42,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(42, 42),
                painter: _CincinPainter(percentage: persentase, color: warna),
              ),
              Text(
                '${(persentase * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: persentase >= 1 ? 8 : 9,
                  fontWeight: FontWeight.bold,
                  color: warna,
                ),
              ),
            ],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _kotakHari({
    required String label,
    required Color warna,
    required String actualText,
    String? orderText,
    String? targetText,
  }) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: Tema.sudut,
        border: Border.all(color: Tema.seed),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: warna,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          if (targetText != null) ...[
            const SizedBox(height: 4),
            Text(
              'Target : $targetText',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          if (orderText != null)
            Text(
              'Order : $orderText',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          Text(
            orderText == null && targetText == null
                ? actualText
                : 'Actual : $actualText',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          ],
        ),
      ),
    );
  }
}

class _CincinPainter extends CustomPainter {
  _CincinPainter({required this.percentage, required this.color});

  final double percentage;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    const strokeWidth = 5.0;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..color = color.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);
    if (percentage > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;
      canvas.drawArc(
        rect,
        -3.141592653589793 / 2,
        percentage.clamp(0.0, 1.0) * 2 * 3.141592653589793,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CincinPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}
