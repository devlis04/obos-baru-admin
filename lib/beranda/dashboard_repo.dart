import 'package:supabase_flutter/supabase_flutter.dart';

import '../uang.dart';

class CapaianDash {
  const CapaianDash({
    required this.omsetOrder,
    required this.labaOrder,
    required this.omsetActual,
    required this.labaActual,
    required this.ecOrder,
    required this.ecActual,
    required this.visit,
    required this.targetEc,
    required this.targetVisit,
  });

  final int omsetOrder;
  final int labaOrder;
  final int omsetActual;
  final int labaActual;
  final int ecOrder;
  final int ecActual;
  final int visit;
  final int targetEc;
  final int targetVisit;

  static const kosong = CapaianDash(
    omsetOrder: 0,
    labaOrder: 0,
    omsetActual: 0,
    labaActual: 0,
    ecOrder: 0,
    ecActual: 0,
    visit: 0,
    targetEc: 1,
    targetVisit: 1,
  );

  factory CapaianDash.dari(Map<String, dynamic>? j) {
    if (j == null) return kosong;
    return CapaianDash(
      omsetOrder: Uang.dari(j['omset_order']),
      labaOrder: Uang.dari(j['laba_order']),
      omsetActual: Uang.dari(j['omset_actual']),
      labaActual: Uang.dari(j['laba_actual']),
      ecOrder: Uang.dari(j['ec_order']),
      ecActual: Uang.dari(j['ec_actual']),
      visit: Uang.dari(j['visit']),
      targetEc: Uang.dari(j['target_ec']).clamp(1, 1 << 30),
      targetVisit: Uang.dari(j['target_visit']).clamp(1, 1 << 30),
    );
  }
}

class KartuDash {
  const KartuDash({
    required this.rute,
    required this.nama,
    required this.targetOmset,
    required this.targetPersen,
    required this.minggu,
    required this.hari,
  });

  final String rute;
  final String nama;
  final int targetOmset;
  final double targetPersen;
  final CapaianDash minggu;
  final CapaianDash hari;

  static const totalKosong = KartuDash(
    rute: '',
    nama: 'Total',
    targetOmset: 0,
    targetPersen: 0,
    minggu: CapaianDash.kosong,
    hari: CapaianDash.kosong,
  );

  factory KartuDash.dari(Map<String, dynamic>? j) {
    if (j == null) return totalKosong;
    return KartuDash(
      rute: (j['rute']?.toString() ?? '').trim(),
      nama: (j['nama']?.toString() ?? '').trim(),
      targetOmset: Uang.dari(j['target_omset']),
      targetPersen: (j['target_persen'] as num?)?.toDouble() ?? 0,
      minggu: CapaianDash.dari(
        j['minggu'] is Map
            ? Map<String, dynamic>.from(j['minggu'] as Map)
            : null,
      ),
      hari: CapaianDash.dari(
        j['hari'] is Map ? Map<String, dynamic>.from(j['hari'] as Map) : null,
      ),
    );
  }

  String get judul {
    if (rute.isEmpty) return nama.isEmpty ? 'Total' : nama;
    if (nama.isEmpty) return rute;
    return '$rute · $nama';
  }
}

class IsiDashboard {
  const IsiDashboard({
    required this.senin,
    required this.sabtu,
    required this.hari,
    required this.total,
    required this.rute,
  });

  final DateTime senin;
  final DateTime sabtu;
  final DateTime hari;
  final KartuDash total;
  final List<KartuDash> rute;

  static IsiDashboard kosong(DateTime senin, DateTime hari) {
    return IsiDashboard(
      senin: senin,
      sabtu: senin.add(const Duration(days: 5)),
      hari: hari,
      total: KartuDash.totalKosong,
      rute: const [],
    );
  }
}

class DashboardRepo {
  DashboardRepo(this._sb);
  final SupabaseClient _sb;

  static const _tunggu = Duration(seconds: 30);

  Future<IsiDashboard> isi({
    required DateTime senin,
    required DateTime hari,
  }) async {
    final hasil = await _sb
        .rpc(
          'admin_dashboard',
          params: {
            'p_senin': Uang.isoHari(senin),
            'p_hari': Uang.isoHari(hari),
          },
        )
        .timeout(_tunggu);
    if (hasil is! Map) {
      throw Exception('Dashboard belum bisa dimuat.');
    }
    return _baca(Map<String, dynamic>.from(hasil));
  }

  IsiDashboard _baca(Map<String, dynamic> j) {
    final senin = _tgl(j['senin']) ?? DateTime.now();
    final sabtu =
        _tgl(j['sabtu']) ?? senin.add(const Duration(days: 5));
    final hari = _tgl(j['hari']) ?? DateTime.now();
    final rute = <KartuDash>[];
    final raw = j['rute'];
    if (raw is List) {
      for (final e in raw) {
        if (e is! Map) continue;
        rute.add(KartuDash.dari(Map<String, dynamic>.from(e)));
      }
    }
    return IsiDashboard(
      senin: senin,
      sabtu: sabtu,
      hari: hari,
      total: KartuDash.dari(
        j['total'] is Map ? Map<String, dynamic>.from(j['total'] as Map) : null,
      ),
      rute: rute,
    );
  }

  DateTime? _tgl(Object? v) {
    final s = v?.toString().trim() ?? '';
    if (s.isEmpty) return null;
    return DateTime.tryParse(s.length >= 10 ? s.substring(0, 10) : s);
  }
}
